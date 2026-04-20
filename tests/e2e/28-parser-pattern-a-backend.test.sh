#!/bin/bash
# DexHub E2E Test 28 — Parser Pattern A Vector+Text Backend (Phase 5.3.d)
#
# Structural-first test for parser.pattern_a_vector_text:
#   - script exists, executable, bash-parses
#   - --help emits header
#   - --detect returns valid JSON with required fields (including hint_type)
#   - status ∈ vocabulary; hint_type ∈ vocabulary; status↔hint_type consistent
#   - --extract without backend ready: graceful exit 0
#   - --extract --require without backend: exit 2
#   - --extract on missing file: exit 3
#   - Unknown flag: exit 1
#   - features.yaml: registered as enabled, test-path present
#   - parse-route.sh: routes PDF to pattern_a when installed + kreuzberg absent
#   - capabilities-probe.sh: includes pattern_a_vector_text in KNOWN_BACKENDS
#
# Live path (opt-in via CLAUDE_E2E_LIVE_PATTERN_A=1 AND pdftotext on PATH):
#   - Generate a test PDF via weasyprint (if available)
#   - --extract the PDF, assert content contains the magic phrase
#   - Assert extracted bytes > 0

set -u

HARNESS="$(cd "$(dirname "$0")/harness" && pwd)"
source "$HARNESS/assertion-lib.sh"

ensure_beta_root
test_banner "28 Parser Pattern A (Vector+Text) Backend (Phase 5.3.d first slice)"

ADAPTER=".dexCore/core/parser/backends/pattern-a-vector-text.sh"

# ─── Structural ──────────────────────────────────────────────────────
assert_file_exists "$ADAPTER" "pattern-a-vector-text.sh present"
if [ -x "$ADAPTER" ]; then pass "pattern-a-vector-text.sh executable"; else fail "not executable"; fi
if bash -n "$ADAPTER" 2>/dev/null; then
  pass "pattern-a-vector-text.sh bash-parses cleanly"
else
  fail "pattern-a-vector-text.sh has syntax errors"
fi

HELP=$(bash "$ADAPTER" --help 2>&1 | head -10)
if echo "$HELP" | grep -qi "Pattern A"; then
  pass "--help emits header"
else
  fail "--help output unexpected"
fi

# ─── --detect JSON shape ────────────────────────────────────────────
DETECT_JSON=$(bash "$ADAPTER" --detect --format json 2>&1)
if echo "$DETECT_JSON" | ruby -rjson -e '
  d = JSON.parse(STDIN.read)
  required = %w[backend binary version status setup_hint hint_type supported compliance]
  missing = required.reject { |k| d.key?(k) }
  abort "missing fields: #{missing.join(",")}" unless missing.empty?
  abort "backend must be pattern_a_vector_text, got #{d["backend"].inspect}" unless d["backend"] == "pattern_a_vector_text"
  abort "supported must include pdf" unless d["supported"].include?("pdf")
  abort "compliance must be ok" unless d["compliance"] == "ok"
' 2>/dev/null; then
  pass "--detect JSON has all required fields + correct identity"
else
  fail "--detect JSON shape invalid"
fi

# ─── Status vocabulary ──────────────────────────────────────────────
STATUS=$(echo "$DETECT_JSON" | ruby -rjson -e 'puts JSON.parse(STDIN.read)["status"]' 2>/dev/null)
case "$STATUS" in
  ready|not_installed|probe_failed|blocked)
    pass "--detect: status '$STATUS' is valid vocabulary"
    ;;
  *)
    fail "--detect: status '$STATUS' not in allowed set"
    ;;
esac

# ─── hint_type field + consistency ──────────────────────────────────
if echo "$DETECT_JSON" | ruby -rjson -e '
  d = JSON.parse(STDIN.read)
  vocab = %w[ok install_backend daemon_unreachable missing_dependency policy_blocked probe_error]
  ht = d["hint_type"]
  abort "hint_type missing" if ht.nil? || ht.to_s.empty?
  abort "hint_type #{ht.inspect} not in vocab" unless vocab.include?(ht)
  # Pattern A has no daemon — daemon_unreachable should never appear
  abort "pattern_a should never emit daemon_unreachable" if ht == "daemon_unreachable"
  # Status↔hint_type consistency
  if d["status"] == "ready" && ht != "ok"
    abort "status=ready but hint_type=#{ht.inspect} (expected ok)"
  end
  if d["status"] == "not_installed" && ht != "install_backend"
    abort "status=not_installed but hint_type=#{ht.inspect} (expected install_backend)"
  end
  if d["status"] == "probe_failed" && ht != "probe_error"
    abort "status=probe_failed but hint_type=#{ht.inspect} (expected probe_error)"
  end
