#!/bin/bash
# DexHub E2E Test 21 — Agent Packs (Phase 5.1.d first slice)
#
# Proves agents.user_toggle_menu + agents.meta_pack + agents.onboarding_pack:
#   - packs.sh exists, parses, has --help
#   - 3 manifests ship in-repo (core_pack, meta_pack, onboarding_pack)
#   - Each manifest has required fields: pack_id, name, description,
#     default_state, mandatory, compliance, version, agents[]
#   - `list` prints all 3 packs + their effective state (text + JSON)
#   - `status <pack>` returns pack detail (text + JSON)
#   - `enable <pack>` creates state file + adds pack to enabled list
#   - `disable <pack>` moves pack to disabled list
#   - `disable core_pack` REFUSES (mandatory packs protected, exit 1)
#   - State file round-trips: enable → disable flips the list correctly
#   - Manifest-referenced agent files exist (core + meta-agents)
#   - packs.yaml.example template ships in-repo
#   - features.yaml: agents.user_toggle_menu + agents.meta_pack +
#     agents.onboarding_pack flipped from deferred to enabled

set -u

HARNESS="$(cd "$(dirname "$0")/harness" && pwd)"
source "$HARNESS/assertion-lib.sh"

ensure_beta_root
test_banner "21 Agent Packs (Phase 5.1.d first slice)"

# ─── Structural presence ────────────────────────────────────────────
assert_file_exists ".dexCore/core/agents/packs.sh" "packs.sh present"
assert_file_exists ".dexCore/core/agents/packs/core_pack.yaml" "core_pack manifest present"
assert_file_exists ".dexCore/core/agents/packs/meta_pack.yaml" "meta_pack manifest present"
assert_file_exists ".dexCore/core/agents/packs/onboarding_pack.yaml" "onboarding_pack manifest present"
assert_file_exists "myDex/.dex/config/packs.yaml.example" "packs.yaml.example template shipped"

if [ -x ".dexCore/core/agents/packs.sh" ]; then pass "packs.sh executable"; else fail "packs.sh not executable"; fi
if bash -n .dexCore/core/agents/packs.sh 2>/dev/null; then
  pass "packs.sh bash-parses cleanly"
else
  fail "packs.sh has syntax errors"
fi

HELP_OUT=$(bash .dexCore/core/agents/packs.sh --help 2>&1)
if echo "$HELP_OUT" | grep -q "Agent Packs"; then
  pass "--help emits header"
else
  fail "--help missing header"
fi

# ─── Manifest required fields ───────────────────────────────────────
for pack in core_pack meta_pack onboarding_pack; do
  file=".dexCore/core/agents/packs/${pack}.yaml"
  for field in pack_id name description default_state mandatory compliance version agents; do
    if grep -qE "^${field}:" "$file"; then
      pass "$pack: field '$field' present"
    else
      fail "$pack: missing field '$field'"
    fi
  done
done

# ─── list output (text) ─────────────────────────────────────────────
LIST_OUT=$(bash .dexCore/core/agents/packs.sh list 2>&1)
for pack in core_pack meta_pack onboarding_pack; do
  if echo "$LIST_OUT" | grep -q "^${pack}"; then
    pass "list shows $pack"
  else
    fail "list missing $pack" "got: $LIST_OUT"
  fi
done
# core_pack shows as always_on (because mandatory=true)
if echo "$LIST_OUT" | grep -E "^core_pack\s+always_on" > /dev/null; then
  pass "list: core_pack shown as always_on (mandatory)"
else
  fail "list: core_pack state wrong"
fi

# ─── list --format json ─────────────────────────────────────────────
LIST_JSON=$(bash .dexCore/core/agents/packs.sh list --format json 2>&1)
if echo "$LIST_JSON" | ruby -rjson -e '
  arr = JSON.parse(STDIN.read)
  ids = arr.map { |x| x["pack_id"] }
  exit(ids.include?("core_pack") && ids.include?("meta_pack") && ids.include?("onboarding_pack") ? 0 : 1)
' 2>/dev/null; then
  pass "list --format json: valid JSON with all 3 pack_ids"
else
  fail "list JSON malformed or missing packs"
fi

# ─── status <pack> ──────────────────────────────────────────────────
STATUS_OUT=$(bash .dexCore/core/agents/packs.sh status meta_pack 2>&1)
if echo "$STATUS_OUT" | grep -q "^Pack:[[:space:]]*meta_pack"; then
  pass "status meta_pack: emits pack detail"
else
  fail "status meta_pack: unexpected"
fi
STATUS_JSON=$(bash .dexCore/core/agents/packs.sh status --format json meta_pack 2>&1)
if echo "$STATUS_JSON" | ruby -rjson -e 'd=JSON.parse(STDIN.read); exit(d["pack_id"]=="meta_pack" && d.key?("effective_state") ? 0 : 1)' 2>/dev/null; then
  pass "status --format json: valid + has pack_id + effective_state"
else
  fail "status JSON shape wrong"
fi

# ─── enable / disable round-trip ────────────────────────────────────
SCRATCH_STATE=$(mktemp -t dexhub-21-state-XXXXXX).yaml
rm -f "$SCRATCH_STATE"  # start with no state file

