#!/bin/bash
# DexHub E2E Test 20 — Parser Router (Phase 5.3.a)
#
# Proves parser.router:
#   - detect-mime.sh + parse-route.sh present, executable, parseable
#   - detect-mime classifies files by extension into the stable type
#     vocabulary (text, pdf, office, image, code, data, archive, email,
#     unknown) and reports size_bytes
#   - parse-route.sh emits the stable JSON shape for every outcome:
#     {file, type, size_bytes, backend, reason, status, policy, hint}
#   - Routing decisions are correct for the min-viable tree:
#       text/code/data/email  → backend=native (always works)
#       pdf + no kreuzberg    → backend=native OR backend=none (pdftotext
#                                fallback if available, else missing)
#       office + no kreuzberg → backend=none, status=backend_missing
#       image + no ollama_vlm → backend=none, status=backend_missing
#       unknown ext           → backend=none, status=unsupported
#       missing file          → backend=none, status=unsupported
#       large pdf (>oversize) → backend=defer, status=deferred
#   - capabilities.yaml.example exists + ships in-repo (template)
#   - features.yaml has parser.router registered as a real entry
#     with status=enabled (flipped from deferred)
#
# No network, no live model calls — all structural. Always green.

set -u

HARNESS="$(cd "$(dirname "$0")/harness" && pwd)"
source "$HARNESS/assertion-lib.sh"

ensure_beta_root
test_banner "20 Parser Router (Phase 5.3.a)"

# ─── Structural presence ────────────────────────────────────────────
assert_file_exists ".dexCore/core/parser/parse-route.sh" "parse-route.sh present"
assert_file_exists ".dexCore/core/parser/detect-mime.sh" "detect-mime.sh present"
assert_file_exists "myDex/.dex/config/capabilities.yaml.example" "capabilities.yaml.example template shipped"

for f in parse-route.sh detect-mime.sh; do
  if [ -x ".dexCore/core/parser/$f" ]; then pass "$f executable"; else fail "$f not executable"; fi
  if bash -n ".dexCore/core/parser/$f" 2>/dev/null; then
    pass "$f bash-parses cleanly"
  else
    fail "$f has syntax errors"
  fi
done

# ─── --help works ───────────────────────────────────────────────────
HELP_ROUTE=$(bash .dexCore/core/parser/parse-route.sh --help 2>&1 | head -30)
if echo "$HELP_ROUTE" | grep -q "Routing decision layer"; then
  pass "parse-route.sh --help emits header"
else
  fail "parse-route.sh --help missing header"
fi
HELP_MIME=$(bash .dexCore/core/parser/detect-mime.sh --help 2>&1 | head -20)
if echo "$HELP_MIME" | grep -q "MIME"; then
  pass "detect-mime.sh --help emits header"
else
  fail "detect-mime.sh --help missing header"
fi

# ─── detect-mime classifications ────────────────────────────────────
# Create fixture files in a scratch dir
SCRATCH=$(mktemp -d -t dexhub-20-XXXXXX)
cleanup() { rm -rf "$SCRATCH"; }
trap 'cleanup' EXIT INT TERM

touch "$SCRATCH/a.txt" "$SCRATCH/b.md" "$SCRATCH/c.pdf" "$SCRATCH/d.docx" \
      "$SCRATCH/e.png" "$SCRATCH/f.py" "$SCRATCH/g.json" "$SCRATCH/h.zip" \
      "$SCRATCH/i.eml" "$SCRATCH/j.xyz" "$SCRATCH/k_noext"
echo "hello" > "$SCRATCH/a.txt"

declare -a cases=(
  "a.txt:text"
  "b.md:text"
  "c.pdf:pdf"
  "d.docx:office"
  "e.png:image"
  "f.py:code"
  "g.json:data"
  "h.zip:archive"
  "i.eml:email"
  "j.xyz:unknown"
  "k_noext:unknown"
)
for case_entry in "${cases[@]}"; do
  file="${case_entry%%:*}"
  expected="${case_entry#*:}"
  got=$(bash .dexCore/core/parser/detect-mime.sh "$SCRATCH/$file" 2>/dev/null | awk '{print $1}')
  if [ "$got" = "$expected" ]; then
    pass "detect-mime: $file → $expected"
  else
    fail "detect-mime: $file → expected '$expected' got '$got'"
  fi
done

# detect-mime JSON shape
MIME_JSON=$(bash .dexCore/core/parser/detect-mime.sh --format json "$SCRATCH/a.txt" 2>/dev/null)
if echo "$MIME_JSON" | ruby -rjson -e '
  d = JSON.parse(STDIN.read)
  exit(d.key?("path") && d.key?("exists") && d.key?("type") && d.key?("size_bytes") ? 0 : 1)
' 2>/dev/null; then
  pass "detect-mime JSON has {path, exists, type, size_bytes}"
else
  fail "detect-mime JSON shape malformed"
fi