' 2>/dev/null; then
  pass "--detect: hint_type present + in vocabulary + consistent with status"
else
  fail "--detect: hint_type missing/invalid/inconsistent"
fi

# ─── --extract without backend ready → graceful exit 0 ──────────────
# On a box without pdftotext, this would exit 0 with status=not_installed
# in the JSON body. On a box WITH pdftotext on PATH + a real pdf, same
# exit 0 but status=ok. Both paths are graceful.
TMP_MD=$(mktemp -t pa28-XXXXXX).md
echo "fake markdown" > "$TMP_MD"
bash "$ADAPTER" --extract "$TMP_MD" >/dev/null 2>&1
EXTRACT_EXIT=$?
case "$EXTRACT_EXIT" in
  0|4)
    # 0 = graceful (not_installed) or ok output
    # 4 = pdftotext crashed on non-PDF input (honest failure, pattern_a narrow scope)
    pass "--extract (any state): exit 0 (graceful) or 4 (honest non-PDF failure), got $EXTRACT_EXIT"
    ;;
  *)
    fail "--extract: unexpected exit $EXTRACT_EXIT (expected 0 or 4)"
    ;;
esac
rm -f "$TMP_MD"

# ─── --extract on missing file → exit 3 ─────────────────────────────
bash "$ADAPTER" --extract "/tmp/does-not-exist-pa-${RANDOM}${RANDOM}.pdf" >/dev/null 2>&1
MISS_EXIT=$?
if [ "$MISS_EXIT" = "3" ]; then
  pass "--extract missing file: exit 3"
else
  fail "--extract missing: expected 3, got $MISS_EXIT"
fi

# ─── --extract --require without backend → exit 2 (only if not ready) ──
if [ "$STATUS" != "ready" ]; then
  # On a CI clean runner, pdftotext absent → exit 2 under --require
  TMP_PDF=$(mktemp -t pa28-XXXXXX).pdf
  echo "%PDF-1.4 fake" > "$TMP_PDF"
  bash "$ADAPTER" --extract "$TMP_PDF" --require >/dev/null 2>&1
  REQ_EXIT=$?
  if [ "$REQ_EXIT" = "2" ]; then
    pass "--extract --require without backend: exit 2"
  else
    fail "--extract --require without backend: expected 2, got $REQ_EXIT"
  fi
  rm -f "$TMP_PDF"
fi

# ─── Unknown flag → exit 1 ──────────────────────────────────────────
bash "$ADAPTER" --nonsense >/dev/null 2>&1
if [ "$?" = "1" ]; then
  pass "unknown flag: exit 1"
else
  fail "unknown flag: expected 1, got $?"
fi

# ─── features.yaml registration ─────────────────────────────────────
if grep -qE "^\s+- id: parser\.pattern_a_vector_text\b" .dexCore/_cfg/features.yaml; then
  pass "features.yaml: parser.pattern_a_vector_text registered"
else
  fail "features.yaml: parser.pattern_a_vector_text NOT registered"
fi
PA_STATUS=$(grep -A 5 -e "- id: parser\.pattern_a_vector_text" .dexCore/_cfg/features.yaml | grep -m1 "status:" | tr -d ' ')
if echo "$PA_STATUS" | grep -q "^status:enabled"; then
  pass "features.yaml: parser.pattern_a_vector_text status=enabled"
else
  fail "features.yaml: parser.pattern_a_vector_text status='$PA_STATUS'"
fi
PA_BODY=$(awk '/- id: parser\.pattern_a_vector_text/{flag=1; print; next} flag && /^  - id: / {exit} flag {print}' .dexCore/_cfg/features.yaml)
if echo "$PA_BODY" | grep -q "28-parser-pattern-a-backend"; then
  pass "features.yaml: tests[] references test 28"