# enable creates the file + adds pack
ENABLE_OUT=$(bash .dexCore/core/agents/packs.sh --state "$SCRATCH_STATE" enable meta_pack 2>&1)
if echo "$ENABLE_OUT" | grep -q "Enabled: meta_pack"; then
  pass "enable meta_pack: reports success"
else
  fail "enable meta_pack: unexpected output '$ENABLE_OUT'"
fi
if [ -f "$SCRATCH_STATE" ] && grep -qE "^  - meta_pack$" "$SCRATCH_STATE"; then
  pass "enable meta_pack: state file contains pack in enabled_packs list"
else
  fail "enable state didn't land in file"
fi

# Idempotent — second enable should NOT duplicate
bash .dexCore/core/agents/packs.sh --state "$SCRATCH_STATE" enable meta_pack >/dev/null 2>&1
DUPE_COUNT=$(grep -cE "^  - meta_pack$" "$SCRATCH_STATE" || echo 0)
if [ "$DUPE_COUNT" = "1" ]; then
  pass "enable is idempotent (no duplicate entries)"
else
  fail "enable duplicated entry (count=$DUPE_COUNT)"
fi

# list reflects new state
LIST_AFTER=$(bash .dexCore/core/agents/packs.sh --state "$SCRATCH_STATE" list 2>&1)
if echo "$LIST_AFTER" | grep -E "^meta_pack\s+enabled" > /dev/null; then
  pass "list: meta_pack shows as enabled after enable"
else
  fail "list after enable: meta_pack state wrong"
fi

# disable flips it
bash .dexCore/core/agents/packs.sh --state "$SCRATCH_STATE" disable meta_pack >/dev/null 2>&1
if ! grep -qE "^  - meta_pack$" <(awk '/^enabled_packs:/{flag=1; next} /^[a-zA-Z]/ && !/^[[:space:]]/{flag=0} flag' "$SCRATCH_STATE"); then
  pass "disable: pack removed from enabled list"
else
  fail "disable: pack still in enabled list"
fi
if grep -qE "^  - meta_pack$" <(awk '/^disabled_packs:/{flag=1; next} /^[a-zA-Z]/ && !/^[[:space:]]/{flag=0} flag' "$SCRATCH_STATE"); then
  pass "disable: pack moved to disabled list"
else
  fail "disable: pack not in disabled list"
fi

# ─── core_pack cannot be disabled ───────────────────────────────────
CORE_DISABLE=$(bash .dexCore/core/agents/packs.sh --state "$SCRATCH_STATE" disable core_pack 2>&1)
CORE_EXIT=$?
if [ "$CORE_EXIT" = "1" ]; then
  pass "disable core_pack: exit 1 (mandatory protection)"
else
  fail "disable core_pack: expected exit 1, got $CORE_EXIT"
fi
if echo "$CORE_DISABLE" | grep -qi "mandatory"; then
  pass "disable core_pack: message mentions 'mandatory'"
else
  fail "disable core_pack: unhelpful message"
fi

rm -f "$SCRATCH_STATE"

# ─── Unknown pack handling ──────────────────────────────────────────
UNK_OUT=$(bash .dexCore/core/agents/packs.sh enable nonexistent_pack 2>&1)
UNK_EXIT=$?
if [ "$UNK_EXIT" = "1" ] && echo "$UNK_OUT" | grep -qi "no manifest"; then
  pass "unknown pack → exit 1 + 'no manifest' message"
else
  fail "unknown pack handling weird"
fi

# ─── Manifest-referenced agent files exist ──────────────────────────
# core_pack references agents that SHOULD exist
for f in dex-master.md mydex-agent.md mydex-project-manager.md; do
  if [ -f ".dexCore/core/agents/$f" ]; then
    pass "core_pack manifest ref exists: $f"
  else
    fail "core_pack manifest references missing file: $f"
  fi
done
# meta_pack references meta-agents that SHOULD exist
for f in analysis/codebase-analyzer.md analysis/pattern-detector.md review/test-coverage-analyzer.md; do
  if [ -f ".dexCore/meta-agents/$f" ]; then
    pass "meta_pack manifest ref exists: $f"
  else
    fail "meta_pack manifest references missing file: $f"
  fi
done

# ─── features.yaml registration + status=enabled ────────────────────
for feat in agents.user_toggle_menu agents.meta_pack agents.onboarding_pack; do
  if grep -qE "^\s+- id: $(echo "$feat" | sed 's/\./\\./g')\b" .dexCore/_cfg/features.yaml; then
    pass "features.yaml: $feat registered"
  else
    fail "features.yaml: $feat NOT registered"
  fi
  STATUS_LINE=$(grep -A 5 -e "- id: $feat" .dexCore/_cfg/features.yaml | grep -m1 "status:" | tr -d ' ')
  if echo "$STATUS_LINE" | grep -q "^status:enabled"; then
    pass "features.yaml: $feat status=enabled"
  else
    fail "features.yaml: $feat status unexpected ($STATUS_LINE)"
  fi
done

test_summary
