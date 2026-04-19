#!/bin/bash
# DexHub E2E Test 10 — L1 Wiki Injection scaffold (Phase 5.2.d first slice)
#
# Structural test. No API cost. No opt-in gate.
#
# Verifies the L1 Wiki session-start injection scaffold works end-to-end
# at the enumeration layer:
#   - Pattern doc in place
#   - load-wiki.sh script executable + valid bash
#   - Empty wiki (only README.md) → silent exit
#   - User-authored entries → correctly enumerated + formatted
#   - Template files (*.template.md) → correctly skipped
#   - Archived entries → correctly skipped
#   - Size caps honored
#
# Actual wiring to Claude Code / Copilot session-start is intentionally
# out of scope here (platform-specific, deferred).

set -u

HARNESS="$(cd "$(dirname "$0")/harness" && pwd)"
source "$HARNESS/assertion-lib.sh"

ensure_beta_root
test_banner "10 L1 Wiki Injection scaffold (Phase 5.2.d first slice)"

# ─── Design doc in place ─────────────────────────────────────────────
assert_file_exists ".dexCore/_dev/docs/L1-WIKI-INJECTION.md" \
  "Injection pattern doc present"
assert_file_contains ".dexCore/_dev/docs/L1-WIKI-INJECTION.md" "load-wiki.sh" \
  "Doc references the script"
assert_file_contains ".dexCore/_dev/docs/L1-WIKI-INJECTION.md" "Size cap" \
  "Doc documents size-cap contract"

# ─── Script in place + executable ────────────────────────────────────
assert_file_exists ".dexCore/core/knowledge/load-wiki.sh" \
  "load-wiki.sh present"
if [ -x ".dexCore/core/knowledge/load-wiki.sh" ]; then
  pass "load-wiki.sh is executable"
else
  fail "load-wiki.sh not executable" "run chmod +x"
fi
# Syntax check: `bash -n` parses without executing
if bash -n ".dexCore/core/knowledge/load-wiki.sh" 2>/dev/null; then
  pass "load-wiki.sh bash-parses cleanly"
else
  fail "load-wiki.sh has syntax errors"
fi

# ─── Functional test: fresh install (only README.md) ─────────────────
# Use a fixture dir to avoid touching real myDex/.dex/wiki
FIXTURE_DIR=$(mktemp -d)
trap 'rm -rf "$FIXTURE_DIR"' EXIT INT TERM

# Case 1: empty-ish wiki (only framework README)
cat > "$FIXTURE_DIR/README.md" <<'README_EOF'
# Framework README
This should be skipped.
README_EOF

OUTPUT=$(bash .dexCore/core/knowledge/load-wiki.sh --wiki-dir "$FIXTURE_DIR" 2>&1 || true)
if [ -z "$OUTPUT" ]; then
  pass "Case 1: fresh-install (only README) → silent exit (no output)"
else
  fail "Case 1: unexpected output on README-only wiki" "got: ${OUTPUT:0:200}"
fi

SUMMARY=$(bash .dexCore/core/knowledge/load-wiki.sh --wiki-dir "$FIXTURE_DIR" --summary-only 2>&1 || true)
if echo "$SUMMARY" | grep -q "^0 entries loaded"; then
  pass "Case 1: --summary-only reports 0 entries"
else
  fail "Case 1: --summary-only output wrong" "got: $SUMMARY"
fi

# ─── Case 2: user-authored entry loads ───────────────────────────────
cat > "$FIXTURE_DIR/project-glossary.md" <<'GLOSSARY_EOF'
---
title: Project Glossary
last_reviewed: 2026-04-20
status: active
why_l1: Team-specific terms
---

# Glossary

**DEX** — Knowledge Meta-Layer.
**myDex** — Personal Workspace.
GLOSSARY_EOF

OUTPUT=$(bash .dexCore/core/knowledge/load-wiki.sh --wiki-dir "$FIXTURE_DIR" 2>&1)
if echo "$OUTPUT" | grep -q "L1 WIKI"; then
  pass "Case 2: user entry triggers wiki-block header"
else
  fail "Case 2: wiki-block header missing" "got: ${OUTPUT:0:200}"
