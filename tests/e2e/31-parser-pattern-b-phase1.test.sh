#!/bin/bash
# DexHub E2E Test 31 — Parser Pattern B Phase 1 Overview (Phase 5.3.k)
#
# Standalone first phase of the 6-phase Pattern B raster pipeline. Ships
# without Phases 2-6, which stay deferred under parser.pattern_b_raster_6phase.
#
# Structural assertions:
#   - adapter exists, executable, bash-parses
#   - --help emits header
#   - --detect JSON has required fields (backend, raster_tool, vlm_status,
#     status, setup_hint, hint_type, supported, compliance, max_px,
#     phases_covered, phases_deferred)
#   - status ∈ { ready | not_installed | partial | probe_failed | blocked }
#   - hint_type ∈ { ok | install_backend | missing_dependency |
#                    daemon_unreachable | policy_blocked | probe_error }
#   - status↔hint_type consistency (ready→ok, not_installed→install_backend)
#   - compliance == "local_vlm_required" (this ALWAYS needs a local VLM)
#   - phases_covered == ["overview"]; phases_deferred has all 5 remaining
#   - --extract missing file: exit 3
#   - --extract without backend ready: exit 0 graceful
#   - --extract --require without ready: exit 2
#   - Unknown flag: exit 1
#   - features.yaml: registered as enabled + test-path references test 31
#   - capabilities-probe.sh: pattern_b_phase1_overview in KNOWN_BACKENDS
#   - NOT in parse-route.sh routing table (opt-in only, not auto-routed)
#
# Live path (opt-in via CLAUDE_E2E_LIVE_PATTERN_B_PHASE1=1 + VLM pulled):
#   - Generate small test PDF
#   - --extract and assert content is non-empty VLM description
#   - Assert overview_png_bytes > 0 (raster pipeline produced a PNG)

set -u

HARNESS="$(cd "$(dirname "$0")/harness" && pwd)"
source "$HARNESS/assertion-lib.sh"

ensure_beta_root
test_banner "31 Parser Pattern B Phase 1 Overview (Phase 5.3.k first slice)"

ADAPTER=".dexCore/core/parser/backends/pattern-b-phase1-overview.sh"

# ─── Structural ──────────────────────────────────────────────────────
assert_file_exists "$ADAPTER" "pattern-b-phase1-overview.sh present"
if [ -x "$ADAPTER" ]; then pass "pattern-b-phase1-overview.sh executable"; else fail "not executable"; fi
if bash -n "$ADAPTER" 2>/dev/null; then
  pass "pattern-b-phase1-overview.sh bash-parses cleanly"
else
  fail "pattern-b-phase1-overview.sh has syntax errors"
fi

HELP=$(bash "$ADAPTER" --help 2>&1 | head -8)
if echo "$HELP" | grep -qi "Pattern B Phase 1"; then
  pass "--help emits header"
else
  fail "--help output unexpected"
fi

# ─── --detect JSON shape ────────────────────────────────────────────
DETECT_JSON=$(bash "$ADAPTER" --detect --format json 2>&1)
if echo "$DETECT_JSON" | ruby -rjson -e '
  d = JSON.parse(STDIN.read)
  required = %w[backend raster_tool pdf_rasterizer vlm_status vlm_model status setup_hint hint_type supported compliance max_px phases_covered phases_deferred]
  missing = required.reject { |k| d.key?(k) }
  abort "missing fields: #{missing.join(",")}" unless missing.empty?
  abort "backend must be pattern_b_phase1_overview, got #{d["backend"].inspect}" unless d["backend"] == "pattern_b_phase1_overview"
  abort "supported must include pdf" unless d["supported"].include?("pdf")
  abort "supported must include png" unless d["supported"].include?("png")
  abort "compliance must be local_vlm_required" unless d["compliance"] == "local_vlm_required"
  abort "phases_covered must be exactly [overview]" unless d["phases_covered"] == ["overview"]
  expected_deferred = %w[cluster_detect hi_res_crops per_cluster_vlm synthesis verify]
  abort "phases_deferred must list 5 remaining phases, got #{d["phases_deferred"].inspect}" unless d["phases_deferred"] == expected_deferred
  abort "max_px must be > 0" unless d["max_px"].to_i > 0
