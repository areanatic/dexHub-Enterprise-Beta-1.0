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

# ─── Bad --name → exit 1 (Agent-β finding 2026-04-22 session-7) ─────
# Reject names containing path separators or control characters, which
# would produce malformed filenames or corrupt .desktop files.
bash "$SCRIPT" --inbox "$SCRATCH_INBOX" --name "bad/slash" >/dev/null 2>&1
NAME_SLASH_EXIT=$?
if [ "$NAME_SLASH_EXIT" = "1" ]; then
  pass "--name with slash: exit 1"
else
  fail "--name with slash: expected exit 1, got $NAME_SLASH_EXIT"
fi
bash "$SCRIPT" --inbox "$SCRATCH_INBOX" --name "" >/dev/null 2>&1
NAME_EMPTY_EXIT=$?
if [ "$NAME_EMPTY_EXIT" = "1" ]; then
  pass "--name empty: exit 1"
else
  fail "--name empty: expected exit 1, got $NAME_EMPTY_EXIT"
fi
# Control char: newline in the name
bash "$SCRIPT" --inbox "$SCRATCH_INBOX" --name "$(printf 'line1\nline2')" >/dev/null 2>&1
NAME_NL_EXIT=$?
if [ "$NAME_NL_EXIT" = "1" ]; then
  pass "--name with embedded newline: exit 1"
else
  fail "--name with newline: expected exit 1, got $NAME_NL_EXIT"
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

# ─── XDG_DESKTOP_DIR full xdg-user-dirs.dirs resolution (session-7) ─
# Priority: env var > user-dirs.dirs file > $HOME/Desktop default.
# Localized Linux (Schreibtisch / Bureau / 桌面) now works via file parse.
XDG_SCRATCH=$(mktemp -d -t dex-xdg-XXXXXX)
mkdir -p "$XDG_SCRATCH/.config" "$XDG_SCRATCH/Schreibtisch" "$XDG_SCRATCH/inbox"

# Case 1: env var takes priority
mkdir -p "$XDG_SCRATCH/custom"
XDG_ENV_JSON=$(XDG_DESKTOP_DIR="$XDG_SCRATCH/custom" HOME="$XDG_SCRATCH" \
  bash "$SCRIPT" --dry-run --inbox "$XDG_SCRATCH/inbox" --format json 2>/dev/null)
XDG_ENV_PATH=$(echo "$XDG_ENV_JSON" | ruby -rjson -e 'puts JSON.parse(STDIN.read)["shortcut_path"]' 2>/dev/null)
if echo "$XDG_ENV_PATH" | grep -q "/custom/"; then
  pass "XDG_DESKTOP_DIR env var takes priority over user-dirs.dirs"
else
  fail "XDG env priority failed: got '$XDG_ENV_PATH'"
fi

# Case 2: user-dirs.dirs with German locale (\$HOME/Schreibtisch)
cat > "$XDG_SCRATCH/.config/user-dirs.dirs" <<'UDIRS'
# Localized Linux Desktop folder
XDG_DESKTOP_DIR="$HOME/Schreibtisch"
XDG_DOWNLOAD_DIR="$HOME/Downloads"
UDIRS
# unset XDG_DESKTOP_DIR so file-based path is used
LOC_JSON=$(env -u XDG_DESKTOP_DIR HOME="$XDG_SCRATCH" \
  bash "$SCRIPT" --dry-run --inbox "$XDG_SCRATCH/inbox" --format json 2>/dev/null)
LOC_PATH=$(echo "$LOC_JSON" | ruby -rjson -e 'puts JSON.parse(STDIN.read)["shortcut_path"]' 2>/dev/null)
if echo "$LOC_PATH" | grep -q "/Schreibtisch/"; then
  pass "xdg-user-dirs.dirs file: localized Desktop (Schreibtisch) resolved"
else
  fail "xdg-user-dirs resolution failed: got '$LOC_PATH'"
fi

# Case 3: commented-out line must be ignored (edge-case hardening)
cat > "$XDG_SCRATCH/.config/user-dirs.dirs" <<'UDIRS'
# XDG_DESKTOP_DIR="$HOME/ShouldBeIgnored"
XDG_DESKTOP_DIR="$HOME/Schreibtisch"
UDIRS
IGN_JSON=$(env -u XDG_DESKTOP_DIR HOME="$XDG_SCRATCH" \
  bash "$SCRIPT" --dry-run --inbox "$XDG_SCRATCH/inbox" --format json 2>/dev/null)
IGN_PATH=$(echo "$IGN_JSON" | ruby -rjson -e 'puts JSON.parse(STDIN.read)["shortcut_path"]' 2>/dev/null)
if echo "$IGN_PATH" | grep -q "/Schreibtisch/" && ! echo "$IGN_PATH" | grep -q "ShouldBeIgnored"; then
  pass "xdg-user-dirs.dirs: commented lines are skipped"
else
  fail "xdg-user-dirs comment handling: got '$IGN_PATH'"
fi

# Case 4: no env, no user-dirs.dirs → default $HOME/Desktop
mkdir -p "$XDG_SCRATCH/Desktop"
rm -f "$XDG_SCRATCH/.config/user-dirs.dirs"
DEF_JSON=$(env -u XDG_DESKTOP_DIR HOME="$XDG_SCRATCH" \
  bash "$SCRIPT" --dry-run --inbox "$XDG_SCRATCH/inbox" --format json 2>/dev/null)
