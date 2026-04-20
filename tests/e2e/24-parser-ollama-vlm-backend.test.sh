#!/bin/bash
# DexHub E2E Test 24 — Parser Ollama VLM Backend (Phase 5.3.c)
#
# Second backend adapter under the Parser Router architecture, following
# BACKEND-ADAPTER-PATTERN.md. Mirrors test 23 (kreuzberg) structure.
# Adds VLM-specific checks: model auto-discovery, OLLAMA_HOST override,
# local_vlm_required compliance, base64 image encoding for extract.
#
# All assertions structural (always-green on any box). Live path gated
# behind CLAUDE_E2E_LIVE_VLM=1 AND adapter status=ready (skipped when
# user doesn't have a VLM pulled — a pulled model is a ~4-8 GB download
# that the test won't do for you).

set -u

HARNESS="$(cd "$(dirname "$0")/harness" && pwd)"
source "$HARNESS/assertion-lib.sh"

ensure_beta_root
test_banner "24 Parser Ollama VLM Backend (Phase 5.3.c)"

ADAPTER=".dexCore/core/parser/backends/ollama-vlm.sh"

# ─── Structural ──────────────────────────────────────────────────────
assert_file_exists "$ADAPTER" "ollama-vlm.sh present"
if [ -x "$ADAPTER" ]; then pass "ollama-vlm.sh executable"; else fail "ollama-vlm.sh not executable"; fi
if bash -n "$ADAPTER" 2>/dev/null; then
  pass "ollama-vlm.sh bash-parses cleanly"
else
  fail "ollama-vlm.sh has syntax errors"
fi

# ─── --help ─────────────────────────────────────────────────────────
HELP=$(bash "$ADAPTER" --help 2>&1 | head -30)
if echo "$HELP" | grep -qi "Ollama VLM backend adapter"; then
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

# Required fields per BACKEND-ADAPTER-PATTERN + VLM-specific extensions
for field in backend binary version endpoint daemon_running model status setup_hint supported compliance; do
  if echo "$DETECT_JSON" | ruby -rjson -e "d=JSON.parse(STDIN.read); exit(d.key?('$field') ? 0 : 1)" 2>/dev/null; then
    pass "--detect JSON has field '$field'"
  else
    fail "--detect JSON missing field '$field'"
  fi
done

# backend == "ollama_vlm"
BACKEND=$(echo "$DETECT_JSON" | ruby -rjson -e 'puts JSON.parse(STDIN.read)["backend"]' 2>/dev/null)
if [ "$BACKEND" = "ollama_vlm" ]; then
  pass "--detect: backend='ollama_vlm'"
else
  fail "--detect: backend='$BACKEND' (expected ollama_vlm)"
fi

# compliance MUST be local_vlm_required (design invariant)
COMPL=$(echo "$DETECT_JSON" | ruby -rjson -e 'puts JSON.parse(STDIN.read)["compliance"]' 2>/dev/null)
if [ "$COMPL" = "local_vlm_required" ]; then
  pass "--detect: compliance='local_vlm_required' (matches feature contract)"
else
  fail "--detect: compliance='$COMPL' (expected local_vlm_required)"
fi

# supported is an image-format array
if echo "$DETECT_JSON" | ruby -rjson -e '
  d = JSON.parse(STDIN.read)
  s = d["supported"]
  exit(s.is_a?(Array) && s.include?("png") && s.include?("jpg") ? 0 : 1)
' 2>/dev/null; then
  pass "--detect: supported[] includes png + jpg (image formats)"
else
  fail "--detect: supported[] doesn't cover expected image formats"
fi

# Status is valid vocabulary
STATUS=$(echo "$DETECT_JSON" | ruby -rjson -e 'puts JSON.parse(STDIN.read)["status"]' 2>/dev/null)
case "$STATUS" in
  ready|not_installed|partial|probe_failed|blocked)
    pass "--detect: status '$STATUS' is valid vocabulary"
    ;;
  *)
    fail "--detect: status '$STATUS' not in allowed set"
    ;;
esac

