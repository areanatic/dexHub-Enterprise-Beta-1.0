#!/bin/bash
# DexHub E2E Test 23 — Parser Kreuzberg Backend (Phase 5.3.b)
#
# Proves the kreuzberg adapter at .dexCore/core/parser/backends/kreuzberg.sh:
#   - Script exists, is executable, bash-parses cleanly
#   - --help + --detect + --extract modes all respond
#   - --detect JSON shape matches the stable contract
#     {backend, binary, version, status, setup_hint, supported[], compliance}
#   - When kreuzberg is NOT installed (the default CI state):
#       * --detect returns status=not_installed with a concrete install hint
#       * --extract returns status=not_installed JSON, exit 0
#       * --extract --require returns exit 2 (caller-opt-in hard-fail)
#   - --extract on a missing file returns exit 3
#   - Bad args + unknown flags return exit 1
#   - features.yaml: parser.kreuzberg_backend registered as status=enabled
#     with tests list referencing this file
#   - Opt-in live path (CLAUDE_E2E_LIVE_KREUZBERG=1): when kreuzberg IS
#     installed, extract of a fixture PDF returns status=ok with non-empty
#     content. Gated behind env var so default CI stays always-green.

set -u

HARNESS="$(cd "$(dirname "$0")/harness" && pwd)"
source "$HARNESS/assertion-lib.sh"

ensure_beta_root
test_banner "23 Parser Kreuzberg Backend (Phase 5.3.b)"

ADAPTER=".dexCore/core/parser/backends/kreuzberg.sh"

# ─── Structural ──────────────────────────────────────────────────────
assert_file_exists "$ADAPTER" "kreuzberg.sh present"
if [ -x "$ADAPTER" ]; then pass "kreuzberg.sh executable"; else fail "kreuzberg.sh not executable"; fi
if bash -n "$ADAPTER" 2>/dev/null; then
  pass "kreuzberg.sh bash-parses cleanly"
else
  fail "kreuzberg.sh has syntax errors"
fi

# ─── --help ─────────────────────────────────────────────────────────
HELP=$(bash "$ADAPTER" --help 2>&1 | head -25)
if echo "$HELP" | grep -qi "Kreuzberg backend adapter"; then
  pass "--help emits adapter header"
else
  fail "--help output unexpected"
fi

# ─── --detect JSON shape ────────────────────────────────────────────
DETECT_JSON=$(bash "$ADAPTER" --detect 2>&1)
if echo "$DETECT_JSON" | ruby -rjson -e 'JSON.parse(STDIN.read)' 2>/dev/null; then
  pass "--detect JSON is valid"
else
  fail "--detect JSON malformed" "got: ${DETECT_JSON:0:200}"
fi

for field in backend binary version status setup_hint supported compliance; do
  if echo "$DETECT_JSON" | ruby -rjson -e "d=JSON.parse(STDIN.read); exit(d.key?('$field') ? 0 : 1)" 2>/dev/null; then
    pass "--detect JSON has field '$field'"
  else
    fail "--detect JSON missing field '$field'"
  fi
done

# 'supported' should be a non-empty array
if echo "$DETECT_JSON" | ruby -rjson -e '
  d = JSON.parse(STDIN.read)
  exit(d["supported"].is_a?(Array) && !d["supported"].empty? ? 0 : 1)
' 2>/dev/null; then
  pass "--detect JSON: supported[] is non-empty array"
else
  fail "--detect JSON: supported[] empty or wrong type"
fi

# 'compliance' should be a string matching the known vocabulary
COMPL=$(echo "$DETECT_JSON" | ruby -rjson -e 'puts JSON.parse(STDIN.read)["compliance"]' 2>/dev/null)
case "$COMPL" in
  ok|local_vlm_required|cloud_only) pass "--detect: compliance='$COMPL' is valid" ;;
  *) fail "--detect: compliance='$COMPL' unknown" ;;
esac

# ─── --detect text format ───────────────────────────────────────────
DETECT_TEXT=$(bash "$ADAPTER" --detect --format text 2>&1)
if echo "$DETECT_TEXT" | grep -q "Kreuzberg adapter"; then
  pass "--detect --format text emits human-readable output"
else
  fail "--detect --format text output unexpected"
fi

# ─── Not-installed path (default CI state) ──────────────────────────
STATUS=$(echo "$DETECT_JSON" | ruby -rjson -e 'puts JSON.parse(STDIN.read)["status"]' 2>/dev/null)
case "$STATUS" in
  ready|not_installed|probe_failed|blocked)
    pass "--detect: status '$STATUS' is a valid vocabulary entry"
    ;;
  *)
    fail "--detect: status '$STATUS' is not in the allowed set"
    ;;
esac

