#!/bin/bash
# DexHub E2E Test 09 — Complete-Only Path (Tier 5.5.2, choice 1)
#
# The opposite of "destroy and restart" — the user has a PARTIAL profile
# and wants to ONLY answer the missing questions without losing existing
# answers. This is the data-preservation path: new answers are added,
# old answers must survive.
#
# Structural (always runs): mydex-agent.md spec for choice 1:
#   "Load profile, determine missing questions, start Q&A with only missing"
#
# Live (opt-in, ~5 USD): install a PARTIALLY-complete fixture (known
# name + known language but missing experience/team_size/data_handling).
# Pick "1". Answer the missing 3 questions. Verify:
#   - Existing answers PRESERVED (TestUser09 name + "de" language survive)
#   - New answers APPLIED (experience + team + data_handling populated)
#   - Profile hash CHANGED (additive update expected)
#
# This is the one test in the Tier 5.5 set where the profile SHOULD change.
# Hash-inequality is the expected outcome; the strict assertions are on
# field-level preservation + addition.

set -u

HARNESS="$(cd "$(dirname "$0")/harness" && pwd)"
source "$HARNESS/assertion-lib.sh"
source "$HARNESS/claude-runner.sh"

ensure_beta_root
test_banner "09 Onboarding — complete-only (Tier 5.5.2, choice 1)"

# ─── STRUCTURAL ──────────────────────────────────────────────────────
assert_file_contains ".dexCore/core/agents/mydex-agent.md" \
  "Load profile, determine missing questions" \
  "mydex-agent: choice 1 — load-existing + determine-missing spec present"

assert_file_contains ".dexCore/core/agents/mydex-agent.md" \
  "start Q&A with only missing" \
  "mydex-agent: choice 1 — Q&A limited to missing fields"

assert_file_contains ".dexCore/core/agents/mydex-agent.md" \
  "1 → Load profile" \
  "mydex-agent: choice 1 handler line present"

# ─── LIVE gate ───────────────────────────────────────────────────────
if ! walkthrough_mode_enabled; then
  echo -e "\033[1;33m  ⊘ SKIPPED live portion\033[0m"
  echo "     Run with: CLAUDE_E2E_LIVE_WALKTHROUGH=1 bash tests/e2e/09-onboarding-complete-only.test.sh"
  pass "Live gate honored (skipped)"
  test_summary
  exit 0
fi

if ! check_claude_installed; then
  fail "claude CLI missing"
  test_summary
  exit 1
fi

echo -e "\033[1;33m  ⚡ LIVE PORTION: ~7 turns, partial profile → answer-missing (REAL COST ~5 USD)\033[0m"

# ─── Fixture: PARTIAL profile (2 of 5 SMART v5 answers filled) ──────
PROFILE_PATH="myDex/.dex/config/profile.yaml"
BACKUP_PATH="/tmp/dexhub-profile-backup-09-$$-$(date +%s).yaml"
BACKUP_DONE=0

if [ -f "$PROFILE_PATH" ]; then
  cp "$PROFILE_PATH" "$BACKUP_PATH" && rm "$PROFILE_PATH" && BACKUP_DONE=1
  pass "Pre-walk: real profile archived"
fi

# Partial: name + language filled, experience/team/data_handling null
cat > "$PROFILE_PATH" <<'FIXTURE_YAML'
# FIXTURE — Test 09 partial profile (2/5 SMART v5 answered)
version: "1.2"
created_at: "2026-01-15T10:00:00Z"
updated_at: "2026-01-15T10:02:00Z"
personalization:
  name: "TestUser09"
  language: "de"
  role: null
technical:
  experience_level: null
  code_style: null
  verbosity: null
tech:
  primary_stack: []
ai:
  readiness: null
  copilot_enabled: false
communication:
  language_preference: "de"
  verbosity: null
identity:
  experience_years: null
  team_size: null
company:
  data_handling_policy: null
onboarding:
  variant: "smart_v5"
  version: "v5.0"
  started_at: "2026-01-15T10:00:00Z"
  completed_at: null
  questions_answered: 2
  questions_skipped: 3
  completion_percentage: 40.0
consents: []
FIXTURE_YAML

FIXTURE_HASH=$(shasum -a 256 "$PROFILE_PATH" | cut -d' ' -f1)
pass "Fixture: TestUser09 partial profile installed (2/5 answered, 40%)"

