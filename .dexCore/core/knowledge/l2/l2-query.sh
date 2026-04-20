#!/usr/bin/env bash
# DexHub L2 Tank — Query
# ==========================================================
# FTS5 keyword search over the chunk store. Output formatted
# as markdown (default) or JSON, suitable for pasting into a
# Copilot/Claude chat as context, or for build-time baking
# into copilot-instructions.md (see build-instructions.sh
# wire-copilot integration in 5.2.b-wire-copilot slice).
#
# Status: Phase 5.2.b-query — KEYWORD-ONLY (FTS5 BM25).
# Semantic cosine-sim hybrid ships in a later slice once
# 5.2.b-embed populates the embeddings table.
#
# Usage:
#   bash l2-query.sh "how did we handle X"
#   bash l2-query.sh --top 10 "search terms"
#   bash l2-query.sh --format json "search"
#   bash l2-query.sh --db CUSTOM.sqlite "search"
#   bash l2-query.sh --source-type wiki "only from wiki"
#   bash l2-query.sh --quiet "no header chrome"
#
# Output (markdown default):
#   # L2 TANK — results for "<query>"
#   (<N> chunks from <total> matched, top <top>)
#
#   ## <title> — <source_path> (rank: <score>)
#
#   <content>
#
#   ---
#
#   ## <next...>
#
# Exit codes:
#   0   success (may return 0 results with a "no matches" notice)
#   1   bad args / empty query
#   2   sqlite3 not available
#   3   DB missing (not initialized)

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

while [ $# -gt 0 ]; do
  case "$1" in
    --db)          DB="$2"; shift 2 ;;
    --top)         TOP="$2"; shift 2 ;;
    --format)      FORMAT="$2"; shift 2 ;;
    --source-type) SOURCE_TYPE="$2"; shift 2 ;;
    --quiet)       QUIET=1; shift ;;
    --help|-h)
      sed -n '2,26p' "${BASH_SOURCE[0]}"
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

# SQL-escape the query for FTS5 MATCH
# FTS5 uses its own syntax; quotes need escaping. We'll pass as a simple
# phrase query — users needing advanced FTS5 syntax can still get it
# through since we wrap in double-quotes for phrase safety.
escape_for_fts() {
  # Replace double quotes with two double quotes (FTS5 phrase escape)
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

# Run FTS5 query. rank is BM25 (lower = more relevant in SQLite FTS5).
# Use sqlite3 .mode json to get proper JSON array — newlines inside content
# are correctly escaped, avoiding the "content breaks tab-separated row
# parsing" class of bug.
RAW_JSON=$(sqlite3 "$DB" <<SQL 2>/dev/null
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

# If no results, sqlite3 .mode json returns empty string
if [ -z "$RAW_JSON" ]; then
  RAW_JSON="[]"
fi

RESULT_COUNT=$(printf '%s' "$RAW_JSON" | ruby -rjson -e 'puts JSON.parse(STDIN.read).length' 2>/dev/null || echo 0)

# Total matches (not limited) for headline
TOTAL_MATCHES=$(sqlite3 "$DB" "SELECT COUNT(*) FROM chunks_fts WHERE chunks_fts MATCH '\"$(escape_sql "$FTS_QUERY")\"'" 2>/dev/null || echo "?")

# ─── Output ───────────────────────────────────────────────────────────
if [ "$FORMAT" = "json" ]; then
  # Wrap the results array in the outer structure
  printf '%s' "$RAW_JSON" | ruby -rjson -e '
    query = ARGV[0]
    total_matches = ARGV[1].to_i
    top = ARGV[2].to_i
    results = JSON.parse(STDIN.read)
    out = { query: query, total_matches: total_matches, top: top, results: results }
    puts JSON.pretty_generate(out)
  ' "$QUERY" "$TOTAL_MATCHES" "$TOP"
  exit 0
fi

# Markdown output
if [ "$QUIET" = "0" ]; then
  echo "# L2 TANK — results for \"$QUERY\""
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
    puts "## #{r["title"]} — `#{r["source_path"]}` (rank: #{r["rank"]})"
    puts ""
    puts r["content"]
  end
'
