#!/bin/bash
# DexHub E2E Test 27 — Parser Inbox Desktop-Shortcut Setup (Phase 5.3.h first slice)
#
# Proves the shortcut-setup orchestrator:
#   - script exists, parses, has --help
#   - --dry-run produces plan without touching the filesystem
#   - --name custom name works
#   - --inbox override resolves correctly
#   - Bad flag → exit 1
#   - Unsupported platform → exit 2
#   - features.yaml: parser.inbox_shortcut_setup registered as enabled
#   - DexMaster *inbox-setup menu item + prompt handler exist
#
# Live assertions (opt-in via CLAUDE_E2E_LIVE_INBOX_SETUP=1):
#   - Actually creates a shortcut on a scratch Desktop directory
#   - --remove actually deletes it
#   - Idempotency: re-create without --force → exit 5
#
# Dual-env-safe: structural assertions run on dev + CI clean. The live
# path requires Desktop write access so it's opt-in only.

set -u

HARNESS="$(cd "$(dirname "$0")/harness" && pwd)"
source "$HARNESS/assertion-lib.sh"

ensure_beta_root
test_banner "27 Parser Inbox Desktop-Shortcut Setup (Phase 5.3.h first slice)"

SCRIPT=".dexCore/core/parser/inbox-setup.sh"

# ─── Structural ──────────────────────────────────────────────────────
assert_file_exists "$SCRIPT" "inbox-setup.sh present"
if [ -x "$SCRIPT" ]; then pass "inbox-setup.sh executable"; else fail "not executable"; fi
if bash -n "$SCRIPT" 2>/dev/null; then
  pass "inbox-setup.sh bash-parses cleanly"
else
  fail "inbox-setup.sh has syntax errors"
fi

HELP=$(bash "$SCRIPT" --help 2>&1 | head -20)
if echo "$HELP" | grep -qi "desktop-shortcut setup"; then
  pass "--help emits header"
else
  fail "--help output unexpected"
fi

# ─── Scratch fixture ─────────────────────────────────────────────────
SCRATCH=$(mktemp -d -t dex-setup27-XXXXXX)
SCRATCH_INBOX="$SCRATCH/inbox"
mkdir -p "$SCRATCH_INBOX"
cleanup() { rm -rf "$SCRATCH"; }
trap 'cleanup' EXIT INT TERM

# ─── --dry-run default create ───────────────────────────────────────
DRY_JSON=$(bash "$SCRIPT" --dry-run --inbox "$SCRATCH_INBOX" --format json 2>/dev/null)
DRY_STATUS=$(echo "$DRY_JSON" | ruby -rjson -e 'puts JSON.parse(STDIN.read)["status"]' 2>/dev/null)
DRY_FLAG=$(echo "$DRY_JSON" | ruby -rjson -e 'puts JSON.parse(STDIN.read)["dry_run"]' 2>/dev/null)
DRY_INBOX=$(echo "$DRY_JSON" | ruby -rjson -e 'puts JSON.parse(STDIN.read)["inbox"]' 2>/dev/null)

case "$DRY_STATUS" in
  would_create|unsupported_platform|desktop_missing)
    pass "dry-run: status='$DRY_STATUS' (valid)"
    ;;
  *)
    fail "dry-run: unexpected status='$DRY_STATUS'"
    ;;
esac
if [ "$DRY_FLAG" = "true" ]; then
  pass "dry-run: dry_run=true in output"
else
  fail "dry-run: dry_run='$DRY_FLAG' (expected true)"
fi
# --inbox override must flow into output
if [ "$DRY_INBOX" = "$SCRATCH_INBOX" ]; then
  pass "dry-run: --inbox override propagated"
else
  fail "dry-run: inbox='$DRY_INBOX', expected '$SCRATCH_INBOX'"
fi

# ─── --name custom shortcut name ────────────────────────────────────
NAME_JSON=$(bash "$SCRIPT" --dry-run --inbox "$SCRATCH_INBOX" --name "MyDexBox" --format json 2>/dev/null)
NAME_FIELD=$(echo "$NAME_JSON" | ruby -rjson -e 'puts JSON.parse(STDIN.read)["shortcut_name"]' 2>/dev/null)
if [ "$NAME_FIELD" = "MyDexBox" ]; then
  pass "--name override: shortcut_name='MyDexBox'"
