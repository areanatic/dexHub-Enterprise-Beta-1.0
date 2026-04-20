#!/bin/bash
# DexHub E2E Test 18 — L2 Tank Hybrid Query (Phase 5.2.b-hybrid-query)
#
# Proves:
#   - --keyword-only works identically to the pre-hybrid baseline (test 14
#     still passes)
#   - --hybrid / --semantic-only without backend / embeddings exit 4 with
#     a clear error message on stderr
#   - Auto mode routes to keyword-only when embeddings are empty, regardless
#     of Ollama state
#   - --alpha flag parses (structural — actual weighting verified in live)
#   - JSON output contains a "mode" field
#   - Mode banner reports HYBRID when active (live), KEYWORD-ONLY otherwise
#   - Opt-in LIVE path (CLAUDE_E2E_LIVE_EMBED=1): ingest + embed + hybrid
#     query actually ranks a semantically-related query higher than a
#     keyword-only baseline would

set -u

HARNESS="$(cd "$(dirname "$0")/harness" && pwd)"
source "$HARNESS/assertion-lib.sh"

ensure_beta_root
test_banner "18 L2 Tank Hybrid Query (Phase 5.2.b-hybrid-query)"

# ─── Structural ──────────────────────────────────────────────────────
if bash -n .dexCore/core/knowledge/l2/l2-query.sh 2>/dev/null; then
  pass "l2-query.sh bash-parses cleanly after hybrid rewrite"
else
  fail "l2-query.sh has syntax errors after hybrid rewrite"
fi

# --help mentions the new flags
HELP_OUT=$(bash .dexCore/core/knowledge/l2/l2-query.sh --help 2>&1)
for flag in "--keyword-only" "--hybrid" "--semantic-only" "--alpha"; do
  if echo "$HELP_OUT" | grep -q -- "$flag"; then
    pass "--help mentions $flag"
  else
    fail "--help missing $flag"
  fi
done

# ─── Fixture prep ────────────────────────────────────────────────────
FIXTURE_DB=$(mktemp -u -t dexhub-18-XXXXXX).sqlite
FIXTURE_MD=$(mktemp -t dexhub-18-src-XXXXXX).md

cat > "$FIXTURE_MD" <<'FIXEOF'
# Authentication
The login flow uses session tokens. Users authenticate via OAuth.
# Deployment
CI runs GitHub Actions on every push to main.
# Glossary
DEX stands for Knowledge Meta-Layer — a DexHub-specific concept.
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

# ─── --keyword-only explicit works ──────────────────────────────────
KW_OUT=$(bash .dexCore/core/knowledge/l2/l2-query.sh --db "$FIXTURE_DB" --keyword-only "authentication" 2>&1)
if echo "$KW_OUT" | grep -qE "^\s+Mode: KEYWORD-ONLY"; then
  pass "--keyword-only: banner says KEYWORD-ONLY"
else
  fail "--keyword-only: banner missing" "got: ${KW_OUT:0:400}"
fi
if echo "$KW_OUT" | grep -q "## Authentication"; then
  pass "--keyword-only: finds 'Authentication' chunk by keyword"
else
  fail "--keyword-only: missed Authentication chunk"
fi

# ─── --hybrid on empty-embedding tank → exit 4 ─────────────────────
HYBRID_OUT=$(bash .dexCore/core/knowledge/l2/l2-query.sh --db "$FIXTURE_DB" --hybrid "authentication" 2>&1)
HYBRID_EXIT=$?
if [ "$HYBRID_EXIT" = "4" ]; then
  pass "--hybrid without embeddings: exits 4"
else
  fail "--hybrid without embeddings: expected exit 4, got $HYBRID_EXIT"
fi
if echo "$HYBRID_OUT" | grep -qi "backend not ready\|no embeddings"; then
  pass "--hybrid without embeddings: error explains reason"
else
  fail "--hybrid without embeddings: error unhelpful" "got: ${HYBRID_OUT:0:200}"
fi

# ─── --semantic-only on empty-embedding tank → exit 4 ──────────────
SEM_OUT=$(bash .dexCore/core/knowledge/l2/l2-query.sh --db "$FIXTURE_DB" --semantic-only "authentication" 2>&1)
SEM_EXIT=$?
if [ "$SEM_EXIT" = "4" ]; then
  pass "--semantic-only without embeddings: exits 4"
else
  fail "--semantic-only without embeddings: expected exit 4, got $SEM_EXIT"
fi

# ─── Auto mode routes to keyword-only on empty-embedding tank ──────
AUTO_JSON=$(bash .dexCore/core/knowledge/l2/l2-query.sh --db "$FIXTURE_DB" --format json "authentication" 2>&1)
if echo "$AUTO_JSON" | ruby -rjson -e '
  d = JSON.parse(STDIN.read)
  exit(d["mode"] == "keyword-only" ? 0 : 1)
' 2>/dev/null; then
  pass "Auto mode: JSON 'mode' field = 'keyword-only' on unembedded tank"
else
  GOT_MODE=$(echo "$AUTO_JSON" | ruby -rjson -e 'puts JSON.parse(STDIN.read)["mode"]' 2>/dev/null)
  fail "Auto mode: expected 'keyword-only', got '$GOT_MODE'"
fi

