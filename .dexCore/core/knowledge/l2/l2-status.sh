#!/usr/bin/env bash
# DexHub L2 Tank — Status Dashboard
# ==========================================================
# Human-friendly summary of Tank state: DB size, chunk counts,
# source-type breakdown, embedding coverage, backend availability,
# and the resulting query mode users will see. One command that
# answers "what does my L2 Tank look like right now?".
#
# Safe: no DB writes, no network (beyond the cheap Ollama probe
# in l2-detect-backend.sh). Works on an empty or missing Tank —
# reports "not initialized" instead of erroring.
#
# Feature: knowledge.l2_tank_backend_routing
# Phase:   5.2.b-embed-detect
#
# Usage:
#   bash l2-status.sh                        # text (human)
#   bash l2-status.sh --format json          # machine-parseable
#   bash l2-status.sh --db CUSTOM.sqlite     # alternate DB path

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"

DEFAULT_DB="$REPO_ROOT/myDex/.dex/l2/tank.sqlite"
DB="$DEFAULT_DB"
FORMAT="text"

while [ $# -gt 0 ]; do
  case "$1" in
    --db)     DB="$2"; shift 2 ;;
    --format) FORMAT="$2"; shift 2 ;;
    --help|-h)
      sed -n '2,25p' "${BASH_SOURCE[0]}"
      exit 0
      ;;
    *)
      echo "ERROR: unknown arg: $1" >&2
      exit 1
      ;;
  esac
done

# ─── Tank state ─────────────────────────────────────────────────────
TANK_EXISTS="false"
TANK_SIZE="0"
TANK_SIZE_HUMAN="0B"
CHUNK_COUNT="0"
EMBEDDING_COUNT="0"
COVERAGE_PCT="0"
WIKI_COUNT="0"
CHRONICLE_COUNT="0"
INGEST_COUNT="0"
LAST_INGEST="never"

if [ -f "$DB" ]; then
  TANK_EXISTS="true"
  TANK_SIZE=$(wc -c < "$DB" 2>/dev/null | tr -d ' ')
  # Human-readable size
  if [ "$TANK_SIZE" -ge 1048576 ]; then
    TANK_SIZE_HUMAN=$(awk -v s="$TANK_SIZE" 'BEGIN{printf "%.1fMB", s/1048576}')
  elif [ "$TANK_SIZE" -ge 1024 ]; then
    TANK_SIZE_HUMAN=$(awk -v s="$TANK_SIZE" 'BEGIN{printf "%.1fKB", s/1024}')
  else
    TANK_SIZE_HUMAN="${TANK_SIZE}B"
  fi

  if command -v sqlite3 >/dev/null 2>&1; then
    if sqlite3 "$DB" "SELECT 1 FROM meta WHERE key='schema_version' LIMIT 1" >/dev/null 2>&1; then
      CHUNK_COUNT=$(sqlite3 "$DB" "SELECT COUNT(*) FROM chunks" 2>/dev/null || echo 0)
      EMBEDDING_COUNT=$(sqlite3 "$DB" "SELECT COUNT(*) FROM embeddings" 2>/dev/null || echo 0)
      WIKI_COUNT=$(sqlite3 "$DB" "SELECT COUNT(*) FROM chunks WHERE source_type='wiki'" 2>/dev/null || echo 0)
      CHRONICLE_COUNT=$(sqlite3 "$DB" "SELECT COUNT(*) FROM chunks WHERE source_type='chronicle'" 2>/dev/null || echo 0)
      INGEST_COUNT=$(sqlite3 "$DB" "SELECT COUNT(*) FROM chunks WHERE source_type='ingest'" 2>/dev/null || echo 0)
      LAST_INGEST=$(sqlite3 "$DB" "SELECT started_at FROM ingest_runs ORDER BY started_at DESC LIMIT 1" 2>/dev/null || echo "never")
      [ -z "$LAST_INGEST" ] && LAST_INGEST="never"
      if [ "$CHUNK_COUNT" -gt 0 ]; then
        COVERAGE_PCT=$(awk -v e="$EMBEDDING_COUNT" -v c="$CHUNK_COUNT" 'BEGIN{printf "%.0f", (e*100)/c}')
      fi
    fi
  fi
fi

# ─── Backend detection (reuse helper) ───────────────────────────────
BACKEND_JSON=""
if [ -x "$SCRIPT_DIR/l2-detect-backend.sh" ]; then
  BACKEND_JSON=$("$SCRIPT_DIR/l2-detect-backend.sh" --format json --db "$DB" 2>/dev/null || echo "")
fi

