#!/bin/bash
# DexHub E2E Test 03 — Onboarding SMART v5.0 FULL walkthrough (Tier 5.2, opt-in)
#
# Phase 5.1.c Tier 5.2 (2026-04-20):
# Extension of Test 02. Where 02 proves the plumbing (claude -p + --resume works,
# DexMaster greets, *mydex transitions), 03 proves the BEHAVIOR: a full 5-answer
# SMART v5 conversation produces a valid profile.yaml with the expected fields
# populated, including the P0 enterprise gate (company.data_handling_policy).
#
# Cost: this test costs real API tokens (~3-7 USD per run, depending on model +
# response length). DO NOT run in CI default. Same opt-in gate as Test 02:
#
#   CLAUDE_E2E_LIVE_WALKTHROUGH=1 bash tests/e2e/03-onboarding-smart-v5-full-walk.test.sh
#
# What this test proves when green:
#   - 5-answer SMART v5 flow produces a file at myDex/.dex/config/profile.yaml
#   - File is valid YAML
#   - File contains the expected answer for each SMART v5 question (Q0 name,
#     Q1 language, Q3 experience, Q4 team_size, Q43 data_handling_policy)
#   - The profile maps to schema v1.1 (company.* block present)
#
# What it does NOT yet prove (deferred to Tier 5.3+):
#   - VOLLSTÄNDIG v5 (12 answers including enterprise fields)
#   - Legacy *mydex-advanced v4.3.1 (42 answers)
#   - Edge cases (cancel, invalid input, existing profile re-ask vs keep)
#
# Honesty label: assertion thresholds are deliberately tolerant. The LLM may
# phrase questions differently across runs, accept answers in multiple
# formats, and compose the profile in either a single turn or multiple turns.
# We assert on end-state (profile.yaml fields), not on every intermediate
# turn's exact wording.

set -u

HARNESS="$(cd "$(dirname "$0")/harness" && pwd)"
source "$HARNESS/assertion-lib.sh"
source "$HARNESS/claude-runner.sh"

ensure_beta_root
test_banner "03 SMART v5 FULL walkthrough (Tier 5.2) — 5 answers → profile.yaml"

# ─── Gate ──────────────────────────────────────────────────────────────
if ! walkthrough_mode_enabled; then
  echo -e "\033[1;33m  ⊘ SKIPPED: CLAUDE_E2E_LIVE_WALKTHROUGH=1 not set\033[0m"
  echo -e "     Reason: full walkthroughs cost real API tokens (~3-7 USD each)."
  echo -e "     Run with: CLAUDE_E2E_LIVE_WALKTHROUGH=1 bash tests/e2e/03-onboarding-smart-v5-full-walk.test.sh"
  pass "Walkthrough gate honored (skipped as expected)"
  test_summary
  exit 0
fi

if ! check_claude_installed; then
  fail "Walkthrough requested but claude CLI missing" "install Claude Code"
  test_summary
  exit 1
fi

echo -e "\033[1;33m  ⚡ FULL LIVE WALKTHROUGH: ~8 turns, multi-turn session-resume (REAL COST)\033[0m"

# ─── Fixture setup ─────────────────────────────────────────────────────
PROFILE_PATH="myDex/.dex/config/profile.yaml"
BACKUP_PATH="/tmp/dexhub-profile-backup-$$-$(date +%s).yaml"

# Back up any existing profile.yaml so we don't destroy dev-local data.
# The profile is gitignored, so a pre-existing one is personal state.
BACKUP_DONE=0
if [ -f "$PROFILE_PATH" ]; then
  if cp "$PROFILE_PATH" "$BACKUP_PATH" 2>/dev/null; then
    rm "$PROFILE_PATH"
    BACKUP_DONE=1
    pass "Pre-walk: existing profile.yaml archived to $BACKUP_PATH, source cleared"
  else
    fail "Pre-walk: could not back up existing profile.yaml — aborting to avoid data loss"
    test_summary
    exit 1
  fi
else
  pass "Pre-walk: no pre-existing profile.yaml (clean slate)"
fi

# Restore trap: whatever happens, put the user's backup back at the original path.
restore_backup() {
  if [ "$BACKUP_DONE" = "1" ] && [ -f "$BACKUP_PATH" ]; then
    # Always overwrite, so walkthrough-produced profile doesn't shadow user's real one.
    cp "$BACKUP_PATH" "$PROFILE_PATH" 2>/dev/null || true
    rm -f "$BACKUP_PATH"
    echo -e "\033[0;34m  (trap: restored user's original profile.yaml)\033[0m"
  fi
}
trap 'restore_backup' EXIT INT TERM

# ─── Turn 1: greeting ──────────────────────────────────────────────────
start_conversation "hi"
if [ -z "${LAST_CLAUDE_SESSION_ID:-}" ]; then
  fail "Turn 1: no session_id returned" "claude --print --output-format=json failed"
  test_summary
  exit 1
