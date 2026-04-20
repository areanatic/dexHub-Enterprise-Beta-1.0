#!/usr/bin/env bash
# DexHub L2 Tank — Query
# ==========================================================
# Hybrid keyword + semantic search over the chunk store. Output
# formatted as markdown (default) or JSON, suitable for pasting into a
# Copilot/Claude chat as context, or for build-time baking
# into copilot-instructions.md (see build-instructions.sh
# wire-copilot integration in 5.2.b-wire-copilot slice).
#
# Modes:
#   keyword-only   FTS5 BM25, no embedding used
#   semantic-only  cosine-similarity over query+chunk embeddings only
#   hybrid         α·keyword + (1-α)·semantic (default α=0.5)
#   auto           hybrid when embeddings + backend are ready, else keyword-only
#
# Default is auto. Explicit flags --keyword-only / --hybrid / --semantic-only
# override. --alpha N tunes the hybrid weight (keyword side; 0.0..1.0).
#
# Usage:
#   bash l2-query.sh "how did we handle X"
#   bash l2-query.sh --top 10 "search terms"
#   bash l2-query.sh --format json "search"
#   bash l2-query.sh --db CUSTOM.sqlite "search"
#   bash l2-query.sh --source-type wiki "only from wiki"
#   bash l2-query.sh --quiet "no header chrome"           # copilot-wire safe
#   bash l2-query.sh --hybrid "query"                      # force hybrid, needs embeddings
#   bash l2-query.sh --keyword-only "query"                # force FTS5
#   bash l2-query.sh --semantic-only "query"               # force cosine, needs embeddings
#   bash l2-query.sh --alpha 0.3 "query"                   # keyword weight 30% / semantic 70%
#
# Exit codes:
#   0   success (may return 0 results with a "no matches" notice)
#   1   bad args / empty query
#   2   sqlite3 not available
#   3   DB missing (not initialized)
#   4   --semantic-only or --hybrid requested but backend not ready

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"

DEFAULT_DB="$REPO_ROOT/myDex/.dex/l2/tank.sqlite"
DB="$DEFAULT_DB"
TOP=5
FORMAT="markdown"
QUERY=""
SOURCE_TYPE=""
QUIET=0
MODE="auto"          # auto | keyword-only | hybrid | semantic-only
ALPHA="0.5"          # weight on keyword side (0.0 = pure semantic, 1.0 = pure keyword)

while [ $# -gt 0 ]; do
  case "$1" in
    --db)            DB="$2"; shift 2 ;;
    --top)           TOP="$2"; shift 2 ;;
    --format)        FORMAT="$2"; shift 2 ;;
    --source-type)   SOURCE_TYPE="$2"; shift 2 ;;
    --quiet)         QUIET=1; shift ;;
    --keyword-only)  MODE="keyword-only"; shift ;;
    --hybrid)        MODE="hybrid"; shift ;;
    --semantic-only) MODE="semantic-only"; shift ;;
    --alpha)         ALPHA="$2"; shift 2 ;;
    --help|-h)
      sed -n '2,34p' "${BASH_SOURCE[0]}"
      exit 0
      ;;
    -*)
      echo "ERROR: unknown flag: $1" >&2
      exit 1
      ;;
    *)
      if [ -n "$QUERY" ]; then
        QUERY="$QUERY $1"  # concatenate unquoted multi-word queries
      else
        QUERY="$1"
      fi
      shift
      ;;
  esac
done

if [ -z "$QUERY" ]; then
  echo "ERROR: query text required. Usage: l2-query.sh \"your query\"" >&2
  exit 1
fi

command -v sqlite3 >/dev/null 2>&1 || { echo "ERROR: sqlite3 not installed" >&2; exit 2; }