# ─── parse-route routing decisions ──────────────────────────────────
# Text file → native
ROUTE=$(bash .dexCore/core/parser/parse-route.sh "$SCRATCH/a.txt" 2>/dev/null)
if echo "$ROUTE" | ruby -rjson -e 'd=JSON.parse(STDIN.read); exit(d["backend"]=="native" && d["status"]=="ready" ? 0 : 1)' 2>/dev/null; then
  pass "text file → backend=native, status=ready"
else
  fail "text file routing wrong" "got: $(echo "$ROUTE" | head -20)"
fi

# Code + data + email files all route to native (plain-text family)
for entry in "f.py:native:ready" "g.json:native:ready" "i.eml:native:ready"; do
  file="${entry%%:*}"
  exp_backend=$(echo "$entry" | cut -d: -f2)
  exp_status=$(echo "$entry" | cut -d: -f3)
  got=$(bash .dexCore/core/parser/parse-route.sh "$SCRATCH/$file" 2>/dev/null | \
    ruby -rjson -e 'd=JSON.parse(STDIN.read); puts "#{d["backend"]}:#{d["status"]}"' 2>/dev/null)
  if [ "$got" = "${exp_backend}:${exp_status}" ]; then
    pass "$file → backend=$exp_backend, status=$exp_status"
  else
    fail "$file routing wrong: got '$got', expected '${exp_backend}:${exp_status}'"
  fi
done

# Office file → backend_missing (no kreuzberg)
OFFICE_ROUTE=$(bash .dexCore/core/parser/parse-route.sh "$SCRATCH/d.docx" 2>/dev/null)
OFFICE_STATUS=$(echo "$OFFICE_ROUTE" | ruby -rjson -e 'puts JSON.parse(STDIN.read)["status"]' 2>/dev/null)
OFFICE_BACKEND=$(echo "$OFFICE_ROUTE" | ruby -rjson -e 'puts JSON.parse(STDIN.read)["backend"]' 2>/dev/null)
if [ "$OFFICE_STATUS" = "backend_missing" ] && [ "$OFFICE_BACKEND" = "none" ]; then
  pass "office file without kreuzberg → backend=none, status=backend_missing"
else
  fail "office routing: got backend=$OFFICE_BACKEND, status=$OFFICE_STATUS"
fi

# Image file → backend_missing (no ollama_vlm backend declared)
IMG_ROUTE=$(bash .dexCore/core/parser/parse-route.sh "$SCRATCH/e.png" 2>/dev/null)
IMG_STATUS=$(echo "$IMG_ROUTE" | ruby -rjson -e 'puts JSON.parse(STDIN.read)["status"]' 2>/dev/null)
if [ "$IMG_STATUS" = "backend_missing" ]; then
  pass "image file without ollama_vlm → status=backend_missing"
else
  fail "image routing: got status=$IMG_STATUS"
fi

# Unknown ext → unsupported
UNK_ROUTE=$(bash .dexCore/core/parser/parse-route.sh "$SCRATCH/j.xyz" 2>/dev/null)
UNK_STATUS=$(echo "$UNK_ROUTE" | ruby -rjson -e 'puts JSON.parse(STDIN.read)["status"]' 2>/dev/null)
if [ "$UNK_STATUS" = "unsupported" ]; then
  pass "unknown ext → status=unsupported"
else
  fail "unknown ext: got status=$UNK_STATUS"
fi

# Missing file → unsupported (file not found)
MISS_ROUTE=$(bash .dexCore/core/parser/parse-route.sh "/tmp/dexhub-20-missing-${RANDOM}-${RANDOM}.pdf" 2>/dev/null)
MISS_STATUS=$(echo "$MISS_ROUTE" | ruby -rjson -e 'puts JSON.parse(STDIN.read)["status"]' 2>/dev/null)
MISS_REASON=$(echo "$MISS_ROUTE" | ruby -rjson -e 'puts JSON.parse(STDIN.read)["reason"]' 2>/dev/null)
if [ "$MISS_STATUS" = "unsupported" ] && echo "$MISS_REASON" | grep -qi "does not exist"; then
  pass "missing file → status=unsupported, reason mentions 'does not exist'"
else
  fail "missing-file routing: status=$MISS_STATUS, reason=$MISS_REASON"
fi

# Oversize PDF → deferred to roadmap 1.1
# Simulate by setting --oversize to a small threshold
SMALLPDF="$SCRATCH/c.pdf"
dd if=/dev/zero of="$SMALLPDF" bs=1024 count=2 2>/dev/null   # 2KB fake
OVER_ROUTE=$(bash .dexCore/core/parser/parse-route.sh --oversize 1000 "$SMALLPDF" 2>/dev/null)
OVER_STATUS=$(echo "$OVER_ROUTE" | ruby -rjson -e 'puts JSON.parse(STDIN.read)["status"]' 2>/dev/null)
OVER_BACKEND=$(echo "$OVER_ROUTE" | ruby -rjson -e 'puts JSON.parse(STDIN.read)["backend"]' 2>/dev/null)
if [ "$OVER_STATUS" = "deferred" ] && [ "$OVER_BACKEND" = "defer" ]; then
  pass "oversize PDF → backend=defer, status=deferred (roadmap 1.1)"
