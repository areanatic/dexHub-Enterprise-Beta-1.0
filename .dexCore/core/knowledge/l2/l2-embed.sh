#!/usr/bin/env bash
# DexHub L2 Tank — Embedding Generator
# ==========================================================
# Generates embeddings for chunks that don't have one yet, using the
# configured embedding backend. For Beta 1.0 the only supported backend
# is Ollama with a local embedding model (default: nomic-embed-text,
# ~137 MB, 768 dim). Cloud backends (OpenAI, Anthropic) are scaffolded
# in meta/config but not implemented — they will ship with the
# enterprise-audit slice when policy enforcement is in place.
#
# Semantic search is optional in DexHub. Running this script is opt-in.
# If the backend is not available, the script exits 0 with a clear
# explanation and zero side effects — keyword-only search keeps working
# independently. This is the graceful-degradation contract.
#
# Feature: knowledge.l2_tank_embed
# Phase:   5.2.b-embed
#
# Usage:
#   bash l2-embed.sh                         # embed chunks missing embeddings
#   bash l2-embed.sh --all                   # re-embed every chunk (refresh after model change)
#   bash l2-embed.sh --batch 50              # cap how many get embedded in this run
#   bash l2-embed.sh --db CUSTOM.sqlite      # alternate tank
#   bash l2-embed.sh --dry-run               # plan only, no writes, no API calls
#   bash l2-embed.sh --require-backend       # exit 4 if backend not ready (for scripts)
#
# Exit codes:
#   0   success (embedded N ≥ 0 chunks, or backend not ready + no --require-backend)
#   1   bad args
#   2   sqlite3 / ruby / curl not available
#   3   DB missing / schema incomplete
#   4   backend not ready AND --require-backend was set

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"

DEFAULT_DB="$REPO_ROOT/myDex/.dex/l2/tank.sqlite"
DB="$DEFAULT_DB"
ALL=0
BATCH=0          # 0 = unlimited
DRY_RUN=0
REQUIRE_BACKEND=0
OLLAMA_ENDPOINT="http://localhost:11434"

while [ $# -gt 0 ]; do
  case "$1" in
    --db)               DB="$2"; shift 2 ;;
    --all)              ALL=1; shift ;;
    --batch)            BATCH="$2"; shift 2 ;;
    --dry-run)          DRY_RUN=1; shift ;;
    --require-backend)  REQUIRE_BACKEND=1; shift ;;
    --endpoint)         OLLAMA_ENDPOINT="$2"; shift 2 ;;
    --help|-h)
      sed -n '2,30p' "${BASH_SOURCE[0]}"
      exit 0
      ;;
    *)
      echo "ERROR: unknown arg: $1" >&2
      exit 1
      ;;
  esac
done

# ─── Dep checks ─────────────────────────────────────────────────────
command -v sqlite3 >/dev/null 2>&1 || { echo "ERROR: sqlite3 not installed" >&2; exit 2; }
command -v ruby    >/dev/null 2>&1 || { echo "ERROR: ruby not installed (required for JSON vector + NUL-safe SQL)" >&2; exit 2; }
command -v curl    >/dev/null 2>&1 || { echo "ERROR: curl not installed (required for Ollama HTTP API)" >&2; exit 2; }

# ─── DB check ───────────────────────────────────────────────────────
if [ ! -f "$DB" ]; then
  echo "ERROR: DB not initialized: $DB" >&2
  echo "       Run: bash $SCRIPT_DIR/l2-init.sh --db $DB" >&2
  exit 3
fi
if ! sqlite3 "$DB" "SELECT value FROM meta WHERE key='schema_version'" >/dev/null 2>&1; then
  echo "ERROR: DB schema incomplete — run l2-init.sh --db $DB" >&2
  exit 3
fi

# ─── Backend detection (reuse helper) ───────────────────────────────
# Propagate --endpoint so users (and tests) that point at a non-default
# Ollama host get consistent detect-vs-embed answers — otherwise detect
# says "ready" (probing localhost:11434) while embed fails to reach the
# user-specified host.
DETECT_JSON=$("$SCRIPT_DIR/l2-detect-backend.sh" --db "$DB" --format json --endpoint "$OLLAMA_ENDPOINT" 2>/dev/null || echo "{}")
BACKEND=$(printf "%s" "$DETECT_JSON" | ruby -rjson -e 'd=JSON.parse(STDIN.read); puts d["backend"] || "ollama/nomic-embed-text"' 2>/dev/null)
PROVIDER=$(printf "%s" "$DETECT_JSON" | ruby -rjson -e 'd=JSON.parse(STDIN.read); puts d["provider"] || "ollama"' 2>/dev/null)
MODEL=$(printf "%s" "$DETECT_JSON" | ruby -rjson -e 'd=JSON.parse(STDIN.read); puts d["model"] || "nomic-embed-text"' 2>/dev/null)
STATUS=$(printf "%s" "$DETECT_JSON" | ruby -rjson -e 'd=JSON.parse(STDIN.read); puts d["status"] || "none"' 2>/dev/null)
SEMANTIC_AVAILABLE=$(printf "%s" "$DETECT_JSON" | ruby -rjson -e 'd=JSON.parse(STDIN.read); puts d["semantic_available"] ? "true" : "false"' 2>/dev/null)
HINT=$(printf "%s" "$DETECT_JSON" | ruby -rjson -e 'd=JSON.parse(STDIN.read); puts d["setup_hint"] || ""' 2>/dev/null)
POLICY=$(printf "%s" "$DETECT_JSON" | ruby -rjson -e 'd=JSON.parse(STDIN.read); puts d["policy"] || "unset"' 2>/dev/null)
POLICY_NOTE=$(printf "%s" "$DETECT_JSON" | ruby -rjson -e 'd=JSON.parse(STDIN.read); puts d["policy_note"] || ""' 2>/dev/null)

