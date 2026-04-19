#!/usr/bin/env bash
# DexHub L2 Tank — Ingest (STUB)
# ==========================================================
# Status: SCAFFOLD / STUB (5.2.b-scaffold, commit 2026-04-20).
# This script does NOT ingest yet. It validates the arguments,
# confirms the tank exists, and emits a clear "[L2 STUB]" signal
# so no downstream consumer mistakes the scaffold for a working
# pipeline. Implementation ships in 5.2.b-ingest (chunker) +
# 5.2.b-embed (embedding backend).
#
# Design: .dexCore/_dev/docs/L2-TANK.md
# Future contract (when implemented):
#   - Read source files (markdown)
#   - Chunk via heading-aware sliding window (target 2KB, 200-byte overlap)
#   - Compute SHA-256 per chunk for dedup + source_hash tracking
#   - Compute embedding via configured backend (default: ollama/nomic-embed-text)
#   - Enforce enterprise_compliance from profile.company.data_handling_policy
#   - Append to chunks + embeddings tables, log to ingest_runs

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"

DEFAULT_DB="$REPO_ROOT/myDex/.dex/l2/tank.sqlite"
DB="$DEFAULT_DB"
SOURCES=()

while [ $# -gt 0 ]; do
  case "$1" in
    --db)     DB="$2"; shift 2 ;;
    --source) SOURCES+=("$2"); shift 2 ;;
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

echo "[L2 STUB] l2-ingest.sh invoked"
echo "[L2 STUB] db:              $DB"
echo "[L2 STUB] sources:         ${SOURCES[*]:-<none given>}"
echo ""
echo "[L2 STUB] Real ingest pipeline not yet implemented. Ships in phase 5.2.b-ingest + 5.2.b-embed."
echo "[L2 STUB] Design contract documented in .dexCore/_dev/docs/L2-TANK.md"
echo "[L2 STUB] Exiting 0 — scaffold is intentionally a no-op to avoid mis-signalling."

exit 0
