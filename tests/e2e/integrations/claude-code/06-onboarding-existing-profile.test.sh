#!/bin/bash
# DexHub E2E Test 06 — Existing-Profile Edge Case (Tier 5.5, first slice)
#
# Proves the walkthrough does NOT silently overwrite an existing profile.yaml.
# When user runs `*mydex` → `*onboarding` on a repo that already has a
# profile.yaml, the agent must detect it and ASK (4 choices: complete /
# new / show / cancel) rather than blindly restart the flow.
#
# Two levels:
#   - Structural (always runs, no API cost): verify mydex-agent.md contains
#     the expected "Check Existing Profile" spec phrases. Proves the
#     design is still present in the agent prompt.
#   - Live (opt-in, CLAUDE_E2E_LIVE_WALKTHROUGH=1, ~3-5 USD): install a
#     fixture profile, run the walkthrough turns, verify the agent
#     recognizes the existing profile AND respects a "cancel" choice
#     without modifying the file.
#
# Scope boundary (honest):
#   - Tests ONE of four choices (cancel). Choice 1 (complete-only) and
#     choice 2 (confirmed overwrite) are Tier 5.5.2 / 5.5.3 follow-ups.
#   - Live assertions are tolerant on exact wording; they look for any
#     of several reasonable German/English phrasings.

set -u

HARNESS="$(cd "$(dirname "$0")/../../harness" && pwd)"
CC_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$HARNESS/assertion-lib.sh"
source "$CC_DIR/claude-runner.sh"

ensure_beta_root
test_banner "06 Onboarding — existing-profile handling (Tier 5.5, choice: cancel)"

# ─── STRUCTURAL: mydex-agent has the spec ──────────────────────────────
assert_file_contains ".dexCore/core/agents/mydex-agent.md" \
  "Check Existing Profile" \
  "mydex-agent: 'Check Existing Profile' step present"

assert_file_contains ".dexCore/core/agents/mydex-agent.md" \
  "bereits ein Profil" \
  "mydex-agent: existing-profile greeting phrase present"

assert_file_contains ".dexCore/core/agents/mydex-agent.md" \
  "Profil vervollständigen" \
  "mydex-agent: choice 1 — complete existing"

assert_file_contains ".dexCore/core/agents/mydex-agent.md" \
  "Neu beginnen" \
  "mydex-agent: choice 2 — restart fresh"

assert_file_contains ".dexCore/core/agents/mydex-agent.md" \
  "überschreibt aktuelles Profil" \
  "mydex-agent: choice 2 confirmation-gate wording"

assert_file_contains ".dexCore/core/agents/mydex-agent.md" \
  "Profil anzeigen" \
  "mydex-agent: choice 3 — view without change"

assert_file_contains ".dexCore/core/agents/mydex-agent.md" \
  "Abbrechen" \
  "mydex-agent: choice 4 — cancel"

# ─── LIVE gate ─────────────────────────────────────────────────────────
if ! walkthrough_mode_enabled; then
  echo -e "\033[1;33m  ⊘ SKIPPED live portion: CLAUDE_E2E_LIVE_WALKTHROUGH=1 not set\033[0m"
  echo -e "     Reason: live portion costs real API tokens (~3-5 USD)."
  echo -e "     Run with: CLAUDE_E2E_LIVE_WALKTHROUGH=1 bash tests/e2e/06-onboarding-existing-profile.test.sh"
  pass "Live gate honored (skipped)"
  test_summary
  exit 0
fi

if ! check_claude_installed; then
  fail "Live portion requested but claude CLI missing" "install Claude Code"
  test_summary
  exit 1
fi

echo -e "\033[1;33m  ⚡ LIVE PORTION: 4 turns, existing-profile fixture + cancel-choice (REAL COST)\033[0m"

# ─── Fixture setup ─────────────────────────────────────────────────────
PROFILE_PATH="myDex/.dex/config/profile.yaml"
BACKUP_PATH="/tmp/dexhub-profile-backup-06-$$-$(date +%s).yaml"
BACKUP_DONE=0

# Back up any pre-existing real profile so we can install + safely restore
if [ -f "$PROFILE_PATH" ]; then
  if cp "$PROFILE_PATH" "$BACKUP_PATH" 2>/dev/null; then
    BACKUP_DONE=1
    pass "Pre-walk: real profile.yaml archived to $BACKUP_PATH"
  else
    fail "Pre-walk: could not back up existing profile.yaml — aborting"
    test_summary
    exit 1
  fi
fi