# Hardened per 2026-04-22 audit (Agent D finding #2): status-vocab check
# alone is weak — an adapter that hardcoded any plausible value would pass.
# Assert behavioral invariants that must hold REGARDLESS of status:
#   - setup_hint must be a non-empty string (every status needs some user-facing
#     guidance, whether it's "you're good" or "install via X")
#   - compliance must be a non-empty string matching the policy vocabulary
#   - backend must be the literal "kreuzberg" (adapter identifies itself)
if echo "$DETECT_JSON" | ruby -rjson -e '
  d = JSON.parse(STDIN.read)
  failures = []
  failures << "setup_hint missing/empty" if d["setup_hint"].to_s.strip.empty?
  failures << "compliance missing/empty" if d["compliance"].to_s.strip.empty?
  failures << "backend must be \"kreuzberg\", got #{d["backend"].inspect}" unless d["backend"] == "kreuzberg"
  abort failures.join("; ") unless failures.empty?
' 2>/dev/null; then
  pass "--detect: structural invariants hold across all status values (setup_hint, compliance, backend)"
else
  fail "--detect: invariant field missing — status-vocabulary alone is not enough"
fi

# FORMAT=json regression guard (2026-04-22 session-7 post-review).
# Bug: extract_file() captured probe_status via `probe | ruby -rjson`,
# but the probe honors outer $FORMAT. Calling --extract --format text
# would make probe emit text → ruby JSON.parse choke → empty probe_status
# → false "not ready" branch fires even when backend is healthy. The fix
# (local saved_format="$FORMAT"; FORMAT=json; ...; FORMAT="$saved_format")
# prevents this. This assertion exercises the text-mode path that was
# previously only integration-tested via inbox-auto-parse.sh.
TEXT_OUT=$(bash "$ADAPTER" --extract README.md --format text 2>&1 || true)
if echo "$TEXT_OUT" | grep -q "status= —"; then
  fail "--extract --format text emits empty probe_status (FORMAT=json regression)"
else
  pass "--extract --format text: FORMAT=json save/restore holds (no empty-status signature)"
fi

# hint_type field (introduced 2026-04-22 session-7 Option E) — structured
# categorization of setup_hint. Must be present and in the defined vocabulary.
# status→hint_type mapping for this adapter:
#   ready → ok | not_installed → install_backend | probe_failed → probe_error
if echo "$DETECT_JSON" | ruby -rjson -e '
  d = JSON.parse(STDIN.read)
  vocab = %w[ok install_backend daemon_unreachable missing_dependency policy_blocked probe_error]
  ht = d["hint_type"]
  abort "hint_type missing" if ht.nil? || ht.to_s.empty?
  abort "hint_type #{ht.inspect} not in vocab #{vocab}" unless vocab.include?(ht)
  # For kreuzberg specifically: daemon_unreachable is not a valid mapping
  # (kreuzberg is a one-shot CLI, no daemon). Would indicate a bug.
  abort "kreuzberg should never emit daemon_unreachable" if ht == "daemon_unreachable"
  # Consistency: status=ready must map to hint_type=ok
  if d["status"] == "ready" && ht != "ok"
    abort "status=ready but hint_type=#{ht.inspect} (should be ok)"
  end
  # Consistency: status=not_installed must map to install_backend
  if d["status"] == "not_installed" && ht != "install_backend"
    abort "status=not_installed but hint_type=#{ht.inspect} (should be install_backend)"
  end
' 2>/dev/null; then
  pass "--detect: hint_type present + in vocabulary + consistent with status"
else
  fail "--detect: hint_type field missing, invalid, or inconsistent with status"
fi

# On a CI box where kreuzberg is not installed (usual case), we expect
# status=not_installed + a concrete install hint.
if [ "$STATUS" = "not_installed" ]; then
  HINT=$(echo "$DETECT_JSON" | ruby -rjson -e 'puts JSON.parse(STDIN.read)["setup_hint"]' 2>/dev/null)
  if echo "$HINT" | grep -qi "install\|brew\|cargo"; then
    pass "not_installed: hint mentions an install path (brew/cargo/docker)"
  else
    fail "not_installed: hint doesn't mention any install path" "got: $HINT"
  fi

  # --extract in this state returns JSON with status=not_installed, exit 0
  EXTRACT_OUT=$(bash "$ADAPTER" --extract README.md 2>&1)
  EXTRACT_EXIT=$?
  if [ "$EXTRACT_EXIT" = "0" ]; then
    pass "--extract without backend: graceful exit 0"
  else
    fail "--extract without backend: expected exit 0, got $EXTRACT_EXIT"
  fi
  EX_STATUS=$(echo "$EXTRACT_OUT" | ruby -rjson -e 'puts JSON.parse(STDIN.read)["status"]' 2>/dev/null)
  if [ "$EX_STATUS" = "not_installed" ]; then
    pass "--extract without backend: JSON status=not_installed"
  else
    fail "--extract without backend: status=$EX_STATUS"
  fi
  # --require flips exit code to 2
  bash "$ADAPTER" --extract README.md --require >/dev/null 2>&1
  REQ_EXIT=$?
  if [ "$REQ_EXIT" = "2" ]; then
    pass "--extract --require without backend: exit 2"
  else
    fail "--extract --require without backend: expected exit 2, got $REQ_EXIT"
  fi
