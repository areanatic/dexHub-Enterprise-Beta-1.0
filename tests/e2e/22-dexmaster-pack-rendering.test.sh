#!/bin/bash
# DexHub E2E Test 22 — DexMaster Pack-Aware Menu Rendering (5.1.d follow-up)
#
# Closes the "DexMaster menu doesn't consume packs.yaml" gap noted in the
# known_issues of agents.user_toggle_menu after the 2026-04-21 first slice.
#
# This is a prompt-layer change (dex-master.md content), so structural
# tests assert presence of the new instructions. Actual behavioral
# verification requires CLAUDE_E2E_LIVE (a live agent session that reads
# dex-master.md and renders a pack-filtered menu) — gated behind the env
# var so default CI stays always-green.
#
# Proves:
#   - Activation step 2.7 (pack state load) exists with required pieces
#   - Menu contains *packs, *enable-pack, *disable-pack items pointing
#     to the right handler prompt ids
#   - *list-agents entry mentions it's pack-filtered
#   - Prompt sections defined for: show-packs, enable-pack, disable-pack
#     — each invokes packs.sh with the right subcommand
#   - list-agents-from-registry prompt references {enabled_packs} and
#     the pack filter behavior
#   - SSOT drift-check passes (no source-vs-generated mismatch — dex-
#     master.md is loaded dynamically so not in CLAUDE.md anyway)
#   - features.yaml known_issue about DexMaster menu-rendering pending
#     is removed from agents.user_toggle_menu

set -u

HARNESS="$(cd "$(dirname "$0")/harness" && pwd)"
source "$HARNESS/assertion-lib.sh"

ensure_beta_root
test_banner "22 DexMaster Pack-Aware Menu Rendering (5.1.d follow-up)"

DEX_MASTER=".dexCore/core/agents/dex-master.md"
FEATURES=".dexCore/_cfg/features.yaml"

# ─── File still parses as the expected XML-ish structure ────────────
assert_file_exists "$DEX_MASTER" "dex-master.md present"
if grep -qE "^<activation " "$DEX_MASTER" && grep -qE "^</activation>" "$DEX_MASTER"; then
  pass "dex-master.md: <activation> block structure intact"
else
  fail "dex-master.md: activation block markers missing after edit"
fi

# ─── Step 2.7 pack state load ───────────────────────────────────────
if grep -qE '^\s*<step n="2\.7">' "$DEX_MASTER"; then
  pass "Activation step 2.7 added"
else
  fail "Activation step 2.7 NOT added"
fi
if grep -q "packs.sh list --format json" "$DEX_MASTER"; then
  pass "Step 2.7 invokes packs.sh list --format json"
else
  fail "Step 2.7 missing bash invocation"
fi
if grep -q "{enabled_packs}" "$DEX_MASTER"; then
  pass "Step 2.7 defines session variable {enabled_packs}"
else
  fail "Step 2.7 missing {enabled_packs} variable"
fi
if grep -q 'core_pack.*mandatory\|mandatory.*core_pack' "$DEX_MASTER"; then
  pass "Step 2.7 documents core_pack mandatory protection"
else
  fail "Step 2.7 missing core_pack mandatory note"
fi

# ─── Menu items: *packs + *enable-pack + *disable-pack ──────────────
if grep -qE '<item cmd="\*packs"' "$DEX_MASTER"; then
  pass "Menu: *packs item present"
else
  fail "Menu: *packs item missing"
fi
if grep -qE '<item cmd="\*enable-pack"' "$DEX_MASTER"; then
  pass "Menu: *enable-pack item present"
else
  fail "Menu: *enable-pack item missing"
fi
if grep -qE '<item cmd="\*disable-pack"' "$DEX_MASTER"; then
  pass "Menu: *disable-pack item present"
else
  fail "Menu: *disable-pack item missing"
fi

# Enable / disable pack items should be marked hidden (advanced usage)
if grep -E '<item cmd="\*enable-pack"' "$DEX_MASTER" | grep -q 'hidden="true"'; then
  pass "Menu: *enable-pack marked hidden=true (advanced usage)"
else
  fail "Menu: *enable-pack should be hidden=true"
fi

# ─── *list-agents mentions pack-filtering in its menu label ─────────
if grep -E '<item cmd="\*list-agents"' "$DEX_MASTER" | grep -qi "pack"; then
  pass "Menu: *list-agents description mentions pack-filtering"
else
  fail "Menu: *list-agents description doesn't mention pack-filtering"
fi

# ─── Prompt handlers exist ──────────────────────────────────────────
for prompt_id in show-packs enable-pack disable-pack; do
  if grep -qE "<prompt id=\"${prompt_id}\">" "$DEX_MASTER"; then
    pass "Prompt handler <$prompt_id> defined"
  else
    fail "Prompt handler <$prompt_id> missing"
  fi