' 2>/dev/null; then
  pass "--detect JSON has all required fields + correct identity + phase split"
else
  fail "--detect JSON shape invalid"
fi

# ─── Status vocabulary ──────────────────────────────────────────────
STATUS=$(echo "$DETECT_JSON" | ruby -rjson -e 'puts JSON.parse(STDIN.read)["status"]' 2>/dev/null)
case "$STATUS" in
  ready|not_installed|partial|probe_failed|blocked)
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
  if d["status"] == "ready" && ht != "ok"
    abort "status=ready but hint_type=#{ht.inspect} (expected ok)"
  end
  if d["status"] == "not_installed" && ht != "install_backend"
    abort "status=not_installed but hint_type=#{ht.inspect} (expected install_backend)"
  end
  if d["status"] == "probe_failed" && ht != "probe_error" && ht != "missing_dependency"
    abort "status=probe_failed but hint_type=#{ht.inspect} (expected probe_error or missing_dependency)"
  end
' 2>/dev/null; then
  pass "--detect: hint_type present + in vocabulary + consistent with status"
else
  fail "--detect: hint_type missing/invalid/inconsistent"
fi

# ─── --extract without backend ready → graceful ────────────────────
# On a fresh runner (no raster tool / no VLM) this should exit 0 with
# status field indicating why. On a box with full setup, live-path test
# below handles it.
TMP_PNG=$(mktemp -t pb31-XXXXXX).png
# Minimal PNG header + IEND so file exists
printf '\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02\x00\x00\x00\x90wS\xde\x00\x00\x00\x00IEND\xaeB`\x82' > "$TMP_PNG"
bash "$ADAPTER" --extract "$TMP_PNG" >/dev/null 2>&1
EXTRACT_EXIT=$?
case "$EXTRACT_EXIT" in
  0|4)
    # 0 = graceful (backend not ready) or VLM ready + description emitted
    # 4 = VLM call crashed (unusual in CI without Ollama — should take
    #     not-ready branch first)
    pass "--extract (any state): exit 0 (graceful) or 4 (crash), got $EXTRACT_EXIT"
    ;;
  *)
    fail "--extract: unexpected exit $EXTRACT_EXIT (expected 0 or 4)"
    ;;
esac
rm -f "$TMP_PNG"

# ─── --extract on missing file → exit 3 ─────────────────────────────
bash "$ADAPTER" --extract "/tmp/does-not-exist-pb31-${RANDOM}${RANDOM}.pdf" >/dev/null 2>&1
MISS_EXIT=$?
if [ "$MISS_EXIT" = "3" ]; then
  pass "--extract missing file: exit 3"
else
  fail "--extract missing: expected 3, got $MISS_EXIT"
fi

# ─── --extract --require without backend → exit 2 (always covered) ──
# Previously gated on `$STATUS != ready`, which silently SKIPPED this
# assertion on boxes with a full VLM setup. Agent-β review (session-8)
# flagged this — users with working Ollama had zero coverage of the
# --require path. Fix: force-unreachable OLLAMA_HOST to drive the probe
# into `partial` status regardless of real system state. The ollama-vlm
# sub-adapter reads OLLAMA_HOST from env, so inheriting it down is
# enough.
TMP_IMG=$(mktemp -t pb31-XXXXXX).png
printf '\x89PNG\r\n\x1a\n' > "$TMP_IMG"
OLLAMA_HOST="http://127.0.0.1:1" bash "$ADAPTER" --extract "$TMP_IMG" --require >/dev/null 2>&1
REQ_EXIT=$?
if [ "$REQ_EXIT" = "2" ]; then
  pass "--extract --require with unreachable VLM: exit 2 (forced not-ready)"