fi

# ─── Missing file ───────────────────────────────────────────────────
bash "$ADAPTER" --extract "/tmp/nonexistent-kreuzberg-test-${RANDOM}.pdf" >/dev/null 2>&1
MISS_EXIT=$?
if [ "$MISS_EXIT" = "3" ]; then
  pass "--extract missing file: exit 3"
else
  fail "--extract missing file: expected exit 3, got $MISS_EXIT"
fi

# ─── Bad args ───────────────────────────────────────────────────────
bash "$ADAPTER" --nonsense >/dev/null 2>&1
BAD_EXIT=$?
if [ "$BAD_EXIT" = "1" ]; then
  pass "unknown flag: exit 1"
else
  fail "unknown flag: expected exit 1, got $BAD_EXIT"
fi

bash "$ADAPTER" >/dev/null 2>&1
NOARG_EXIT=$?
if [ "$NOARG_EXIT" = "1" ]; then
  pass "no args: exit 1"
else
  fail "no args: expected exit 1, got $NOARG_EXIT"
fi

# ─── features.yaml registration ─────────────────────────────────────
if grep -qE "^\s+- id: parser\.kreuzberg_backend\b" .dexCore/_cfg/features.yaml; then
  pass "features.yaml: parser.kreuzberg_backend registered as '- id:' entry"
else
  fail "features.yaml: parser.kreuzberg_backend NOT registered as feature entry"
fi

KBZ_STATUS_LINE=$(grep -A 5 -e "- id: parser\.kreuzberg_backend" .dexCore/_cfg/features.yaml | grep -m1 "status:" | tr -d ' ')
if echo "$KBZ_STATUS_LINE" | grep -q "^status:enabled"; then
  pass "features.yaml: parser.kreuzberg_backend status=enabled"
else
  fail "features.yaml: parser.kreuzberg_backend status unexpected ($KBZ_STATUS_LINE)"
fi

# tests[] should reference this file
KBZ_BODY=$(awk '/- id: parser\.kreuzberg_backend/{flag=1; print; next} flag && /^  - id: / {exit} flag {print}' .dexCore/_cfg/features.yaml)
if echo "$KBZ_BODY" | grep -q "23-parser-kreuzberg-backend"; then
  pass "features.yaml: parser.kreuzberg_backend tests[] references test 23"
else
  fail "features.yaml: parser.kreuzberg_backend tests[] doesn't reference test 23"
fi

# Documented honest boundary: known_issues should mention that live
# behavior requires user install.
if echo "$KBZ_BODY" | grep -qi "not installed\|user.*install\|install.*not\|requires.*install"; then
  pass "features.yaml: known_issues documents install-required nature"
else
  fail "features.yaml: doesn't note backend install requirement"
fi

# ─── OPT-IN LIVE: kreuzberg-installed path ──────────────────────────
if [ "${CLAUDE_E2E_LIVE_KREUZBERG:-0}" = "1" ]; then
  echo ""
  echo "  [LIVE] CLAUDE_E2E_LIVE_KREUZBERG=1 — attempting real extraction…"
  if [ "$STATUS" != "ready" ]; then
    echo "  [LIVE] Backend not ready on this machine — skipping live assertions."
    echo "        Install: brew install kreuzberg-dev/tap/kreuzberg"
  else
    # Create a small text fixture for a portability-safe test —
    # kreuzberg handles .txt, and we don't need a large sample.
    FX=$(mktemp -t dexhub-23-live-XXXXXX).txt
    printf "Unique live test string: quokka-xylophone-7824\n" > "$FX"
    LIVE_OUT=$(bash "$ADAPTER" --extract "$FX" 2>&1)
    LIVE_STATUS=$(echo "$LIVE_OUT" | ruby -rjson -e 'puts JSON.parse(STDIN.read)["status"]' 2>/dev/null)
    LIVE_CONTENT=$(echo "$LIVE_OUT" | ruby -rjson -e 'puts JSON.parse(STDIN.read)["content"]' 2>/dev/null)
    if [ "$LIVE_STATUS" = "ok" ]; then
      pass "[LIVE] extract: status=ok"
    else
      fail "[LIVE] extract: status=$LIVE_STATUS"
    fi
    if echo "$LIVE_CONTENT" | grep -q "quokka-xylophone-7824"; then
      pass "[LIVE] extract: content preserved round-trip"
    else
      fail "[LIVE] extract: content didn't round-trip"
    fi
    rm -f "$FX"
  fi
fi

test_summary
