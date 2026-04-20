#!/bin/bash
# DexHub E2E Test 15 — L2 Tank → Copilot Wire (Phase 5.2.b-wire-copilot)
#
# Proves the SSOT compile step picks up L2 Tank results (via seed query)
# and bakes top-N chunks into .github/copilot-instructions.md. Companion
# to test 11 (L1 Wiki injection); together they cover both Knowledge
# Layer injections into Copilot's primary target.
#
# Gates for injection (all must be true):
#   1. myDex/.dex/l2/copilot-seed-query.txt exists + non-empty
#   2. myDex/.dex/l2/tank.sqlite exists (tank initialized)
#   3. Query returns ≥1 chunk
# When any gate fails → silent no-op (no injection, no pollution).
#
# Full fixture round-trip with backup/restore. No API cost.

set -u

HARNESS="$(cd "$(dirname "$0")/harness" && pwd)"
source "$HARNESS/assertion-lib.sh"

ensure_beta_root
test_banner "15 L2 Tank → Copilot Wire (Phase 5.2.b-wire-copilot)"

if ! command -v sqlite3 >/dev/null 2>&1; then
  fail "sqlite3 not available"; test_summary; exit 1
fi

BUILD_SH=".dexCore/_dev/tools/build-instructions.sh"
COPILOT_OUT=".github/copilot-instructions.md"
TANK_DB="myDex/.dex/l2/tank.sqlite"
SEED_FILE="myDex/.dex/l2/copilot-seed-query.txt"

# ─── Structural ──────────────────────────────────────────────────────
assert_file_contains "$BUILD_SH" "l2_block" \
  "build-instructions.sh has l2_block helper"
assert_file_contains "$BUILD_SH" "L2_MAX_COPILOT" \
  "build-instructions.sh declares L2 Copilot cap"
assert_file_contains "$BUILD_SH" "copilot-seed-query.txt" \
  "build-instructions.sh references seed file"

# ─── Backup current state ────────────────────────────────────────────
COPILOT_BACKUP="/tmp/dexhub-copilot-backup-15-$$-$(date +%s).md"
cp "$COPILOT_OUT" "$COPILOT_BACKUP"

TANK_BACKUP=""
if [ -f "$TANK_DB" ]; then
  TANK_BACKUP="/tmp/dexhub-tank-backup-15-$$-$(date +%s).sqlite"
  cp "$TANK_DB" "$TANK_BACKUP"
fi

SEED_BACKUP=""
if [ -f "$SEED_FILE" ]; then
  SEED_BACKUP="/tmp/dexhub-seed-backup-15-$$-$(date +%s).txt"
  cp "$SEED_FILE" "$SEED_BACKUP"
fi

# Restore trap
restore_state() {
  # Remove any fixtures we installed
  rm -f "$SEED_FILE" "$TANK_DB" "${TANK_DB}-wal" "${TANK_DB}-shm"
  # Restore originals if they existed
  [ -n "$TANK_BACKUP" ] && [ -f "$TANK_BACKUP" ] && cp "$TANK_BACKUP" "$TANK_DB" && rm -f "$TANK_BACKUP"
  [ -n "$SEED_BACKUP" ] && [ -f "$SEED_BACKUP" ] && cp "$SEED_BACKUP" "$SEED_FILE" && rm -f "$SEED_BACKUP"
  # Rebuild copilot-instructions.md to match restored state
  bash "$BUILD_SH" >/dev/null 2>&1
  # Then overwrite with the real backup (idempotency)
  cp "$COPILOT_BACKUP" "$COPILOT_OUT" && rm -f "$COPILOT_BACKUP"
  echo -e "\033[0;34m  (trap: L2 fixtures removed, copilot-instructions.md + tank restored)\033[0m"
}
trap 'restore_state' EXIT INT TERM

# ─── Scenario 1: no seed file → no L2 injection ──────────────────────
rm -f "$SEED_FILE" "$TANK_DB" "${TANK_DB}-wal" "${TANK_DB}-shm"
bash "$BUILD_SH" >/dev/null 2>&1
SIZE_NO_L2=$(wc -c < "$COPILOT_OUT" | tr -d ' ')

if grep -q "L2 TANK" "$COPILOT_OUT"; then
  fail "Scenario 1: L2 TANK block present despite no seed file"
else
  pass "Scenario 1: no seed file → no L2 injection (correct)"
fi

if bash "$BUILD_SH" check >/dev/null 2>&1; then
  pass "Scenario 1: drift-check green (idempotent without L2)"
else
  fail "Scenario 1: drift-check fails"
fi

# ─── Scenario 2: seed file present but no tank → no injection ─────────
echo "decision" > "$SEED_FILE"
bash "$BUILD_SH" >/dev/null 2>&1

if grep -q "L2 TANK" "$COPILOT_OUT"; then
  fail "Scenario 2: L2 injected despite missing tank DB"
else
  pass "Scenario 2: seed file + no tank DB → no injection (graceful)"