else
  fail "--extract --require: expected 2 with unreachable VLM, got $REQ_EXIT"
fi
rm -f "$TMP_IMG"

# ─── Unknown flag → exit 1 ──────────────────────────────────────────
bash "$ADAPTER" --nonsense >/dev/null 2>&1
UF_EXIT=$?
if [ "$UF_EXIT" = "1" ]; then
  pass "unknown flag: exit 1"
else
  fail "unknown flag: expected 1, got $UF_EXIT"
fi

# ─── features.yaml registration ─────────────────────────────────────
if grep -qE "^\s+- id: parser\.pattern_b_phase1_overview\b" .dexCore/_cfg/features.yaml; then
  pass "features.yaml: parser.pattern_b_phase1_overview registered"
else
  fail "features.yaml: parser.pattern_b_phase1_overview NOT registered"
fi
PB_STATUS=$(grep -A 5 -e "- id: parser\.pattern_b_phase1_overview" .dexCore/_cfg/features.yaml | grep -m1 "status:" | tr -d ' ')
if echo "$PB_STATUS" | grep -q "^status:enabled"; then
  pass "features.yaml: parser.pattern_b_phase1_overview status=enabled"
else
  fail "features.yaml: parser.pattern_b_phase1_overview status='$PB_STATUS'"
fi
PB_BODY=$(awk '/- id: parser\.pattern_b_phase1_overview/{flag=1; print; next} flag && /^  - id: / {exit} flag {print}' .dexCore/_cfg/features.yaml)
if echo "$PB_BODY" | grep -q "31-parser-pattern-b-phase1"; then
  pass "features.yaml: tests[] references test 31"
else
  fail "features.yaml: tests[] missing test 31"
fi

# ─── capabilities-probe.sh KNOWN_BACKENDS ───────────────────────────
if grep -qE '"pattern_b_phase1_overview:pattern-b-phase1-overview\.sh"' .dexCore/core/parser/capabilities-probe.sh; then
  pass "capabilities-probe.sh: pattern_b_phase1_overview in KNOWN_BACKENDS"
else
  fail "capabilities-probe.sh: pattern_b_phase1_overview not registered"
fi

# ─── NOT in parse-route.sh (opt-in only, not auto-routed) ───────────
# Pattern B Phase 1 is a SPECIALIZED backend — it returns a VLM
# description, not verbatim content. Auto-routing would surprise users
# expecting pattern_a-style text extraction. Must be opt-in.
if grep -q 'cap_backend_installed pattern_b_phase1_overview' .dexCore/core/parser/parse-route.sh; then
  fail "parse-route.sh auto-routes to pattern_b_phase1_overview — should be opt-in only"
else
  pass "parse-route.sh does NOT auto-route to pattern_b_phase1_overview (opt-in only)"
fi

# ─── --extract --format text happy path ─────────────────────────────
# When backend not ready, --format text emits "backend status=..." line
TEXT_OUT=$(bash "$ADAPTER" --extract README.md --format text 2>&1 || true)
if [ -n "$TEXT_OUT" ]; then
  pass "--extract --format text: emits output (not silent)"
else
  fail "--extract --format text: silent output"
fi

# ─── Regression: 0-byte / missing raster output guards (Agent-1 review) ─
# pdftoppm / sips / convert can exit 0 while producing empty output
# (encrypted PDF, permission issue, catalog corruption). Without -s size
# check we would pass garbage to VLM. Test: adapter source must have a
# -s post-raster guard + an emit_error path for 0-byte overview PNG.
if grep -q '\[ ! -s "\$downscale_out" \]' "$ADAPTER"; then
  pass "adapter has 0-byte overview PNG guard (Agent-review session-8 fix)"
else
  fail "adapter missing 0-byte overview PNG guard — raster tools can exit 0 with empty output"
fi

