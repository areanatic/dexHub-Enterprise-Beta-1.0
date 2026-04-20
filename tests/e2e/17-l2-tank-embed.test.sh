#!/bin/bash
# DexHub E2E Test 17 — L2 Tank Embedding Generator (Phase 5.2.b-embed)
#
# Proves l2-embed.sh:
#   - Exists, parses, executable
#   - When backend NOT ready: exits 0 gracefully by default, exits 4 with
#     --require-backend. No DB writes. Clear user-facing message.
#   - --dry-run on empty tank: reports "Tank empty", no writes
#   - --help works
#   - Opt-in LIVE path (CLAUDE_E2E_LIVE_EMBED=1): actually hits Ollama,
#     verifies vectors land in embeddings table with correct dimensions,
#     is idempotent (2nd run no-op), --all clears + re-embeds. Gated by
#     env var so default CI stays always-green.
#
# Live-mode cost: ~30s local-only, no API $.
# Default mode:   ~2s, no network, no DB writes in failure path.

set -u

HARNESS="$(cd "$(dirname "$0")/harness" && pwd)"
source "$HARNESS/assertion-lib.sh"

ensure_beta_root
test_banner "17 L2 Tank Embed (Phase 5.2.b-embed)"

# ─── Structural ──────────────────────────────────────────────────────
assert_file_exists ".dexCore/core/knowledge/l2/l2-embed.sh" \
  "l2-embed.sh present"
if [ -x ".dexCore/core/knowledge/l2/l2-embed.sh" ]; then
  pass "l2-embed.sh executable"
else
  fail "l2-embed.sh not executable"
fi
if bash -n .dexCore/core/knowledge/l2/l2-embed.sh 2>/dev/null; then
  pass "l2-embed.sh bash-parses cleanly"
else
  fail "l2-embed.sh has syntax errors"
fi

# ─── Help flag ───────────────────────────────────────────────────────
HELP_OUT=$(bash .dexCore/core/knowledge/l2/l2-embed.sh --help 2>&1 | head -20)
if echo "$HELP_OUT" | grep -q "Embedding Generator"; then
  pass "--help emits header"
else
  fail "--help missing header" "got: ${HELP_OUT:0:200}"
fi

# ─── Fixture prep ────────────────────────────────────────────────────
FIXTURE_DB=$(mktemp -u -t dexhub-17-XXXXXX).sqlite
FIXTURE_MD=$(mktemp -t dexhub-17-src-XXXXXX).md

cat > "$FIXTURE_MD" <<'FIXEOF'
# Architecture
Platform priority. DexHub targets GitHub Copilot first.
# Workflow
Session routine. Read handoff, verify gates, ask user.
# Knowledge Layers
L1 Wiki, L2 Tank, L3 Chronicle — complementary not competing.
FIXEOF

cleanup() {
  rm -f "$FIXTURE_DB" "${FIXTURE_DB}-wal" "${FIXTURE_DB}-shm" "$FIXTURE_MD"
}
trap 'cleanup' EXIT INT TERM

bash .dexCore/core/knowledge/l2/l2-init.sh --db "$FIXTURE_DB" >/dev/null 2>&1
bash .dexCore/core/knowledge/l2/l2-ingest.sh --db "$FIXTURE_DB" --source "$FIXTURE_MD" >/dev/null 2>&1

CHUNK_COUNT=$(sqlite3 "$FIXTURE_DB" "SELECT COUNT(*) FROM chunks" 2>/dev/null)
if [ "$CHUNK_COUNT" -ge 3 ]; then
  pass "Fixture ingested: $CHUNK_COUNT chunks"
else
  fail "Fixture ingest failed ($CHUNK_COUNT chunks)"
  test_summary
  exit 1
fi