done

# show-packs must invoke packs.sh list --format json
# We use awk to extract the prompt body so adjacent prompts don't contaminate
SHOW_PACKS_BODY=$(awk '/^[[:space:]]*<prompt id="show-packs">/,/^[[:space:]]*<\/prompt>/' "$DEX_MASTER")
if echo "$SHOW_PACKS_BODY" | grep -q "packs.sh list --format json"; then
  pass "show-packs prompt invokes packs.sh list --format json"
else
  fail "show-packs prompt missing bash invocation"
fi

# enable-pack must invoke packs.sh enable
ENABLE_BODY=$(awk '/^[[:space:]]*<prompt id="enable-pack">/,/^[[:space:]]*<\/prompt>/' "$DEX_MASTER")
if echo "$ENABLE_BODY" | grep -q "packs.sh enable"; then
  pass "enable-pack prompt invokes packs.sh enable"
else
  fail "enable-pack prompt missing bash invocation"
fi
if echo "$ENABLE_BODY" | grep -q "activation step 2.7"; then
  pass "enable-pack prompt re-runs activation step 2.7 after success"
else
  fail "enable-pack prompt doesn't refresh session state"
fi

# disable-pack must invoke packs.sh disable + handle mandatory-refusal
DISABLE_BODY=$(awk '/^[[:space:]]*<prompt id="disable-pack">/,/^[[:space:]]*<\/prompt>/' "$DEX_MASTER")
if echo "$DISABLE_BODY" | grep -q "packs.sh disable"; then
  pass "disable-pack prompt invokes packs.sh disable"
else
  fail "disable-pack prompt missing bash invocation"
fi
if echo "$DISABLE_BODY" | grep -qi "mandatory"; then
  pass "disable-pack prompt handles mandatory-refusal"
else
  fail "disable-pack prompt missing mandatory-refusal handling"
fi

# ─── list-agents-from-registry consumes {enabled_packs} ─────────────
LIST_BODY=$(awk '/^[[:space:]]*<prompt id="list-agents-from-registry">/,/^[[:space:]]*<\/prompt>/' "$DEX_MASTER")
if echo "$LIST_BODY" | grep -q "{enabled_packs}"; then
  pass "list-agents-from-registry prompt references {enabled_packs}"
else
  fail "list-agents-from-registry prompt doesn't consume pack state"
fi
if echo "$LIST_BODY" | grep -qi "pack" ; then
  pass "list-agents-from-registry prompt mentions pack filtering"
else
  fail "list-agents-from-registry prompt doesn't mention pack filtering"
fi
if echo "$LIST_BODY" | grep -q '\*packs'; then
  pass "list-agents-from-registry prompt hints *packs toggle command"
else
  fail "list-agents-from-registry prompt doesn't hint *packs"
fi
if echo "$LIST_BODY" | grep -qi "core_pack.*always\|always.*core_pack"; then
  pass "list-agents-from-registry prompt documents core_pack mandatory"
else
  fail "list-agents-from-registry prompt doesn't protect core_pack visibility"
fi

# ─── SSOT drift check (tail files are in sync with sources) ─────────
if bash .dexCore/_dev/tools/build-instructions.sh check 2>&1 | grep -q "all generated.*in sync"; then
  pass "SSOT drift check: tail files in sync with sources"
else
  fail "SSOT drift check failed — rebuild required"
fi

# ─── features.yaml: known_issue about menu rendering is resolved ────
# We removed the 'DexMaster menu doesn't yet consume packs.yaml' line
# from agents.user_toggle_menu's known_issues. Verify absence.
TOGGLE_BODY=$(awk '/- id: agents\.user_toggle_menu/{flag=1; print; next} flag && /^  - id: / {exit} flag {print}' "$FEATURES")
if echo "$TOGGLE_BODY" | grep -qi "menu doesn't yet consume"; then
  fail "features.yaml: stale 'menu doesn't yet consume' known_issue still present"
else
  pass "features.yaml: stale 'menu doesn't yet consume' known_issue removed"
fi

# Version bump note: validated_at should be set for this slice
if echo "$TOGGLE_BODY" | grep -q "validated_at:"; then
  pass "features.yaml: agents.user_toggle_menu has validated_at stamp"
else
  fail "features.yaml: agents.user_toggle_menu missing validated_at stamp"
fi

# ─── Menu footer hint still intact (regression guard) ───────────────
if grep -q 'Neu hier? Erstelle dein Profil' "$DEX_MASTER"; then
  pass "Menu footer intact (regression guard)"
else
  fail "Menu footer accidentally removed"
fi

test_summary