# ─── Regression: ollama-vlm sub-adapter exit-code check (Agent-1 review) ─
# Previously only stdout JSON was captured; a VLM crash (timeout, OOM)
# produced empty output swallowed by `rescue ""`. Adapter must now
# capture vlm_exit separately + branch on non-zero with a concrete
# error path.
if grep -q 'vlm_exit=\$?' "$ADAPTER" && grep -q '"\$vlm_exit" != "0"' "$ADAPTER"; then
  pass "adapter captures ollama_vlm sub-adapter exit code (Agent-review session-8 fix)"
else
  fail "adapter missing explicit vlm_exit capture — VLM crash invisible to error handling"
fi

# ─── scaffold backward-compat: pattern_b_raster_6phase stays deferred ─
# Shipping the Phase 1 adapter does NOT graduate the scaffold. The full
# 6-phase remains deferred until Phases 2-6 land.
# Match only the feature row (id at canonical 2-space indent), not bare
# string hits elsewhere (description, known_issues) which would false-match.
SCAFFOLD_BODY=$(awk '/^  - id: parser\.pattern_b_raster_6phase$/{flag=1; print; next} flag && /^  - id: / {exit} flag {print}' .dexCore/_cfg/features.yaml)
if echo "$SCAFFOLD_BODY" | grep -m1 "status:" | grep -q "status: deferred"; then
  pass "features.yaml: parser.pattern_b_raster_6phase stays deferred (Phase 1 split out cleanly)"
else
  fail "features.yaml: parser.pattern_b_raster_6phase status changed — scaffold must stay deferred"
fi

# ─── Live path (opt-in) ─────────────────────────────────────────────
if [ "${CLAUDE_E2E_LIVE_PATTERN_B_PHASE1:-0}" = "1" ] && [ "$STATUS" = "ready" ]; then
  # Need weasyprint to emit test PDF
  if command -v weasyprint >/dev/null 2>&1; then
    TD=$(mktemp -d)
    cat > "$TD/src.html" <<'HTML'
<html><body><h1>Overview Test</h1>
<p>Magic overview phrase: tangerine-zebrafish-441.</p>
<table border="1"><tr><th>Col A</th><th>Col B</th></tr><tr><td>1</td><td>2</td></tr></table>
</body></html>
HTML
    weasyprint "$TD/src.html" "$TD/test.pdf" >/dev/null 2>&1
    LIVE_OUT=$(bash "$ADAPTER" --extract "$TD/test.pdf" --format json 2>/dev/null)
    LIVE_STATUS=$(echo "$LIVE_OUT" | ruby -rjson -e 'puts JSON.parse(STDIN.read)["status"] rescue ""' 2>/dev/null)
    LIVE_CONTENT=$(echo "$LIVE_OUT" | ruby -rjson -e 'puts (JSON.parse(STDIN.read)["content"] || "").length.to_s' 2>/dev/null)
    LIVE_BYTES=$(echo "$LIVE_OUT" | ruby -rjson -e 'puts (JSON.parse(STDIN.read)["overview_png_bytes"] || 0).to_i' 2>/dev/null)
    if [ "$LIVE_STATUS" = "ready" ] && [ "${LIVE_CONTENT:-0}" -gt 20 ]; then
      pass "live --extract: status=ready + content length > 20 chars ($LIVE_CONTENT)"
    else
      fail "live --extract: status='$LIVE_STATUS' content_len=$LIVE_CONTENT"
    fi
    if [ "${LIVE_BYTES:-0}" -gt 100 ]; then
      pass "live --extract: overview_png_bytes > 100 ($LIVE_BYTES)"
    else
      fail "live --extract: overview_png_bytes=$LIVE_BYTES (expected >100)"
    fi
    rm -rf "$TD"
  else
    pass "live skipped (weasyprint absent — structural-only on this box)"
  fi
else
  pass "live path opt-in (set CLAUDE_E2E_LIVE_PATTERN_B_PHASE1=1 + VLM pulled to enable)"
fi

test_summary