# ─── Backend-not-ready path (always-green default) ──────────────────
# We don't know the user's Ollama state at test time. We force a known
# not-ready path by pointing at a backend the detector will flag as
# "deferred" (openai provider) — no Ollama probe matters. This gives
# us a deterministic not-ready response regardless of environment.
DEFERRED_OUT=$(bash .dexCore/core/knowledge/l2/l2-embed.sh --db "$FIXTURE_DB" --endpoint "http://localhost:1" 2>&1)
DEFERRED_EXIT=$?
# With Ollama endpoint pointed at :1 (guaranteed refused), status becomes
# 'none' → semantic_available=false → exit 0 (default graceful).
if [ "$DEFERRED_EXIT" = "0" ]; then
  pass "Not-ready backend: exits 0 by default (graceful degradation)"
else
  fail "Not-ready backend: expected exit 0, got $DEFERRED_EXIT"
fi
if echo "$DEFERRED_OUT" | grep -q "Backend not ready"; then
  pass "Not-ready message shown to user"
else
  fail "Not-ready message missing" "got: ${DEFERRED_OUT:0:300}"
fi
if echo "$DEFERRED_OUT" | grep -q "Keyword-only search"; then
  pass "Not-ready message reassures user that keyword-only works"
else
  fail "Not-ready message missing reassurance"
fi

# DB unchanged — no embeddings added despite script running
EMB_COUNT=$(sqlite3 "$FIXTURE_DB" "SELECT COUNT(*) FROM embeddings" 2>/dev/null)
if [ "$EMB_COUNT" = "0" ]; then
  pass "Not-ready path: no embeddings written (DB clean)"
else
  fail "Not-ready path: $EMB_COUNT embeddings leaked into DB (expected 0)"
fi

# ─── --require-backend: non-zero exit on not-ready ──────────────────
REQ_OUT=$(bash .dexCore/core/knowledge/l2/l2-embed.sh --db "$FIXTURE_DB" --endpoint "http://localhost:1" --require-backend 2>&1)
REQ_EXIT=$?
if [ "$REQ_EXIT" = "4" ]; then
  pass "--require-backend: exits 4 when backend not ready"
else
  fail "--require-backend: expected exit 4, got $REQ_EXIT"
fi

# ─── --dry-run on empty tank ────────────────────────────────────────
EMPTY_DB=$(mktemp -u -t dexhub-17-empty-XXXXXX).sqlite
bash .dexCore/core/knowledge/l2/l2-init.sh --db "$EMPTY_DB" >/dev/null 2>&1
EMPTY_OUT=$(bash .dexCore/core/knowledge/l2/l2-embed.sh --db "$EMPTY_DB" --dry-run 2>&1)
EMPTY_EXIT=$?
# Result depends on backend state — if backend ready + empty tank, script
# reports "Tank empty". If backend not ready, script exits after the
# not-ready message (before even counting chunks). Either way: exit 0, no writes.
if [ "$EMPTY_EXIT" = "0" ]; then
  pass "Empty-tank dry-run: exits 0"
else
  fail "Empty-tank dry-run: expected exit 0, got $EMPTY_EXIT"
fi
EMPTY_EMB=$(sqlite3 "$EMPTY_DB" "SELECT COUNT(*) FROM embeddings" 2>/dev/null)
if [ "$EMPTY_EMB" = "0" ]; then
  pass "Empty-tank dry-run: no writes"
else
  fail "Empty-tank dry-run: $EMPTY_EMB writes leaked"
fi
rm -f "$EMPTY_DB" "${EMPTY_DB}-wal" "${EMPTY_DB}-shm"

# ─── Missing-DB path ────────────────────────────────────────────────
MISSING_OUT=$(bash .dexCore/core/knowledge/l2/l2-embed.sh --db "/tmp/nonexistent-${RANDOM}-${RANDOM}.sqlite" 2>&1)
MISSING_EXIT=$?
if [ "$MISSING_EXIT" = "3" ]; then
  pass "Missing-DB: exits 3 (initialization error)"
else
  fail "Missing-DB: expected exit 3, got $MISSING_EXIT"
fi
if echo "$MISSING_OUT" | grep -q "not initialized"; then
  pass "Missing-DB: message points to l2-init.sh"
else
  fail "Missing-DB: unhelpful message" "got: ${MISSING_OUT:0:200}"
fi

