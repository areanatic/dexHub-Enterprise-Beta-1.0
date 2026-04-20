#!/bin/bash
# DexHub E2E Test 29 — Parser Inbox Watcher (Phase 5.3.i)
#
# Structural tests for parser.inbox_watcher:
#   - script exists, executable, bash-parses
#   - --help emits header
#   - --dry-run (text + json) shows resolved method + interval
#   - --once delegates to inbox-auto-parse and returns cleanly
#   - Bad flag → exit 1
#   - Missing inbox → exit 3
#   - --method explicit + tool absent → exit 4 with honest hint
#   - Invalid --interval → exit 1
#   - features.yaml: parser.inbox_watcher registered + enabled + test 29
#   - DexMaster menu has *inbox-watch item
#
# Does NOT test the continuous --start loop (would require a long-running
# process + real filesystem events — out of scope for structural e2e).
# The --once path exercises the same process_once() function used by
# every loop method, so coverage is effectively good.

set -u

HARNESS="$(cd "$(dirname "$0")/harness" && pwd)"
source "$HARNESS/assertion-lib.sh"

ensure_beta_root
test_banner "29 Parser Inbox Watcher (Phase 5.3.i first slice)"

SCRIPT=".dexCore/core/parser/inbox-watch.sh"

# ─── Structural ──────────────────────────────────────────────────────
assert_file_exists "$SCRIPT" "inbox-watch.sh present"
if [ -x "$SCRIPT" ]; then pass "inbox-watch.sh executable"; else fail "not executable"; fi
if bash -n "$SCRIPT" 2>/dev/null; then
  pass "inbox-watch.sh bash-parses cleanly"
else
  fail "inbox-watch.sh has syntax errors"
fi

HELP=$(bash "$SCRIPT" --help 2>&1 | head -5)
if echo "$HELP" | grep -qi "Inbox Watcher"; then
  pass "--help emits header"
else
  fail "--help output unexpected"
fi

# ─── Scratch inbox ──────────────────────────────────────────────────
SCRATCH=$(mktemp -d -t dex-watch29-XXXXXX)
SCRATCH_INBOX="$SCRATCH/inbox"
mkdir -p "$SCRATCH_INBOX"
cleanup() { rm -rf "$SCRATCH"; }
trap 'cleanup' EXIT INT TERM

# ─── --dry-run JSON ─────────────────────────────────────────────────
DRY_JSON=$(bash "$SCRIPT" --dry-run --inbox "$SCRATCH_INBOX" --format json 2>/dev/null)
if echo "$DRY_JSON" | ruby -rjson -e '
  d = JSON.parse(STDIN.read)
  fields = %w[mode inbox method interval would]
  missing = fields.reject { |f| d.key?(f) }
  abort "missing fields: #{missing}" unless missing.empty?
  abort "mode must be dry-run" unless d["mode"] == "dry-run"
  abort "method must be in vocab" unless %w[fswatch inotify poll].include?(d["method"])
  abort "interval must be a positive integer" unless d["interval"].is_a?(Integer) && d["interval"] >= 1
' 2>/dev/null; then
  pass "--dry-run JSON: all required fields + valid vocabulary"
else
  fail "--dry-run JSON malformed"
fi

# ─── --dry-run text ─────────────────────────────────────────────────
DRY_TEXT=$(bash "$SCRIPT" --dry-run --inbox "$SCRATCH_INBOX" 2>&1)
if echo "$DRY_TEXT" | grep -qi "dry-run"; then
  pass "--dry-run text: mode surfaced in output"
else
  fail "--dry-run text: mode missing"
fi

# ─── --once delegates to inbox-auto-parse ──────────────────────────
ONCE_JSON=$(bash "$SCRIPT" --once --inbox "$SCRATCH_INBOX" --format json 2>/dev/null)
# inbox-auto-parse JSON contract: {inbox, inbox_source, dry_run, count, results}
if echo "$ONCE_JSON" | ruby -rjson -e '
  d = JSON.parse(STDIN.read)
  abort "not inbox-auto-parse output — missing count/results" unless d.key?("count") && d.key?("results")
  abort "expected count=0 for empty inbox" unless d["count"] == 0
' 2>/dev/null; then
  pass "--once delegates to inbox-auto-parse (count=0 on empty inbox)"
else
  fail "--once delegation broken"
fi

# ─── Bad flag → exit 1 ──────────────────────────────────────────────
bash "$SCRIPT" --nonsense >/dev/null 2>&1
if [ "$?" = "1" ]; then
  pass "unknown flag: exit 1"
else
  fail "unknown flag: expected 1, got $?"
fi