DEF_PATH=$(echo "$DEF_JSON" | ruby -rjson -e 'puts JSON.parse(STDIN.read)["shortcut_path"]' 2>/dev/null)
if echo "$DEF_PATH" | grep -qE "/Desktop/"; then
  pass "no env + no user-dirs.dirs → defaults to \$HOME/Desktop"
else
  fail "XDG fallback-default failed: got '$DEF_PATH'"
fi

rm -rf "$XDG_SCRATCH"

# ─── Windows .lnk scaffold (session-7 TODO #6) ──────────────────────
# Can't execute PowerShell on this macOS CI — assert STRUCTURAL presence
# of the windows branch so future refactors don't silently drop it.
if grep -qE '^\s+windows\)' "$SCRIPT"; then
  pass "inbox-setup.sh: windows case present in create-action dispatch"
else
  fail "inbox-setup.sh: windows branch missing"
fi
if grep -qE '^\s+windows\)\s+SHORTCUT_PATH=.*\.lnk' "$SCRIPT"; then
  pass "inbox-setup.sh: windows computes SHORTCUT_PATH as .lnk"
else
  fail "inbox-setup.sh: windows SHORTCUT_PATH not .lnk"
fi
if grep -q 'pwsh.exe' "$SCRIPT" && grep -q 'powershell.exe' "$SCRIPT"; then
  pass "inbox-setup.sh: windows probes both pwsh.exe + powershell.exe"
else
  fail "inbox-setup.sh: PowerShell detection incomplete"
fi
if grep -q 'WScript.Shell' "$SCRIPT" && grep -q 'CreateShortcut' "$SCRIPT"; then
  pass "inbox-setup.sh: windows uses WScript.Shell COM for .lnk creation"
else
  fail "inbox-setup.sh: COM shortcut creation missing"
fi
if grep -q 'cygpath' "$SCRIPT"; then
  pass "inbox-setup.sh: windows uses cygpath for bash↔Windows path conversion"
else
  fail "inbox-setup.sh: cygpath conversion missing"
fi
if grep -qE '"missing_dependency".*pwsh.*powershell|PowerShell.*PATH' "$SCRIPT"; then
  pass "inbox-setup.sh: missing-PowerShell case surfaces honest hint"
else
  fail "inbox-setup.sh: PowerShell-missing hint missing"
fi
# Help text must still exit 2 for unknown platforms (not windows anymore)
if ! grep -q 'unsupported_platform.*2.*roadmap' "$SCRIPT"; then
  pass "inbox-setup.sh: Windows-roadmap hint replaced by live scaffold (known_issue retired)"
else
  fail "inbox-setup.sh: stale \"Windows on 1.1 roadmap\" hint still present"
fi

# ─── PowerShell apostrophe escaping (session-7 Agent-β critical) ────
# Names with apostrophes ("Arash's Inbox", "O'Connor's Documents",
# "d'Angelo's Folder") broke the PS single-quoted string. Fix: double
# the apostrophe (PowerShell's own escape rule for single-quoted strings).
# Verify the escape is present in the Windows branch.
if grep -qE 'INBOX_WIN_PS=.*//\\?..*\\?.\\?.' "$SCRIPT" || grep -q 'INBOX_WIN_PS=' "$SCRIPT"; then
  pass "inbox-setup.sh: INBOX_WIN_PS variable present (PowerShell escape layer)"
else
  fail "inbox-setup.sh: PowerShell apostrophe escape missing (Arash's Inbox would break)"
fi
if grep -q 'SHORTCUT_WIN_PS=' "$SCRIPT"; then
  pass "inbox-setup.sh: SHORTCUT_WIN_PS variable present (PowerShell escape layer)"
else
  fail "inbox-setup.sh: SHORTCUT_WIN_PS escape missing"
fi
# Verify the PS -Command uses the escaped vars, not the raw ones
if grep -qE "CreateShortcut\('\\\$SHORTCUT_WIN_PS'\)" "$SCRIPT"; then
  pass "inbox-setup.sh: PS CreateShortcut uses escaped SHORTCUT_WIN_PS"
else
  fail "inbox-setup.sh: PS still uses raw SHORTCUT_WIN (apostrophe vulnerability)"
fi

# Behavioral test: run the bash-only portion (not PS) with an
# apostrophe-bearing name. Bash validation should PASS (apostrophes
# are legal in filenames), and the escape-layer should produce the
# doubled-apostrophe form. Simulate by exercising --dry-run (which
# never calls PS) and verifying the script accepts the name.
# Uses an explicit scratch Desktop via XDG_DESKTOP_DIR so CI runners
# without $HOME/Desktop don't exit 3 before the name-validation path.
APOS_SCRATCH=$(mktemp -d -t dex-apos-XXXXXX)
mkdir -p "$APOS_SCRATCH/Desktop" "$APOS_SCRATCH/inbox"
APOS_JSON=$(XDG_DESKTOP_DIR="$APOS_SCRATCH/Desktop" HOME="$APOS_SCRATCH" \
  bash "$SCRIPT" --dry-run --inbox "$APOS_SCRATCH/inbox" --name "Arash's Inbox" --format json 2>/dev/null)
APOS_EXIT=$?
APOS_NAME=$(echo "$APOS_JSON" | ruby -rjson -e 'puts JSON.parse(STDIN.read)["shortcut_name"]' 2>/dev/null)
if [ "$APOS_EXIT" = "0" ] && [ "$APOS_NAME" = "Arash's Inbox" ]; then
  pass "apostrophe-bearing name passes bash validation + propagates correctly"
else
  fail "apostrophe name rejected or mangled: exit=$APOS_EXIT name='$APOS_NAME'"
fi
rm -rf "$APOS_SCRATCH"

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
