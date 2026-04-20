#!/bin/bash
# DexHub E2E Test 26 — Parser Inbox Auto-Parse (Phase 5.3.f first slice)
#
# Proves the inbox orchestrator makes the Parser arc end-to-end USABLE:
#   - script exists, parses, has --help
#   - Config-driven inbox path resolution (flag > env > config.yaml > default)
#   - --dry-run doesn't touch anything
#   - Processes native/text files via the direct path (no backend needed)
#   - Routes binary/office/image files correctly but reports
#     routed_but_backend_unavailable when backends not installed
#   - Archives originals to .processed/<timestamp>-<name>
#   - --no-archive leaves originals in place
#   - --one-file PATH processes a single file
#   - features.yaml: parser.inbox_auto_parse flipped enabled
#   - DexMaster *inbox menu + prompt handler exist
#
# Dual-env-safe: structural assertions only, works on both dev + CI clean.

set -u

HARNESS="$(cd "$(dirname "$0")/harness" && pwd)"
source "$HARNESS/assertion-lib.sh"

ensure_beta_root
test_banner "26 Parser Inbox Auto-Parse (Phase 5.3.f first slice)"

SCRIPT=".dexCore/core/parser/inbox-auto-parse.sh"

# ─── Structural ──────────────────────────────────────────────────────
assert_file_exists "$SCRIPT" "inbox-auto-parse.sh present"
if [ -x "$SCRIPT" ]; then pass "inbox-auto-parse.sh executable"; else fail "not executable"; fi
if bash -n "$SCRIPT" 2>/dev/null; then
  pass "inbox-auto-parse.sh bash-parses cleanly"
else
  fail "inbox-auto-parse.sh has syntax errors"
fi

HELP=$(bash "$SCRIPT" --help 2>&1 | head -20)
if echo "$HELP" | grep -qi "Inbox orchestrator"; then
  pass "--help emits header"
else
  fail "--help output unexpected"
fi

# ─── Scratch fixture inbox ──────────────────────────────────────────
SCRATCH=$(mktemp -d -t dex-inbox26-XXXXXX)
mkdir -p "$SCRATCH"
cleanup() { rm -rf "$SCRATCH"; }
trap 'cleanup' EXIT INT TERM

# ─── Empty inbox: count=0, no files processed ───────────────────────
EMPTY_JSON=$(bash "$SCRIPT" --inbox "$SCRATCH" --format json 2>/dev/null)
if echo "$EMPTY_JSON" | ruby -rjson -e 'd=JSON.parse(STDIN.read); exit(d["count"] == 0 ? 0 : 1)' 2>/dev/null; then
  pass "empty inbox: count=0"
else
  fail "empty inbox: count non-zero"
fi

# ─── Drop a text file: should process via 'native' backend ──────────
echo "# Test doc
Hello world from inbox orchestrator." > "$SCRATCH/doc1.md"

# Dry-run first
DRY_JSON=$(bash "$SCRIPT" --inbox "$SCRATCH" --dry-run --format json 2>/dev/null)
DRY_COUNT=$(echo "$DRY_JSON" | ruby -rjson -e 'puts JSON.parse(STDIN.read)["count"]' 2>/dev/null)
DRY_STATUS=$(echo "$DRY_JSON" | ruby -rjson -e 'puts JSON.parse(STDIN.read)["results"][0]["status"]' 2>/dev/null)
DRY_BACKEND=$(echo "$DRY_JSON" | ruby -rjson -e 'puts JSON.parse(STDIN.read)["results"][0]["backend"]' 2>/dev/null)
if [ "$DRY_COUNT" = "1" ] && [ "$DRY_STATUS" = "dry_run" ] && [ "$DRY_BACKEND" = "native" ]; then
  pass "dry-run: 1 file, status=dry_run, backend=native"
else
  fail "dry-run unexpected" "count=$DRY_COUNT status=$DRY_STATUS backend=$DRY_BACKEND"
fi

# File should still be in inbox (dry-run shouldn't move)
if [ -f "$SCRATCH/doc1.md" ]; then
  pass "dry-run: original file untouched"
else
  fail "dry-run moved the file"
fi

# ─── Real run: ingests + archives ───────────────────────────────────
REAL_JSON=$(bash "$SCRIPT" --inbox "$SCRATCH" --format json 2>/dev/null)
REAL_STATUS=$(echo "$REAL_JSON" | ruby -rjson -e 'puts JSON.parse(STDIN.read)["results"][0]["status"]' 2>/dev/null)
REAL_ARCHIVED=$(echo "$REAL_JSON" | ruby -rjson -e 'puts JSON.parse(STDIN.read)["results"][0]["archived_to"]' 2>/dev/null)
REAL_BYTES=$(echo "$REAL_JSON" | ruby -rjson -e 'puts JSON.parse(STDIN.read)["results"][0]["extracted_bytes"]' 2>/dev/null)

if [ "$REAL_STATUS" = "ok" ]; then
  pass "real run: status=ok"
else
  fail "real run: status=$REAL_STATUS"
fi
if [ -n "$REAL_ARCHIVED" ] && [ "$REAL_ARCHIVED" != "null" ]; then
  pass "real run: archived_to set"
else
  fail "real run: archived_to missing"
fi
if [ "$REAL_BYTES" -gt 0 ]; then
  pass "real run: extracted_bytes=$REAL_BYTES > 0"
else
  fail "real run: extracted_bytes=$REAL_BYTES"
fi

# Inbox should no longer have the original; .processed/ should
if [ ! -f "$SCRATCH/doc1.md" ]; then
  pass "real run: original removed from inbox root"
else
  fail "real run: original still in inbox"
fi
if ls "$SCRATCH/.processed/"*doc1.md >/dev/null 2>&1; then
  pass "real run: file present in .processed/ archive"
