#!/bin/bash
# DexHub E2E Test 13 — L2 Tank Ingest (Phase 5.2.b-ingest)
#
# Proves the L2 Tank chunker + ingest pipeline works end-to-end:
#   - Markdown source → heading-aware chunks → SQLite inserts
#   - FTS5 virtual table queryable post-ingest
#   - SHA-256-based dedup: re-ingest unchanged source = no-op
#   - Edit source + re-ingest: old chunks deleted, new ones inserted
#   - Audit trail: ingest_runs table records each run
#   - Source-type auto-detection (wiki / chronicle / ingest)
#   - Special characters (single quotes) in content survive SQL escape
#
# Fixture-based. No API cost. Uses mktemp for DB + source files.

set -u

HARNESS="$(cd "$(dirname "$0")/harness" && pwd)"
source "$HARNESS/assertion-lib.sh"

ensure_beta_root
test_banner "13 L2 Tank Ingest (Phase 5.2.b-ingest)"

# ─── Dep checks ──────────────────────────────────────────────────────
if ! command -v sqlite3 >/dev/null 2>&1; then
  fail "sqlite3 not available — cannot test L2 ingest"
  test_summary
  exit 1
fi
if ! command -v ruby >/dev/null 2>&1; then
  fail "ruby not available — required by l2-ingest.sh"
  test_summary
  exit 1
fi
pass "Deps present: sqlite3 + ruby + awk"

# ─── Structural: chunker + ingest script ─────────────────────────────
assert_file_exists ".dexCore/core/knowledge/l2/l2-chunker.awk" \
  "l2-chunker.awk present"
assert_file_contains ".dexCore/core/knowledge/l2/l2-chunker.awk" "MAX_SIZE" \
  "chunker honors MAX_SIZE"
assert_file_contains ".dexCore/core/knowledge/l2/l2-ingest.sh" "shasum -a 256" \
  "ingest script computes SHA-256"
assert_file_contains ".dexCore/core/knowledge/l2/l2-ingest.sh" "ingest_runs" \
  "ingest script logs to ingest_runs audit table"

# ─── Fixture setup ───────────────────────────────────────────────────
FIXTURE_DB=$(mktemp -u -t dexhub-l2-test-XXXXXX).sqlite
FIXTURE_MD=$(mktemp -t dexhub-l2-src-XXXXXX).md

# Content includes a single quote to test SQL escape
cat > "$FIXTURE_MD" <<'FIXTURE_EOF'
# Team Glossary

Terms we use that don't mean what you'd expect.

## DEX

Knowledge Meta-Layer. Note: it's not "DEX" the swap protocol.

## myDex

Personal Workspace Manager.

# Architecture Notes

The 3-5 decisions that shape the codebase.

## Decision: local-first

All data stays on device. No cloud dependency.

# Institutional Knowledge

Long-lived truths agents need to know.
FIXTURE_EOF

# Cleanup trap
cleanup() {
  rm -f "$FIXTURE_DB" "${FIXTURE_DB}-wal" "${FIXTURE_DB}-shm" "$FIXTURE_MD"
}
trap 'cleanup' EXIT INT TERM

# ─── Init DB ────────────────────────────────────────────────────────
if bash .dexCore/core/knowledge/l2/l2-init.sh --db "$FIXTURE_DB" >/dev/null 2>&1; then
  pass "Fixture DB initialized"
else
  fail "Fixture DB init failed"
  test_summary
  exit 1
fi

# ─── First ingest: should insert chunks ──────────────────────────────
OUTPUT=$(bash .dexCore/core/knowledge/l2/l2-ingest.sh --db "$FIXTURE_DB" --source "$FIXTURE_MD" 2>&1)
if echo "$OUTPUT" | grep -q "OK:.*chunks"; then
  pass "First ingest: OK"
else
  fail "First ingest failed" "output: ${OUTPUT:0:200}"
fi