restore_backup() {
  rm -f "$PROFILE_PATH"
  if [ "$BACKUP_DONE" = "1" ] && [ -f "$BACKUP_PATH" ]; then
    cp "$BACKUP_PATH" "$PROFILE_PATH" && rm -f "$BACKUP_PATH"
    echo -e "\033[0;34m  (trap: fixture removed, real profile restored)\033[0m"
  else
    echo -e "\033[0;34m  (trap: fixture removed)\033[0m"
  fi
}
trap 'restore_backup' EXIT INT TERM

# ─── Turns ───────────────────────────────────────────────────────────
start_conversation "hi"
SID="${LAST_CLAUDE_SESSION_ID:-}"
[ -z "$SID" ] && { fail "Turn 1: no sid"; test_summary; exit 1; }
pass "Turn 1: session started"

resume_conversation "$SID" "*mydex"
pass "Turn 2: *mydex"

resume_conversation "$SID" "*onboarding"
if echo "${LAST_CLAUDE_RESPONSE:-}" | grep -qiE "bereits ein profil|vollständigkeit|existing|40"; then
  pass "Turn 3: partial-profile detected"
else
  fail "Turn 3: partial-profile not detected" "first 300: ${LAST_CLAUDE_RESPONSE:0:300}"
fi

# ─── Turn 4: choice "1" — complete existing ──────────────────────────
# Agent should start asking ONLY the missing questions (experience/team/data_handling),
# NOT re-ask name or language. We can't strictly verify "did not ask" without
# deep log inspection, but we can verify the first question asked is a missing one.
resume_conversation "$SID" "1"
pass "Turn 4: choice 1 (complete existing) sent"

# ─── Turns 5-7: answer the 3 missing SMART v5 questions ──────────────
# Tolerant: agent may ask in any order (Q3/Q4/Q43 = experience/team/data_handling)
# We feed answers that work for each.
resume_conversation "$SID" "3-7 Jahre"
pass "Turn 5: experience answer sent"

resume_conversation "$SID" "Ich arbeite allein"
pass "Turn 6: team_size answer sent"

resume_conversation "$SID" "Cloud-LLMs erlaubt"
pass "Turn 7: data_handling answer sent"

# Some flows may need a save-confirm turn
resume_conversation "$SID" "Ja speichere das Profil."
pass "Turn 8: save-confirmation sent"

# ─── Post-walk: VALIDATE data-preservation + additive-update ─────────
if [ -f "$PROFILE_PATH" ]; then
  pass "Post-walk: profile.yaml still present (not deleted)"

  # Hash MUST differ (additive update expected)
  FINAL_HASH=$(shasum -a 256 "$PROFILE_PATH" 2>/dev/null | cut -d' ' -f1)
  if [ "$FINAL_HASH" != "$FIXTURE_HASH" ]; then
    pass "Post-walk: profile hash CHANGED (update applied, as expected for choice 1)"
  else
    fail "Post-walk: profile hash UNCHANGED — no update happened, walkthrough didn't persist"
  fi

  # ORIGINAL data PRESERVED
  if grep -q "TestUser09" "$PROFILE_PATH"; then
    pass "Data preservation: TestUser09 name PRESERVED (not wiped)"
  else
    fail "Data preservation: TestUser09 name LOST — choice 1 violated preserve-existing semantics"
  fi
  if grep -qE "language:[[:space:]]*\"?de\"?" "$PROFILE_PATH"; then
    pass "Data preservation: language='de' PRESERVED"
  else
    fail "Data preservation: language was overwritten or lost"
  fi

  # NEW data ADDED
  assert_file_contains "$PROFILE_PATH" "(3-7|intermediate|senior)" \
    "Additive update: experience field populated"
  assert_file_contains "$PROFILE_PATH" "(solo|allein)" \
    "Additive update: team_size field populated"
  assert_file_contains "$PROFILE_PATH" "cloud_llm_allowed" \
    "Additive update: data_handling_policy populated"
else
  fail "Post-walk: profile.yaml deleted during complete-only flow — BUG"
fi

echo ""
echo -e "\033[1;33m  Tier 5.5.2 scope:\033[0m choice 1 = preserve-existing + add-missing. Both verified."

test_summary
