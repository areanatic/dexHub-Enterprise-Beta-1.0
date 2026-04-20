#!/bin/bash
# DexHub E2E Test 16 — L2 Tank Backend Detection (Phase 5.2.b-embed-detect)
#
# Proves the routing + graceful-degradation layer:
#   - l2-detect-backend.sh reports honest status without side effects
#   - Works regardless of whether Ollama is installed / running / has the model
#   - JSON output is valid + well-formed
#   - l2-status.sh dashboards tank state + backend status together
#   - l2-query.sh prints a Mode: banner that mentions KEYWORD-ONLY
#   - --quiet mode in l2-query.sh suppresses the banner (critical — build-
#     instructions.sh bakes query output into copilot-instructions.md and must
#     not have banner chrome in that path)
#   - No-Ollama simulation via PATH manipulation produces STATUS=NONE
#   - Cloud backend (openai/*) produces STATUS=DEFERRED with clear hint
#   - Policy=local_only + cloud backend produces STATUS=BLOCKED
#
# Fixture-based. No API cost. Always green regardless of user's Ollama state.

set -u

HARNESS="$(cd "$(dirname "$0")/harness" && pwd)"
source "$HARNESS/assertion-lib.sh"

ensure_beta_root
test_banner "16 L2 Tank Backend Detection (Phase 5.2.b-embed-detect)"

# ─── Structural ──────────────────────────────────────────────────────
assert_file_exists ".dexCore/core/knowledge/l2/l2-detect-backend.sh" \
  "l2-detect-backend.sh present"
assert_file_exists ".dexCore/core/knowledge/l2/l2-status.sh" \
  "l2-status.sh present"

if [ -x ".dexCore/core/knowledge/l2/l2-detect-backend.sh" ]; then
  pass "l2-detect-backend.sh executable"
else
  fail "l2-detect-backend.sh not executable"
fi
if [ -x ".dexCore/core/knowledge/l2/l2-status.sh" ]; then
  pass "l2-status.sh executable"
else
  fail "l2-status.sh not executable"
fi
if bash -n .dexCore/core/knowledge/l2/l2-detect-backend.sh 2>/dev/null; then
  pass "l2-detect-backend.sh bash-parses cleanly"
else
  fail "l2-detect-backend.sh has syntax errors"
fi
if bash -n .dexCore/core/knowledge/l2/l2-status.sh 2>/dev/null; then
  pass "l2-status.sh bash-parses cleanly"
else
  fail "l2-status.sh has syntax errors"
fi

# ─── Detection runs without error on this machine ───────────────────
DETECT_OUT=$(bash .dexCore/core/knowledge/l2/l2-detect-backend.sh 2>&1)
DETECT_EXIT=$?
if [ "$DETECT_EXIT" = "0" ]; then
  pass "l2-detect-backend.sh exits 0 (detection is informational, never errors)"
else
  fail "l2-detect-backend.sh exited non-zero ($DETECT_EXIT)"
fi

if echo "$DETECT_OUT" | grep -q "Backend Detection"; then
  pass "Detect text: human-readable header"
else
  fail "Detect text: missing header" "got: ${DETECT_OUT:0:200}"
fi
if echo "$DETECT_OUT" | grep -q "Keyword search (BM25) works regardless"; then
  pass "Detect text: reassures user that keyword-only always works"
else
  fail "Detect text: missing graceful-degradation reassurance"
fi

# ─── JSON output is valid + has all expected fields ─────────────────
JSON_OUT=$(bash .dexCore/core/knowledge/l2/l2-detect-backend.sh --format json 2>/dev/null)
if echo "$JSON_OUT" | ruby -rjson -e 'JSON.parse(STDIN.read)' 2>/dev/null; then
  pass "Detect JSON: valid parseable JSON"
else
  fail "Detect JSON: malformed"
fi
for field in backend provider model ollama_installed ollama_running model_pulled policy status semantic_available setup_hint; do
  if echo "$JSON_OUT" | grep -q "\"$field\""; then
    pass "Detect JSON: field '$field' present"
  else
    fail "Detect JSON: missing field '$field'"
  fi
done

# Status is one of the allowed values
STATUS=$(echo "$JSON_OUT" | ruby -rjson -e 'puts JSON.parse(STDIN.read)["status"]' 2>/dev/null)
case "$STATUS" in
  ready|partial|none|blocked|deferred)
    pass "Detect JSON: status '$STATUS' is valid"
    ;;
  *)
    fail "Detect JSON: unknown status '$STATUS'"
    ;;