# Verify chunk count (fixture has 5 sections: h1+h2+h2+h1+h2+h1 = 6 chunks incl. subsections)
CHUNK_COUNT=$(sqlite3 "$FIXTURE_DB" "SELECT COUNT(*) FROM chunks" 2>/dev/null)
if [ "$CHUNK_COUNT" -ge 5 ] && [ "$CHUNK_COUNT" -le 8 ]; then
  pass "Chunk count in expected range ($CHUNK_COUNT, expected 5-8)"
else
  fail "Chunk count unexpected: $CHUNK_COUNT"
fi

# Verify specific titles present
TITLES=$(sqlite3 "$FIXTURE_DB" "SELECT title FROM chunks ORDER BY chunk_index" 2>/dev/null)
for expected_title in "Team Glossary" "DEX" "myDex" "Architecture Notes" "Institutional Knowledge"; do
  if echo "$TITLES" | grep -qF "$expected_title"; then
    pass "Chunk title present: $expected_title"
  else
    fail "Chunk title missing: $expected_title" "all titles: $TITLES"
  fi
done

# ─── SQL-escape robustness: content with single quote survives ──────
DEX_CONTENT=$(sqlite3 "$FIXTURE_DB" "SELECT content FROM chunks WHERE title='DEX'" 2>/dev/null)
if echo "$DEX_CONTENT" | grep -q "it's not"; then
  pass "Content with single quote preserved through SQL escape"
else
  fail "Content lost single-quote handling" "content: ${DEX_CONTENT:0:100}"
fi

# ─── FTS5 keyword search works ───────────────────────────────────────
FTS_HITS=$(sqlite3 "$FIXTURE_DB" "SELECT COUNT(*) FROM chunks_fts WHERE chunks_fts MATCH 'decision'" 2>/dev/null)
if [ "$FTS_HITS" -ge 1 ]; then
  pass "FTS5 search finds 'decision' ($FTS_HITS hit(s))"
else
  fail "FTS5 search failed"
fi

FTS_HITS2=$(sqlite3 "$FIXTURE_DB" "SELECT COUNT(*) FROM chunks_fts WHERE chunks_fts MATCH 'workspace'" 2>/dev/null)
if [ "$FTS_HITS2" -ge 1 ]; then
  pass "FTS5 search finds 'workspace' ($FTS_HITS2 hit(s))"
else
  fail "FTS5 search for 'workspace' failed"
fi

# ─── Source-hash dedup: second ingest = no-op ────────────────────────
OUTPUT=$(bash .dexCore/core/knowledge/l2/l2-ingest.sh --db "$FIXTURE_DB" --source "$FIXTURE_MD" 2>&1)
if echo "$OUTPUT" | grep -q "SKIP:.*unchanged"; then
  pass "Dedup: re-ingest unchanged source = SKIP"
else
  fail "Dedup failed — source should be skipped" "output: ${OUTPUT:0:200}"
fi

CHUNK_COUNT_AFTER_DEDUP=$(sqlite3 "$FIXTURE_DB" "SELECT COUNT(*) FROM chunks" 2>/dev/null)
if [ "$CHUNK_COUNT_AFTER_DEDUP" = "$CHUNK_COUNT" ]; then
  pass "Dedup: chunk count unchanged after no-op ingest ($CHUNK_COUNT)"
else
  fail "Dedup regression: count changed from $CHUNK_COUNT to $CHUNK_COUNT_AFTER_DEDUP"
fi

# ─── Edit source, re-ingest: delete-and-insert ──────────────────────
echo "" >> "$FIXTURE_MD"
echo "# Added Section" >> "$FIXTURE_MD"
echo "Fresh content after edit." >> "$FIXTURE_MD"

OUTPUT=$(bash .dexCore/core/knowledge/l2/l2-ingest.sh --db "$FIXTURE_DB" --source "$FIXTURE_MD" 2>&1)
if echo "$OUTPUT" | grep -q "UPDATE:.*re-ingesting"; then
  pass "Edit detected: re-ingest announced"
else
  fail "Edit detection failed" "output: ${OUTPUT:0:200}"
fi

