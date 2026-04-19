#!/bin/bash
# DexHub E2E Test 11 — L1 Wiki → Copilot Injection (Phase 5.2.d wire-copilot)
#
# Proves the SSOT compile step picks up L1 Wiki content and bakes it into
# .github/copilot-instructions.md. This is the PRIMARY Beta activation of
# the L1 Wiki scaffold (commit 019af7c) + loader (bac8bd0) + injection
# wire-up shipped this turn.
#
# Structural + functional (no API cost, uses mktemp fixture):
#   1. build-instructions.sh references load-wiki.sh (hook exists)
#   2. Empty-wiki scenario: running build twice is idempotent; drift-check
#      passes; file sizes within cap
#   3. With-user-entry scenario: install fixture wiki entry, rebuild,
#      verify the entry content appears in copilot-instructions.md
#   4. Drift-check with wiki-present: rebuild is green
#   5. Fixture cleanup: remove fixture, rebuild, verify entry content GONE
#
# Safety: if user has a real wiki entry, we back it up + restore at exit.

set -u

HARNESS="$(cd "$(dirname "$0")/harness" && pwd)"
source "$HARNESS/assertion-lib.sh"

ensure_beta_root
test_banner "11 L1 Wiki → Copilot Injection (Phase 5.2.d wire-copilot)"

BUILD_SH=".dexCore/_dev/tools/build-instructions.sh"
LOAD_WIKI=".dexCore/core/knowledge/load-wiki.sh"
COPILOT_OUT=".github/copilot-instructions.md"
WIKI_DIR="myDex/.dex/wiki"

# ─── Structural: build-instructions.sh references load-wiki.sh ───────
assert_file_exists "$BUILD_SH" "build-instructions.sh present"
assert_file_contains "$BUILD_SH" "load-wiki.sh" \
  "build-instructions.sh references load-wiki.sh (wire exists)"
assert_file_contains "$BUILD_SH" "WIKI_MAX_COPILOT" \
  "build-instructions.sh declares Copilot wiki cap"
assert_file_contains "$BUILD_SH" "wiki_block" \
  "build-instructions.sh has wiki_block helper"