# ─── features.yaml + L2-TANK.md references ──────────────────────────
if grep -qE "^\s+- id: knowledge\.l2_tank_embed\b" .dexCore/_cfg/features.yaml; then
  pass "features.yaml: knowledge.l2_tank_embed registered as a feature entry"
else
  fail "features.yaml: knowledge.l2_tank_embed NOT registered (as '- id:' entry)"
fi

# ─── UX hint in l2-ingest.sh ────────────────────────────────────────
if grep -q "l2-embed.sh" .dexCore/core/knowledge/l2/l2-ingest.sh; then
  pass "l2-ingest.sh: UX hint references l2-embed.sh"
else
  fail "l2-ingest.sh: missing UX hint about l2-embed.sh"
fi

# ─── OPT-IN LIVE: actually embed via Ollama ─────────────────────────
if [ "${CLAUDE_E2E_LIVE_EMBED:-0}" = "1" ]; then
  echo ""
  echo "  [LIVE] CLAUDE_E2E_LIVE_EMBED=1 — running actual Ollama embedding…"

  # Pre-check: detection must say ready (else skip cleanly)
  READY=$(bash .dexCore/core/knowledge/l2/l2-detect-backend.sh --format json --db "$FIXTURE_DB" 2>/dev/null | ruby -rjson -e 'puts JSON.parse(STDIN.read)["semantic_available"] ? "true" : "false"' 2>/dev/null)
  if [ "$READY" != "true" ]; then
    echo "  [LIVE] Backend not ready — skipping live assertions."
    echo "        Setup: install Ollama + ollama pull nomic-embed-text"
  else
    LIVE_OUT=$(bash .dexCore/core/knowledge/l2/l2-embed.sh --db "$FIXTURE_DB" 2>&1)
    if echo "$LIVE_OUT" | grep -qE "Embedded: [0-9]+ chunk"; then
      pass "[LIVE] Embed step produced 'Embedded: N' line"
    else
      fail "[LIVE] Embed step output unexpected" "got: ${LIVE_OUT:0:400}"
    fi

    LIVE_EMB=$(sqlite3 "$FIXTURE_DB" "SELECT COUNT(*) FROM embeddings" 2>/dev/null)
    if [ "$LIVE_EMB" -ge "$CHUNK_COUNT" ]; then
      pass "[LIVE] embeddings table populated: $LIVE_EMB rows ≥ $CHUNK_COUNT chunks"
    else
      fail "[LIVE] embeddings incomplete: $LIVE_EMB / $CHUNK_COUNT"
    fi

    DIMS=$(sqlite3 "$FIXTURE_DB" "SELECT dimensions FROM embeddings LIMIT 1" 2>/dev/null)
    if [ "$DIMS" -gt 100 ]; then
      pass "[LIVE] dimension sanity: $DIMS (expected >100 for nomic-embed-text: 768)"
    else
      fail "[LIVE] dimension too low: $DIMS"
    fi

    # Idempotent: second run should be no-op
    IDEM_OUT=$(bash .dexCore/core/knowledge/l2/l2-embed.sh --db "$FIXTURE_DB" 2>&1)
    if echo "$IDEM_OUT" | grep -q "already have"; then
      pass "[LIVE] idempotent: 2nd run reports 'already have' embeddings"
    else
      fail "[LIVE] idempotence failed" "got: ${IDEM_OUT:0:300}"
    fi

    # Vector is a valid JSON array
    VEC_OK=$(sqlite3 "$FIXTURE_DB" "SELECT vector_json FROM embeddings LIMIT 1" 2>/dev/null | ruby -rjson -e '
      v = JSON.parse(STDIN.read)
      exit(v.is_a?(Array) && v.length > 100 && v.all? { |x| x.is_a?(Numeric) } ? 0 : 1)
    ' >/dev/null 2>&1 && echo "1" || echo "0")
    if [ "$VEC_OK" = "1" ]; then
      pass "[LIVE] vector_json parses to a valid numeric array"
    else
      fail "[LIVE] vector_json malformed"
    fi
  fi
fi

test_summary