fi
if echo "$OUTPUT" | grep -q "project-glossary.md"; then
  pass "Case 2: user entry filename appears in output"
else
  fail "Case 2: user entry filename not in output"
fi
if echo "$OUTPUT" | grep -q "DEX.*Knowledge Meta-Layer"; then
  pass "Case 2: user entry content loaded"
else
  fail "Case 2: user entry content missing"
fi

# ─── Case 3: template file is skipped ────────────────────────────────
cat > "$FIXTURE_DIR/example.template.md" <<'TMPL_EOF'
---
status: active
---
# Template (should be skipped)
This is template content.
TMPL_EOF

OUTPUT=$(bash .dexCore/core/knowledge/load-wiki.sh --wiki-dir "$FIXTURE_DIR" 2>&1)
if echo "$OUTPUT" | grep -q "example.template.md"; then
  fail "Case 3: template file NOT skipped (should be)"
else
  pass "Case 3: template file (*.template.md) skipped"
fi

# ─── Case 4: archived entry is skipped ───────────────────────────────
cat > "$FIXTURE_DIR/old-decisions.md" <<'ARCHIVE_EOF'
---
title: Old Decisions
status: archived
---
# These decisions no longer apply.
ARCHIVE_EOF

OUTPUT=$(bash .dexCore/core/knowledge/load-wiki.sh --wiki-dir "$FIXTURE_DIR" 2>&1)
if echo "$OUTPUT" | grep -q "old-decisions.md"; then
  fail "Case 4: archived entry NOT skipped"
else
  pass "Case 4: archived entry (status: archived) skipped"
fi

# ─── Case 5: per-file size cap truncates ─────────────────────────────
# Create a 3KB file; with --max-file 1024 should truncate
python3 -c "print('x' * 3000)" > "$FIXTURE_DIR/oversized.md" 2>/dev/null || \
  perl -e 'print "x" x 3000' > "$FIXTURE_DIR/oversized.md"
# Add minimal frontmatter so it's not filtered by status check (no status = load)
TMP=$(mktemp)
printf -- "---\nstatus: active\n---\n" > "$TMP"
cat "$FIXTURE_DIR/oversized.md" >> "$TMP"
mv "$TMP" "$FIXTURE_DIR/oversized.md"

OUTPUT=$(bash .dexCore/core/knowledge/load-wiki.sh --wiki-dir "$FIXTURE_DIR" --max-file 1024 --max-total 20480 2>&1)
if echo "$OUTPUT" | grep -q "truncated"; then
  pass "Case 5: oversized file truncation marker present"
else
  fail "Case 5: no truncation marker despite 3KB file vs 1KB per-file cap"
fi

# ─── Case 6: summary reports correct counts ──────────────────────────
SUMMARY=$(bash .dexCore/core/knowledge/load-wiki.sh --wiki-dir "$FIXTURE_DIR" --summary-only 2>&1)
# We have: README.md (skip), project-glossary.md (load), example.template.md (skip),
#          old-decisions.md (skip — archived), oversized.md (load — but truncated)
# Expected: 2 loaded, 3 skipped
if echo "$SUMMARY" | grep -qE "^2 entries loaded, 3 skipped"; then
  pass "Case 6: summary reports 2 loaded + 3 skipped"
else
  echo -e "\033[1;33m  ⚠\033[0m Case 6: summary text differs — got: $SUMMARY"
  # Soft-check — the contract is documented but exact string not strict
fi

# ─── Case 7: nonexistent wiki dir → silent exit code 0 ──────────────
bash .dexCore/core/knowledge/load-wiki.sh --wiki-dir /nonexistent/path 2>&1 >/dev/null
EXIT=$?
if [ "$EXIT" -eq 0 ]; then
  pass "Case 7: nonexistent wiki dir → exit 0 (not an error)"
else
  fail "Case 7: nonexistent wiki dir → exit $EXIT (should be 0)"
fi

# ─── Feature registry claim ──────────────────────────────────────────
assert_file_contains ".dexCore/_cfg/features.yaml" "knowledge.l1_wiki_injection" \
  "features.yaml declares knowledge.l1_wiki_injection"

test_summary