if [ ! -f "$DB" ]; then
  # Empty tank is not an error — just no results
  if [ "$QUIET" = "0" ]; then
    if [ "$FORMAT" = "json" ]; then
      printf '{"query": %s, "results": [], "notice": "tank not initialized"}\n' \
        "$(printf '%s' "$QUERY" | ruby -rjson -e 'puts STDIN.read.to_json')"
    else
      echo "# L2 TANK — no results"
      echo ""
      echo "Tank not initialized at $DB. Run l2-init.sh first."
    fi
  fi
  exit 0
fi

# Verify schema
if ! sqlite3 "$DB" "SELECT value FROM meta WHERE key='schema_version'" >/dev/null 2>&1; then
  echo "ERROR: DB schema incomplete at $DB — run l2-init.sh" >&2
  exit 3
fi

# Count total + chunks matching (for headline)
TOTAL_CHUNKS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM chunks" 2>/dev/null)
if [ "$TOTAL_CHUNKS" = "0" ]; then
  if [ "$QUIET" = "0" ]; then
    if [ "$FORMAT" = "json" ]; then
      printf '{"query": %s, "results": [], "notice": "tank is empty"}\n' \
        "$(printf '%s' "$QUERY" | ruby -rjson -e 'puts STDIN.read.to_json')"
    else
      echo "# L2 TANK — no results"
      echo ""
      echo "Tank is empty. Ingest content via l2-ingest.sh first."
    fi
  fi
  exit 0
fi

# ─── Decide effective mode ─────────────────────────────────────────
# auto mode: use hybrid if embeddings exist AND backend is ready, else keyword
EMB_COUNT=$(sqlite3 "$DB" "SELECT COUNT(*) FROM embeddings" 2>/dev/null || echo 0)
SEMANTIC_READY="false"
BACKEND=""
SETUP_HINT=""
BACKEND_STATUS=""
POLICY_VALUE=""
POLICY_NOTE=""
if [ -x "$SCRIPT_DIR/l2-detect-backend.sh" ]; then
  DETECT_JSON=$("$SCRIPT_DIR/l2-detect-backend.sh" --db "$DB" --format json 2>/dev/null || echo "{}")
  SEMANTIC_READY=$(printf "%s" "$DETECT_JSON" | ruby -rjson -e 'd=JSON.parse(STDIN.read) rescue {}; puts d["semantic_available"] ? "true" : "false"' 2>/dev/null || echo "false")
  BACKEND=$(printf "%s" "$DETECT_JSON" | ruby -rjson -e 'd=JSON.parse(STDIN.read) rescue {}; puts d["backend"] || ""' 2>/dev/null)
  SETUP_HINT=$(printf "%s" "$DETECT_JSON" | ruby -rjson -e 'd=JSON.parse(STDIN.read) rescue {}; puts d["setup_hint"] || ""' 2>/dev/null)
  BACKEND_STATUS=$(printf "%s" "$DETECT_JSON" | ruby -rjson -e 'd=JSON.parse(STDIN.read) rescue {}; puts d["status"] || ""' 2>/dev/null)
  POLICY_VALUE=$(printf "%s" "$DETECT_JSON" | ruby -rjson -e 'd=JSON.parse(STDIN.read) rescue {}; puts d["policy"] || ""' 2>/dev/null)
  POLICY_NOTE=$(printf "%s" "$DETECT_JSON" | ruby -rjson -e 'd=JSON.parse(STDIN.read) rescue {}; puts d["policy_note"] || ""' 2>/dev/null)
fi

EFFECTIVE_MODE="keyword-only"
case "$MODE" in
  auto)
    if [ "$SEMANTIC_READY" = "true" ] && [ "$EMB_COUNT" -gt 0 ]; then
      EFFECTIVE_MODE="hybrid"
    else
      EFFECTIVE_MODE="keyword-only"
    fi
    ;;
  keyword-only)
    EFFECTIVE_MODE="keyword-only"
    ;;
  hybrid|semantic-only)
    if [ "$BACKEND_STATUS" = "blocked" ]; then
      echo "ERROR: --$MODE uses backend '$BACKEND' which is BLOCKED by data_handling_policy=$POLICY_VALUE." >&2
      echo "       Reason: $POLICY_NOTE" >&2
      echo "       Resolve: switch to a local backend (ollama/*) or update profile.yaml." >&2
      exit 4
    fi
    if [ "$SEMANTIC_READY" != "true" ]; then
      echo "ERROR: --$MODE requested but backend not ready (${SETUP_HINT:-no backend available})" >&2
      exit 4
    fi
    if [ "$EMB_COUNT" = "0" ]; then
      echo "ERROR: --$MODE requested but no embeddings in tank. Run l2-embed.sh first." >&2
      exit 4
    fi
    EFFECTIVE_MODE="$MODE"
    ;;