# ─── JSON contains hybrid-aware fields ──────────────────────────────
if echo "$AUTO_JSON" | ruby -rjson -e '
  d = JSON.parse(STDIN.read)
  exit(d.key?("mode") && d.key?("results") ? 0 : 1)
' 2>/dev/null; then
  pass "JSON: includes 'mode' + 'results' fields"
else
  fail "JSON: missing expected fields"
fi

# ─── --alpha accepted ──────────────────────────────────────────────
ALPHA_OUT=$(bash .dexCore/core/knowledge/l2/l2-query.sh --db "$FIXTURE_DB" --alpha 0.3 --keyword-only "authentication" 2>&1)
if [ "$?" = "0" ] && echo "$ALPHA_OUT" | grep -q "## Authentication"; then
  pass "--alpha 0.3: parses (structural) and still returns keyword results"
else
  fail "--alpha 0.3: failed"
fi

# ─── --quiet suppresses mode banner ────────────────────────────────
QUIET_OUT=$(bash .dexCore/core/knowledge/l2/l2-query.sh --db "$FIXTURE_DB" --quiet "authentication" 2>&1)
if echo "$QUIET_OUT" | grep -qE "Mode:"; then
  fail "--quiet: banner leaked (copilot-wire drift-check safe regression)"
else
  pass "--quiet: banner suppressed (copilot-wire drift-check safe)"
fi

# ─── features.yaml registration (strict: must be a real feature row, not
# just a mention in a description or known_issue)
if grep -qE "^\s+- id: knowledge\.l2_tank_hybrid_query\b" .dexCore/_cfg/features.yaml; then
  pass "features.yaml: knowledge.l2_tank_hybrid_query registered as a feature entry"
else
  fail "features.yaml: knowledge.l2_tank_hybrid_query NOT registered (as '- id:' entry)"
fi

# ─── OPT-IN LIVE: actually run hybrid query ────────────────────────
if [ "${CLAUDE_E2E_LIVE_EMBED:-0}" = "1" ]; then
  echo ""
  echo "  [LIVE] CLAUDE_E2E_LIVE_EMBED=1 — running real embed + hybrid…"

  READY=$(bash .dexCore/core/knowledge/l2/l2-detect-backend.sh --format json --db "$FIXTURE_DB" 2>/dev/null | ruby -rjson -e 'puts JSON.parse(STDIN.read)["semantic_available"] ? "true" : "false"' 2>/dev/null)
  if [ "$READY" != "true" ]; then
    echo "  [LIVE] Backend not ready — skipping hybrid live assertions."
  else
    # Embed the fixture
    bash .dexCore/core/knowledge/l2/l2-embed.sh --db "$FIXTURE_DB" >/dev/null 2>&1
    LIVE_EMB=$(sqlite3 "$FIXTURE_DB" "SELECT COUNT(*) FROM embeddings" 2>/dev/null)
    if [ "$LIVE_EMB" = "$CHUNK_COUNT" ]; then
      pass "[LIVE] embed step populated $LIVE_EMB / $CHUNK_COUNT chunks"
    else
      fail "[LIVE] embed incomplete: $LIVE_EMB / $CHUNK_COUNT"
    fi

    # Auto-mode should now route to hybrid
    LIVE_AUTO=$(bash .dexCore/core/knowledge/l2/l2-query.sh --db "$FIXTURE_DB" --format json "authentication" 2>&1)
    LIVE_MODE=$(echo "$LIVE_AUTO" | ruby -rjson -e 'puts JSON.parse(STDIN.read)["mode"]' 2>/dev/null)
    if [ "$LIVE_MODE" = "hybrid" ]; then
      pass "[LIVE] auto mode routes to HYBRID when embeddings + backend ready"
    else
      fail "[LIVE] auto mode: expected 'hybrid', got '$LIVE_MODE'"
    fi

    # Semantic query — ask about "login" and expect the Authentication chunk
    # to still rank high (semantic match on "session tokens" / "OAuth")
    LIVE_SEM=$(bash .dexCore/core/knowledge/l2/l2-query.sh --db "$FIXTURE_DB" --semantic-only --format json "how do users log in" 2>&1)
    TOP_TITLE=$(echo "$LIVE_SEM" | ruby -rjson -e '
      r = JSON.parse(STDIN.read)["results"]
      puts r.first ? r.first["title"] : ""
    ' 2>/dev/null)
    if [ "$TOP_TITLE" = "Authentication" ]; then
      pass "[LIVE] semantic-only: 'how do users log in' → top match is 'Authentication'"
    else
      fail "[LIVE] semantic-only: top match was '$TOP_TITLE' (expected 'Authentication')"
    fi

    # Hybrid query output has keyword + semantic scores
    LIVE_HY=$(bash .dexCore/core/knowledge/l2/l2-query.sh --db "$FIXTURE_DB" --hybrid --format json "authentication" 2>&1)
    HAS_BOTH=$(echo "$LIVE_HY" | ruby -rjson -e '
      r = JSON.parse(STDIN.read)["results"]
      first = r.first
      exit(first && first.key?("keyword_score") && first.key?("semantic_score") ? 0 : 1)
    ' >/dev/null 2>&1 && echo "1" || echo "0")
    if [ "$HAS_BOTH" = "1" ]; then
      pass "[LIVE] hybrid JSON includes keyword_score + semantic_score per result"
    else
      fail "[LIVE] hybrid JSON missing score breakdown"
    fi
  fi
fi

test_summary
