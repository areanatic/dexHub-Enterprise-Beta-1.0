#!/bin/bash
# DexHub E2E Test 08 — View-Profile Path (Tier 5.5.4)
#
# Smallest slice in the existing-profile menu: user picks choice 3
# ("Profil anzeigen"), agent displays profile content, returns to menu,
# profile UNCHANGED.
#
# Lower stakes than 06 (cancel) or 07 (confirm-gate reject) but still
# worth locking down: choice 3 should be a pure read operation. Any
# write here would be a bug.
#
# Two levels:
#   - Structural (always runs): mydex-agent.md has the "Read and display
#     profile.yaml (formatted), return to menu" spec
#   - Live (opt-in CLAUDE_E2E_LIVE_WALKTHROUGH=1, ~3 USD): install fixture,
#     pick "3", assert response includes fixture content + SHA-256 UNCHANGED

set -u

HARNESS="$(cd "$(dirname "$0")/harness" && pwd)"
source "$HARNESS/assertion-lib.sh"
source "$HARNESS/claude-runner.sh"

ensure_beta_root
test_banner "08 Onboarding — view-profile (Tier 5.5.4, choice 3)"

# ─── STRUCTURAL ──────────────────────────────────────────────────────
assert_file_contains ".dexCore/core/agents/mydex-agent.md" \
  "Read and display profile.yaml" \
  "mydex-agent: choice 3 — read + display spec present"

assert_file_contains ".dexCore/core/agents/mydex-agent.md" \
  "return to menu" \
  "mydex-agent: choice 3 — returns to menu after display"

assert_file_contains ".dexCore/core/agents/mydex-agent.md" \
  "3 → Read and display" \
  "mydex-agent: choice 3 handler line present"

# ─── LIVE gate ───────────────────────────────────────────────────────
if ! walkthrough_mode_enabled; then
  echo -e "\033[1;33m  ⊘ SKIPPED live portion\033[0m"
  echo "     Run with: CLAUDE_E2E_LIVE_WALKTHROUGH=1 bash tests/e2e/08-onboarding-view-profile.test.sh"
  pass "Live gate honored (skipped)"
  test_summary
  exit 0
fi

if ! check_claude_installed; then
  fail "claude CLI missing"
  test_summary
  exit 1
fi

echo -e "\033[1;33m  ⚡ LIVE PORTION: 4 turns, view-profile choice (REAL COST ~3 USD)\033[0m"

# ─── Fixture setup ───────────────────────────────────────────────────
PROFILE_PATH="myDex/.dex/config/profile.yaml"
BACKUP_PATH="/tmp/dexhub-profile-backup-08-$$-$(date +%s).yaml"
BACKUP_DONE=0

if [ -f "$PROFILE_PATH" ]; then
  cp "$PROFILE_PATH" "$BACKUP_PATH" && rm "$PROFILE_PATH" && BACKUP_DONE=1
  pass "Pre-walk: real profile archived"
fi

cat > "$PROFILE_PATH" <<'FIXTURE_YAML'
# FIXTURE — Test 08 view-profile edge case
version: "1.2"
created_at: "2026-01-15T10:00:00Z"
updated_at: "2026-01-15T10:05:00Z"
personalization:
  name: "TestUser08"
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
  questions_answered: 5
  questions_skipped: 0
  completion_percentage: 100.0
consents: []
FIXTURE_YAML

FIXTURE_HASH=$(shasum -a 256 "$PROFILE_PATH" | cut -d' ' -f1)
pass "Fixture: TestUser08 installed (hash=${FIXTURE_HASH:0:12})"

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
if echo "${LAST_CLAUDE_RESPONSE:-}" | grep -qiE "bereits ein profil|vollständigkeit|existing"; then
  pass "Turn 3: existing-profile dialog surfaced"
else
  fail "Turn 3: existing-profile not detected" "first 300: ${LAST_CLAUDE_RESPONSE:0:300}"
fi

# ─── Turn 4: choice "3" — view profile ───────────────────────────────
resume_conversation "$SID" "3"

# Agent should display profile content. TestUser08 name is the strongest
# signal — if it appears in the response, the agent read + displayed.
if echo "${LAST_CLAUDE_RESPONSE:-}" | grep -q "TestUser08"; then
  pass "Turn 4: profile content displayed (TestUser08 name visible in response)"
else
  fail "Turn 4: profile name NOT in response — did agent actually read + display?" \
    "first 300: ${LAST_CLAUDE_RESPONSE:0:300}"
fi

# Agent should indicate return-to-menu
if echo "${LAST_CLAUDE_RESPONSE:-}" | grep -qiE "menu|menü|zurück|back|weiter"; then
  pass "Turn 4: return-to-menu signal present"
else
  echo -e "\033[1;33m  ⚠\033[0m Turn 4: menu-return signal unclear (tolerant)"
fi

# ─── CRITICAL: profile UNCHANGED ─────────────────────────────────────
FINAL_HASH=$(shasum -a 256 "$PROFILE_PATH" 2>/dev/null | cut -d' ' -f1)
if [ "$FINAL_HASH" = "$FIXTURE_HASH" ]; then
  pass "Post-walk: profile.yaml hash UNCHANGED after view (read-only op confirmed)"
else
  fail "Post-walk: profile.yaml MODIFIED during a VIEW operation — REAL BUG" \
    "fixture: $FIXTURE_HASH → final: $FINAL_HASH"
fi

if grep -q "TestUser08" "$PROFILE_PATH" 2>/dev/null; then
  pass "Post-walk: TestUser08 still in profile"
else
  fail "Post-walk: TestUser08 missing"
fi

echo ""
echo -e "\033[1;33m  Tier 5.5.4 scope:\033[0m choice 3 = pure read. No mutations."

test_summary
