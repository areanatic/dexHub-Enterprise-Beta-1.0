#!/usr/bin/env bash
# DexHub L2 Tank — Initialize
# ==========================================================
# Creates (or validates) the SQLite knowledge tank at
# myDex/.dex/l2/tank.sqlite. Applies schema.sql idempotently.
#
# Status: scaffold (5.2.b-scaffold, commit 2026-04-20). This script
# actually works — creates an empty DB with the schema, ready for
# future ingest. The ingest + query pipeline that USES this DB is
# still stub-level (see l2-ingest.sh, l2-query.sh).
#
# Usage:
#   bash .dexCore/core/knowledge/l2/l2-init.sh
#   bash .dexCore/core/knowledge/l2/l2-init.sh --db /custom/path.sqlite
#   bash .dexCore/core/knowledge/l2/l2-init.sh --check    # exit 0 if initialized, 1 otherwise
#
# Exit codes:
#   0   success (DB created or already present with correct schema)
#   1   check failed (DB absent or schema mismatch)
#   2   sqlite3 not available
#   3   schema.sql missing

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
SCHEMA="$SCRIPT_DIR/schema.sql"

DEFAULT_DB="$REPO_ROOT/myDex/.dex/l2/tank.sqlite"
DB=""
CHECK_ONLY=0

while [ $# -gt 0 ]; do
  case "$1" in
    --db)    DB="$2"; shift 2 ;;
    --check) CHECK_ONLY=1; shift ;;
    --help|-h)
      sed -n '2,20p' "${BASH_SOURCE[0]}"
      exit 0
      ;;
    *)
      echo "ERROR: unknown arg: $1" >&2
      exit 1
      ;;
  esac
done

DB="${DB:-$DEFAULT_DB}"

# Dependency checks
if ! command -v sqlite3 >/dev/null 2>&1; then
  echo "ERROR: sqlite3 not installed. Install with: brew install sqlite (macOS) or apt-get install sqlite3 (Debian)" >&2
  exit 2
fi

if [ ! -f "$SCHEMA" ]; then
  echo "ERROR: schema file missing: $SCHEMA" >&2
  exit 3
fi

# --check mode: does the DB exist + have the schema?
if [ "$CHECK_ONLY" = "1" ]; then
  if [ ! -f "$DB" ]; then
    echo "Tank not initialized: $DB (missing)"
    exit 1
  fi
  # Verify expected tables exist
  TABLES=$(sqlite3 "$DB" "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name" 2>/dev/null || echo "")
  MISSING=0
  for expected in chunks embeddings ingest_runs meta; do
    if ! echo "$TABLES" | grep -q "^${expected}$"; then
      echo "Tank missing table: $expected"
      MISSING=$((MISSING + 1))
    fi
  done
  if [ "$MISSING" -eq 0 ]; then
    SCHEMA_VER=$(sqlite3 "$DB" "SELECT value FROM meta WHERE key='schema_version'" 2>/dev/null || echo "?")
    echo "Tank initialized: $DB (schema v$SCHEMA_VER)"
    exit 0
  else
    echo "Tank schema incomplete"
    exit 1
  fi
fi

# Init mode: ensure directory + apply schema
mkdir -p "$(dirname "$DB")"

if [ -f "$DB" ]; then
  echo "Tank exists at $DB — re-applying schema (idempotent)"
else
  echo "Creating new tank at $DB"
fi

sqlite3 "$DB" < "$SCHEMA"

# Verify
SCHEMA_VER=$(sqlite3 "$DB" "SELECT value FROM meta WHERE key='schema_version'" 2>/dev/null || echo "?")
CHUNK_COUNT=$(sqlite3 "$DB" "SELECT COUNT(*) FROM chunks" 2>/dev/null || echo "?")

echo "OK"
echo "  Path:           $DB"
echo "  Schema version: $SCHEMA_VER"
echo "  Chunks:         $CHUNK_COUNT"
echo ""
echo "Next: ingest content via l2-ingest.sh (currently STUB — see L2-TANK.md phase milestones)"