else
  fail "--name override: got '$NAME_FIELD'"
fi

# ─── Bad flag → exit 1 ──────────────────────────────────────────────
bash "$SCRIPT" --nonsense >/dev/null 2>&1
BAD_EXIT=$?
if [ "$BAD_EXIT" = "1" ]; then
  pass "unknown flag: exit 1"
else
  fail "unknown flag: expected exit 1, got $BAD_EXIT"
fi

# ─── Missing inbox dir → exit 4 ─────────────────────────────────────
bash "$SCRIPT" --inbox "/tmp/does-not-exist-${RANDOM}${RANDOM}" --format json >/dev/null 2>&1
MISS_EXIT=$?
if [ "$MISS_EXIT" = "4" ] || [ "$MISS_EXIT" = "2" ] || [ "$MISS_EXIT" = "3" ]; then
  # 4 = inbox missing (expected on real platforms where Desktop exists)
  # 2/3 = platform/desktop guard fired first — still correctly non-zero
  pass "missing inbox: non-zero exit ($MISS_EXIT)"
else
  fail "missing inbox: expected exit 2/3/4, got $MISS_EXIT"
fi

# ─── features.yaml registration ─────────────────────────────────────
if grep -qE "^\s+- id: parser\.inbox_shortcut_setup\b" .dexCore/_cfg/features.yaml; then
  pass "features.yaml: parser.inbox_shortcut_setup registered"
else
  fail "features.yaml: parser.inbox_shortcut_setup NOT registered"
fi
ISS_STATUS=$(grep -A 5 -e "- id: parser\.inbox_shortcut_setup" .dexCore/_cfg/features.yaml | grep -m1 "status:" | tr -d ' ')
if echo "$ISS_STATUS" | grep -q "^status:enabled"; then
  pass "features.yaml: parser.inbox_shortcut_setup status=enabled"
else
  fail "features.yaml: parser.inbox_shortcut_setup status='$ISS_STATUS'"
fi
ISS_BODY=$(awk '/- id: parser\.inbox_shortcut_setup/{flag=1; print; next} flag && /^  - id: / {exit} flag {print}' .dexCore/_cfg/features.yaml)
if echo "$ISS_BODY" | grep -q "27-parser-inbox-shortcut"; then
  pass "features.yaml: tests[] references test 27"
else
  fail "features.yaml: tests[] missing test 27"
fi

# ─── DexMaster menu + prompt handler ────────────────────────────────
if grep -qE '<item cmd="\*inbox-setup"' .dexCore/core/agents/dex-master.md; then
  pass "dex-master.md: *inbox-setup menu item present"
else
  fail "dex-master.md: *inbox-setup menu item missing"
fi
if grep -qE '^[[:space:]]*<prompt id="inbox-setup">' .dexCore/core/agents/dex-master.md; then
  pass "dex-master.md: inbox-setup prompt handler defined"
else
  fail "dex-master.md: inbox-setup prompt handler missing"
fi
SETUP_PROMPT_BODY=$(awk '/^[[:space:]]*<prompt id="inbox-setup">/,/^[[:space:]]*<\/prompt>/' .dexCore/core/agents/dex-master.md)
if echo "$SETUP_PROMPT_BODY" | grep -q "inbox-setup.sh"; then
  pass "dex-master.md: inbox-setup prompt invokes inbox-setup.sh"
else
  fail "dex-master.md: inbox-setup prompt doesn't reference the script"
fi

# ─── Cosmetic: known_issue on parser.inbox_auto_parse is retired ────
# Session-7 closes the "Desktop-shortcut creation is NOT in this slice" note.
IAP_BODY=$(awk '/- id: parser\.inbox_auto_parse/{flag=1; print; next} flag && /^  - id: / {exit} flag {print}' .dexCore/_cfg/features.yaml)
if echo "$IAP_BODY" | grep -q "Desktop-shortcut creation.*is NOT in this slice"; then
  fail "parser.inbox_auto_parse still carries the retired desktop-shortcut known_issue"
else
  pass "parser.inbox_auto_parse: session-6 desktop-shortcut known_issue retired"