echo "L2 Embed — backend: $BACKEND  [status: $(echo "$STATUS" | tr '[:lower:]' '[:upper:]')]"

# Policy-block audit helper — writes an ingest_runs row whenever a block
# fires, so the trail lives in the DB alongside normal runs.
log_policy_block() {
  local reason="$1"
  sqlite3 "$DB" "INSERT INTO ingest_runs (started_at, source_count, chunks_added, chunks_updated, chunks_deleted, backend, notes) VALUES (datetime('now'), 0, 0, 0, 0, '$(printf "%s" "$BACKEND" | sed "s/'/''/g")', 'POLICY-BLOCK: $(printf "%s" "$reason" | sed "s/'/''/g")')" 2>/dev/null || true
}

if [ "$STATUS" = "blocked" ]; then
  echo ""
  echo "  ⛔  Backend BLOCKED by enterprise policy."
  echo "      Backend: $BACKEND"
  echo "      Policy:  data_handling_policy=$POLICY"
  echo "      Reason:  $POLICY_NOTE"
  echo ""
  echo "  Options:"
  echo "    1. Switch to a local backend (ollama/nomic-embed-text recommended)"
  echo "    2. Update profile.company.data_handling_policy in myDex/.dex/config/profile.yaml"
  echo "       (do NOT do this casually — the policy exists for compliance reasons)"
  echo ""
  echo "  Keyword-only search via l2-query.sh remains available."
  log_policy_block "$BACKEND blocked under $POLICY ($POLICY_NOTE)"
  if [ "$REQUIRE_BACKEND" = "1" ]; then
    exit 4
  fi
  exit 0
fi

if [ "$SEMANTIC_AVAILABLE" != "true" ]; then
  echo ""
  echo "  Backend not ready. Semantic search unavailable right now."
  if [ -n "$HINT" ]; then
    echo "  Next step: $HINT"
  fi
  echo ""
  echo "  Keyword-only search (via l2-query.sh) keeps working regardless —"
  echo "  no action needed if you only want keyword matching."
  if [ "$REQUIRE_BACKEND" = "1" ]; then
    exit 4
  fi
  exit 0
fi