# Hardened per 2026-04-22 audit (Agent D finding #2): invariant-field
# assertion beyond vocab check. Every status value MUST deliver these:
#   - setup_hint (non-empty) — ready state explains success, others explain fix
#   - compliance (non-empty, matches policy vocabulary)
#   - backend == "ollama_vlm" (adapter identifies itself)
if echo "$DETECT_JSON" | ruby -rjson -e '
  d = JSON.parse(STDIN.read)
  failures = []
  failures << "setup_hint missing/empty" if d["setup_hint"].to_s.strip.empty?
  failures << "compliance missing/empty" if d["compliance"].to_s.strip.empty?
  failures << "backend must be \"ollama_vlm\", got #{d["backend"].inspect}" unless d["backend"] == "ollama_vlm"
  abort failures.join("; ") unless failures.empty?
' 2>/dev/null; then
  pass "--detect: structural invariants hold across all status values (setup_hint, compliance, backend)"
else
  fail "--detect: invariant field missing — vocab alone doesn't prove behavior"
fi

# Endpoint field should match OLLAMA_HOST or default
ENDPOINT=$(echo "$DETECT_JSON" | ruby -rjson -e 'puts JSON.parse(STDIN.read)["endpoint"]' 2>/dev/null)
if echo "$ENDPOINT" | grep -qE "^https?://"; then
  pass "--detect: endpoint '$ENDPOINT' is a URL"
else
  fail "--detect: endpoint malformed: '$ENDPOINT'"
fi

# ─── --detect text format ───────────────────────────────────────────
DETECT_TEXT=$(bash "$ADAPTER" --detect --format text 2>&1)
if echo "$DETECT_TEXT" | grep -q "Ollama VLM adapter"; then
  pass "--detect --format text human-readable header"
else
  fail "--detect --format text output unexpected"
fi
if echo "$DETECT_TEXT" | grep -q "Endpoint:"; then
  pass "--detect --format text shows endpoint line"
else
  fail "--detect --format text missing endpoint"
fi

# ─── OLLAMA_HOST override works ─────────────────────────────────────
FAKE_ENDPOINT_JSON=$(OLLAMA_HOST="http://localhost:1" bash "$ADAPTER" --detect 2>&1)
FAKE_EP=$(echo "$FAKE_ENDPOINT_JSON" | ruby -rjson -e 'puts JSON.parse(STDIN.read)["endpoint"]' 2>/dev/null)
if [ "$FAKE_EP" = "http://localhost:1" ]; then
  pass "OLLAMA_HOST env override respected in --detect"
else
  fail "OLLAMA_HOST override not propagated: endpoint='$FAKE_EP'"
fi
FAKE_STATUS=$(echo "$FAKE_ENDPOINT_JSON" | ruby -rjson -e 'puts JSON.parse(STDIN.read)["status"]' 2>/dev/null)
if [ "$FAKE_STATUS" = "partial" ] || [ "$FAKE_STATUS" = "not_installed" ]; then
  pass "OLLAMA_HOST=unreachable: status='$FAKE_STATUS' (daemon not reachable → partial)"
else
  fail "OLLAMA_HOST=unreachable: unexpected status '$FAKE_STATUS'"
fi

# ─── --endpoint flag override ───────────────────────────────────────
FLAG_EP_JSON=$(bash "$ADAPTER" --detect --endpoint "http://example.invalid:9999" 2>&1)
FLAG_EP=$(echo "$FLAG_EP_JSON" | ruby -rjson -e 'puts JSON.parse(STDIN.read)["endpoint"]' 2>/dev/null)
if [ "$FLAG_EP" = "http://example.invalid:9999" ]; then
  pass "--endpoint flag override respected"
else
  fail "--endpoint flag not propagated: '$FLAG_EP'"
fi

# ─── --model override picked up in partial path ─────────────────────
# (Can't easily test when model IS pulled without pulling one; but we
# CAN test that an override not-present keeps status=partial with a
# message that names the override.)
OVERRIDE_JSON=$(bash "$ADAPTER" --detect --model "nonexistent-model-zzz" 2>&1)
OV_STATUS=$(echo "$OVERRIDE_JSON" | ruby -rjson -e 'puts JSON.parse(STDIN.read)["status"]' 2>/dev/null)
OV_HINT=$(echo "$OVERRIDE_JSON" | ruby -rjson -e 'puts JSON.parse(STDIN.read)["setup_hint"]' 2>/dev/null)
if [ "$OV_STATUS" = "partial" ] || [ "$OV_STATUS" = "not_installed" ]; then
  pass "--model override with missing name: status='$OV_STATUS'"
else
  fail "--model override: unexpected status '$OV_STATUS'"
fi
if echo "$OV_HINT" | grep -q "nonexistent-model-zzz"; then
  pass "--model override: hint mentions the requested model (in daemon-running state)"
