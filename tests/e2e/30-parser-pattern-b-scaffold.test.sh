#!/bin/bash
# DexHub E2E Test 30 — Parser Pattern B Scaffold (Phase 1.1)
#
# Structural tests for the parser.pattern_b_raster_6phase scaffold.
# The real 6-phase raster pipeline is deferred to 1.1 — this test
# verifies the SCAFFOLD CONTRACT:
#   - adapter file exists + executable + bash-parses
#   - --detect returns status=deferred + hint_type=install_backend
#     + the 6 phase names + scaffold:true marker
#   - --extract returns status=deferred without attempting extraction
#   - --extract --require → exit 2 (scaffold refuses to pretend)
#   - features.yaml entry marks status=deferred + references test 30
#   - KNOWN_BACKENDS (capabilities-probe.sh) does NOT yet list pattern_b
#     (we don't want the router to route to a scaffold; listing happens
#     when the real impl ships)
#
# When the 6-phase impl lands in 1.1, this test becomes the scaffold→live
# migration checklist — flip status=deferred→enabled, flip scaffold:true
# to false, wire into KNOWN_BACKENDS, add behavioral assertions.

set -u

HARNESS="$(cd "$(dirname "$0")/harness" && pwd)"
source "$HARNESS/assertion-lib.sh"

ensure_beta_root
test_banner "30 Parser Pattern B Scaffold (Phase 1.1 target)"

ADAPTER=".dexCore/core/parser/backends/pattern-b-raster-6phase.sh"

# ─── Structural ──────────────────────────────────────────────────────
assert_file_exists "$ADAPTER" "pattern-b-raster-6phase.sh scaffold present"
if [ -x "$ADAPTER" ]; then pass "scaffold executable"; else fail "not executable"; fi
if bash -n "$ADAPTER" 2>/dev/null; then
  pass "scaffold bash-parses cleanly"
else
  fail "scaffold has syntax errors"
fi

HELP=$(bash "$ADAPTER" --help 2>&1 | head -10)
if echo "$HELP" | grep -qi "Pattern B"; then
  pass "--help emits header"
else
  fail "--help output unexpected"
fi

# ─── --detect scaffold contract ─────────────────────────────────────
DETECT_JSON=$(bash "$ADAPTER" --detect --format json 2>&1)
if echo "$DETECT_JSON" | ruby -rjson -e '
  d = JSON.parse(STDIN.read)
  # Must emit BACKEND-ADAPTER-PATTERN core fields
  required = %w[backend status setup_hint hint_type supported compliance]
  missing = required.reject { |k| d.key?(k) }
  abort "missing fields: #{missing}" unless missing.empty?
  # Identity
  abort "backend must be pattern_b_raster_6phase" unless d["backend"] == "pattern_b_raster_6phase"
  # Scaffold-specific: status=deferred + scaffold:true + phases array
  abort "status must be deferred (scaffold marker)" unless d["status"] == "deferred"
  abort "hint_type must be install_backend" unless d["hint_type"] == "install_backend"
  abort "scaffold:true marker missing" unless d["scaffold"] == true
  # 6 phases enumerated
  phases = d["phases"]
  abort "phases array must have 6 entries, got #{phases.length if phases.is_a?(Array)}" unless phases.is_a?(Array) && phases.length == 6
  expected_phases = %w[overview cluster_detect hi_res_crops per_cluster_vlm synthesis verify]
  missing_phases = expected_phases - phases
  abort "missing phases: #{missing_phases}" unless missing_phases.empty?
  # Supported formats include pdf + image (1.1 targets hybrid case)
  abort "supported must include pdf" unless d["supported"].include?("pdf")
  abort "supported must include image" unless d["supported"].include?("image")
  # compliance = local_vlm_required (VLM is load-bearing)
  abort "compliance must be local_vlm_required" unless d["compliance"] == "local_vlm_required"
' 2>/dev/null; then
  pass "--detect: scaffold contract complete (status=deferred, hint_type=install_backend, 6 phases, local_vlm_required)"
else
  fail "--detect: scaffold contract malformed"
fi

# ─── --detect text mode ─────────────────────────────────────────────
DETECT_TEXT=$(bash "$ADAPTER" --detect --format text 2>&1)
if echo "$DETECT_TEXT" | grep -qi "SCAFFOLD"; then
  pass "--detect text mode surfaces SCAFFOLD label"