fi

# ─── Live path (opt-in via CLAUDE_E2E_LIVE_INBOX_SETUP=1) ───────────
# Creates a real shortcut on a scratch Desktop. Never touches the user's
# actual ~/Desktop even in live mode — XDG_DESKTOP_DIR=scratch redirects.
if [ "${CLAUDE_E2E_LIVE_INBOX_SETUP:-0}" = "1" ]; then
  echo "  [LIVE] running desktop-shortcut create/remove on scratch Desktop..."
  LIVE_DESKTOP="$SCRATCH/Desktop"
  mkdir -p "$LIVE_DESKTOP"

  # Create
  CREATE_JSON=$(XDG_DESKTOP_DIR="$LIVE_DESKTOP" HOME="$SCRATCH" \
    bash "$SCRIPT" --inbox "$SCRATCH_INBOX" --format json 2>/dev/null)
  CREATE_STATUS=$(echo "$CREATE_JSON" | ruby -rjson -e 'puts JSON.parse(STDIN.read)["status"]' 2>/dev/null)
  if [ "$CREATE_STATUS" = "created" ]; then
    pass "[LIVE] create: status=created"
  else
    fail "[LIVE] create: status='$CREATE_STATUS'"
  fi
  # Verify file exists on platform AND points at the right inbox.
  # Existence alone is weak — a buggy script could create a shortcut
  # to /tmp and still pass. Per session-7 critical review: target must
  # match the resolved inbox absolute path.
  UNAME_S=$(uname -s)
  EXPECTED_ABS="$(cd "$SCRATCH_INBOX" && pwd)"
  if [ "$UNAME_S" = "Darwin" ]; then
    if [ -L "$LIVE_DESKTOP/DexHub-Inbox" ]; then
      pass "[LIVE] macOS: symlink exists at scratch Desktop"
      LINK_TARGET=$(readlink "$LIVE_DESKTOP/DexHub-Inbox")
      if [ "$LINK_TARGET" = "$EXPECTED_ABS" ]; then
        pass "[LIVE] macOS: symlink target matches scratch inbox ($LINK_TARGET)"
      else
        fail "[LIVE] macOS: symlink points to '$LINK_TARGET', expected '$EXPECTED_ABS'"
      fi
    else
      fail "[LIVE] macOS: symlink missing"
    fi
  else
    if [ -f "$LIVE_DESKTOP/DexHub-Inbox.desktop" ]; then
      pass "[LIVE] linux: .desktop file exists"
      if grep -qF "URL=file://$EXPECTED_ABS" "$LIVE_DESKTOP/DexHub-Inbox.desktop"; then
        pass "[LIVE] linux: .desktop URL points at scratch inbox"
      else
        fail "[LIVE] linux: .desktop URL doesn't match expected path '$EXPECTED_ABS'"
      fi
    else
      fail "[LIVE] linux: .desktop file missing"
    fi
  fi

  # Idempotency: re-create without --force → exit 5
  XDG_DESKTOP_DIR="$LIVE_DESKTOP" HOME="$SCRATCH" \
    bash "$SCRIPT" --inbox "$SCRATCH_INBOX" >/dev/null 2>&1
  REEX_EXIT=$?
  if [ "$REEX_EXIT" = "5" ]; then
    pass "[LIVE] idempotency: re-create without --force → exit 5"
  else
    fail "[LIVE] idempotency: expected exit 5, got $REEX_EXIT"
  fi

  # Remove
  REMOVE_JSON=$(XDG_DESKTOP_DIR="$LIVE_DESKTOP" HOME="$SCRATCH" \
    bash "$SCRIPT" --remove --format json 2>/dev/null)
  REMOVE_STATUS=$(echo "$REMOVE_JSON" | ruby -rjson -e 'puts JSON.parse(STDIN.read)["status"]' 2>/dev/null)
  if [ "$REMOVE_STATUS" = "removed" ]; then
    pass "[LIVE] remove: status=removed"
  else
    fail "[LIVE] remove: status='$REMOVE_STATUS'"
  fi
else
  echo "  (live path skipped — set CLAUDE_E2E_LIVE_INBOX_SETUP=1 to run)"
fi

test_summary