else
  fail "features.yaml: tests[] missing test 28"
fi

# ─── capabilities-probe.sh KNOWN_BACKENDS ───────────────────────────
if grep -qE '"pattern_a_vector_text:pattern-a-vector-text\.sh"' .dexCore/core/parser/capabilities-probe.sh; then
  pass "capabilities-probe.sh: pattern_a_vector_text in KNOWN_BACKENDS"
else
  fail "capabilities-probe.sh: pattern_a not registered"
fi

# ─── parse-route.sh: PDF routing includes pattern_a check ───────────
if grep -q 'cap_backend_installed pattern_a_vector_text' .dexCore/core/parser/parse-route.sh; then
  pass "parse-route.sh: routes PDF via pattern_a when kreuzberg absent"
else
  fail "parse-route.sh: pattern_a routing decision missing"
fi

# ─── inbox-auto-parse.sh: handles pattern_a_vector_text backend ─────
if grep -qE '^\s+pattern_a_vector_text\)' .dexCore/core/parser/inbox-auto-parse.sh; then
  pass "inbox-auto-parse.sh: pattern_a_vector_text backend branch present"
else
  fail "inbox-auto-parse.sh: pattern_a_vector_text branch missing"
fi

# ─── Live path (opt-in) ─────────────────────────────────────────────
if [ "${CLAUDE_E2E_LIVE_PATTERN_A:-0}" = "1" ] && [ "$STATUS" = "ready" ] && command -v weasyprint >/dev/null 2>&1; then
  echo "  [LIVE] generating real PDF + extracting via pattern_a..."
  LIVE_DIR=$(mktemp -d -t pa28-live-XXXXXX)
  cat > "$LIVE_DIR/doc.html" <<'LIVEHTML'
<html><body><h1>Pattern A Live Test</h1>
<p>Magic phrase: zebra-fortnight-917-AX.</p>
<p>Second paragraph for layout testing.</p></body></html>
LIVEHTML
  weasyprint "$LIVE_DIR/doc.html" "$LIVE_DIR/doc.pdf" 2>/dev/null
  if [ -f "$LIVE_DIR/doc.pdf" ] && [ -s "$LIVE_DIR/doc.pdf" ]; then
    pass "[LIVE] test PDF generated"
    EXT_JSON=$(bash "$ADAPTER" --extract "$LIVE_DIR/doc.pdf" 2>/dev/null)
    EXT_STATUS=$(echo "$EXT_JSON" | ruby -rjson -e 'puts JSON.parse(STDIN.read)["status"]' 2>/dev/null)
    EXT_CONTENT=$(echo "$EXT_JSON" | ruby -rjson -e 'puts JSON.parse(STDIN.read)["content"]' 2>/dev/null)
    EXT_BYTES=$(echo "$EXT_JSON" | ruby -rjson -e 'puts JSON.parse(STDIN.read)["bytes"]' 2>/dev/null)
    if [ "$EXT_STATUS" = "ok" ]; then
      pass "[LIVE] --extract returned status=ok"
    else
      fail "[LIVE] --extract returned status=$EXT_STATUS"
    fi
    if echo "$EXT_CONTENT" | grep -q "zebra-fortnight-917-AX"; then
      pass "[LIVE] extracted content contains the magic phrase"
    else
      fail "[LIVE] magic phrase missing from extracted content"
    fi
    if [ "${EXT_BYTES:-0}" -gt 0 ]; then
      pass "[LIVE] extracted bytes > 0 (${EXT_BYTES})"
    else
      fail "[LIVE] extracted bytes = 0"
    fi
  else
    fail "[LIVE] weasyprint failed to generate test PDF"
  fi
  rm -rf "$LIVE_DIR"
elif [ "${CLAUDE_E2E_LIVE_PATTERN_A:-0}" = "1" ]; then
  echo "  (live path requested but unavailable — pdftotext not ready OR weasyprint absent)"
else
  echo "  (live path skipped — set CLAUDE_E2E_LIVE_PATTERN_A=1 + have pdftotext & weasyprint to run)"
fi

test_summary
