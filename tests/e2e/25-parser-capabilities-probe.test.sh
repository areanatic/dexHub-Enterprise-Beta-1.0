#!/bin/bash
# DexHub E2E Test 25 — Parser Capabilities Probe (Phase 5.3.g first slice)
#
# Proves parser.guided_setup_wizard (the probe-and-write layer, without
# the conversational wrapper yet): .dexCore/core/parser/capabilities-probe.sh
# iterates all registered backend adapters, calls each --detect, and
# writes the merged result into capabilities.yaml while preserving user
# notes + preferences.
#
# Closes the known_issue on both kreuzberg + ollama_vlm backends:
#   "Router does NOT yet auto-probe via the adapter's --detect. That
#    unification is a natural follow-up slice — most valuable once
#    guided_setup_wizard (5.3.g) automates capabilities.yaml maintenance."
#
# Per BACKEND-ADAPTER-PATTERN.md §142-157, every assertion runs both on
# a dev-like environment and a PATH-stripped CI-like environment. Both
# must produce green + equivalent structure.

set -u

HARNESS="$(cd "$(dirname "$0")/harness" && pwd)"
source "$HARNESS/assertion-lib.sh"

ensure_beta_root
test_banner "25 Parser Capabilities Probe (Phase 5.3.g first slice)"

PROBE=".dexCore/core/parser/capabilities-probe.sh"

# ─── Structural presence ────────────────────────────────────────────
assert_file_exists "$PROBE" "capabilities-probe.sh present"
if [ -x "$PROBE" ]; then pass "capabilities-probe.sh executable"; else fail "not executable"; fi
if bash -n "$PROBE" 2>/dev/null; then
  pass "capabilities-probe.sh bash-parses cleanly"
else
  fail "capabilities-probe.sh has syntax errors"
fi

HELP=$(bash "$PROBE" --help 2>&1 | head -20)
if echo "$HELP" | grep -qi "capabilities probe"; then
  pass "--help emits header"
else
  fail "--help output unexpected"
fi

# ─── --dry-run emits per-backend JSON ───────────────────────────────
# Capture STDOUT only (the advisory "(dry-run …)" message is on STDERR
# by design — keeps stdout a parseable stream).
DRY_JSON=$(bash "$PROBE" --dry-run --format json 2>/dev/null)
if echo "$DRY_JSON" | ruby -rjson -e 'JSON.parse(STDIN.read)' 2>/dev/null; then
  pass "--dry-run --format json: valid JSON array"
else
  fail "--dry-run JSON malformed" "got: ${DRY_JSON:0:200}"
fi

# Array should include both registered backends
for backend in kreuzberg ollama_vlm; do
  if echo "$DRY_JSON" | ruby -rjson -e '
    arr = JSON.parse(STDIN.read)
    exit(arr.any? { |r| r["backend"] == ARGV[0] } ? 0 : 1)
  ' "$backend" 2>/dev/null; then
    pass "probe result covers backend '$backend'"
  else
    fail "probe result missing backend '$backend'"
  fi
done

# Each entry has required fields from BACKEND-ADAPTER-PATTERN
for field in backend status; do
  if echo "$DRY_JSON" | ruby -rjson -e "
    arr = JSON.parse(STDIN.read)
    exit(arr.all? { |r| r.key?('$field') } ? 0 : 1)
  " 2>/dev/null; then
    pass "probe JSON: all entries have '$field'"
  else
    fail "probe JSON: entry missing '$field'"
  fi
done

# ─── --dry-run emits human-readable table with --format text ────────
# (Default format is TTY-sensitive: text when stdout is a TTY, json
# otherwise. Command substitution captures stdout so TTY check fails
# and default becomes json — we ask explicitly for text here.)
DRY_TEXT=$(bash "$PROBE" --dry-run --format text 2>&1)
if echo "$DRY_TEXT" | grep -q "Capability Probe"; then
  pass "--dry-run --format text: header present"
else
  fail "--dry-run --format text: no header" "got: ${DRY_TEXT:0:200}"
fi
if echo "$DRY_TEXT" | grep -q "BACKEND"; then
  pass "--dry-run --format text: column headers present"
else
  fail "--dry-run --format text: no column headers"
fi