# ─── Back up any existing user wiki entry ─────────────────────────────
# We'll install a fixture; user's real entries (if any) get archived + restored.
WIKI_BACKUP_DIR=$(mktemp -d -t dexhub-wiki-backup-XXXXXX)
BACKED_UP=0
for f in "$WIKI_DIR"/*.md; do
  [ -f "$f" ] || continue
  case "$(basename "$f")" in
    README.md) ;;  # framework-shipped, leave alone
    *.template.md) ;;  # template files, leave alone
    *)
      cp "$f" "$WIKI_BACKUP_DIR/" && rm "$f"
      BACKED_UP=$((BACKED_UP + 1))
      ;;
  esac
done
if [ "$BACKED_UP" -gt 0 ]; then
  pass "Pre-test: $BACKED_UP user wiki entries archived to $WIKI_BACKUP_DIR"
fi

# Also back up current copilot-instructions.md for restoration
COPILOT_BACKUP="/tmp/dexhub-copilot-backup-11-$$-$(date +%s).md"
cp "$COPILOT_OUT" "$COPILOT_BACKUP" 2>/dev/null || true

# Restore trap
restore_fixtures() {
  # Restore user wiki entries
  if [ "$BACKED_UP" -gt 0 ] && [ -d "$WIKI_BACKUP_DIR" ]; then
    for f in "$WIKI_BACKUP_DIR"/*.md; do
      [ -f "$f" ] || continue
      cp "$f" "$WIKI_DIR/"
    done
  fi
  rm -rf "$WIKI_BACKUP_DIR"

  # Restore copilot-instructions.md (rebuild, since the fixture round-trip changed it)
  if [ -f "$COPILOT_BACKUP" ]; then
    cp "$COPILOT_BACKUP" "$COPILOT_OUT"
    rm -f "$COPILOT_BACKUP"
  fi
  echo -e "\033[0;34m  (trap: wiki fixtures removed, copilot-instructions.md restored to pre-test state)\033[0m"
}
trap 'restore_fixtures' EXIT INT TERM

# ─── Scenario 1: empty wiki → build produces clean output ────────────
bash "$BUILD_SH" >/dev/null 2>&1
SIZE_EMPTY=$(wc -c < "$COPILOT_OUT" | tr -d ' ')
if [ "$SIZE_EMPTY" -lt 35000 ]; then
  pass "Scenario 1 (empty wiki): copilot-instructions.md within 35KB cap ($SIZE_EMPTY bytes)"
else
  fail "Scenario 1: copilot-instructions.md exceeds 35KB even with empty wiki ($SIZE_EMPTY)"
fi

# Drift check should pass
if bash "$BUILD_SH" check >/dev/null 2>&1; then
  pass "Scenario 1: drift-check green after build (idempotent)"
else
  fail "Scenario 1: drift-check fails immediately after build"
fi

# No L1 WIKI block in output when wiki is empty
if grep -q "L1 WIKI (user's institutional knowledge)" "$COPILOT_OUT"; then
  fail "Scenario 1: L1 WIKI block present despite empty wiki"
else
  pass "Scenario 1: no L1 WIKI block injected (correctly quiet on empty wiki)"
fi

# ─── Scenario 2: install fixture wiki entry, rebuild, verify injection ─
FIXTURE_MARKER="DEXHUB_TEST_WIKI_INJECTION_MARKER_11"
cat > "$WIKI_DIR/test-fixture.md" <<FIXTURE_EOF
---
title: Test Fixture Entry 11
status: active
why_l1: Pytest assertion target — this string must reach copilot-instructions.md
---

# Wiki Test Entry

The marker $FIXTURE_MARKER should appear in copilot-instructions.md after build.
FIXTURE_EOF

bash "$BUILD_SH" >/dev/null 2>&1
SIZE_WITH_WIKI=$(wc -c < "$COPILOT_OUT" | tr -d ' ')
if [ "$SIZE_WITH_WIKI" -gt "$SIZE_EMPTY" ]; then
  pass "Scenario 2: copilot-instructions.md grew after wiki inject ($SIZE_EMPTY → $SIZE_WITH_WIKI)"
else
  fail "Scenario 2: no size change after wiki inject ($SIZE_EMPTY → $SIZE_WITH_WIKI)"
fi

if [ "$SIZE_WITH_WIKI" -lt 35000 ]; then
  pass "Scenario 2: still within 35KB cap ($SIZE_WITH_WIKI bytes, cap 35000)"
else
  fail "Scenario 2: exceeded 35KB cap with wiki ($SIZE_WITH_WIKI)"
fi

assert_file_contains "$COPILOT_OUT" "L1 WIKI" \
  "Scenario 2: L1 WIKI header injected"
assert_file_contains "$COPILOT_OUT" "test-fixture.md" \
  "Scenario 2: fixture filename in output"
assert_file_contains "$COPILOT_OUT" "$FIXTURE_MARKER" \
  "Scenario 2: fixture content marker reaches copilot-instructions.md"

# Drift-check should still pass with wiki content (because our hash function
# also calls load-wiki.sh — idempotent within a single filesystem state)
if bash "$BUILD_SH" check >/dev/null 2>&1; then
  pass "Scenario 2: drift-check green with wiki injected"
else
  fail "Scenario 2: drift-check fails after wiki inject"
fi

# ─── Scenario 3: remove fixture, rebuild, verify content gone ────────
rm "$WIKI_DIR/test-fixture.md"
bash "$BUILD_SH" >/dev/null 2>&1

if grep -q "$FIXTURE_MARKER" "$COPILOT_OUT"; then
  fail "Scenario 3: fixture marker still in copilot-instructions.md after wiki removed"
else
  pass "Scenario 3: fixture content correctly removed on rebuild"
fi

if grep -q "test-fixture.md" "$COPILOT_OUT"; then
  fail "Scenario 3: fixture filename still in output after removal"
else
  pass "Scenario 3: fixture filename correctly absent after removal"
fi

# ─── Feature registry claim ──────────────────────────────────────────
assert_file_contains ".dexCore/_cfg/features.yaml" "knowledge.l1_wiki_injection_copilot" \
  "features.yaml declares knowledge.l1_wiki_injection_copilot"

test_summary