esac

# ─── Mode banner (user-facing, skipped under --quiet) ───────────────
compute_mode_banner() {
  case "$EFFECTIVE_MODE" in
    keyword-only)
      if [ "$EMB_COUNT" -gt 0 ]; then
        echo "Mode: KEYWORD-ONLY (BM25 via FTS5) — forced via flag; $EMB_COUNT embeddings unused"
      elif [ -n "$SETUP_HINT" ] && [ "$SEMANTIC_READY" != "true" ]; then
        echo "Mode: KEYWORD-ONLY (BM25 via FTS5)  ·  enable semantic: $SETUP_HINT"
      else
        echo "Mode: KEYWORD-ONLY (BM25 via FTS5)"
      fi
      ;;
    hybrid)
      echo "Mode: HYBRID (BM25 × $ALPHA + cosine × $(awk -v a="$ALPHA" 'BEGIN{printf "%.2f", 1-a}')) via $BACKEND"
      ;;
    semantic-only)
      echo "Mode: SEMANTIC-ONLY (cosine similarity) via $BACKEND"
      ;;
  esac
}

# ─── Keyword-only path ─────────────────────────────────────────────
escape_for_fts() {
  printf "%s" "$1" | sed 's/"/""/g'
}
escape_sql() {
  printf "%s" "$1" | sed "s/'/''/g"
}

FTS_QUERY=$(escape_for_fts "$QUERY")
SOURCE_TYPE_CLAUSE=""
if [ -n "$SOURCE_TYPE" ]; then
  SOURCE_TYPE_CLAUSE="AND c.source_type = '$(escape_sql "$SOURCE_TYPE")'"
fi

emit_keyword_only_results() {
  # Run FTS5 query. rank is BM25 (lower = more relevant in SQLite FTS5).
  local raw_json
  raw_json=$(sqlite3 "$DB" <<SQL 2>/dev/null
.mode json
SELECT c.id, c.title, c.source_path, c.source_type, c.content, fts.rank
FROM chunks_fts fts
JOIN chunks c ON c.id = fts.rowid
WHERE chunks_fts MATCH '"$FTS_QUERY"'
  $SOURCE_TYPE_CLAUSE
ORDER BY fts.rank
LIMIT $TOP;
SQL
)
  [ -z "$raw_json" ] && raw_json="[]"
  printf "%s" "$raw_json"
}

# Hybrid / semantic path is inlined below (shell-level). The ruby block
# does the heavy lifting: query embedding via Ollama, candidate merge from
# FTS5 top-K + all embedded chunks, cosine sim per candidate, blended rank,
# emits the same JSON shape as the keyword-only path so the downstream
# markdown/JSON renderer stays unchanged.

# Decide output JSON
if [ "$EFFECTIVE_MODE" = "keyword-only" ]; then
  RAW_JSON=$(emit_keyword_only_results)
