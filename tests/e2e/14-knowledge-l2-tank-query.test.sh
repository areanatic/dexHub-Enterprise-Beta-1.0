#!/bin/bash
# DexHub E2E Test 14 — L2 Tank Query (Phase 5.2.b-query, FTS5-only)
#
# Proves the l2-query.sh pipeline works end-to-end:
#   - FTS5 BM25 keyword search over ingested chunks
#   - Markdown output format (default) preserves source paths + rank + content
#   - JSON output format emits valid parseable JSON
#   - --top N limits result count
#   - --source-type filter restricts to wiki / chronicle / ingest
#   - Empty tank / no-match cases return graceful messages, exit 0
#   - Content with newlines round-trips correctly (JSON mode escapes, markdown
#     renders line-breaks naturally)
#
# Fixture-based. No API cost.

set -u

HARNESS="$(cd "$(dirname "$0")/harness" && pwd)"
source "$HARNESS/assertion-lib.sh"

ensure_beta_root
test_banner "14 L2 Tank Query (Phase 5.2.b-query, FTS5-only)"

# ─── Dep checks ──────────────────────────────────────────────────────
if ! command -v sqlite3 >/dev/null 2>&1; then
  fail "sqlite3 not available"; test_summary; exit 1
fi
if ! command -v ruby >/dev/null 2>&1; then
  fail "ruby not available"; test_summary; exit 1
fi
pass "Deps: sqlite3 + ruby"

# ─── Structural ──────────────────────────────────────────────────────
assert_file_exists ".dexCore/core/knowledge/l2/l2-query.sh" \
  "l2-query.sh present"
if [ -x ".dexCore/core/knowledge/l2/l2-query.sh" ]; then
  pass "l2-query.sh executable"
else
  fail "l2-query.sh not executable"
fi
if bash -n .dexCore/core/knowledge/l2/l2-query.sh 2>/dev/null; then
  pass "l2-query.sh bash-parses cleanly"
else
  fail "l2-query.sh has syntax errors"
fi

# Must NOT still emit [L2 STUB] signal (we promoted from stub to real)
STUB_OUT=$(bash .dexCore/core/knowledge/l2/l2-query.sh "test" 2>&1 || true)
if echo "$STUB_OUT" | grep -q "\[L2 STUB\]"; then
  fail "l2-query.sh still emits [L2 STUB] — not yet promoted from stub"
else
  pass "l2-query.sh no longer a stub (promoted to real FTS5)"
fi

# ─── Fixture setup ───────────────────────────────────────────────────
FIXTURE_DB=$(mktemp -u -t dexhub-l2-q14-XXXXXX).sqlite
FIXTURE_MD=$(mktemp -t dexhub-l2-q14src-XXXXXX).md

cat > "$FIXTURE_MD" <<'FIXTURE_EOF'
# Architecture

## Decision: platform priority

Beta ships for GitHub Copilot. Claude Code is an integration module.

## Decision: local-first

All user data stays on device by default. Cloud embeddings are opt-in.

# Team Glossary

## DEX

Knowledge Meta-Layer. Unique term used across DexHub.

## Workspace

The user's working directory at myDex/.

# Incident Log

## 2026-04-20 Claude Code coupling

User caught Claude Code tightly coupled in test paths. Fixed by moving to
integrations/claude-code/ module.
FIXTURE_EOF

cleanup() {
  rm -f "$FIXTURE_DB" "${FIXTURE_DB}-wal" "${FIXTURE_DB}-shm" "$FIXTURE_MD"
}
trap 'cleanup' EXIT INT TERM

bash .dexCore/core/knowledge/l2/l2-init.sh --db "$FIXTURE_DB" >/dev/null
bash .dexCore/core/knowledge/l2/l2-ingest.sh --db "$FIXTURE_DB" --source "$FIXTURE_MD" >/dev/null 2>&1

CHUNK_COUNT=$(sqlite3 "$FIXTURE_DB" "SELECT COUNT(*) FROM chunks" 2>/dev/null)
if [ "$CHUNK_COUNT" -ge 5 ]; then
  pass "Fixture ingested: $CHUNK_COUNT chunks"
else
  fail "Fixture ingest failed ($CHUNK_COUNT chunks)"
  test_summary
  exit 1
fi

# ─── Markdown query ──────────────────────────────────────────────────
OUTPUT=$(bash .dexCore/core/knowledge/l2/l2-query.sh --db "$FIXTURE_DB" "decision" 2>&1)
if echo "$OUTPUT" | grep -q "^# L2 TANK"; then
  pass "Markdown: header emitted"
else
  fail "Markdown: no header"
fi
if echo "$OUTPUT" | grep -qc "^## Decision"; then
  pass "Markdown: at least one 'Decision' chunk in results"
else
  fail "Markdown: no Decision chunks"
fi
if echo "$OUTPUT" | grep -q "platform priority"; then
  pass "Markdown: content preserved ('platform priority')"
else
  fail "Markdown: content lost"
fi
if echo "$OUTPUT" | grep -q "rank:"; then
  pass "Markdown: rank score in output"
else
  fail "Markdown: rank missing"
fi

# ─── JSON query ──────────────────────────────────────────────────────
JSON_OUT=$(bash .dexCore/core/knowledge/l2/l2-query.sh --db "$FIXTURE_DB" --format json "workspace" 2>&1)
# Validate it parses as JSON
if echo "$JSON_OUT" | ruby -rjson -e 'JSON.parse(STDIN.read)' 2>/dev/null; then
  pass "JSON: valid parseable JSON output"