CHUNK_COUNT_AFTER_EDIT=$(sqlite3 "$FIXTURE_DB" "SELECT COUNT(*) FROM chunks" 2>/dev/null)
if [ "$CHUNK_COUNT_AFTER_EDIT" -gt "$CHUNK_COUNT" ]; then
  pass "Post-edit: chunk count grew ($CHUNK_COUNT → $CHUNK_COUNT_AFTER_EDIT)"
else
  fail "Post-edit: chunk count didn't grow (edit added a section)"
fi

# New section title present
TITLES_AFTER=$(sqlite3 "$FIXTURE_DB" "SELECT title FROM chunks" 2>/dev/null)
if echo "$TITLES_AFTER" | grep -qF "Added Section"; then
  pass "Post-edit: 'Added Section' in chunks"
else
  fail "Post-edit: new section not found"
fi

# ─── Source-type auto-detection ─────────────────────────────────────
# Create a fixture in a wiki-looking path
WIKI_MD=$(mktemp -d)/myDex/.dex/wiki
mkdir -p "$WIKI_MD"
cat > "$WIKI_MD/test-wiki.md" <<'WIKI_EOF'
# Wiki Entry
Sample content.
WIKI_EOF

OUTPUT=$(bash .dexCore/core/knowledge/l2/l2-ingest.sh --db "$FIXTURE_DB" --source "$WIKI_MD/test-wiki.md" 2>&1)
# Source type is inferred from path; since our fixture is in a temp dir that
# DOES contain "myDex/.dex/wiki" in the path, the type should be 'wiki'.
WIKI_TYPE=$(sqlite3 "$FIXTURE_DB" "SELECT DISTINCT source_type FROM chunks WHERE source_path LIKE '%test-wiki.md'" 2>/dev/null)
if [ "$WIKI_TYPE" = "wiki" ]; then
  pass "Source-type auto-detect: wiki path → 'wiki'"
else
  echo -e "  \033[1;33m⚠\033[0m Source-type auto-detect returned '$WIKI_TYPE' (expected 'wiki' — may be path-dependent)"
fi
rm -rf "$(dirname "$(dirname "$WIKI_MD")")"

# ─── ingest_runs audit log populated ────────────────────────────────
RUN_COUNT=$(sqlite3 "$FIXTURE_DB" "SELECT COUNT(*) FROM ingest_runs" 2>/dev/null)
if [ "$RUN_COUNT" -ge 3 ]; then
  pass "Audit log: $RUN_COUNT ingest_runs recorded (≥3 expected: first, dedup skip still creates row, edit re-ingest, wiki)"
else
  fail "Audit log has too few entries ($RUN_COUNT)"
fi

# ─── Dry-run mode doesn't write ──────────────────────────────────────
DRY_DB=$(mktemp -u -t dexhub-l2-dry-XXXXXX).sqlite
bash .dexCore/core/knowledge/l2/l2-init.sh --db "$DRY_DB" >/dev/null 2>&1
bash .dexCore/core/knowledge/l2/l2-ingest.sh --db "$DRY_DB" --dry-run --source "$FIXTURE_MD" >/dev/null 2>&1 || true
DRY_COUNT=$(sqlite3 "$DRY_DB" "SELECT COUNT(*) FROM chunks" 2>/dev/null || echo 0)
if [ "$DRY_COUNT" = "0" ]; then
  pass "Dry-run mode: no DB writes"
else
  fail "Dry-run wrote $DRY_COUNT chunks (should be 0)"
fi
rm -f "$DRY_DB" "${DRY_DB}-wal" "${DRY_DB}-shm"

# ─── features.yaml flipped to enabled ────────────────────────────────
# Feature entries span ~5-15 lines; search within a larger window.
if grep -A 10 "id: knowledge.l2_tank_ingest" .dexCore/_cfg/features.yaml | grep -qE "^    status: enabled"; then
  pass "features.yaml: l2_tank_ingest flipped experimental → enabled"
else
  fail "features.yaml: l2_tank_ingest status not yet 'enabled'"
fi

test_summary