else
  # Pass query via env var to avoid shell-escape issues
  export L2_QUERY_TEXT="$QUERY"
  # Ruby reads two JSON blobs from stdin separated by form-feed (\f = \x0c)
  # We don't actually use this split — the helper re-reads from variables below
  # but we still stream for forward-compat. Cleanest: invoke helper and pass
  # the two blobs on stdin.

  # Re-fetch candidates (same queries as inside emit_hybrid_results but at shell level)
  source_filter_sh=""
  if [ -n "$SOURCE_TYPE" ]; then
    source_filter_sh="AND c.source_type = '$(escape_sql "$SOURCE_TYPE")'"
  fi
  KW_CANDIDATES=$(sqlite3 "$DB" <<SQL 2>/dev/null
.mode json
SELECT c.id, c.title, c.source_path, c.source_type, c.content, fts.rank AS kw_rank, NULL AS embedding
FROM chunks_fts fts
JOIN chunks c ON c.id = fts.rowid
WHERE chunks_fts MATCH '"$FTS_QUERY"'
  $source_filter_sh
ORDER BY fts.rank
LIMIT $((TOP * 10));
SQL
)
  [ -z "$KW_CANDIDATES" ] && KW_CANDIDATES="[]"

  BACKEND_ESC=$(escape_sql "$BACKEND")
  SEM_CANDIDATES=$(sqlite3 "$DB" <<SQL 2>/dev/null
.mode json
SELECT c.id, c.title, c.source_path, c.source_type, c.content, NULL AS kw_rank, e.vector_json AS embedding
FROM chunks c
JOIN embeddings e ON e.chunk_id = c.id AND e.backend = '$BACKEND_ESC'
WHERE 1=1 $source_filter_sh
LIMIT 500;
SQL
)
  [ -z "$SEM_CANDIDATES" ] && SEM_CANDIDATES="[]"

  RAW_JSON=$(printf '%s\x0c%s' "$KW_CANDIDATES" "$SEM_CANDIDATES" | \
    L2_QUERY_TEXT="$QUERY" ruby -rjson -ropen3 - "$EFFECTIVE_MODE" "$ALPHA" "$TOP" "http://localhost:11434" "${BACKEND#*/}" <<'HYBRID_RUBY'
mode = ARGV[0]
alpha = ARGV[1].to_f
top = ARGV[2].to_i
endpoint = ARGV[3]
model = ARGV[4]

payload = STDIN.read
kw_json, sem_json = payload.split("\x0c", 2)
kw_arr  = (kw_json  && !kw_json.empty?)  ? JSON.parse(kw_json)  : []
sem_arr = (sem_json && !sem_json.empty?) ? JSON.parse(sem_json) : []

query_text = ENV["L2_QUERY_TEXT"] || ""
body = JSON.generate({"model" => model, "prompt" => query_text})
out, _, status = Open3.capture3("curl", "-sS", "--max-time", "60", "-X", "POST",
  endpoint + "/api/embeddings",
  "-H", "Content-Type: application/json",
  "-d", body)
unless status.success? && !out.empty?
  STDERR.puts "ERROR: query embedding failed (http)"
  puts "[]"
  exit 2
end
qresp = JSON.parse(out)
qvec = qresp["embedding"]
unless qvec.is_a?(Array) && qvec.length > 0
  STDERR.puts "ERROR: query embedding empty"
  puts "[]"
  exit 2
end
qnorm = Math.sqrt(qvec.reduce(0.0) { |s, x| s + x * x })

by_id = {}
kw_arr.each do |row|
  by_id[row["id"]] = { row: row, kw_rank: row["kw_rank"].to_f, embedding: nil }
end
sem_arr.each do |row|
  id = row["id"]
  if by_id[id]
    by_id[id][:embedding] = row["embedding"]
  else
    by_id[id] = { row: row, kw_rank: nil, embedding: row["embedding"] }
  end
end

kw_ranks = by_id.values.map { |v| v[:kw_rank] }.compact
kw_max = kw_ranks.empty? ? nil : kw_ranks.min
kw_min = kw_ranks.empty? ? nil : kw_ranks.max
kw_range = (kw_max && kw_min) ? (kw_min - kw_max) : 0

results = []
by_id.each do |id, v|
  sem_score = 0.0
  if v[:embedding] && !v[:embedding].to_s.empty?
    chunk_vec = JSON.parse(v[:embedding]) rescue nil
    if chunk_vec.is_a?(Array) && chunk_vec.length == qvec.length
      dot = 0.0
      cnorm = 0.0
      chunk_vec.each_with_index do |x, i|
        dot += x * qvec[i]
        cnorm += x * x
      end
      cnorm = Math.sqrt(cnorm)
      cos = (qnorm > 0 && cnorm > 0) ? (dot / (qnorm * cnorm)) : 0.0
      sem_score = (cos + 1.0) / 2.0
    end
  end

  kw_score = 0.0
  if v[:kw_rank] && kw_range > 0
    kw_score = (kw_min - v[:kw_rank]) / kw_range
  elsif v[:kw_rank]
    kw_score = 1.0
  end

  hybrid = 0.0
  case mode
  when "hybrid"
    hybrid = alpha * kw_score + (1.0 - alpha) * sem_score
  when "semantic-only"
    hybrid = sem_score
  end

  next if mode == "semantic-only" && (v[:embedding].nil? || v[:embedding].to_s.empty?)
  next if mode == "hybrid" && v[:kw_rank].nil? && sem_score == 0.0

  results << {
    "id" => id,
    "title" => v[:row]["title"],
    "source_path" => v[:row]["source_path"],
    "source_type" => v[:row]["source_type"],
    "content" => v[:row]["content"],
    "rank" => hybrid,
    "keyword_score" => kw_score.round(4),
    "semantic_score" => sem_score.round(4),
    "hybrid_score" => hybrid.round(4)
  }
end

results.sort_by! { |r| -r["rank"] }
puts JSON.generate(results[0...top])
HYBRID_RUBY
)
  [ -z "$RAW_JSON" ] && RAW_JSON="[]"