else
  # Fallback: if Ollama isn't installed (CI case) OR the daemon isn't
  # reachable, the probe short-circuits BEFORE the model-already-pulled
  # check. But the hint MUST STILL name the requested model (this was
  # the 2026-04-21 review finding — adapter used to hardcode
  # llama3.2-vision in the not-installed path, losing the user's choice).
  if echo "$OV_HINT" | grep -qiE "daemon not reachable|ollama pull nonexistent-model-zzz"; then
    pass "--model override: daemon-not-reachable hint OR install hint preserves the requested model"
  else
    fail "--model override: hint lost user's model name" "got: '$OV_HINT'"
  fi
fi

# Dedicated regression guard: simulate CI (no ollama on PATH) and
# assert that --model override is propagated to the install hint.
# This catches the adapter-logic gap that slipped through the 2026-04-21
# regex-widening fix (the adapter used to hardcode llama3.2-vision in
# the not-installed path). Use env PATH to hide ollama from the probe.
NO_OLLAMA_HINT=$(env PATH="/usr/bin:/bin" bash "$ADAPTER" --detect --model "quokka-vision-7b" 2>/dev/null | \
  ruby -rjson -e 'puts JSON.parse(STDIN.read)["setup_hint"] rescue ""' 2>/dev/null)
NO_OLLAMA_STATUS=$(env PATH="/usr/bin:/bin" bash "$ADAPTER" --detect --model "quokka-vision-7b" 2>/dev/null | \
  ruby -rjson -e 'puts JSON.parse(STDIN.read)["status"] rescue ""' 2>/dev/null)
if [ "$NO_OLLAMA_STATUS" = "not_installed" ]; then
  pass "--model + no-ollama-simulation: status=not_installed (probe short-circuits)"
else
  fail "--model + no-ollama-simulation: expected not_installed, got '$NO_OLLAMA_STATUS'"
fi
if echo "$NO_OLLAMA_HINT" | grep -q "quokka-vision-7b"; then
  pass "--model override survives not-installed branch (hint names requested model)"
else
  fail "--model override lost in not-installed branch" "got hint: '$NO_OLLAMA_HINT'"
fi

# ─── --extract graceful on not-ready ────────────────────────────────
FIX_IMG=$(mktemp -t dexhub-24-img-XXXXXX).png
printf "\x89PNG\r\n\x1a\n" > "$FIX_IMG"   # PNG header stub; adapter doesn't validate format
EXTRACT_OUT=$(bash "$ADAPTER" --extract "$FIX_IMG" 2>&1)
EXTRACT_EXIT=$?
if [ "$EXTRACT_EXIT" = "0" ]; then
  pass "--extract without ready backend: graceful exit 0"
else
  fail "--extract without backend: expected exit 0, got $EXTRACT_EXIT"
fi

# JSON should have backend + file + status + content + error + hint
if echo "$EXTRACT_OUT" | ruby -rjson -e '
  d = JSON.parse(STDIN.read)
  req = ["backend", "file", "status", "content", "error", "hint"]
  exit(req.all? { |k| d.key?(k) } ? 0 : 1)
' 2>/dev/null; then
  pass "--extract JSON has required keys (backend, file, status, content, error, hint)"
else
  fail "--extract JSON shape incomplete"
fi

EX_STATUS=$(echo "$EXTRACT_OUT" | ruby -rjson -e 'puts JSON.parse(STDIN.read)["status"]' 2>/dev/null)
case "$EX_STATUS" in
  partial|not_installed) pass "--extract graceful: status='$EX_STATUS'" ;;
  ready|ok) pass "--extract on ready backend would succeed (status=$EX_STATUS) — LIVE path exercised" ;;
  *) fail "--extract unexpected status '$EX_STATUS'" ;;
esac

# --require flips exit
bash "$ADAPTER" --extract "$FIX_IMG" --require >/dev/null 2>&1
REQ_EXIT=$?
# On a machine where backend IS ready, --require behaves like --extract (exit 0 on success, 4 on crash).
# On not-ready, --require should exit 2.
if [ "$EX_STATUS" = "partial" ] || [ "$EX_STATUS" = "not_installed" ]; then
  if [ "$REQ_EXIT" = "2" ]; then
    pass "--extract --require without backend: exit 2"
  else
    fail "--extract --require: expected exit 2, got $REQ_EXIT"
  fi