# ─── --backend filter ───────────────────────────────────────────────
SOLO_JSON=$(bash "$PROBE" --dry-run --format json --backend kreuzberg 2>/dev/null)
SOLO_COUNT=$(echo "$SOLO_JSON" | ruby -rjson -e 'puts JSON.parse(STDIN.read).length' 2>/dev/null || echo 0)
if [ "$SOLO_COUNT" = "1" ]; then
  pass "--backend kreuzberg: filters to 1 entry"
else
  fail "--backend kreuzberg: got $SOLO_COUNT entries (expected 1)"
fi

# ─── --out ALT — write to alternate path, verify write ──────────────
SCRATCH_OUT=$(mktemp -t dexhub-probe-out-XXXXXX).yaml
rm -f "$SCRATCH_OUT"   # start fresh, no existing file
bash "$PROBE" --format text --out "$SCRATCH_OUT" >/dev/null 2>&1
if [ -f "$SCRATCH_OUT" ]; then
  pass "--out ALT: capabilities.yaml created at alternate path"
else
  fail "--out ALT: file not created"
fi

# Output YAML has schema_version + parser.backends.* structure
if grep -q "^schema_version:" "$SCRATCH_OUT"; then
  pass "output YAML: schema_version declared"
else
  fail "output YAML: schema_version missing"
fi
if grep -q "^parser:" "$SCRATCH_OUT" && grep -q "^  backends:" "$SCRATCH_OUT"; then
  pass "output YAML: parser.backends: structure present"
else
  fail "output YAML: parser.backends: structure malformed"
fi
for backend in kreuzberg ollama_vlm; do
  if grep -q "^    $backend:" "$SCRATCH_OUT"; then
    pass "output YAML: backend '$backend' block present"
  else
    fail "output YAML: backend '$backend' block missing"
  fi
done

# Each backend block should have installed + probe_status + last_probe
for key in installed probe_status last_probe compliance; do
  COUNT=$(grep -c "^      $key:" "$SCRATCH_OUT" || echo 0)
  if [ "$COUNT" -ge 2 ]; then
    pass "output YAML: '$key' appears for both backends ($COUNT times)"
  else
    fail "output YAML: '$key' count=$COUNT (expected ≥2)"
  fi
done

# ─── Re-probe preserves user-edited notes + preferences ─────────────
# Simulate a user hand-edit: append a preferences block
cat >> "$SCRATCH_OUT" <<'USEREDIT'
  preferences:
    default_pdf_backend: "kreuzberg"
    prefer_native_fallback: false
    user_custom_note: "This is my preference"
USEREDIT

# Hardened per 2026-04-22 session-7 test-quality audit (Agent D finding #1):
# Old check: grep for the substring "user_custom_note" — passes on any
# substring match, including comments, not structural. If the probe dropped
# the preferences block but left "user_custom_note" in a comment somehow,
# the grep would false-pass.
# New check: assert all three VALUE-BEARING keys of the preferences block
# survive as structural entries (indented under preferences:), not just
# as a loose substring. If ANY of the three is lost, the test fails loudly.
verify_preferences_block() {
  local file="$1"
  # Must have a preferences: header
  grep -qE "^  preferences:\s*$" "$file" || return 1
  # All three keys must be present AS KEYS (indented 4 spaces under preferences:)
  grep -qE "^    default_pdf_backend:" "$file" || return 2
  grep -qE "^    prefer_native_fallback:" "$file" || return 3
  grep -qE "^    user_custom_note:" "$file" || return 4
  # Value of user_custom_note must still be the user's string (not empty,
  # not stripped to just a key)
  grep -qE "^    user_custom_note:\s+\"?This is my preference" "$file" || return 5
  return 0
}

verify_preferences_block "$SCRATCH_OUT"
BEFORE_CODE=$?
# Second probe
bash "$PROBE" --format text --out "$SCRATCH_OUT" >/dev/null 2>&1
verify_preferences_block "$SCRATCH_OUT"
AFTER_CODE=$?

if [ "$BEFORE_CODE" = "0" ] && [ "$AFTER_CODE" = "0" ]; then
  pass "re-probe preserves user-edited preferences block (all keys + value survive)"
elif [ "$BEFORE_CODE" != "0" ]; then
  fail "preferences block not even present BEFORE re-probe (code=$BEFORE_CODE) — append step broken?"