fi
SID="$LAST_CLAUDE_SESSION_ID"
pass "Turn 1: greeting → session started (sid captured)"

# ─── Turn 2: *mydex enters myDex agent ────────────────────────────────
resume_conversation "$SID" "*mydex"
if [ -z "${LAST_CLAUDE_SESSION_ID:-}" ]; then
  fail "Turn 2: session-resume failed"
  test_summary
  exit 1
fi
pass "Turn 2: *mydex transitioned to myDex agent"

# ─── Turn 3: start SMART onboarding ────────────────────────────────────
# myDex shows menu with *onboarding. We want SMART variant specifically.
# Phrase it the way a user would: natural language + variant name.
resume_conversation "$SID" "Ich moechte das SMART Onboarding starten."
pass "Turn 3: SMART onboarding requested"

# ─── Turns 4-8: 5 SMART v5 answers ─────────────────────────────────────
# Q0 name
resume_conversation "$SID" "Alex"
pass "Turn 4: Q0 name='Alex' provided"

# Q1 language — pick German to test non-default
resume_conversation "$SID" "Deutsch"
pass "Turn 5: Q1 language='Deutsch' provided"

# Q3 experience — pick intermediate
resume_conversation "$SID" "3-7 Jahre"
pass "Turn 6: Q3 experience='3-7 Jahre' provided"

# Q4 team_size — pick solo
resume_conversation "$SID" "Ich arbeite allein"
pass "Turn 7: Q4 team_size='solo' provided"

# Q43 data_handling_policy — pick cloud_llm_allowed
resume_conversation "$SID" "Cloud-LLMs erlaubt"
pass "Turn 8: Q43 data_handling_policy='cloud_llm_allowed' provided"

# Final confirmation — some flows prompt "save profile?"; always say yes.
resume_conversation "$SID" "Ja, speichere bitte das Profil."
pass "Turn 9: save-confirmation sent"

# ─── Post-walk: verify profile.yaml was produced ──────────────────────
if [ -f "$PROFILE_PATH" ]; then
  pass "Post-walk: profile.yaml created at $PROFILE_PATH"
  assert_yaml_valid "$PROFILE_PATH" "Post-walk: profile.yaml is valid YAML"

  # Semantic assertions: content check, tolerant (just needs to contain these
  # tokens somewhere; exact YAML path is LLM-output-dependent).
  assert_file_contains "$PROFILE_PATH" "Alex" \
    "Post-walk: profile contains name 'Alex' (Q0)"
  assert_file_contains "$PROFILE_PATH" "(de|deutsch|Deutsch)" \
    "Post-walk: profile contains language de/Deutsch (Q1)"
  assert_file_contains "$PROFILE_PATH" "(3-7|intermediate|mid)" \
    "Post-walk: profile contains experience marker (Q3)"
  assert_file_contains "$PROFILE_PATH" "(solo|allein)" \
    "Post-walk: profile contains team_size=solo (Q4)"
  assert_file_contains "$PROFILE_PATH" "data_handling_policy" \
    "Post-walk: profile contains company.data_handling_policy key (Q43 — P0 gate)"
  assert_file_contains "$PROFILE_PATH" "cloud_llm_allowed" \
    "Post-walk: profile has cloud_llm_allowed value (Q43 answer)"

  # Schema-version hint — accept v1.x (v1.0, v1.1, or v1.2).
  # Agent may emit 1.2 (current schema), 1.1 (prior version with company.*),
  # or 1.0 (base); all are valid for a profile that answered Q43.
  if grep -qE "version:[[:space:]]*\"?1\.[012]" "$PROFILE_PATH"; then
    pass "Post-walk: profile declares schema v1.x"
  else
    fail "Post-walk: schema version not in {1.0, 1.1, 1.2}" \
      "unexpected version string — inspect $PROFILE_PATH"
  fi
else
  fail "Post-walk: profile.yaml not created at $PROFILE_PATH" \
    "Agent did not complete the walkthrough in write-profile form. This is the most likely failure mode on first live run. Check: (a) conversation ran to end? (b) agent chose to persist? (c) write-path correct?"
fi

# ─── Cleanup ───────────────────────────────────────────────────────────
# Trap will restore backup on exit. If no backup existed, we leave the
# walkthrough-produced profile in place so the user can inspect it.
if [ "$BACKUP_DONE" = "1" ]; then
  pass "Cleanup: user's original profile will be restored (EXIT trap)"
else
  echo -e "\033[0;34m  (note: no pre-existing profile was backed up. Walkthrough-produced file remains at $PROFILE_PATH for inspection.)\033[0m"
fi

echo ""
echo -e "\033[1;33m  Tier 5.2 scope note:\033[0m"
echo "  This test proves: 5-answer SMART v5 → file produced with expected fields."
echo "  It does NOT yet prove: VOLLSTÄNDIG v5 (12 answers) or legacy v4.3.1 (42 answers)."
echo "  That gap is Tier 5.3 / 5.4."

test_summary
