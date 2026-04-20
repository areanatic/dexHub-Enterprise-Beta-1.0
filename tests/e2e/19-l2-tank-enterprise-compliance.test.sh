#!/bin/bash
# DexHub E2E Test 19 — L2 Tank Enterprise Compliance (Phase 5.2.b-enterprise-audit)
#
# Proves policy enforcement in l2-embed.sh + l2-query.sh:
#   - Scratch-repo fixture with data_handling_policy=local_only and a
#     cloud backend configured → both scripts refuse the operation
#     with a policy-specific error (not the generic "not ready").
#   - l2-embed.sh writes an ingest_runs 'POLICY-BLOCK' audit row on
#     every policy-block encounter — trail is persistent.
#   - l2-query.sh --hybrid / --semantic-only exit 4 with message
#     mentioning policy + backend.
#   - Local backend (ollama/*) passes the policy gate even when
#     policy=local_only.
#   - Default scratch (no policy set / cloud_llm_allowed) does NOT
#     trigger the policy block.

set -u

HARNESS="$(cd "$(dirname "$0")/harness" && pwd)"
source "$HARNESS/assertion-lib.sh"

ensure_beta_root
test_banner "19 L2 Tank Enterprise Compliance (Phase 5.2.b-enterprise-audit)"

# ─── features.yaml: compliance entry flipped to enabled ─────────────
if grep -qE "^\s+- id: knowledge\.l2_tank_enterprise_compliance\b" .dexCore/_cfg/features.yaml; then
  pass "features.yaml: knowledge.l2_tank_enterprise_compliance registered"
else
  fail "features.yaml: entry missing"
fi
# Extract status for that feature — must be 'enabled', not 'deferred'
STATUS_LINE=$(grep -A 5 -e "- id: knowledge\.l2_tank_enterprise_compliance" .dexCore/_cfg/features.yaml | grep -m1 "status:" | tr -d ' ')
if echo "$STATUS_LINE" | grep -q "^status:enabled"; then
  pass "features.yaml: compliance status=enabled (flipped from deferred)"
else
  fail "features.yaml: compliance status unexpected ($STATUS_LINE)"
fi

# ─── Scratch repo with local_only policy + cloud backend ────────────
SCRATCH=$(mktemp -d -t dexhub-19-scratch-XXXXXX)
mkdir -p "$SCRATCH/myDex/.dex/config" "$SCRATCH/myDex/.dex/l2" "$SCRATCH/.dexCore/core/knowledge/l2"

cat > "$SCRATCH/myDex/.dex/config/profile.yaml" <<EOF
version: "1.2"
profile:
  name: "enterprise-test"
company:
  data_handling_policy: local_only
EOF

# Copy just the L2 knowledge scripts into the scratch so REPO_ROOT resolves
# there (they walk ../../../../ from their own dir)
for f in l2-detect-backend.sh l2-init.sh l2-ingest.sh l2-embed.sh l2-query.sh l2-chunker.awk l2-status.sh schema.sql; do
  cp ".dexCore/core/knowledge/l2/$f" "$SCRATCH/.dexCore/core/knowledge/l2/"
done

cleanup() {
  rm -rf "$SCRATCH"
}
trap 'cleanup' EXIT INT TERM

# Init tank inside scratch
SCRATCH_DB="$SCRATCH/myDex/.dex/l2/tank.sqlite"
bash "$SCRATCH/.dexCore/core/knowledge/l2/l2-init.sh" --db "$SCRATCH_DB" >/dev/null 2>&1

# Set backend to openai in the DB's meta table
sqlite3 "$SCRATCH_DB" "UPDATE meta SET value='openai/text-embedding-3-small' WHERE key='default_embedding_backend'" 2>/dev/null

# Detect must say BLOCKED
BLOCKED_JSON=$(bash "$SCRATCH/.dexCore/core/knowledge/l2/l2-detect-backend.sh" --db "$SCRATCH_DB" --format json 2>/dev/null)
STATUS=$(echo "$BLOCKED_JSON" | ruby -rjson -e 'puts JSON.parse(STDIN.read)["status"]' 2>/dev/null)
if [ "$STATUS" = "blocked" ]; then
  pass "Detect: local_only + openai → status=blocked"
else
  fail "Detect: expected blocked, got '$STATUS'"
fi

# ─── l2-embed.sh under policy block ─────────────────────────────────
EMBED_OUT=$(bash "$SCRATCH/.dexCore/core/knowledge/l2/l2-embed.sh" --db "$SCRATCH_DB" 2>&1)
EMBED_EXIT=$?
if [ "$EMBED_EXIT" = "0" ]; then
  pass "l2-embed.sh: graceful exit 0 on policy block (default behavior)"
else
  fail "l2-embed.sh: expected exit 0, got $EMBED_EXIT"
fi
if echo "$EMBED_OUT" | grep -q "BLOCKED by enterprise policy"; then
  pass "l2-embed.sh: message explicitly mentions policy block"
else
  fail "l2-embed.sh: policy-specific message missing" "got: ${EMBED_OUT:0:400}"
fi
if echo "$EMBED_OUT" | grep -q "data_handling_policy=local_only"; then
  pass "l2-embed.sh: names the active policy"
else
  fail "l2-embed.sh: doesn't name active policy"
fi

# Audit row written to ingest_runs
AUDIT_ROW=$(sqlite3 "$SCRATCH_DB" "SELECT notes FROM ingest_runs WHERE notes LIKE 'POLICY-BLOCK:%' ORDER BY id DESC LIMIT 1" 2>/dev/null)
if [ -n "$AUDIT_ROW" ]; then
  pass "l2-embed.sh: POLICY-BLOCK audit row written to ingest_runs"