esac

# ─── No-Ollama simulation via PATH manipulation ─────────────────────
# Strip /usr/local/bin + /opt/homebrew/bin + ~/.ollama from PATH so `command -v ollama`
# fails. Detection must still succeed and report STATUS=NONE.
NO_OLLAMA_JSON=$(env PATH="/usr/bin:/bin" bash .dexCore/core/knowledge/l2/l2-detect-backend.sh --format json 2>/dev/null)
NO_OLLAMA_STATUS=$(echo "$NO_OLLAMA_JSON" | ruby -rjson -e 'puts JSON.parse(STDIN.read)["status"]' 2>/dev/null)
NO_OLLAMA_HINT=$(echo "$NO_OLLAMA_JSON" | ruby -rjson -e 'puts JSON.parse(STDIN.read)["setup_hint"]' 2>/dev/null)
if [ "$NO_OLLAMA_STATUS" = "none" ]; then
  pass "No-Ollama simulation: status=none"
else
  fail "No-Ollama simulation: expected status=none, got '$NO_OLLAMA_STATUS'"
fi
if echo "$NO_OLLAMA_HINT" | grep -qi "install ollama"; then
  pass "No-Ollama simulation: hint mentions installing Ollama"
else
  fail "No-Ollama simulation: hint unhelpful" "got: $NO_OLLAMA_HINT"
fi

# ─── Cloud backend (openai) → DEFERRED with informative hint ────────
CLOUD_JSON=$(bash .dexCore/core/knowledge/l2/l2-detect-backend.sh --backend openai/text-embedding-3-small --format json 2>/dev/null)
CLOUD_STATUS=$(echo "$CLOUD_JSON" | ruby -rjson -e 'puts JSON.parse(STDIN.read)["status"]' 2>/dev/null)
if [ "$CLOUD_STATUS" = "deferred" ]; then
  pass "Cloud backend (openai): status=deferred (implementation pending)"
else
  fail "Cloud backend: expected deferred, got '$CLOUD_STATUS'"
fi

# ─── Policy=local_only + cloud backend → BLOCKED ────────────────────
# Synthesize a temp profile with local_only policy and point detection at it
# by temporarily renaming the real profile (we restore on exit). To avoid
# mutating user state, we instead stage a throwaway repo-root and cd there,
# making profile.yaml absent; the detect script falls through to "no profile"
# which treats policy as cloud_llm_allowed. So the better strategy is a
# direct-env override. We pick a cleaner path: inject policy via a temp
# HOME-ish redirect would require env knobs we don't have. Instead, test
# this by writing a synthetic profile into a scratch repo-root fixture.

SCRATCH_ROOT=$(mktemp -d -t dexhub-16-scratch-XXXXXX)
mkdir -p "$SCRATCH_ROOT/myDex/.dex/config"
cat > "$SCRATCH_ROOT/myDex/.dex/config/profile.yaml" <<EOF
version: "1.2"
profile:
  name: "test"
company:
  data_handling_policy: local_only
EOF
# Copy the detect script into the scratch repo so its REPO_ROOT resolves there
mkdir -p "$SCRATCH_ROOT/.dexCore/core/knowledge/l2"
cp .dexCore/core/knowledge/l2/l2-detect-backend.sh "$SCRATCH_ROOT/.dexCore/core/knowledge/l2/"
BLOCKED_JSON=$(bash "$SCRATCH_ROOT/.dexCore/core/knowledge/l2/l2-detect-backend.sh" --backend openai/text-embedding-3-small --format json 2>/dev/null)
BLOCKED_STATUS=$(echo "$BLOCKED_JSON" | ruby -rjson -e 'puts JSON.parse(STDIN.read)["status"]' 2>/dev/null)
BLOCKED_POLICY_OK=$(echo "$BLOCKED_JSON" | ruby -rjson -e 'puts JSON.parse(STDIN.read)["policy_ok"]' 2>/dev/null)
if [ "$BLOCKED_STATUS" = "blocked" ] && [ "$BLOCKED_POLICY_OK" = "false" ]; then
  pass "Policy=local_only + cloud backend: status=blocked, policy_ok=false"
else
  fail "Policy enforcement: status='$BLOCKED_STATUS', policy_ok='$BLOCKED_POLICY_OK' (expected blocked/false)"
fi
rm -rf "$SCRATCH_ROOT"