# ─── Ollama embeddings API helper ───────────────────────────────────
# POST /api/embeddings with {model, prompt} → returns {embedding: [...]}
# We use ruby to build the JSON body (NUL-safe, escape-safe) and parse
# the response. Ollama rejects payloads with raw newlines, but ruby's
# JSON.generate handles that correctly.
embed_one() {
  local content="$1"
  local body
  body=$(printf "%s" "$content" | ruby -rjson -e '
    content = STDIN.read
    puts JSON.generate({"model" => ARGV[0], "prompt" => content})
  ' "$MODEL")

  local resp
  resp=$(curl -sS --max-time 60 -X POST "$OLLAMA_ENDPOINT/api/embeddings" \
    -H "Content-Type: application/json" \
    -d "$body" 2>/dev/null || echo "")

  if [ -z "$resp" ]; then
    echo "ERROR|HTTP request failed"
    return 1
  fi

  # Parse. Expected: {"embedding":[0.1, 0.2, ...]} OR {"error":"..."}
  printf "%s" "$resp" | ruby -rjson -e '
    begin
      r = JSON.parse(STDIN.read)
      if r["error"]
        puts "ERROR|#{r["error"]}"
      elsif r["embedding"].is_a?(Array) && r["embedding"].length > 0
        dims = r["embedding"].length
        puts "OK|#{dims}|#{JSON.generate(r["embedding"])}"
      else
        puts "ERROR|unexpected response shape"
      end
    rescue JSON::ParserError => e
      puts "ERROR|invalid JSON: #{e.message}"
    end
  '
}

# ─── Collect chunks to embed ────────────────────────────────────────
# Without --all: only chunks that don't yet have a row in embeddings
# With --all: every chunk (DELETE existing rows first for the target backend)
if [ "$ALL" = "1" ]; then
  if [ "$DRY_RUN" = "0" ]; then
    sqlite3 "$DB" "DELETE FROM embeddings WHERE backend = '$(printf "%s" "$BACKEND" | sed "s/'/''/g")'" 2>/dev/null
    echo "  --all: cleared existing '$BACKEND' embeddings"
  else
    echo "  --all (dry): would clear existing '$BACKEND' embeddings"
  fi
fi

if [ "$BATCH" -gt 0 ]; then
  LIMIT_CLAUSE="LIMIT $BATCH"
else
  LIMIT_CLAUSE=""
fi

TO_EMBED_SQL="
SELECT c.id, c.title, c.content
FROM chunks c
LEFT JOIN embeddings e ON e.chunk_id = c.id AND e.backend = '$(printf "%s" "$BACKEND" | sed "s/'/''/g")'
WHERE e.chunk_id IS NULL
ORDER BY c.id
$LIMIT_CLAUSE
"

# Use .mode json to safely handle newlines in content
CHUNKS_JSON=$(sqlite3 "$DB" <<SQL 2>/dev/null
.mode json
$TO_EMBED_SQL
SQL
)
[ -z "$CHUNKS_JSON" ] && CHUNKS_JSON="[]"

TOTAL_PENDING=$(printf "%s" "$CHUNKS_JSON" | ruby -rjson -e 'puts JSON.parse(STDIN.read).length' 2>/dev/null || echo 0)

if [ "$TOTAL_PENDING" = "0" ]; then
  TOTAL_CHUNKS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM chunks" 2>/dev/null || echo 0)
  if [ "$TOTAL_CHUNKS" = "0" ]; then
    echo "  Tank empty — ingest chunks first via l2-ingest.sh"
  else
    echo "  All $TOTAL_CHUNKS chunks already have '$BACKEND' embeddings. Nothing to do."
    echo "  (Use --all to force re-embed — e.g. after switching models.)"
  fi
  exit 0
fi

echo "  $TOTAL_PENDING chunk(s) pending embedding"

if [ "$DRY_RUN" = "1" ]; then
  printf "%s" "$CHUNKS_JSON" | ruby -rjson -e '
    chunks = JSON.parse(STDIN.read)
    chunks.each_with_index do |c, i|
      title = c["title"] || "?"
      title = title[0..60] + "..." if title.length > 63
      byte_size = (c["content"] || "").bytesize
      printf "    [%d/%d] id=%d  '"'"'%s'"'"'  (%d bytes)\n", i+1, chunks.length, c["id"], title, byte_size
    end
  '
  echo "  (dry-run — no API calls made, no DB writes)"
  exit 0
fi

# ─── Embed each chunk ───────────────────────────────────────────────
RUN_ID=$(sqlite3 "$DB" "INSERT INTO ingest_runs (started_at, source_count, chunks_added, chunks_updated, chunks_deleted, backend, notes) VALUES (datetime('now'), 0, 0, 0, 0, '$(printf "%s" "$BACKEND" | sed "s/'/''/g")', 'l2-embed.sh v1'); SELECT last_insert_rowid();" 2>/dev/null)

OK_COUNT=0
FAIL_COUNT=0
DIMENSIONS=0

# Stream chunks one-at-a-time. Ruby reads the JSON array and emits
# NUL-delim records (id TAB title TAB content) for bash to loop over —
# but because content can contain arbitrary characters, we do the
# embedding call INSIDE ruby to avoid the shell-escape nightmare.
# Two-stage: ruby emits the OK|dims|vector output per chunk, bash collects.

# mktemp produces paths whose lifetime we control — avoids the PID mismatch
# trap that bit us on first live run (ruby's Process.pid ≠ bash's $$ when the
# filename is interpolated inside the ruby -e block).
STREAM_FILE=$(mktemp -t dexhub-l2-embed-stream-XXXXXX)
SQL_FILE=$(mktemp -t dexhub-l2-embed-sql-XXXXXX)
COUNTS_FILE=$(mktemp -t dexhub-l2-embed-counts-XXXXXX)

# EXIT trap — cleans up temp files on early exit (Ctrl+C, bash error,
# Ollama crash mid-batch). Without this, interrupted runs leak MBs of
# intermediate vector JSON per pending chunk into /tmp/.
trap 'rm -f "$STREAM_FILE" "$SQL_FILE" "$COUNTS_FILE" 2>/dev/null || true' EXIT INT TERM

printf "%s" "$CHUNKS_JSON" | ruby -rjson -ropen3 -e '
  chunks = JSON.parse(STDIN.read)
  endpoint = ARGV[0]
  model = ARGV[1]
  chunks.each do |c|
    id = c["id"]
    title = c["title"] || ""
    content = c["content"] || ""
    body = JSON.generate({"model" => model, "prompt" => content})
    stdout_s, _, status = Open3.capture3("curl", "-sS", "--max-time", "60", "-X", "POST",
      endpoint + "/api/embeddings",
      "-H", "Content-Type: application/json",
      "-d", body)
    if status.success? && !stdout_s.empty?
      begin
        r = JSON.parse(stdout_s)
        if r["embedding"].is_a?(Array) && r["embedding"].length > 0
          vec = JSON.generate(r["embedding"])
          dims = r["embedding"].length
          # NUL-delim record: id TAB title TAB dims TAB vector_json
          title_oneline = title.gsub("\t", " ").gsub("\n", " ")
          STDOUT.write "OK\t#{id}\t#{title_oneline}\t#{dims}\t#{vec}\0"
        else
          STDOUT.write "ERR\t#{id}\tunexpected-response\0"
        end
      rescue JSON::ParserError => e
        STDOUT.write "ERR\t#{id}\tparse-error\0"
      end
    else
      STDOUT.write "ERR\t#{id}\thttp-failed\0"
    end
  end
' "$OLLAMA_ENDPOINT" "$MODEL" > "$STREAM_FILE" 2>/dev/null

# Process the stream → build SQL + per-chunk counts. Ruby again for NUL-safe
# SQL generation. Output path for SQL is passed as ARGV[3] so we don't get
# bitten by ruby's Process.pid vs bash's $$ mismatch (our first live run's
# bug).
ruby -rjson -e '
  db = ARGV[0]
  backend = ARGV[1]
  stream_file = ARGV[2]
  sql_file = ARGV[3]
  data = File.binread(stream_file)
  ok = 0
  fail_count = 0
  dims_first = 0

  sql_statements = ["BEGIN TRANSACTION;"]

  data.split("\0").each do |rec|
    next if rec.empty?
    parts = rec.split("\t", 5)
    if parts[0] == "OK"
      _, id, _title, dims, vec = parts
      dims_first = dims.to_i if dims_first == 0
      esc_vec = vec.gsub("'"'"'", "'"'"''"'"'")
      esc_backend = backend.gsub("'"'"'", "'"'"''"'"'")
      sql_statements << "INSERT OR REPLACE INTO embeddings (chunk_id, backend, dimensions, vector_json, embedded_at) VALUES (#{id.to_i}, '"'"'#{esc_backend}'"'"', #{dims.to_i}, '"'"'#{esc_vec}'"'"', datetime('"'"'now'"'"'));"
      ok += 1
    else
      fail_count += 1
      STDERR.puts "  FAIL: chunk id=#{parts[1]} reason=#{parts[2]}"
    end
  end
  sql_statements << "COMMIT;"

  File.write(sql_file, sql_statements.join("\n"))
  STDOUT.puts "#{ok}\t#{fail_count}\t#{dims_first}"
' "$DB" "$BACKEND" "$STREAM_FILE" "$SQL_FILE" > "$COUNTS_FILE" 2>/dev/null

# Apply the SQL
if [ -s "$SQL_FILE" ]; then
  sqlite3 "$DB" < "$SQL_FILE" 2>/dev/null
fi

if [ -s "$COUNTS_FILE" ]; then
  read -r OK_COUNT FAIL_COUNT DIMENSIONS < "$COUNTS_FILE"
fi

rm -f "$STREAM_FILE" "$SQL_FILE" "$COUNTS_FILE"

# ─── Finalize audit row ─────────────────────────────────────────────
if [ -n "${RUN_ID:-}" ]; then
  sqlite3 "$DB" "UPDATE ingest_runs SET finished_at=datetime('now'), chunks_added=$OK_COUNT, notes='l2-embed.sh v1 ($OK_COUNT ok, $FAIL_COUNT fail, dims=$DIMENSIONS)' WHERE id=$RUN_ID" 2>/dev/null || true
fi

echo ""
echo "  Embedded: $OK_COUNT chunk(s) at $DIMENSIONS dim via $BACKEND"
[ "$FAIL_COUNT" -gt 0 ] && echo "  Failed:   $FAIL_COUNT chunk(s) (see errors above)"
TOTAL_COVERAGE=$(sqlite3 "$DB" "SELECT COUNT(*) FROM embeddings" 2>/dev/null || echo 0)
TOTAL_CHUNKS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM chunks" 2>/dev/null || echo 0)
[ "$TOTAL_CHUNKS" -gt 0 ] && PCT=$(awk -v e="$TOTAL_COVERAGE" -v c="$TOTAL_CHUNKS" 'BEGIN{printf "%.0f", (e*100)/c}') || PCT=0
echo "  Coverage: $TOTAL_COVERAGE / $TOTAL_CHUNKS chunks (${PCT}%)"