# Install fixture: minimal, valid, 100%-complete v1.2 profile
cat > "$PROFILE_PATH" <<'FIXTURE_YAML'
# FIXTURE — Test 06 existing-profile edge case
version: "1.2"
created_at: "2026-01-15T10:00:00Z"
updated_at: "2026-01-15T10:05:00Z"
personalization:
  name: "TestUser06"
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
  variant: "standard"
  version: "v5.0"
  started_at: "2026-01-15T10:00:00Z"
  completed_at: "2026-01-15T10:05:00Z"
  questions_answered: 5
  questions_skipped: 0
  completion_percentage: 100.0
consents: []
FIXTURE_YAML

FIXTURE_HASH=$(shasum -a 256 "$PROFILE_PATH" | cut -d' ' -f1)
pass "Fixture installed: profile.yaml with TestUser06 (100% complete, v5.0)"

# Restore trap: always remove fixture + restore real backup if any
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
pass "Turn 1: greeting → session started"

# ─── Turn 2: *mydex — should recognize existing profile ───────────────
resume_conversation "$SID" "*mydex"
# myDex greeting for completed profile should mention welcome-back OR the name/profile
if echo "${LAST_CLAUDE_RESPONSE:-}" | grep -qiE "testuser|willkommen zurück|welcome back|profil.*vollständig|100%"; then
  pass "Turn 2: myDex recognizes existing profile (greeting differs from fresh-install)"
else
  # Soft: agent may respond with standard menu; greeting-differentiation is UX polish
  echo -e "\033[1;33m  ⚠\033[0m Turn 2: greeting doesn't explicitly cite existing profile (first 200: ${LAST_CLAUDE_RESPONSE:0:200})"
fi

# ─── Turn 3: *onboarding — MUST trigger existing-profile dialog ───────
resume_conversation "$SID" "*onboarding"
if echo "${LAST_CLAUDE_RESPONSE:-}" | grep -qiE "bereits ein profil|schon.*profil|vollständigkeit|existing profile|already.*profile"; then
  pass "Turn 3: *onboarding detects existing profile"
else
  fail "Turn 3: *onboarding did NOT detect existing profile" \
    "first 300: ${LAST_CLAUDE_RESPONSE:0:300}"
fi

# Four choices should be offered (or at least the cancel option)
if echo "${LAST_CLAUDE_RESPONSE:-}" | grep -qiE "abbrechen|cancel"; then
  pass "Turn 3: cancel option surfaced in choice menu"
else
  echo -e "\033[1;33m  ⚠\033[0m Turn 3: cancel option not obviously surfaced (tolerant check)"
fi

# ─── Turn 4: choose "4" (Abbrechen) — agent MUST NOT modify profile ───
resume_conversation "$SID" "4"
# Agent should confirm exit / return to menu
if echo "${LAST_CLAUDE_RESPONSE:-}" | grep -qiE "abbrechen|cancel|menu|menü|zurück|back"; then
  pass "Turn 4: cancel honored (agent did not proceed to overwrite)"
else
  echo -e "\033[1;33m  ⚠\033[0m Turn 4: cancel-ack unclear (tolerant check). first 200: ${LAST_CLAUDE_RESPONSE:0:200}"
fi

# ─── Post-walk: critical assertion — profile UNCHANGED ────────────────
CURRENT_HASH=$(shasum -a 256 "$PROFILE_PATH" 2>/dev/null | cut -d' ' -f1)
if [ "$CURRENT_HASH" = "$FIXTURE_HASH" ]; then
  pass "Post-walk: profile.yaml hash UNCHANGED — no silent overwrite (critical safety assertion)"
else
  fail "Post-walk: profile.yaml WAS MODIFIED despite user choosing cancel" \
    "fixture hash: $FIXTURE_HASH; current hash: $CURRENT_HASH. This is a REAL BUG — agent violated user consent."
fi

# TestUser06 name should still be in the file
if grep -q "TestUser06" "$PROFILE_PATH" 2>/dev/null; then
  pass "Post-walk: TestUser06 still present (fixture data intact)"
else
  fail "Post-walk: TestUser06 not in profile — fixture was wiped"
fi

echo ""
echo -e "\033[1;33m  Tier 5.5 scope note:\033[0m"
echo "  This test proves: existing-profile + cancel-choice → no modification."
echo "  Follow-ups: Tier 5.5.2 choice 1 (complete-only, partial fill-in),"
echo "              Tier 5.5.3 choice 2 (confirmed overwrite path)."

test_summary
