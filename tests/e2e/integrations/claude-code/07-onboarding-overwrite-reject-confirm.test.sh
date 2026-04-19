#!/bin/bash
# DexHub E2E Test 07 — Overwrite Confirm-Gate Reject Path (Tier 5.5.3)
#
# Companion to Test 06 (cancel-at-menu). Test 07 goes ONE LEVEL DEEPER:
# the user actually picks "2 Neu beginnen" (restart fresh), reaches the
# confirmation gate ("Sicher? Aktuelles Profil wird überschrieben. [j/n]"),
# and says "n" — the profile MUST survive unchanged.
#
# This test is critical because it verifies the confirm-gate ITSELF works,
# not just the outer menu-level cancel. If the confirm-gate were broken,
# a user who hesitated could still destroy their profile via an unconfirmed
# yes. Test 06 catches menu-level cancel bugs; Test 07 catches confirm-gate
# bugs.
#
# Two levels:
#   - Structural (always runs, no API cost): mydex-agent.md contains the
#     exact confirm-gate wording + j/n branch logic + rollback-to-menu.
#   - Live (opt-in CLAUDE_E2E_LIVE_WALKTHROUGH=1, ~3-5 USD): 5 turns —
#     hi → *mydex → *onboarding → "2" → "n" — asserts profile hash
#     UNCHANGED after reject.
#
# Scope boundary (honest):
#   - Does NOT test the "confirmed yes" path (Tier 5.5.3b, expensive
#     because it would chain a full walkthrough after).
#   - LLM may phrase the confirm prompt slightly differently in some
#     runs — assertion is tolerant on phrasing, strict on outcome.

set -u

HARNESS="$(cd "$(dirname "$0")/../../harness" && pwd)"
CC_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$HARNESS/assertion-lib.sh"
source "$CC_DIR/claude-runner.sh"

ensure_beta_root
test_banner "07 Onboarding — overwrite confirm-gate REJECT (Tier 5.5.3)"

# ─── STRUCTURAL: confirm-gate spec lives in mydex-agent ───────────────
assert_file_contains ".dexCore/core/agents/mydex-agent.md" \
  "Sicher\? Aktuelles Profil wird überschrieben" \
  "mydex-agent: confirm-gate wording (j/n prompt) present"

assert_file_contains ".dexCore/core/agents/mydex-agent.md" \
  "\[j/n\]" \
  "mydex-agent: confirm-gate uses [j/n] pattern"

assert_file_contains ".dexCore/core/agents/mydex-agent.md" \
  "IF confirmed: Delete profile.yaml" \
  "mydex-agent: confirm-branch deletes on yes"

assert_file_contains ".dexCore/core/agents/mydex-agent.md" \
  "ELSE: Return to menu" \
  "mydex-agent: reject-branch returns to menu (no deletion)"

# ─── LIVE gate ─────────────────────────────────────────────────────────
if ! walkthrough_mode_enabled; then
  echo -e "\033[1;33m  ⊘ SKIPPED live portion: CLAUDE_E2E_LIVE_WALKTHROUGH=1 not set\033[0m"
  echo -e "     Reason: live portion costs real API tokens (~3-5 USD)."
  echo -e "     Run with: CLAUDE_E2E_LIVE_WALKTHROUGH=1 bash tests/e2e/07-onboarding-overwrite-reject-confirm.test.sh"
  pass "Live gate honored (skipped)"
  test_summary
  exit 0
fi

if ! check_claude_installed; then
  fail "Live portion requested but claude CLI missing"
  test_summary
  exit 1
fi

echo -e "\033[1;33m  ⚡ LIVE PORTION: 5 turns, overwrite-choice + reject-confirm (REAL COST)\033[0m"

# ─── Fixture setup ─────────────────────────────────────────────────────
PROFILE_PATH="myDex/.dex/config/profile.yaml"
BACKUP_PATH="/tmp/dexhub-profile-backup-07-$$-$(date +%s).yaml"
BACKUP_DONE=0

# Back up any real profile
if [ -f "$PROFILE_PATH" ]; then
  if cp "$PROFILE_PATH" "$BACKUP_PATH" 2>/dev/null; then
    BACKUP_DONE=1
    pass "Pre-walk: real profile.yaml archived to $BACKUP_PATH"
  else
    fail "Pre-walk: could not back up — aborting"
    test_summary
    exit 1
  fi
fi

# Fixture: minimal but obviously-identifiable 100%-complete profile
cat > "$PROFILE_PATH" <<'FIXTURE_YAML'
# FIXTURE — Test 07 overwrite reject-confirm edge case
version: "1.2"
created_at: "2026-01-15T10:00:00Z"
updated_at: "2026-01-15T10:05:00Z"
personalization:
  name: "TestUser07"
  language: "de"
  role: "developer"
technical:
  experience_level: "senior"
  code_style: "standard"
  verbosity: "balanced"
tech:
  primary_stack: ["typescript"]
ai:
  readiness: "intermediate"
  copilot_enabled: false
communication:
  language_preference: "de"
  verbosity: "balanced"
identity:
  experience_years: "8-15"
  team_size: "small"
company:
  data_handling_policy: "cloud_llm_allowed"
onboarding:
  variant: "smart_v5"
  version: "v5.0"
  started_at: "2026-01-15T10:00:00Z"
  completed_at: "2026-01-15T10:05:00Z"
  questions_answered: 5
  questions_skipped: 0
  completion_percentage: 100.0