else
  fail "JSON: malformed output"
fi
# Check structure
if echo "$JSON_OUT" | ruby -rjson -e '
  d = JSON.parse(STDIN.read)
  exit(1) unless d.is_a?(Hash) && d.key?("query") && d.key?("results") && d["results"].is_a?(Array)
' 2>/dev/null; then
  pass "JSON: has expected shape {query, results[]}"
else
  fail "JSON: unexpected shape"
fi
# Content preserved (note: "Workspace" has capital W in source; FTS porter stemmer matches "workspace")
if echo "$JSON_OUT" | grep -q "working directory"; then
  pass "JSON: content text preserved"
else
  fail "JSON: content text missing"
fi

# ─── --top N limits results ──────────────────────────────────────────
TOP_OUT=$(bash .dexCore/core/knowledge/l2/l2-query.sh --db "$FIXTURE_DB" --top 1 --format json "decision" 2>&1)
TOP_COUNT=$(echo "$TOP_OUT" | ruby -rjson -e 'puts JSON.parse(STDIN.read)["results"].length' 2>/dev/null || echo "?")
if [ "$TOP_COUNT" = "1" ]; then
  pass "--top 1 returns exactly 1 result"
else
  fail "--top 1 returned $TOP_COUNT results"
fi

# ─── --source-type filter ────────────────────────────────────────────
# All fixture chunks are source_type=ingest (temp path). Filtering
# --source-type wiki should return 0.
FILTER_OUT=$(bash .dexCore/core/knowledge/l2/l2-query.sh --db "$FIXTURE_DB" --source-type wiki --format json "decision" 2>&1)
FILTER_COUNT=$(echo "$FILTER_OUT" | ruby -rjson -e 'puts JSON.parse(STDIN.read)["results"].length' 2>/dev/null || echo "?")
if [ "$FILTER_COUNT" = "0" ]; then
  pass "--source-type wiki excludes non-wiki chunks"
else
  fail "--source-type filter let through $FILTER_COUNT chunks"
fi

# With --source-type ingest, should match
FILTER2_OUT=$(bash .dexCore/core/knowledge/l2/l2-query.sh --db "$FIXTURE_DB" --source-type ingest --format json "decision" 2>&1)
FILTER2_COUNT=$(echo "$FILTER2_OUT" | ruby -rjson -e 'puts JSON.parse(STDIN.read)["results"].length' 2>/dev/null || echo 0)
if [ "$FILTER2_COUNT" -ge 1 ]; then
  pass "--source-type ingest includes ingest chunks ($FILTER2_COUNT)"
else
  fail "--source-type ingest returned 0"
fi

# ─── No-match graceful ───────────────────────────────────────────────
NOMATCH_OUT=$(bash .dexCore/core/knowledge/l2/l2-query.sh --db "$FIXTURE_DB" "nonexistentkeywordxyz" 2>&1)
if echo "$NOMATCH_OUT" | grep -q "No matches"; then
  pass "No-match case shows 'No matches' notice"
else
  fail "No-match case did not show notice" "got: ${NOMATCH_OUT:0:200}"
fi

# ─── Empty-tank graceful ─────────────────────────────────────────────
EMPTY_DB=$(mktemp -u -t dexhub-l2-empty-XXXXXX).sqlite
bash .dexCore/core/knowledge/l2/l2-init.sh --db "$EMPTY_DB" >/dev/null
EMPTY_OUT=$(bash .dexCore/core/knowledge/l2/l2-query.sh --db "$EMPTY_DB" "anything" 2>&1)
if echo "$EMPTY_OUT" | grep -qi "empty"; then
  pass "Empty-tank case shows 'empty' notice"
else
  fail "Empty-tank case unexpected: ${EMPTY_OUT:0:200}"
fi
rm -f "$EMPTY_DB" "${EMPTY_DB}-wal" "${EMPTY_DB}-shm"

# ─── Missing-tank graceful (no error, just notice) ───────────────────
MISSING_OUT=$(bash .dexCore/core/knowledge/l2/l2-query.sh --db "/tmp/nonexistent-path-${RANDOM}.sqlite" "anything" 2>&1)
if echo "$MISSING_OUT" | grep -qi "not initialized"; then
  pass "Missing-tank case shows 'not initialized' notice"
else
  fail "Missing-tank case unexpected: ${MISSING_OUT:0:200}"
fi

# ─── Newline preservation in content ─────────────────────────────────
# Our fixture has multi-line sections; ensure the query for a term
# like "Beta ships" (which is on line 1 of the "Decision: platform priority"
# section) returns that section with its content intact.
MULTI_OUT=$(bash .dexCore/core/knowledge/l2/l2-query.sh --db "$FIXTURE_DB" --format json "Beta" 2>&1)
CONTENT=$(echo "$MULTI_OUT" | ruby -rjson -e '
  d = JSON.parse(STDIN.read)
  puts d["results"].first["content"] if d["results"].any?
' 2>/dev/null)
if echo "$CONTENT" | grep -q "Claude Code is an integration module"; then
  pass "Multi-line content preserved in JSON output"
else
  fail "Multi-line content truncated or missing"
fi

# ─── features.yaml reflects promotion ───────────────────────────────
if grep -A 10 "id: knowledge.l2_tank_query" .dexCore/_cfg/features.yaml | grep -qE "^    status: enabled"; then
  pass "features.yaml: l2_tank_query flipped experimental → enabled"
else
  fail "features.yaml: l2_tank_query status not yet 'enabled'"
fi

test_summary