else
  fail "re-probe dropped preferences content (after-code=$AFTER_CODE: 0=ok, 1=header, 2=default_pdf_backend, 3=prefer_native_fallback, 4=user_custom_note key, 5=user_custom_note value)"
fi

# ─── Idempotent re-probe doesn't spuriously rewrite ─────────────────
# Hardened per 2026-04-22 audit (Agent D finding #5): old check only
# validated two top-level anchors (schema_version + kreuzberg). Broader
# idempotency guarantee: when we strip the volatile last_probe timestamp
# (which legitimately changes per run), every other line should be
# byte-identical between runs.
# Strip both forms of the timestamp:
#   line  18:      last_probe: "2026-04-20T19:03:40Z"   (YAML field)
#   line   4: # Last probe: 2026-04-20T19:03:40Z        (header comment)
# Both are expected to change per run. Everything else must be identical.
strip_timestamps() {
  grep -v -E "last_probe:|^# Last probe:" "$1" | sort
}
PRE_RESET=$(strip_timestamps "$SCRATCH_OUT")
sleep 1  # ensure different second if file does get rewritten
bash "$PROBE" --format text --out "$SCRATCH_OUT" >/dev/null 2>&1
POST_RESET=$(strip_timestamps "$SCRATCH_OUT")
if grep -q "^schema_version:" "$SCRATCH_OUT" && grep -q "^    kreuzberg:" "$SCRATCH_OUT"; then
  pass "re-probe: structural invariants preserved"
else
  fail "re-probe: structural invariants broken"
fi
if [ "$PRE_RESET" = "$POST_RESET" ]; then
  pass "re-probe: content byte-identical except last_probe (true idempotency)"
else
  fail "re-probe: content drifted beyond last_probe timestamp — check diff"
fi

rm -f "$SCRATCH_OUT"

# ─── --help path still responds with standard PATH ─────────────────
# (Note: under an ultra-minimal PATH that hides `sed`, even --help can
# fail because the help text uses `sed -n` to extract doc comments.
# That's an OS-level dependency, not a probe regression. Test under
# the normal-CI-like PATH which includes /usr/bin.)
env PATH="/usr/bin:/bin" bash "$PROBE" --help >/dev/null 2>&1
HELP_EXIT=$?
if [ "$HELP_EXIT" = "0" ]; then
  pass "--help: exit 0 under CI-like PATH (sed + head available)"
else
  fail "--help: unexpected exit $HELP_EXIT on CI-like PATH"
fi

# ─── features.yaml registration ─────────────────────────────────────
if grep -qE "^\s+- id: parser\.guided_setup_wizard\b" .dexCore/_cfg/features.yaml; then
  pass "features.yaml: parser.guided_setup_wizard registered"
else
  fail "features.yaml: parser.guided_setup_wizard NOT registered"
fi

GSW_STATUS=$(grep -A 5 -e "- id: parser\.guided_setup_wizard" .dexCore/_cfg/features.yaml | grep -m1 "status:" | tr -d ' ')
if echo "$GSW_STATUS" | grep -q "^status:enabled"; then
  pass "features.yaml: parser.guided_setup_wizard status=enabled"
else
  fail "features.yaml: parser.guided_setup_wizard status unexpected ($GSW_STATUS)"
fi

GSW_BODY=$(awk '/- id: parser\.guided_setup_wizard/{flag=1; print; next} flag && /^  - id: / {exit} flag {print}' .dexCore/_cfg/features.yaml)
if echo "$GSW_BODY" | grep -q "25-parser-capabilities-probe"; then
  pass "features.yaml: tests[] references test 25"
else
  fail "features.yaml: tests[] doesn't reference test 25"
fi

# ─── CI-env + dev-env equivalence check ─────────────────────────────
# Per BACKEND-ADAPTER-PATTERN.md §142-157: structural gates must pass
# in both states. The probe script itself short-circuits on ruby absence
# but with the standard /usr/bin:/bin CI PATH, ruby is available.
CI_EXIT=$(env PATH="/usr/bin:/bin" bash "$PROBE" --dry-run --format json >/dev/null 2>&1; echo $?)
if [ "$CI_EXIT" = "0" ]; then
  pass "probe works under CI-simulated PATH (/usr/bin:/bin)"
else
  fail "probe fails under CI-simulated PATH: exit $CI_EXIT"
fi

test_summary