else
  fail "--detect text mode missing SCAFFOLD marker"
fi

# ─── --extract scaffold behavior ────────────────────────────────────
# Any file — scaffold refuses gracefully without touching it
SCRATCH=$(mktemp -d -t dex-patternb-XXXXXX)
echo "test" > "$SCRATCH/any.pdf"
EXTRACT_JSON=$(bash "$ADAPTER" --extract "$SCRATCH/any.pdf" 2>&1)
if echo "$EXTRACT_JSON" | ruby -rjson -e '
  d = JSON.parse(STDIN.read)
  abort "status must be deferred" unless d["status"] == "deferred"
  abort "content must be nil (scaffold)" unless d["content"].nil?
  abort "bytes must be 0 (scaffold)" unless d["bytes"] == 0
  abort "error must mention scaffold" unless d["error"].to_s.downcase.include?("scaffold")
  abort "hint must name pattern_a or ollama_vlm alternatives" unless d["hint"].to_s.include?("pattern_a") || d["hint"].to_s.include?("ollama_vlm")
' 2>/dev/null; then
  pass "--extract: scaffold refuses gracefully (status=deferred, content=nil, names alternatives)"
else
  fail "--extract: scaffold contract broken"
fi

# --extract --require → exit 2 (scaffold never pretends to be ready)
bash "$ADAPTER" --extract "$SCRATCH/any.pdf" --require >/dev/null 2>&1
REQ_EXIT=$?
if [ "$REQ_EXIT" = "2" ]; then
  pass "--extract --require: exit 2 (scaffold refuses under --require)"
else
  fail "--extract --require: expected 2, got $REQ_EXIT"
fi

# --extract on missing file → exit 3 (same as other adapters)
bash "$ADAPTER" --extract "/tmp/no-such-file-pb-${RANDOM}.pdf" >/dev/null 2>&1
if [ "$?" = "3" ]; then
  pass "--extract missing file: exit 3"
else
  fail "--extract missing: expected 3, got $?"
fi

# Bad flag → exit 1
bash "$ADAPTER" --nonsense >/dev/null 2>&1
if [ "$?" = "1" ]; then
  pass "unknown flag: exit 1"
else
  fail "unknown flag: expected 1, got $?"
fi

rm -rf "$SCRATCH"

# ─── features.yaml registration ─────────────────────────────────────
if grep -qE "^\s+- id: parser\.pattern_b_raster_6phase\b" .dexCore/_cfg/features.yaml; then
  pass "features.yaml: parser.pattern_b_raster_6phase registered"
else
  fail "features.yaml: parser.pattern_b_raster_6phase NOT registered"
fi
PB_STATUS=$(grep -A 5 -e "- id: parser\.pattern_b_raster_6phase" .dexCore/_cfg/features.yaml | grep -m1 "status:" | tr -d ' ')
if echo "$PB_STATUS" | grep -q "^status:deferred"; then
  pass "features.yaml: pattern_b status=deferred (correct for scaffold)"
else
  fail "features.yaml: pattern_b status='$PB_STATUS' (expected deferred)"
fi
PB_BODY=$(awk '/- id: parser\.pattern_b_raster_6phase/{flag=1; print; next} flag && /^  - id: / {exit} flag {print}' .dexCore/_cfg/features.yaml)
if echo "$PB_BODY" | grep -q "30-parser-pattern-b-scaffold"; then
  pass "features.yaml: tests[] references test 30"
else
  fail "features.yaml: tests[] missing test 30"
fi

# ─── capabilities-probe should NOT yet include pattern_b ───────────
# We don't want routing attempts to a scaffold. KNOWN_BACKENDS stays
# pattern_a_vector_text + kreuzberg + ollama_vlm until the real 1.1
# impl is ready. Flipping this list is the tripwire for "scaffold graduated".
if grep -qE '"pattern_b_raster_6phase:' .dexCore/core/parser/capabilities-probe.sh; then
  fail "capabilities-probe.sh: pattern_b in KNOWN_BACKENDS — scaffold promoted prematurely"
else
  pass "capabilities-probe.sh: pattern_b NOT in KNOWN_BACKENDS (correct for scaffold stage)"
fi

test_summary