else
  fail "oversize routing: backend=$OVER_BACKEND, status=$OVER_STATUS"
fi

# ─── parse-route JSON shape ─────────────────────────────────────────
for field in file type size_bytes backend reason status policy hint; do
  if echo "$ROUTE" | ruby -rjson -e "d=JSON.parse(STDIN.read); exit(d.key?('$field') ? 0 : 1)" 2>/dev/null; then
    pass "parse-route JSON includes '$field'"
  else
    fail "parse-route JSON missing '$field'"
  fi
done

# ─── Text format works ──────────────────────────────────────────────
TEXT_OUT=$(bash .dexCore/core/parser/parse-route.sh --format text "$SCRATCH/a.txt" 2>/dev/null)
if echo "$TEXT_OUT" | grep -q "backend=native"; then
  pass "--format text: human-readable one-liner"
else
  fail "--format text: unexpected output"
fi

# ─── Capabilities.yaml template fields ──────────────────────────────
if grep -q "kreuzberg:" myDex/.dex/config/capabilities.yaml.example &&
   grep -q "ollama_vlm:" myDex/.dex/config/capabilities.yaml.example &&
   grep -q "compliance:" myDex/.dex/config/capabilities.yaml.example; then
  pass "capabilities.yaml.example template covers kreuzberg + ollama_vlm + compliance"
else
  fail "capabilities.yaml.example template incomplete"
fi

# ─── Capabilities.yaml can flip a backend to installed:true ─────────
# Verify: if user edits capabilities.yaml to say kreuzberg.installed=true,
# the router picks it up. Write a custom yaml + point --capabilities at it.
CUSTOM_CAPS="$SCRATCH/capabilities.yaml"
cat > "$CUSTOM_CAPS" <<EOF
schema_version: "1"
parser:
  backends:
    kreuzberg:
      installed: true
      version: "0.1.0"
      compliance: ok
    ollama_vlm:
      installed: true
      version: "latest"
      compliance: local_vlm_required
EOF
WITH_KW_OUT=$(bash .dexCore/core/parser/parse-route.sh --capabilities "$CUSTOM_CAPS" "$SCRATCH/d.docx" 2>/dev/null)
WITH_KW_BACKEND=$(echo "$WITH_KW_OUT" | ruby -rjson -e 'puts JSON.parse(STDIN.read)["backend"]' 2>/dev/null)
if [ "$WITH_KW_BACKEND" = "kreuzberg" ]; then
  pass "capabilities kreuzberg=true → docx routes to kreuzberg"
else
  fail "capabilities override: expected kreuzberg backend, got '$WITH_KW_BACKEND'"
fi

WITH_VLM_OUT=$(bash .dexCore/core/parser/parse-route.sh --capabilities "$CUSTOM_CAPS" "$SCRATCH/e.png" 2>/dev/null)
WITH_VLM_BACKEND=$(echo "$WITH_VLM_OUT" | ruby -rjson -e 'puts JSON.parse(STDIN.read)["backend"]' 2>/dev/null)
if [ "$WITH_VLM_BACKEND" = "ollama_vlm" ]; then
  pass "capabilities ollama_vlm=true → png routes to ollama_vlm"
else
  fail "capabilities ollama_vlm: expected ollama_vlm backend, got '$WITH_VLM_BACKEND'"
fi

# ─── Exit code is always 0 ──────────────────────────────────────────
bash .dexCore/core/parser/parse-route.sh "/tmp/missing-${RANDOM}.foo" >/dev/null 2>&1
if [ "$?" = "0" ]; then
  pass "exit code 0 even for missing / unsupported files (router is informational)"
else
  fail "exit code non-zero for missing file"
fi

# ─── features.yaml registration ─────────────────────────────────────
if grep -qE "^\s+- id: parser\.router\b" .dexCore/_cfg/features.yaml; then
  pass "features.yaml: parser.router registered as a feature entry"
else
  fail "features.yaml: parser.router NOT registered"
fi

# Status must be enabled (flipped from deferred)
ROUTER_STATUS=$(grep -A 5 -e "- id: parser\.router" .dexCore/_cfg/features.yaml | grep -m1 "status:" | tr -d ' ')
if echo "$ROUTER_STATUS" | grep -q "^status:enabled"; then
  pass "features.yaml: parser.router status=enabled (flipped from deferred)"
else
  fail "features.yaml: parser.router status unexpected ($ROUTER_STATUS)"
fi

if grep -qE "^\s+- id: parser\.capabilities_yaml\b" .dexCore/_cfg/features.yaml; then
  pass "features.yaml: parser.capabilities_yaml registered"
else
  fail "features.yaml: parser.capabilities_yaml NOT registered"
fi

test_summary