else
  fail "l2-embed.sh: no audit row for policy block"
fi

# --require-backend: exit 4 on policy block
REQ_OUT=$(bash "$SCRATCH/.dexCore/core/knowledge/l2/l2-embed.sh" --db "$SCRATCH_DB" --require-backend 2>&1)
REQ_EXIT=$?
if [ "$REQ_EXIT" = "4" ]; then
  pass "l2-embed.sh --require-backend: exit 4 on policy block"
else
  fail "l2-embed.sh --require-backend: expected 4, got $REQ_EXIT"
fi

# ─── l2-query.sh --hybrid / --semantic-only under policy block ──────
# Need a chunk in the scratch tank for the query layer to reach the mode-decision stage
SCRATCH_MD=$(mktemp -t dexhub-19-md-XXXXXX).md
printf "# Compliance\nPolicy-first.\n" > "$SCRATCH_MD"
bash "$SCRATCH/.dexCore/core/knowledge/l2/l2-ingest.sh" --db "$SCRATCH_DB" --source "$SCRATCH_MD" >/dev/null 2>&1
rm -f "$SCRATCH_MD"

Q_HYBRID_OUT=$(bash "$SCRATCH/.dexCore/core/knowledge/l2/l2-query.sh" --db "$SCRATCH_DB" --hybrid "compliance" 2>&1)
Q_HYBRID_EXIT=$?
if [ "$Q_HYBRID_EXIT" = "4" ]; then
  pass "l2-query.sh --hybrid: exit 4 under policy block"
else
  fail "l2-query.sh --hybrid: expected exit 4, got $Q_HYBRID_EXIT"
fi
if echo "$Q_HYBRID_OUT" | grep -qi "BLOCKED"; then
  pass "l2-query.sh --hybrid: message mentions BLOCKED"
else
  fail "l2-query.sh --hybrid: unhelpful error" "got: ${Q_HYBRID_OUT:0:300}"
fi

Q_SEM_OUT=$(bash "$SCRATCH/.dexCore/core/knowledge/l2/l2-query.sh" --db "$SCRATCH_DB" --semantic-only "compliance" 2>&1)
Q_SEM_EXIT=$?
if [ "$Q_SEM_EXIT" = "4" ]; then
  pass "l2-query.sh --semantic-only: exit 4 under policy block"
else
  fail "l2-query.sh --semantic-only: expected exit 4, got $Q_SEM_EXIT"
fi

# Auto mode should still work (falls back to keyword-only)
AUTO_OUT=$(bash "$SCRATCH/.dexCore/core/knowledge/l2/l2-query.sh" --db "$SCRATCH_DB" "compliance" 2>&1)
AUTO_EXIT=$?
if [ "$AUTO_EXIT" = "0" ]; then
  pass "l2-query.sh auto: falls back to keyword-only under policy block (exit 0)"
else
  fail "l2-query.sh auto: expected exit 0, got $AUTO_EXIT"
fi

# ─── Local backend passes policy gate ───────────────────────────────
# Switch back to ollama/*, re-check detect — should NOT be blocked
sqlite3 "$SCRATCH_DB" "UPDATE meta SET value='ollama/nomic-embed-text' WHERE key='default_embedding_backend'" 2>/dev/null
LOCAL_JSON=$(bash "$SCRATCH/.dexCore/core/knowledge/l2/l2-detect-backend.sh" --db "$SCRATCH_DB" --format json 2>/dev/null)
LOCAL_STATUS=$(echo "$LOCAL_JSON" | ruby -rjson -e 'puts JSON.parse(STDIN.read)["status"]' 2>/dev/null)
LOCAL_POLICY_OK=$(echo "$LOCAL_JSON" | ruby -rjson -e 'puts JSON.parse(STDIN.read)["policy_ok"]' 2>/dev/null)
if [ "$LOCAL_POLICY_OK" = "true" ] && [ "$LOCAL_STATUS" != "blocked" ]; then
  pass "Local backend under local_only: passes policy gate (status=$LOCAL_STATUS, policy_ok=true)"
else
  fail "Local backend: unexpected detection (status=$LOCAL_STATUS, policy_ok=$LOCAL_POLICY_OK)"
fi

# ─── Default (cloud_llm_allowed) does NOT trigger block ────────────
cat > "$SCRATCH/myDex/.dex/config/profile.yaml" <<EOF
version: "1.2"
profile:
  name: "allowed-test"
company:
  data_handling_policy: cloud_llm_allowed
EOF
sqlite3 "$SCRATCH_DB" "UPDATE meta SET value='openai/text-embedding-3-small' WHERE key='default_embedding_backend'" 2>/dev/null
ALLOW_JSON=$(bash "$SCRATCH/.dexCore/core/knowledge/l2/l2-detect-backend.sh" --db "$SCRATCH_DB" --format json 2>/dev/null)
ALLOW_POLICY_OK=$(echo "$ALLOW_JSON" | ruby -rjson -e 'puts JSON.parse(STDIN.read)["policy_ok"]' 2>/dev/null)
if [ "$ALLOW_POLICY_OK" = "true" ]; then
  pass "Cloud backend under cloud_llm_allowed: policy_ok=true (no block)"
else
  fail "Cloud backend + cloud_llm_allowed: unexpected policy_ok=$ALLOW_POLICY_OK"
fi

test_summary
