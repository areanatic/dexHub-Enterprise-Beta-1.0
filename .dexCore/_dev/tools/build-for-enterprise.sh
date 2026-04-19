#!/usr/bin/env bash
# ==========================================================
# DexHub — Build for Enterprise
# ==========================================================
# Produces a clean enterprise-target bundle from this repo by stripping
# all Claude Code coupling and integration modules.
#
# Rationale: DexHub Enterprise Beta ships to GitHub Copilot. Only.
# Everything else (Claude Code, Cursor, IntelliJ, ...) are optional
# integration modules that ride in the areanatic dev repo but must NOT
# appear in enterprise pushes.
#
# Policy: see .dexCore/_dev/docs/PLATFORM-POLICY.md
# Docs:   see .dexCore/_dev/docs/ENTERPRISE-BUILD.md
# Learning origin: 2026-04-20 correction after Claude Code tight-coupling.
#
# Usage:
#   bash .dexCore/_dev/tools/build-for-enterprise.sh --dry-run
#   bash .dexCore/_dev/tools/build-for-enterprise.sh --output /tmp/dexhub-beta.tar.gz
#   bash .dexCore/_dev/tools/build-for-enterprise.sh --output PATH --verify
#
# Flags:
#   --dry-run      List what would be stripped, don't produce a bundle
#   --output PATH  Write tar.gz bundle to PATH
#   --verify       After strip, run validate.sh in scratch dir —
#                  abort if structural checks fail
#   --keep-scratch Keep the scratch dir after build (default: delete)
#                  Useful for debugging what the bundle contains.

set -euo pipefail

DRY_RUN=0
OUTPUT=""
VERIFY=0
KEEP_SCRATCH=0

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run)      DRY_RUN=1; shift ;;
    --output)       OUTPUT="$2"; shift 2 ;;
    --verify)       VERIFY=1; shift ;;
    --keep-scratch) KEEP_SCRATCH=1; shift ;;
    --help|-h)
      sed -n '2,27p' "${BASH_SOURCE[0]}"
      exit 0
      ;;
    *)
      echo "ERROR: unknown arg: $1" >&2
      echo "Run with --help for usage." >&2
      exit 1
      ;;
  esac
done

# Resolve project root (script is at .dexCore/_dev/tools/)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BOLD}${BLUE}========================================${NC}"
echo -e "${BOLD} DexHub — Build for Enterprise${NC}"
echo -e "${BOLD}${BLUE}========================================${NC}"
echo "Source: $PROJECT_ROOT"
echo ""

# ─── Step 1: Enumerate paths to strip ─────────────────────────────
# Defined here + should match the policy doc.
STRIP_PATHS=(
  ".claude"
  "tests/e2e/integrations"
  ".dexcore-session-anchor"                     # dev-safety for parallel-session anchor; not enterprise-relevant
  ".dexCore/_dev/tools/build-for-enterprise.sh" # self: not needed in enterprise bundle
  ".dexCore/_dev/docs/LEARNINGS-CLAUDE-CODE-REMOVABILITY.md"  # dev learning
)

echo -e "${BOLD}[1/5] Paths to strip:${NC}"
for path in "${STRIP_PATHS[@]}"; do
  if [ -e "$PROJECT_ROOT/$path" ]; then
    size=$(du -sh "$PROJECT_ROOT/$path" 2>/dev/null | cut -f1 || echo "?")
    echo "  - $path ($size)"
  else
    echo "  - $path ${YELLOW}(not present — skip)${NC}"
  fi
done
echo ""

if [ "$DRY_RUN" = "1" ]; then
  echo -e "${YELLOW}[dry-run] No bundle produced. Exiting.${NC}"
  exit 0
fi

if [ -z "$OUTPUT" ]; then
  echo -e "${RED}ERROR: --output PATH required (or pass --dry-run)${NC}" >&2
  exit 1
fi

# ─── Step 2: Copy to scratch ───────────────────────────────────────
SCRATCH=$(mktemp -d -t dexhub-enterprise-build-XXXXXX)
echo -e "${BOLD}[2/5] Copy to scratch:${NC} $SCRATCH"