fi

# ─── Scenario 3: seed + empty tank → no injection ────────────────────
bash .dexCore/core/knowledge/l2/l2-init.sh >/dev/null 2>&1
bash "$BUILD_SH" >/dev/null 2>&1

if grep -q "L2 TANK" "$COPILOT_OUT"; then
  fail "Scenario 3: L2 injected despite empty tank"
else
  pass "Scenario 3: empty tank + seed → no injection (graceful)"
fi

# ─── Scenario 4: ingest content + rebuild → L2 injected ──────────────
FIX_SRC=$(mktemp -t dexhub-l2-wire-src-XXXXXX).md
cat > "$FIX_SRC" <<'FIX_EOF'
# Architecture

## Decision: platform priority

DexHub Beta ships for GitHub Copilot only. Claude Code = integration module.

## Decision: local-first

All user data stays on device. No cloud dependency by default.
FIX_EOF
bash .dexCore/core/knowledge/l2/l2-ingest.sh --source "$FIX_SRC" >/dev/null 2>&1

bash "$BUILD_SH" >/dev/null 2>&1
SIZE_WITH_L2=$(wc -c < "$COPILOT_OUT" | tr -d ' ')

if grep -q "L2 TANK" "$COPILOT_OUT"; then
  pass "Scenario 4: L2 TANK block injected after ingest + seed"
else
  fail "Scenario 4: L2 block missing despite all gates met"
fi

if grep -q "seed query" "$COPILOT_OUT"; then
  pass "Scenario 4: seed query echoed in L2 header"
else
  fail "Scenario 4: seed query text not in L2 header"
fi

if grep -q "platform priority" "$COPILOT_OUT"; then
  pass "Scenario 4: chunk content reaches copilot-instructions.md"
else
  fail "Scenario 4: chunk content missing in output"
fi

if [ "$SIZE_WITH_L2" -gt "$SIZE_NO_L2" ]; then
  DELTA=$((SIZE_WITH_L2 - SIZE_NO_L2))
  pass "Scenario 4: file grew by $DELTA bytes from L2 injection"
else
  fail "Scenario 4: file size unchanged (injection didn't stick)"
fi

if [ "$SIZE_WITH_L2" -lt 35000 ]; then
  pass "Scenario 4: still within 35KB cap ($SIZE_WITH_L2 bytes)"
else
  fail "Scenario 4: exceeded 35KB cap with L2 ($SIZE_WITH_L2)"
fi

# Drift-check must pass — hash functions also call l2_block
if bash "$BUILD_SH" check >/dev/null 2>&1; then
  pass "Scenario 4: drift-check green after L2 inject"
else
  fail "Scenario 4: drift-check fails with L2 injected"
fi

# ─── Scenario 5: remove seed file, rebuild → L2 block gone ───────────
rm -f "$SEED_FILE"
bash "$BUILD_SH" >/dev/null 2>&1

if grep -q "L2 TANK" "$COPILOT_OUT"; then
  fail "Scenario 5: L2 block still present after seed removed"
else
  pass "Scenario 5: remove seed → L2 injection cleanly disappears"
fi

# ─── Scenario 6: cap enforcement — oversize content gets truncated ───
echo "architecture" > "$SEED_FILE"
# Add lots of big content to exceed L2_MAX_COPILOT (2000 bytes)
for i in 1 2 3 4 5 6 7 8 9 10; do
  cat >> "$FIX_SRC" <<BIG_EOF

## Big Decision $i

$(python3 -c "print('x' * 1500)" 2>/dev/null || perl -e 'print "x" x 1500')
BIG_EOF
done
# Remove old tank, re-init + re-ingest the now-big fixture
rm -f "$TANK_DB" "${TANK_DB}-wal" "${TANK_DB}-shm"
bash .dexCore/core/knowledge/l2/l2-init.sh >/dev/null 2>&1
bash .dexCore/core/knowledge/l2/l2-ingest.sh --source "$FIX_SRC" >/dev/null 2>&1

bash "$BUILD_SH" >/dev/null 2>&1
SIZE_WITH_BIG=$(wc -c < "$COPILOT_OUT" | tr -d ' ')

if [ "$SIZE_WITH_BIG" -lt 35000 ]; then
  pass "Scenario 6: cap honored even with big chunks ($SIZE_WITH_BIG bytes)"
else
  fail "Scenario 6: cap broken — oversized chunks blew the Copilot limit"
fi

# Cleanup fixture source
rm -f "$FIX_SRC"

# ─── Feature flag ────────────────────────────────────────────────────
if grep -A 10 "id: knowledge.l2_tank_wire_copilot" .dexCore/_cfg/features.yaml | grep -qE "^    status: enabled"; then
  pass "features.yaml: l2_tank_wire_copilot flipped deferred → enabled"
else
  fail "features.yaml: l2_tank_wire_copilot status not yet 'enabled'"
fi

test_summary