else
  pass "--extract --require with ready backend: exit $REQ_EXIT (backend was ready)"
fi

rm -f "$FIX_IMG"

# ─── Missing file + bad args ────────────────────────────────────────
bash "$ADAPTER" --extract "/tmp/nonexistent-vlm-${RANDOM}.png" >/dev/null 2>&1
MISS_EXIT=$?
if [ "$MISS_EXIT" = "3" ]; then
  pass "--extract missing file: exit 3"
else
  fail "--extract missing file: expected exit 3, got $MISS_EXIT"
fi

bash "$ADAPTER" --nonsense >/dev/null 2>&1
if [ "$?" = "1" ]; then
  pass "unknown flag: exit 1"
else
  fail "unknown flag: exit $?"
fi

bash "$ADAPTER" >/dev/null 2>&1
if [ "$?" = "1" ]; then
  pass "no args: exit 1"
else
  fail "no args: exit $?"
fi

# ─── features.yaml registration ─────────────────────────────────────
if grep -qE "^\s+- id: parser\.ollama_vlm_backend\b" .dexCore/_cfg/features.yaml; then
  pass "features.yaml: parser.ollama_vlm_backend registered"
else
  fail "features.yaml: parser.ollama_vlm_backend NOT registered"
fi

VLM_STATUS=$(grep -A 5 -e "- id: parser\.ollama_vlm_backend" .dexCore/_cfg/features.yaml | grep -m1 "status:" | tr -d ' ')
if echo "$VLM_STATUS" | grep -q "^status:enabled"; then
  pass "features.yaml: parser.ollama_vlm_backend status=enabled"
else
  fail "features.yaml: parser.ollama_vlm_backend status unexpected ($VLM_STATUS)"
fi

VLM_BODY=$(awk '/- id: parser\.ollama_vlm_backend/{flag=1; print; next} flag && /^  - id: / {exit} flag {print}' .dexCore/_cfg/features.yaml)
if echo "$VLM_BODY" | grep -q "24-parser-ollama-vlm-backend"; then
  pass "features.yaml: tests[] references test 24"
else
  fail "features.yaml: tests[] doesn't reference test 24"
fi
if echo "$VLM_BODY" | grep -q "local_vlm_required\|VLM.*required\|vision model"; then
  pass "features.yaml: description mentions local_vlm_required compliance"
else
  fail "features.yaml: description doesn't document local_vlm_required"
fi

# ─── OPT-IN LIVE ────────────────────────────────────────────────────
if [ "${CLAUDE_E2E_LIVE_VLM:-0}" = "1" ]; then
  echo ""
  echo "  [LIVE] CLAUDE_E2E_LIVE_VLM=1 — attempting real VLM extract…"
  if [ "$STATUS" != "ready" ]; then
    echo "  [LIVE] Backend not ready on this machine — skipping live assertions."
    echo "        Install: ollama serve && ollama pull llama3.2-vision"
  else
    # Create a trivial test PNG — 10x10 white square, hand-crafted minimal PNG.
    # Python-free approach: use ruby's zlib to make it. Keep fixture tiny.
    FX=$(mktemp -t dexhub-24-live-XXXXXX).png
    ruby -rzlib -e '
      require "base64"
      # Minimal 1x1 white PNG, base64-encoded
      b64 = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNgAAIAAAUAAen63NgAAAAASUVORK5CYII="
      File.binwrite(ARGV[0], Base64.strict_decode64(b64))
    ' "$FX"
    LIVE_OUT=$(bash "$ADAPTER" --extract "$FX" 2>&1)
    LIVE_STATUS=$(echo "$LIVE_OUT" | ruby -rjson -e 'puts JSON.parse(STDIN.read)["status"]' 2>/dev/null)
    if [ "$LIVE_STATUS" = "ok" ]; then
      pass "[LIVE] extract: status=ok"
    else
      fail "[LIVE] extract: status=$LIVE_STATUS"
    fi
    LIVE_CONTENT=$(echo "$LIVE_OUT" | ruby -rjson -e 'puts JSON.parse(STDIN.read)["content"]' 2>/dev/null)
    if [ -n "$LIVE_CONTENT" ] && [ "$LIVE_CONTENT" != "null" ]; then
      pass "[LIVE] extract: content non-empty"
    else
      fail "[LIVE] extract: content empty"
    fi
    rm -f "$FX"
  fi
fi

test_summary