# ─── l2-status.sh on missing tank ───────────────────────────────────
STATUS_MISSING=$(bash .dexCore/core/knowledge/l2/l2-status.sh --db "/tmp/nonexistent-l2-status-${RANDOM}.sqlite" 2>&1)
if echo "$STATUS_MISSING" | grep -q "not initialized"; then
  pass "l2-status.sh handles missing tank gracefully"
else
  fail "l2-status.sh missing-tank output unexpected" "got: ${STATUS_MISSING:0:200}"
fi

# ─── l2-status.sh on populated tank ─────────────────────────────────
FIXTURE_DB=$(mktemp -u -t dexhub-16-db-XXXXXX).sqlite
FIXTURE_MD=$(mktemp -t dexhub-16-md-XXXXXX).md
cat > "$FIXTURE_MD" <<'FIXEOF'
# Architecture
Platform priority section.
# Workflow
Session routine.
FIXEOF

bash .dexCore/core/knowledge/l2/l2-init.sh --db "$FIXTURE_DB" >/dev/null 2>&1
bash .dexCore/core/knowledge/l2/l2-ingest.sh --db "$FIXTURE_DB" --source "$FIXTURE_MD" >/dev/null 2>&1

STATUS_JSON=$(bash .dexCore/core/knowledge/l2/l2-status.sh --db "$FIXTURE_DB" --format json 2>/dev/null)
if echo "$STATUS_JSON" | ruby -rjson -e 'JSON.parse(STDIN.read)' 2>/dev/null; then
  pass "l2-status.sh JSON: valid parseable JSON"
else
  fail "l2-status.sh JSON: malformed"
fi

for field in tank_exists chunks embeddings backend_status semantic_available query_mode; do
  if echo "$STATUS_JSON" | grep -q "\"$field\""; then
    pass "l2-status.sh JSON: field '$field' present"
  else
    fail "l2-status.sh JSON: missing field '$field'"
  fi
done

QUERY_MODE=$(echo "$STATUS_JSON" | ruby -rjson -e 'puts JSON.parse(STDIN.read)["query_mode"]' 2>/dev/null)
if echo "$QUERY_MODE" | grep -qi "keyword"; then
  pass "l2-status.sh: query_mode correctly reports KEYWORD-ONLY for unembedded tank"
else
  fail "l2-status.sh: unexpected query_mode '$QUERY_MODE'"
fi

# ─── l2-query.sh mode banner ────────────────────────────────────────
BANNER_OUT=$(bash .dexCore/core/knowledge/l2/l2-query.sh --db "$FIXTURE_DB" "architecture" 2>&1)
if echo "$BANNER_OUT" | grep -qE "^\s+Mode: KEYWORD-ONLY"; then
  pass "l2-query.sh: Mode: KEYWORD-ONLY banner shown to user"
else
  fail "l2-query.sh: banner missing" "got: ${BANNER_OUT:0:400}"
fi

# --quiet must suppress banner (copilot-wire critical path)
QUIET_OUT=$(bash .dexCore/core/knowledge/l2/l2-query.sh --db "$FIXTURE_DB" --quiet "architecture" 2>&1)
if echo "$QUIET_OUT" | grep -qE "Mode:"; then
  fail "l2-query.sh --quiet: banner leaked into quiet mode (would break copilot-wire drift check)"
else
  pass "l2-query.sh --quiet: banner suppressed (copilot-wire safe)"
fi

# ─── features.yaml references the new routing feature ──────────────
if grep -q "l2_tank_backend_routing" .dexCore/_cfg/features.yaml; then
  pass "features.yaml: knowledge.l2_tank_backend_routing registered"
else
  fail "features.yaml: knowledge.l2_tank_backend_routing NOT registered"
fi

# ─── User docs updated ──────────────────────────────────────────────
if grep -q "Two search modes" myDex/.dex/l2/README.md; then
  pass "L2 README: 'Two search modes' user-facing section present"
else
  fail "L2 README: missing user-facing search-modes explanation"
fi
if grep -q "minimal one" myDex/.dex/l2/README.md; then
  pass "L2 README: minimal-model routing explanation present"
else
  fail "L2 README: missing minimal-model guidance"
fi

# ─── Cleanup ────────────────────────────────────────────────────────
rm -f "$FIXTURE_DB" "${FIXTURE_DB}-wal" "${FIXTURE_DB}-shm" "$FIXTURE_MD"

test_summary