consents: []
FIXTURE_YAML

FIXTURE_HASH=$(shasum -a 256 "$PROFILE_PATH" | cut -d' ' -f1)
pass "Fixture installed: TestUser07 (100% complete v1.2, hash=${FIXTURE_HASH:0:12})"

# Restore trap
restore_backup() {
  rm -f "$PROFILE_PATH"
  if [ "$BACKUP_DONE" = "1" ] && [ -f "$BACKUP_PATH" ]; then
    cp "$BACKUP_PATH" "$PROFILE_PATH" 2>/dev/null || true
    rm -f "$BACKUP_PATH"
    echo -e "\033[0;34m  (trap: removed fixture, restored user's real profile)\033[0m"
  else
    echo -e "\033[0;34m  (trap: removed fixture; no real profile to restore)\033[0m"
  fi
}
trap 'restore_backup' EXIT INT TERM

# ─── Turn 1: greeting ──────────────────────────────────────────────────
start_conversation "hi"
if [ -z "${LAST_CLAUDE_SESSION_ID:-}" ]; then
  fail "Turn 1: no session_id"
  test_summary
  exit 1
fi
SID="$LAST_CLAUDE_SESSION_ID"
pass "Turn 1: session started"

# ─── Turn 2: *mydex ────────────────────────────────────────────────────
resume_conversation "$SID" "*mydex"
pass "Turn 2: *mydex entered"

# ─── Turn 3: *onboarding — triggers existing-profile menu ─────────────
resume_conversation "$SID" "*onboarding"
if echo "${LAST_CLAUDE_RESPONSE:-}" | grep -qiE "bereits ein profil|schon.*profil|vollständigkeit|existing|already"; then
  pass "Turn 3: existing-profile detected"
else
  fail "Turn 3: *onboarding did not surface existing-profile dialog" \
    "first 300: ${LAST_CLAUDE_RESPONSE:0:300}"
fi

# ─── Turn 4: pick "2" (Neu beginnen — restart fresh) ──────────────────
# This must trigger the confirm-gate, NOT delete the profile immediately.
resume_conversation "$SID" "2"

# Confirm-gate should surface. Tolerant match — accepts the exact spec
# wording OR reasonable German/English variants the LLM might produce.
if echo "${LAST_CLAUDE_RESPONSE:-}" | grep -qiE "sicher\?|wirklich\?|überschrieben|überschreiben|wird überschrieben|confirm|sure\?|\[j/n\]|\[y/n\]|neu starten"; then
  pass "Turn 4: confirm-gate surfaced (not immediate deletion — correct)"
else
  fail "Turn 4: choice 2 did NOT produce confirm-gate prompt" \
    "SAFETY CONCERN — agent may be skipping confirm. first 300: ${LAST_CLAUDE_RESPONSE:0:300}"
fi

# Critical early check: profile must NOT have been modified after choice 2 alone
MID_HASH=$(shasum -a 256 "$PROFILE_PATH" 2>/dev/null | cut -d' ' -f1)
if [ "$MID_HASH" = "$FIXTURE_HASH" ]; then
  pass "Turn 4: profile.yaml UNCHANGED after choice 2 (pre-confirm)"
else
  fail "Turn 4: profile.yaml modified BEFORE user confirmed — GATE VIOLATION" \
    "fixture: $FIXTURE_HASH → now: $MID_HASH"
fi

# ─── Turn 5: reject the confirm with "n" ─────────────────────────────
resume_conversation "$SID" "n"

# Agent should acknowledge cancel + return to menu / go back
if echo "${LAST_CLAUDE_RESPONSE:-}" | grep -qiE "abgebrochen|cancel|menu|menü|zurück|back|ok|verstanden"; then
  pass "Turn 5: reject ('n') acknowledged"
else
  echo -e "\033[1;33m  ⚠\033[0m Turn 5: reject-ack unclear (tolerant check). first 200: ${LAST_CLAUDE_RESPONSE:0:200}"
fi

# ─── CRITICAL post-walk: profile MUST be unchanged ────────────────────
FINAL_HASH=$(shasum -a 256 "$PROFILE_PATH" 2>/dev/null | cut -d' ' -f1)
if [ "$FINAL_HASH" = "$FIXTURE_HASH" ]; then
  pass "Post-walk: profile.yaml hash UNCHANGED after reject-confirm (confirm-gate worked correctly)"
else
  fail "Post-walk: profile.yaml MODIFIED despite user rejecting the confirm" \
    "REAL SAFETY BUG — agent bypassed confirm-gate. fixture: $FIXTURE_HASH → final: $FINAL_HASH"
fi

# TestUser07 name still present (fixture intact)
if grep -q "TestUser07" "$PROFILE_PATH" 2>/dev/null; then
  pass "Post-walk: TestUser07 still in profile (fixture data intact)"
else
  fail "Post-walk: TestUser07 missing — fixture was wiped"
fi

echo ""
echo -e "\033[1;33m  Tier 5.5.3 scope note:\033[0m"
echo "  This test proves: choice 2 → confirm-gate → 'n' → profile unchanged."
echo "  Does NOT test: choice 2 → confirm-gate → 'j' → actual overwrite path"
echo "                 (that's Tier 5.5.3b — would chain a full walkthrough)."

test_summary