# Copy everything except .git (we don't want the dev history in enterprise bundle)
# and a few temp-state files
rsync -a \
  --exclude='.git' \
  --exclude='node_modules' \
  --exclude='*.log' \
  --exclude='.DS_Store' \
  --exclude='*.bak' \
  "$PROJECT_ROOT"/ "$SCRATCH"/
echo "  rsync complete"
echo ""

# ─── Step 3: Strip ─────────────────────────────────────────────────
echo -e "${BOLD}[3/5] Strip integration modules:${NC}"
STRIP_COUNT=0
for path in "${STRIP_PATHS[@]}"; do
  if [ -e "$SCRATCH/$path" ]; then
    rm -rf "$SCRATCH/$path"
    echo "  removed: $path"
    STRIP_COUNT=$((STRIP_COUNT + 1))
  fi
done
echo "  $STRIP_COUNT paths stripped"
echo ""

# ─── Step 4: Verify (optional) ────────────────────────────────────
if [ "$VERIFY" = "1" ]; then
  echo -e "${BOLD}[4/5] Verify: run validate.sh in stripped scratch:${NC}"
  if [ -f "$SCRATCH/.dexCore/_dev/tools/validate.sh" ]; then
    if (cd "$SCRATCH" && bash .dexCore/_dev/tools/validate.sh) >/tmp/build-enterprise-verify.log 2>&1; then
      echo -e "  ${GREEN}validate.sh PASS in stripped bundle${NC}"
    else
      echo -e "  ${RED}validate.sh FAILED in stripped bundle — integration coupling leaked into core${NC}" >&2
      echo -e "  Log: /tmp/build-enterprise-verify.log" >&2
      echo -e "  Last 20 lines:" >&2
      tail -20 /tmp/build-enterprise-verify.log >&2
      exit 2
    fi

    # Also verify E2E enterprise mode passes
    if [ -f "$SCRATCH/tests/e2e/run-all.sh" ]; then
      if (cd "$SCRATCH" && bash tests/e2e/run-all.sh --enterprise) >/tmp/build-enterprise-e2e.log 2>&1; then
        echo -e "  ${GREEN}E2E --enterprise PASS in stripped bundle${NC}"
      else
        echo -e "  ${YELLOW}E2E --enterprise had failures in stripped bundle${NC}" >&2
        echo -e "  Log: /tmp/build-enterprise-e2e.log" >&2
      fi
    fi
  else
    echo -e "  ${YELLOW}validate.sh not found in scratch — skipped${NC}"
  fi
  echo ""
else
  echo -e "${BOLD}[4/5] Verify: ${YELLOW}skipped (pass --verify to enable)${NC}"
  echo ""
fi

# ─── Step 5: Tar ──────────────────────────────────────────────────
echo -e "${BOLD}[5/5] Create bundle:${NC} $OUTPUT"
OUTPUT_DIR=$(dirname "$OUTPUT")
mkdir -p "$OUTPUT_DIR"

# tar from scratch; strip leading path component so the archive unpacks to a
# clean dir named after the bundle file (minus extension).
BASENAME=$(basename "$OUTPUT" .tar.gz)
BASENAME=$(basename "$BASENAME" .tgz)

# Copy scratch to final-named dir so tar captures it cleanly
STAGE=$(mktemp -d -t dexhub-stage-XXXXXX)
cp -a "$SCRATCH" "$STAGE/$BASENAME"
(cd "$STAGE" && tar -czf "$OUTPUT" "$BASENAME")
rm -rf "$STAGE"

BUNDLE_SIZE=$(du -sh "$OUTPUT" | cut -f1)
echo "  bundle: $OUTPUT ($BUNDLE_SIZE)"
echo ""

# ─── Cleanup ───────────────────────────────────────────────────────
if [ "$KEEP_SCRATCH" = "1" ]; then
  echo -e "${YELLOW}Scratch kept: $SCRATCH${NC}"
else
  rm -rf "$SCRATCH"
fi

echo -e "${GREEN}${BOLD}Build complete.${NC}"
echo ""
echo "Next steps:"
echo "  - Inspect bundle: tar -tzf $OUTPUT | head -40"
echo "  - Push to enterprise (manual step; do NOT automate without explicit authorization)"
