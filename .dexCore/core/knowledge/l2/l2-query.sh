#!/usr/bin/env bash
# DexHub L2 Tank — Query (STUB)
# ==========================================================
# Status: SCAFFOLD / STUB (5.2.b-scaffold, commit 2026-04-20).
# This script does NOT query yet. It validates arguments + tank
# presence + emits clear [L2 STUB] signals. Implementation ships
# in 5.2.b-query (FTS5 + embedding cosine hybrid).
#
# Design: .dexCore/_dev/docs/L2-TANK.md
#
# Future contract (when implemented):
#   bash l2-query.sh "how did we handle X"
#   bash l2-query.sh --top 10 --format markdown "query text"
#   bash l2-query.sh --format json "query"
#
# Output (markdown default):
#   ## <title> — <source_path> (relevance: <score>)
#   <chunk content>
#   ---
#   ## <title2> — ...

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"

DEFAULT_DB="$REPO_ROOT/myDex/.dex/l2/tank.sqlite"
DB="$DEFAULT_DB"
TOP=5
FORMAT="markdown"
QUERY=""

while [ $# -gt 0 ]; do
  case "$1" in
    --db)     DB="$2"; shift 2 ;;
    --top)    TOP="$2"; shift 2 ;;
    --format) FORMAT="$2"; shift 2 ;;
    --help|-h)
      sed -n '2,22p' "${BASH_SOURCE[0]}"
      exit 0
      ;;
    -*)
      echo "ERROR: unknown flag: $1" >&2
      exit 1
      ;;
    *)
      QUERY="$1"
      shift
      ;;
  esac
done

if [ -z "$QUERY" ]; then
  echo "ERROR: query text required. Usage: l2-query.sh \"your query\"" >&2
  exit 1
fi

echo "[L2 STUB] l2-query.sh invoked"
echo "[L2 STUB] db:     $DB"
echo "[L2 STUB] query:  $QUERY"
echo "[L2 STUB] top:    $TOP"
echo "[L2 STUB] format: $FORMAT"
echo ""
echo "[L2 STUB] Real query pipeline not yet implemented. Ships in phase 5.2.b-query."
echo "[L2 STUB] Design: .dexCore/_dev/docs/L2-TANK.md"
echo "[L2 STUB] Exiting 0 — scaffold is intentionally a no-op."

exit 0
