#!/bin/bash
# DexHub E2E Test 02 — Onboarding SMART v5.0 multi-turn walkthrough (opt-in)
#
# Phase 5.1.c Tier 5 (2026-04-19):
# First measured multi-turn conversation test. Validates that claude -p + --resume
# chaining works, that *mydex command loads the myDex persona (state transition
# IDLE → AGENT:mydex), and that the v5.0 onboarding flow asks the expected
# first question (Q0 name).
#
# THIS TEST COSTS API TOKENS. Each walkthrough ~2-5 USD.
# Gate: CLAUDE_E2E_LIVE_WALKTHROUGH=1 to enable. Default: skipped.
#
# Scope boundary (honest):
#   - This iteration proves the plumbing (session-resume works + state transition
#     observable + first question reached).
#   - Full 5-answer walk producing a valid profile.yaml is Tier 5.2 follow-up
#     (needs fixture profile dir + teardown).

set -u

HARNESS="$(cd "$(dirname "$0")/harness" && pwd)"
source "$HARNESS/assertion-lib.sh"
source "$HARNESS/claude-runner.sh"

ensure_beta_root
test_banner "02 Onboarding SMART v5.0 multi-turn walkthrough (opt-in)"

# Gate check: walkthrough requires both CLI + opt-in flag
if ! walkthrough_mode_enabled; then
  echo -e "\033[1;33m  ⊘ SKIPPED: CLAUDE_E2E_LIVE_WALKTHROUGH=1 not set\033[0m"
  echo -e "     Reason: each walkthrough costs real API tokens (~2-5 USD)."
  echo -e "     Run with: CLAUDE_E2E_LIVE_WALKTHROUGH=1 bash tests/e2e/02-onboarding-walkthrough.test.sh"
  pass "Walkthrough gate honored (skipped as expected)"
  test_summary
  exit 0
fi

if ! check_claude_installed; then
  fail "Walkthrough requested but claude CLI missing" "install Claude Code"
  test_summary
  exit 1
fi

echo -e "\033[1;33m  ⚡ LIVE WALKTHROUGH: multi-turn conversation via claude --resume (COSTS TOKENS)\033[0m"

# ─── Turn 1: greeting activates DexMaster ──────────────────────────────
start_conversation "hi"

if [ -z "${LAST_CLAUDE_SESSION_ID:-}" ]; then
  fail "Turn 1: no session_id returned" "claude --print --output-format=json may have failed"
  test_summary
  exit 1
fi
pass "Turn 1: session started — session_id captured"

if echo "$LAST_CLAUDE_RESPONSE" | grep -qiE "dex[ -]?master"; then
  pass "Turn 1: greeting identifies DexMaster"
else
  fail "Turn 1: response does not identify DexMaster" "first 150 chars: ${LAST_CLAUDE_RESPONSE:0:150}"
fi

if echo "$LAST_CLAUDE_RESPONSE" | grep -qE "\*mydex"; then
  pass "Turn 1: DexMaster menu exposes *mydex"
else
  fail "Turn 1: *mydex entrypoint not in menu"
fi

SID="$LAST_CLAUDE_SESSION_ID"

# ─── Turn 2: *mydex transitions to myDex agent ─────────────────────────
resume_conversation "$SID" "*mydex"

if [ -z "${LAST_CLAUDE_SESSION_ID:-}" ]; then
  fail "Turn 2: session resume failed" "--resume may not have worked"
  test_summary
  exit 1
fi
pass "Turn 2: session resumed"

# The myDex agent should introduce itself OR start asking the first onboarding
# question. Accept either shape (agent persona or onboarding entry).
if echo "$LAST_CLAUDE_RESPONSE" | grep -qiE "mydex|myDex"; then
  pass "Turn 2: response references myDex agent (state transition IDLE → AGENT:mydex observable)"
else
  # Soft fail — agent may have jumped directly to first question without self-intro
  echo -e "\033[1;33m  ⚠\033[0m Turn 2: no 'myDex' mention — agent may have gone direct to first question"
  echo -e "     First 200 chars: ${LAST_CLAUDE_RESPONSE:0:200}"
fi

# Check for onboarding indication: either menu (showing onboarding option)
# or first question directly (Q0 name request)
if echo "$LAST_CLAUDE_RESPONSE" | grep -qiE "name|profile|onboarding|willkommen|welcome"; then
  pass "Turn 2: onboarding context reached (name/profile/onboarding mentioned)"
else
  fail "Turn 2: no onboarding context" "first 200 chars: ${LAST_CLAUDE_RESPONSE:0:200}"
fi

# ─── Turn 3: optional — answer first name question ─────────────────────
# This is a soft probe: we answer "Alex" and check the response advances.
# If the agent never asked for a name, this turn may be confusing — that's OK,
# it's diagnostic not strict-assert.
resume_conversation "$SID" "Alex"

if [ -n "${LAST_CLAUDE_RESPONSE:-}" ]; then
  pass "Turn 3: 'Alex' answer accepted — conversation continues"
else
  fail "Turn 3: no response after providing name" "session state may have broken"
fi

# No profile.yaml-production assertion yet — that requires fixture teardown
# (pre-existing profile.yaml cleanup before walkthrough) + post-walk verify.
# Tier 5.2 scope.

echo ""
echo -e "\033[1;33m  Walkthrough scope note:\033[0m"
echo "  This test proves: session-resume works + state transition observable."
echo "  It does NOT yet prove: 5-answer SMART v5 flow → valid profile.yaml."
echo "  That gap is Tier 5.2 (fixture-based full walk)."

test_summary