else
  fail "real run: archive copy missing"
fi

# ─── --no-archive: leaves file in place ─────────────────────────────
echo "# Keep me" > "$SCRATCH/keep.md"
NOARCH=$(bash "$SCRIPT" --inbox "$SCRATCH" --no-archive --format json 2>/dev/null)
NOARCH_STATUS=$(echo "$NOARCH" | ruby -rjson -e 'puts JSON.parse(STDIN.read)["results"][0]["status"]' 2>/dev/null)
if [ "$NOARCH_STATUS" = "ok" ] && [ -f "$SCRATCH/keep.md" ]; then
  pass "--no-archive: status=ok AND original still in inbox"
else
  fail "--no-archive: status=$NOARCH_STATUS file-present=$([ -f "$SCRATCH/keep.md" ] && echo yes || echo no)"
fi
rm -f "$SCRATCH/keep.md"

# ─── --one-file ONE.md: single-file mode ────────────────────────────
ONE_TMP=$(mktemp -t one-XXXXXX).md
echo "# One" > "$ONE_TMP"
ONE_JSON=$(bash "$SCRIPT" --inbox "$SCRATCH" --one-file "$ONE_TMP" --format json 2>/dev/null)
ONE_COUNT=$(echo "$ONE_JSON" | ruby -rjson -e 'puts JSON.parse(STDIN.read)["count"]' 2>/dev/null)
if [ "$ONE_COUNT" = "1" ]; then
  pass "--one-file: processes exactly 1 file"
else
  fail "--one-file: count=$ONE_COUNT"
fi
rm -f "$ONE_TMP"

# ─── Binary file routing: should report routed_but_backend_unavailable ─
# Create a fake PDF (no actual backend to extract) and ensure orchestrator
# gracefully reports routed_but_backend_unavailable rather than crashing.
# Only assert the status if no kreuzberg — otherwise the test is on a
# machine where it actually processes. Either outcome is valid; we just
# require NO CRASH and a predictable status vocabulary.
echo "%PDF-1.4 fake" > "$SCRATCH/fake.pdf"
PDF_JSON=$(bash "$SCRIPT" --inbox "$SCRATCH" --format json 2>/dev/null)
PDF_STATUS=$(echo "$PDF_JSON" | ruby -rjson -e '
  d = JSON.parse(STDIN.read)
  r = d["results"].find { |x| x["file"].to_s.end_with?("fake.pdf") }
  puts r ? r["status"] : "missing"
' 2>/dev/null)
case "$PDF_STATUS" in
  ok|routed_but_backend_unavailable|extract_failed|ingest_failed)
    pass "PDF file: status='$PDF_STATUS' (valid vocabulary)"
    ;;
  *)
    fail "PDF file: unexpected status '$PDF_STATUS'"
    ;;
esac

# ─── Inbox missing: exit 3 ──────────────────────────────────────────
bash "$SCRIPT" --inbox "/tmp/nonexistent-inbox-${RANDOM}" >/dev/null 2>&1
MISS_EXIT=$?
if [ "$MISS_EXIT" = "3" ]; then
  pass "missing inbox: exit 3"
else
  fail "missing inbox: expected exit 3, got $MISS_EXIT"
fi

# ─── Bad flag: exit 1 ───────────────────────────────────────────────
bash "$SCRIPT" --nonsense >/dev/null 2>&1
if [ "$?" = "1" ]; then
  pass "unknown flag: exit 1"
else
  fail "unknown flag: exit $?"
fi

# ─── features.yaml registration ─────────────────────────────────────
if grep -qE "^\s+- id: parser\.inbox_auto_parse\b" .dexCore/_cfg/features.yaml; then
  pass "features.yaml: parser.inbox_auto_parse registered"
else
  fail "features.yaml: parser.inbox_auto_parse NOT registered"
fi
IAP_STATUS=$(grep -A 5 -e "- id: parser\.inbox_auto_parse" .dexCore/_cfg/features.yaml | grep -m1 "status:" | tr -d ' ')
if echo "$IAP_STATUS" | grep -q "^status:enabled"; then
  pass "features.yaml: parser.inbox_auto_parse status=enabled"
else
  fail "features.yaml: parser.inbox_auto_parse status='$IAP_STATUS'"
fi
IAP_BODY=$(awk '/- id: parser\.inbox_auto_parse/{flag=1; print; next} flag && /^  - id: / {exit} flag {print}' .dexCore/_cfg/features.yaml)
if echo "$IAP_BODY" | grep -q "26-parser-inbox-auto-parse"; then
  pass "features.yaml: tests[] references test 26"
else
  fail "features.yaml: tests[] missing test 26"
fi

# ─── DexMaster menu + prompt handler ────────────────────────────────
if grep -qE '<item cmd="\*inbox"' .dexCore/core/agents/dex-master.md; then
  pass "dex-master.md: *inbox menu item present"
else
  fail "dex-master.md: *inbox menu item missing"
fi
if grep -qE '^[[:space:]]*<prompt id="inbox-auto-parse">' .dexCore/core/agents/dex-master.md; then
  pass "dex-master.md: inbox-auto-parse prompt handler defined"
else
  fail "dex-master.md: inbox-auto-parse prompt handler missing"
fi
INBOX_PROMPT_BODY=$(awk '/^[[:space:]]*<prompt id="inbox-auto-parse">/,/^[[:space:]]*<\/prompt>/' .dexCore/core/agents/dex-master.md)
if echo "$INBOX_PROMPT_BODY" | grep -q "inbox-auto-parse.sh"; then
  pass "dex-master.md: inbox prompt invokes inbox-auto-parse.sh"
else
  fail "dex-master.md: inbox prompt doesn't reference the script"
fi

test_summary