# Extract just the fields we need (keep it dependency-free — parse with grep)
extract_json_field() {
  local key="$1"
  printf "%s" "$BACKEND_JSON" | grep -oE "\"$key\":[[:space:]]*\"[^\"]*\"" | head -1 | sed "s/.*\"$key\":[[:space:]]*\"//; s/\"$//"
}
extract_json_bool() {
  local key="$1"
  printf "%s" "$BACKEND_JSON" | grep -oE "\"$key\":[[:space:]]*(true|false)" | head -1 | awk -F: '{gsub(/[[:space:]]/,"",$2); print $2}'
}

BACKEND_STATUS=$(extract_json_field "status")
SEMANTIC_AVAILABLE=$(extract_json_bool "semantic_available")
SETUP_HINT=$(extract_json_field "setup_hint")
BACKEND_NAME=$(extract_json_field "backend")
[ -z "$BACKEND_STATUS" ] && BACKEND_STATUS="none"
[ -z "$SEMANTIC_AVAILABLE" ] && SEMANTIC_AVAILABLE="false"
[ -z "$BACKEND_NAME" ] && BACKEND_NAME="ollama/nomic-embed-text"

# ─── Derive query mode ──────────────────────────────────────────────
# Even if backend is ready, we also need embeddings to be populated.
if [ "$CHUNK_COUNT" = "0" ]; then
  QUERY_MODE="n/a (empty tank)"
elif [ "$SEMANTIC_AVAILABLE" = "true" ] && [ "$COVERAGE_PCT" -gt 0 ]; then
  if [ "$COVERAGE_PCT" -ge 80 ]; then
    QUERY_MODE="HYBRID (BM25 + semantic, ${COVERAGE_PCT}% coverage)"
  else
    QUERY_MODE="PARTIAL HYBRID (only ${COVERAGE_PCT}% of chunks embedded — run l2-embed.sh to catch up)"
  fi
else
  QUERY_MODE="KEYWORD-ONLY (BM25 via FTS5)"
fi

# ─── Output ─────────────────────────────────────────────────────────
if [ "$FORMAT" = "json" ]; then
  cat <<EOF
{
  "tank_path": "$DB",
  "tank_exists": $TANK_EXISTS,
  "tank_size_bytes": $TANK_SIZE,
  "tank_size_human": "$TANK_SIZE_HUMAN",
  "chunks": {
    "total": $CHUNK_COUNT,
    "wiki": $WIKI_COUNT,
    "chronicle": $CHRONICLE_COUNT,
    "ingest": $INGEST_COUNT
  },
  "embeddings": {
    "count": $EMBEDDING_COUNT,
    "coverage_pct": $COVERAGE_PCT
  },
  "last_ingest": "$LAST_INGEST",
  "backend": "$BACKEND_NAME",
  "backend_status": "$BACKEND_STATUS",
  "semantic_available": $SEMANTIC_AVAILABLE,
  "query_mode": "$QUERY_MODE",
  "setup_hint": "$SETUP_HINT"
}
EOF
  exit 0
fi

echo "DexHub L2 Tank — Status"
echo "======================="
echo ""
if [ "$TANK_EXISTS" = "false" ]; then
  echo "  Tank:        not initialized at $DB"
  echo ""
  echo "  Next step:   bash .dexCore/core/knowledge/l2/l2-init.sh"
  echo "               bash .dexCore/core/knowledge/l2/l2-ingest.sh --source FILE.md"
  exit 0
fi

echo "  Tank:        $DB ($TANK_SIZE_HUMAN)"
if [ "$CHUNK_COUNT" = "0" ]; then
  echo "  Chunks:      0 (tank empty — run l2-ingest.sh)"
else
  echo "  Chunks:      $CHUNK_COUNT total"
  echo "               wiki=$WIKI_COUNT, chronicle=$CHRONICLE_COUNT, ingest=$INGEST_COUNT"
fi
echo "  Last ingest: $LAST_INGEST"
echo ""
echo "  Embeddings:  $EMBEDDING_COUNT / $CHUNK_COUNT (${COVERAGE_PCT}%)"
echo "  Backend:     $BACKEND_NAME  [status: $(echo "$BACKEND_STATUS" | tr '[:lower:]' '[:upper:]')]"
echo ""
echo "  Query mode:  $QUERY_MODE"
if [ -n "$SETUP_HINT" ] && [ "$SEMANTIC_AVAILABLE" != "true" ]; then
  echo ""
  echo "  To enable semantic ranking:"
  echo "    $SETUP_HINT"
fi
echo ""
echo "  (Keyword search always available — L2 never blocks on Ollama.)"