fi

RESULT_COUNT=$(printf '%s' "$RAW_JSON" | ruby -rjson -e 'puts JSON.parse(STDIN.read).length' 2>/dev/null || echo 0)

# Total matches (not limited) for headline — keep keyword-oriented stat for now
TOTAL_MATCHES=$(sqlite3 "$DB" "SELECT COUNT(*) FROM chunks_fts WHERE chunks_fts MATCH '\"$(escape_sql "$FTS_QUERY")\"'" 2>/dev/null || echo "?")

# ─── Output ───────────────────────────────────────────────────────────
if [ "$FORMAT" = "json" ]; then
  printf '%s' "$RAW_JSON" | ruby -rjson -e '
    query = ARGV[0]
    total_matches = ARGV[1].to_i
    top = ARGV[2].to_i
    mode = ARGV[3]
    results = JSON.parse(STDIN.read)
    out = { query: query, total_matches: total_matches, top: top, mode: mode, results: results }
    puts JSON.pretty_generate(out)
  ' "$QUERY" "$TOTAL_MATCHES" "$TOP" "$EFFECTIVE_MODE"
  exit 0
fi

# Markdown output
if [ "$QUIET" = "0" ]; then
  echo "# L2 TANK — results for \"$QUERY\""
  echo ""
  echo "  $(compute_mode_banner)"
  echo ""
  if [ "$RESULT_COUNT" = "0" ]; then
    echo "No matches in $TOTAL_CHUNKS indexed chunks."
    echo ""
    exit 0
  fi
  echo "($RESULT_COUNT shown, $TOTAL_MATCHES matched, top $TOP)"
  echo ""
fi

printf '%s' "$RAW_JSON" | ruby -rjson -e '
  results = JSON.parse(STDIN.read)
  first = true
  results.each do |r|
    unless first
      puts ""
      puts "---"
      puts ""
    end
    first = false
    rank = r["rank"]
    if r["semantic_score"] && r["keyword_score"]
      puts "## #{r["title"]} — `#{r["source_path"]}` (rank: #{rank.is_a?(Numeric) ? rank.round(4) : rank}, kw: #{r["keyword_score"]}, sem: #{r["semantic_score"]})"
    else
      puts "## #{r["title"]} — `#{r["source_path"]}` (rank: #{rank})"
    end
    puts ""
    puts r["content"]
  end
'
