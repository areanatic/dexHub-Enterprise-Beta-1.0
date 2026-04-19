#!/bin/bash
# DexHub E2E Test 00 — Fresh Install State
# Validates: a fresh clone has everything a new user needs to start
# No Claude Code invocation required — purely structural

set -u  # undefined vars = error

# Source harness
HARNESS="$(cd "$(dirname "$0")/harness" && pwd)"
source "$HARNESS/assertion-lib.sh"

ensure_beta_root
test_banner "00 Fresh Install State"

# 1. Critical files that must exist for a fresh user
assert_file_exists "README.md" "README.md present (user's first touchpoint)"
assert_file_exists ".gitignore" ".gitignore present (protects user privacy)"
assert_file_exists "LICENSE" "LICENSE present"
assert_file_exists "CONTRIBUTING.md" "CONTRIBUTING.md present"

# 2. SSOT compile pipeline
assert_file_exists ".dexCore/core/instructions/SHARED.md" "SSOT SHARED.md present"
assert_file_exists ".dexCore/core/instructions/truth-manifest.md" "truth-manifest.md present"
assert_file_exists ".dexCore/core/instructions/claude-specific.md" "Claude tail present"
assert_file_exists ".dexCore/core/instructions/copilot-specific.md" "Copilot tail present"
assert_file_exists ".dexCore/_dev/tools/build-instructions.sh" "build-instructions.sh present"

# 3. Generated outputs exist (CLAUDE.md + copilot-instructions.md must be committed)
assert_file_exists ".claude/CLAUDE.md" "Generated CLAUDE.md present"
assert_file_exists ".github/copilot-instructions.md" "Generated copilot-instructions.md present"

# 4. SSOT outputs are in sync (not stale)
if bash .dexCore/_dev/tools/build-instructions.sh check >/dev/null 2>&1; then
  pass "SSOT outputs in sync with sources"
else
  fail "SSOT drift detected — run build-instructions.sh"
fi

# 5. DexMaster agent exists and has state model
assert_file_exists ".dexCore/core/agents/dex-master.md" "DexMaster agent definition present"
assert_file_contains ".dexCore/core/agents/dex-master.md" "intent-detection" "DexMaster has intent-detection block (D1)"
assert_file_contains ".dexCore/core/agents/dex-master.md" "SESSION STATE RECOVERY" "DexMaster has session recovery (D1 Layer 2)"

# 6. myDex workspace structure
assert_dir_exists "myDex" "myDex/ workspace present"
assert_dir_exists "myDex/.dex" "myDex/.dex/ system dir present"
assert_dir_exists "myDex/.dex/config" "Config dir present"
assert_dir_exists "myDex/.dex/chronicle" "Chronicle dir present"
assert_dir_exists "myDex/.dex/decisions" "Decisions dir present"
assert_dir_exists "myDex/inbox" "Inbox dir present"
assert_dir_exists "myDex/drafts" "Drafts dir present"

# 7. Onboarding configuration available
assert_file_exists ".dexCore/_cfg/onboarding-questions.yaml" "Onboarding questions YAML present"
assert_file_exists "myDex/.dex/config/profile.yaml.example" "Profile YAML example present (template)"
assert_yaml_valid ".dexCore/_cfg/onboarding-questions.yaml" "onboarding-questions.yaml is valid YAML"

# 8. Agent manifest present and non-trivial
assert_file_exists ".dexCore/_cfg/agent-manifest.csv" "Agent manifest CSV present"
AGENT_COUNT=$(tail -n +2 .dexCore/_cfg/agent-manifest.csv 2>/dev/null | wc -l | tr -d ' ')
if [ "${AGENT_COUNT:-0}" -gt 5 ]; then
  pass "Agent manifest has $AGENT_COUNT agents (>5 minimum)"
else
  fail "Agent manifest too small: $AGENT_COUNT agents"
fi

# 9. Workflow manifest present
assert_file_exists ".dexCore/_cfg/workflow-manifest.csv" "Workflow manifest CSV present"
WORKFLOW_COUNT=$(tail -n +2 .dexCore/_cfg/workflow-manifest.csv 2>/dev/null | wc -l | tr -d ' ')
if [ "${WORKFLOW_COUNT:-0}" -gt 5 ]; then
  pass "Workflow manifest has $WORKFLOW_COUNT workflows (>5 minimum)"
else
  fail "Workflow manifest too small: $WORKFLOW_COUNT workflows"
fi

# 10. Gitignore protects user privacy (critical for fresh install)
assert_file_contains ".gitignore" "myDex/.dex/CONTEXT.md" "CONTEXT.md is gitignored (privacy)"
assert_file_contains ".gitignore" "profile.yaml" "profile.yaml is gitignored (privacy)"
assert_file_contains ".gitignore" "chronicle" "chronicle/ is gitignored (privacy)"

# 11. No leftover personal data in committed files
assert_file_not_contains "README.md" "azamani1|@dhl\\.com|/Users/az" "README has no personal paths"
assert_file_not_contains ".dexCore/core/instructions/SHARED.md" "/Users/az|azamani1" "SHARED.md has no personal paths"

# 12. Guardrail hook infrastructure
assert_file_exists ".claude/settings.json" "Claude settings present (PostToolUse hook)"
assert_file_exists ".claude/skills/dexhub-testing/scripts/post-write-check.sh" "post-write-check hook present"

test_summary