# ─── Missing inbox → exit 3 ─────────────────────────────────────────
bash "$SCRIPT" --dry-run --inbox "/tmp/no-such-inbox-${RANDOM}${RANDOM}" >/dev/null 2>&1
MISS_EXIT=$?
if [ "$MISS_EXIT" = "3" ]; then
  pass "missing inbox: exit 3"
else
  fail "missing inbox: expected 3, got $MISS_EXIT"
fi

# ─── Invalid --interval → exit 1 ────────────────────────────────────
bash "$SCRIPT" --dry-run --inbox "$SCRATCH_INBOX" --interval "abc" >/dev/null 2>&1
if [ "$?" = "1" ]; then
  pass "invalid --interval (non-numeric): exit 1"
else
  fail "invalid --interval: expected 1, got $?"
fi
bash "$SCRIPT" --dry-run --inbox "$SCRATCH_INBOX" --interval "0" >/dev/null 2>&1
if [ "$?" = "1" ]; then
  pass "invalid --interval (zero): exit 1"
else
  fail "interval=0: expected 1, got $?"
fi

# ─── --method poll always works (structural) ────────────────────────
POLL_JSON=$(bash "$SCRIPT" --dry-run --inbox "$SCRATCH_INBOX" --method poll --format json 2>/dev/null)
POLL_METHOD=$(echo "$POLL_JSON" | ruby -rjson -e 'puts JSON.parse(STDIN.read)["method"]' 2>/dev/null)
if [ "$POLL_METHOD" = "poll" ]; then
  pass "--method poll: resolved as poll"
else
  fail "--method poll: resolved as '$POLL_METHOD'"
fi

# ─── --method fswatch when absent → exit 4 ──────────────────────────
if ! command -v fswatch >/dev/null 2>&1; then
  bash "$SCRIPT" --inbox "$SCRATCH_INBOX" --method fswatch --once >/dev/null 2>&1
  if [ "$?" = "4" ]; then
    pass "--method fswatch + tool absent: exit 4"
  else
    fail "--method fswatch absent: expected 4, got $?"
  fi
else
  echo "  (fswatch present — skipping missing-tool assertion)"
fi

# ─── --method inotify when absent → exit 4 ─────────────────────────
if ! command -v inotifywait >/dev/null 2>&1; then
  bash "$SCRIPT" --inbox "$SCRATCH_INBOX" --method inotify --once >/dev/null 2>&1
  if [ "$?" = "4" ]; then
    pass "--method inotify + tool absent: exit 4"
  else
    fail "--method inotify absent: expected 4, got $?"
  fi
fi

# ─── --method invalid value → exit 4 ───────────────────────────────
bash "$SCRIPT" --dry-run --inbox "$SCRATCH_INBOX" --method nonsense >/dev/null 2>&1
if [ "$?" = "4" ]; then
  pass "--method invalid value: exit 4"
else
  fail "invalid method: expected 4, got $?"
fi

# ─── features.yaml registration ─────────────────────────────────────
if grep -qE "^\s+- id: parser\.inbox_watcher\b" .dexCore/_cfg/features.yaml; then
  pass "features.yaml: parser.inbox_watcher registered"
else
  fail "features.yaml: parser.inbox_watcher NOT registered"
fi
IW_STATUS=$(grep -A 5 -e "- id: parser\.inbox_watcher" .dexCore/_cfg/features.yaml | grep -m1 "status:" | tr -d ' ')
if echo "$IW_STATUS" | grep -q "^status:enabled"; then
  pass "features.yaml: parser.inbox_watcher status=enabled"
else
  fail "features.yaml: parser.inbox_watcher status='$IW_STATUS'"
fi
IW_BODY=$(awk '/- id: parser\.inbox_watcher/{flag=1; print; next} flag && /^  - id: / {exit} flag {print}' .dexCore/_cfg/features.yaml)
if echo "$IW_BODY" | grep -q "29-parser-inbox-watch"; then
  pass "features.yaml: tests[] references test 29"
else
  fail "features.yaml: tests[] missing test 29"
fi

# ─── DexMaster menu + prompt handler ────────────────────────────────
if grep -qE '<item cmd="\*inbox-watch"' .dexCore/core/agents/dex-master.md; then
  pass "dex-master.md: *inbox-watch menu item present"
else
  fail "dex-master.md: *inbox-watch menu item missing"
fi
if grep -qE '^[[:space:]]*<prompt id="inbox-watch">' .dexCore/core/agents/dex-master.md; then
  pass "dex-master.md: inbox-watch prompt handler defined"
else
  fail "dex-master.md: inbox-watch prompt handler missing"
fi

test_summary
