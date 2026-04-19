#!/usr/bin/env bash
# ============================================================
# DexHub Enterprise Alpha — Validation Script
# ============================================================
# Usage: bash .dexCore/_dev/tools/validate.sh
# Runs automated checks on the DexHub project.
# ============================================================

set -euo pipefail

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'
BOLD='\033[1m'

# Counters
PASS=0
FAIL=0
WARN=0

# Find project root (relative to script location)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
cd "$PROJECT_ROOT"

pass() { PASS=$((PASS + 1)); echo -e "  ${GREEN}PASS${NC} $1"; }
fail() { FAIL=$((FAIL + 1)); echo -e "  ${RED}FAIL${NC} $1"; }
warn() { WARN=$((WARN + 1)); echo -e "  ${YELLOW}WARN${NC} $1"; }
skip() { echo -e "  ${YELLOW}SKIP${NC} $1"; }

# ─── Mode detection ───────────────────────────────────────────────
# Enterprise bundle = stripped of integration modules (no .claude/, no
# tests/e2e/integrations/). validate.sh auto-detects this and skips
# Claude-tail-specific checks that would otherwise FAIL cosmetically.
# See .dexCore/_dev/docs/PLATFORM-POLICY.md.
HAS_CLAUDE_TAIL=1
if [ ! -f ".claude/CLAUDE.md" ]; then
  HAS_CLAUDE_TAIL=0
fi

echo -e "${BOLD}========================================${NC}"
echo -e "${BOLD} DexHub EA — Validation Suite${NC}"
if [ "$HAS_CLAUDE_TAIL" = "0" ]; then
  echo -e "${BOLD} Mode: ENTERPRISE BUNDLE (Claude tail absent)${NC}"
fi
echo -e "${BOLD}========================================${NC}"
echo ""

# ==================== SECTION 1: Byte Limits ====================
echo -e "${BOLD}[1/24] Byte Limits${NC}"

BYTES=$(wc -c < .github/copilot-instructions.md)
# Limit raised 2026-04-20 from 30,500 to 35,000 to accommodate Phase 5.2.d
# L1 Wiki injection (per user's wiki authoring, up to WIKI_MAX_COPILOT=1000 bytes).
# Headroom: ~4,500 bytes for natural SSOT + wiki growth.
if [ "$BYTES" -le 35000 ]; then
  pass "copilot-instructions.md: ${BYTES} bytes (limit: 35,000)"
else
  fail "copilot-instructions.md: ${BYTES} bytes EXCEEDS 35,000 limit"
fi

# ==================== SECTION 2: Bug Status ====================
echo -e "\n${BOLD}[2/24] Bug Status${NC}"

OPEN_BUGS=$(grep -c 'status: open\|status: confirmed' .dexCore/_dev/todos/bugs.md 2>/dev/null || true)
OPEN_BUGS=$(echo "$OPEN_BUGS" | tr -d '[:space:]')
if [ "$OPEN_BUGS" -eq 0 ] 2>/dev/null; then
  pass "No open/confirmed bugs"
else
  fail "$OPEN_BUGS bugs still open/confirmed"
fi

FIXED_BUGS=$(grep -c 'status: fixed' .dexCore/_dev/todos/bugs.md 2>/dev/null || true)
FIXED_BUGS=$(echo "$FIXED_BUGS" | tr -d '[:space:]')
: "${FIXED_BUGS:=0}"
pass "$FIXED_BUGS bugs marked as fixed"

# Bug detail checks (only if bugs are tracked)
BUG_COUNT=$(grep -c 'id: BUG-' .dexCore/_dev/todos/bugs.md 2>/dev/null || true)
BUG_COUNT=$(echo "$BUG_COUNT" | tr -d '[:space:]')
: "${BUG_COUNT:=0}"
if [ "$BUG_COUNT" -gt 0 ]; then
  pass "Bug tracking active ($BUG_COUNT bugs tracked)"
else
  pass "Bug tracking ready (no bugs logged yet)"
fi

# ==================== SECTION 3: Cross-Platform Consistency ====================
echo -e "\n${BOLD}[3/24] Cross-Platform Consistency (CLAUDE.md vs copilot-instructions.md)${NC}"

if [ "$HAS_CLAUDE_TAIL" = "0" ]; then
  skip "§3 cross-platform parity: enterprise bundle has only Copilot tail (nothing to parity-check against)"
  # In enterprise mode, check copilot-instructions.md content for the same concepts
  if grep -q 'GREETING' .github/copilot-instructions.md && grep -q 'dex-master.md' .github/copilot-instructions.md; then
    pass "GREETING action: references dex-master.md in copilot-instructions.md"
  else
    fail "GREETING action missing in copilot-instructions.md"
  fi
  if grep -q 'AGENT-REQUEST' .github/copilot-instructions.md; then
    pass "AGENT-REQUEST action present in copilot-instructions.md"
  else
    fail "AGENT-REQUEST missing in copilot-instructions.md"
  fi
  if [ "$(grep -c 'agent-manifest.csv' .github/copilot-instructions.md 2>/dev/null || echo 0)" -ge 1 ]; then
    pass "Agent Resolution rule in copilot-instructions.md"
  else
    fail "Agent Resolution missing in copilot-instructions.md"
  fi
  if grep -q 'keep scope proportional' .github/copilot-instructions.md; then
    pass "G4 anti-overplanning in copilot-instructions.md"
  else
    fail "G4 anti-overplanning missing in copilot-instructions.md"
  fi
  if grep -qi 'Never invent or simplify.*menu' .github/copilot-instructions.md; then
    pass "NEVER DO: menu integrity in copilot-instructions.md"
  else
    fail "NEVER DO menu integrity missing in copilot-instructions.md"
  fi
else
  # GREETING action — check state model references in both
  if grep -q 'GREETING' .claude/CLAUDE.md && \
     grep -q 'GREETING' .github/copilot-instructions.md && \
     grep -q 'dex-master.md' .claude/CLAUDE.md && \
     grep -q 'dex-master.md' .github/copilot-instructions.md; then
    pass "GREETING action: references dex-master.md in both"
  else
    fail "GREETING action mismatch"
  fi

  # AGENT-REQUEST action — check agent loading protocol in both
  if grep -q 'AGENT-REQUEST' .claude/CLAUDE.md && \
     grep -q 'AGENT-REQUEST' .github/copilot-instructions.md; then
    CLAUDE_AR=$(grep 'AGENT-REQUEST' .claude/CLAUDE.md | head -1)
    COPILOT_AR=$(grep 'AGENT-REQUEST' .github/copilot-instructions.md | head -1)
    if [ "$CLAUDE_AR" = "$COPILOT_AR" ]; then
      pass "AGENT-REQUEST action identical"
    else
      warn "AGENT-REQUEST wording differs (may be platform-specific tail)"
    fi
  else
    fail "AGENT-REQUEST action mismatch"
  fi

  # Agent Resolution rule
  CLAUDE_RES=$(grep -c 'agent-manifest.csv' .claude/CLAUDE.md 2>/dev/null || echo "0")
  COPILOT_RES=$(grep -c 'agent-manifest.csv' .github/copilot-instructions.md 2>/dev/null || echo "0")
  if [ "$CLAUDE_RES" -ge 1 ] && [ "$COPILOT_RES" -ge 1 ]; then
    pass "Agent Resolution rule in both files"
  else
    fail "Agent Resolution missing (CLAUDE=$CLAUDE_RES, COPILOT=$COPILOT_RES)"
  fi

  # G4 Anti-Overplanning
  if grep -q 'keep scope proportional' .claude/CLAUDE.md && grep -q 'keep scope proportional' .github/copilot-instructions.md; then
    pass "G4 anti-overplanning in both files"
  else
    fail "G4 anti-overplanning missing in one file"
  fi

  # NEVER DO — menu integrity rule
  if grep -qi 'Never invent or simplify.*menu' .claude/CLAUDE.md && grep -qi 'Never invent or simplify.*menu' .github/copilot-instructions.md; then
    pass "NEVER DO: menu integrity rule in both"
  else
    fail "NEVER DO #1 mismatch"
  fi
fi

# ==================== SECTION 4: File Existence ====================
echo -e "\n${BOLD}[4/24] Critical File Existence${NC}"

FILES=(
  ".dexCore/core/agents/dex-master.md"
  ".dexCore/core/agents/mydex-agent.md"
  ".dexCore/_cfg/agent-manifest.csv"
  ".dexCore/_cfg/config.yaml"
  ".dexCore/_dev/agents/dev-mode-master.md"
  ".dexCore/_dev/CHANGELOG.md"
  ".dexCore/_dev/todos/bugs.md"
  ".dexCore/_dev/todos/features.md"
  ".dexCore/_dev/tools/dexhub-dashboard.html"
  ".dexCore/_dev/tools/generate-dashboard.py"
  ".dexCore/_dev/docs/SILO-ARCHITECTURE.md"
  ".claude/CLAUDE.md"
  ".github/copilot-instructions.md"
  ".github/agents/dex-master.agent.md"
  ".github/agents/mydex.agent.md"
  ".github/agents/analyst.agent.md"
  ".github/agents/architect.agent.md"
  ".github/agents/dev.agent.md"
  "myDex/.dex/config/profile.yaml.example"
)

for f in "${FILES[@]}"; do
  if [ -e "$f" ]; then
    pass "$f"
  elif [ "$f" = ".claude/CLAUDE.md" ] && [ "$HAS_CLAUDE_TAIL" = "0" ]; then
    skip "$f (enterprise bundle — Claude tail stripped per PLATFORM-POLICY)"
  else
    fail "$f MISSING"
  fi
done

# ==================== SECTION 5: Feature Validation ====================
echo -e "\n${BOLD}[5/24] Feature Artifact Validation${NC}"

# F-005: Guardrails G1-G6
for g in G1 G2 G3 G4 G5 G6; do
  if [ "$HAS_CLAUDE_TAIL" = "0" ]; then
    # Enterprise: check only the Copilot tail
    if grep -q "$g:" .github/copilot-instructions.md; then
      pass "Guardrail $g in copilot-instructions.md"
    else
      fail "Guardrail $g missing in copilot-instructions.md"
    fi
  else
    if grep -q "$g:" .claude/CLAUDE.md && grep -q "$g:" .github/copilot-instructions.md; then
      pass "Guardrail $g in both instruction files"
    else
      fail "Guardrail $g missing"
    fi
  fi
done

# F-008: Templates + Schemas
TEMPLATES=$(find .dexCore/dxm/templates -name "*.md" 2>/dev/null | wc -l)
if [ "$TEMPLATES" -ge 5 ]; then
  pass "F-008: $TEMPLATES templates found"
else
  warn "F-008: Only $TEMPLATES templates (expected 5+)"
fi

SCHEMAS=$(find .dexCore/dxm/schemas -name "*.yaml" 2>/dev/null | wc -l)
if [ "$SCHEMAS" -ge 2 ]; then
  pass "F-008: $SCHEMAS schemas found"
else
  warn "F-008: Only $SCHEMAS schemas (expected 2+)"
fi

# F-009: Multi-Platform (.agent.md files)
AGENT_MD=$(find .github/agents -name "*.agent.md" 2>/dev/null | wc -l)
if [ "$AGENT_MD" -ge 5 ]; then
  pass "F-009: $AGENT_MD .agent.md files"
else
  warn "F-009: Only $AGENT_MD .agent.md files (expected 5+)"
fi

# F-012: DexMemory
if [ "$HAS_CLAUDE_TAIL" = "0" ]; then
  if grep -q 'DexMemory' .github/copilot-instructions.md; then
    pass "F-012: DexMemory in copilot-instructions.md (enterprise mode)"
  else
    fail "F-012: DexMemory missing from copilot-instructions.md"
  fi
elif grep -q 'DexMemory' .claude/CLAUDE.md; then
  pass "F-012: DexMemory referenced in CLAUDE.md"
else
  fail "F-012: DexMemory missing from CLAUDE.md"
fi

if [ -d "myDex/.dex/chronicle" ] && [ -d "myDex/.dex/decisions" ]; then
  pass "F-012: chronicle + decisions directories exist"
else
  warn "F-012: chronicle/decisions directories missing"
fi

# Intent Detection Protocol
# In enterprise mode, check copilot-instructions.md; otherwise check both (CLAUDE.md primary)
INTENT_FILE=".claude/CLAUDE.md"
[ "$HAS_CLAUDE_TAIL" = "0" ] && INTENT_FILE=".github/copilot-instructions.md"
if grep -q 'GREETING.*AGENT-REQUEST.*TASK-DIRECT' "$INTENT_FILE" 2>/dev/null || \
   (grep -q 'GREETING' "$INTENT_FILE" && grep -q 'TASK-DIRECT' "$INTENT_FILE"); then
  pass "Intent Detection Protocol present (in $INTENT_FILE)"
else
  fail "Intent Detection Protocol missing (in $INTENT_FILE)"
fi

# Dev-Mode Welcome + Dashboard
if grep -q 'Dev-Mode.*lets you shape DexHub' .dexCore/_dev/agents/dev-mode-master.md; then
  pass "Dev-Mode: Welcome context present"
else
  fail "Dev-Mode: Welcome missing"
fi

if grep -q '\*dashboard' .dexCore/_dev/agents/dev-mode-master.md; then
  pass "Dev-Mode: *dashboard command defined"
else
  fail "Dev-Mode: *dashboard missing"
fi

# Agent Manifest has name column
if head -1 .dexCore/_cfg/agent-manifest.csv | grep -q 'name'; then
  pass "Agent manifest has 'name' column"
else
  fail "Agent manifest missing 'name' column"
fi

# ==================== SECTION 6: Architecture Rules ====================
echo -e "\n${BOLD}[6/24] Architecture Rules${NC}"

# G3: No files in root (except allowed)
ALLOWED_ROOT="CONTRIBUTING.md|LICENSE|NOTICE|README.md|.gitignore|.gitattributes|myDex|tests"
ROOT_FILES=$(ls -1 "$PROJECT_ROOT" 2>/dev/null | grep -vE "^\.|$ALLOWED_ROOT" || true)
if [ -z "$ROOT_FILES" ]; then
  pass "G3: No unauthorized files in root"
else
  fail "G3: Unauthorized files in root: $ROOT_FILES"
fi

# Dashboard generator script exists
if [ -f ".dexCore/_dev/tools/generate-dashboard.py" ]; then
  pass "Dashboard generator script exists"
else
  warn "Dashboard generator script missing"
fi

# CHANGELOG exists and is writable
if [ -f ".dexCore/_dev/CHANGELOG.md" ]; then
  pass "CHANGELOG exists"
else
  fail "CHANGELOG missing"
fi

# ==================== SECTION 7: Sanity Checks ====================
echo -e "\n${BOLD}[7/24] Sanity Checks${NC}"

# Agent count
AGENT_FILES=$(find .dexCore/dxm/agents -name "*.md" 2>/dev/null | wc -l)
pass "Agent .md files in dxm/agents: $AGENT_FILES"

MANIFEST_ENTRIES=$(tail -n +2 .dexCore/_cfg/agent-manifest.csv | wc -l)
pass "Agent manifest entries: $MANIFEST_ENTRIES"

# Config sanity
if grep -q 'current_project: null' .dexCore/_cfg/config.yaml 2>/dev/null || \
   grep -q 'current_project:$' .dexCore/_cfg/config.yaml 2>/dev/null; then
  pass "Config: current_project is null (no leak)"
else
  warn "Config: current_project may have a value"
fi

# ==================== SECTION 8: Agent File Validation ====================
echo -e "\n${BOLD}[8/24] Agent File Validation${NC}"

# Check all .agent.md files have required frontmatter
for agent_file in .github/agents/*.agent.md; do
  name=$(basename "$agent_file" .agent.md)
  if head -5 "$agent_file" | grep -q 'description:'; then
    pass "Agent $name: has description"
  else
    fail "Agent $name: MISSING description in frontmatter"
  fi
  if head -5 "$agent_file" | grep -q 'model:'; then
    pass "Agent $name: has model routing"
  else
    warn "Agent $name: no model: in frontmatter"
  fi
done

# DexMaster should use gpt-4o (free model)
if head -5 .github/agents/dex-master.agent.md | grep -q 'gpt-4o'; then
  pass "DexMaster uses gpt-4o (free model)"
else
  warn "DexMaster not using gpt-4o"
fi

# ==================== SECTION 9: Skill Validation ====================
echo -e "\n${BOLD}[9/24] Skill Validation${NC}"

SKILL_COUNT=$(find .github/skills -name "SKILL.md" 2>/dev/null | wc -l)
pass "Copilot Skills found: $SKILL_COUNT"

for skill_dir in .github/skills/*/; do
  skill_name=$(basename "$skill_dir")
  if [ -f "$skill_dir/SKILL.md" ]; then
    if head -5 "$skill_dir/SKILL.md" | grep -q 'name:'; then
      pass "Skill $skill_name: has name"
    else
      fail "Skill $skill_name: MISSING name in frontmatter"
    fi
    if head -5 "$skill_dir/SKILL.md" | grep -q 'description:'; then
      pass "Skill $skill_name: has description"
    else
      fail "Skill $skill_name: MISSING description in frontmatter"
    fi
  else
    fail "Skill $skill_name: MISSING SKILL.md"
  fi
done

# ==================== SECTION 10: Manifest Sync ====================
echo -e "\n${BOLD}[10/24] Manifest Sync${NC}"

# Workflow manifest paths should use .dexCore/ not dex/
BAD_PATHS=$(grep -c '"dex/' .dexCore/_cfg/workflow-manifest.csv 2>/dev/null || echo 0)
BAD_PATHS=$(echo "$BAD_PATHS" | tr -d '[:space:]')
if [ "$BAD_PATHS" -eq 0 ]; then
  pass "Workflow manifest: all paths use .dexCore/"
else
  fail "Workflow manifest: $BAD_PATHS paths still use 'dex/' instead of '.dexCore/'"
fi

# No bmb or cis module references
BMB_COUNT=$(grep -c '"bmb"' .dexCore/_cfg/workflow-manifest.csv 2>/dev/null || echo 0)
BMB_COUNT=$(echo "$BMB_COUNT" | tr -d '[:space:]')
CIS_COUNT=$(grep -c '"cis"' .dexCore/_cfg/workflow-manifest.csv 2>/dev/null || echo 0)
CIS_COUNT=$(echo "$CIS_COUNT" | tr -d '[:space:]')
if [ "$BMB_COUNT" -eq 0 ] && [ "$CIS_COUNT" -eq 0 ]; then
  pass "Workflow manifest: no legacy module names (bmb/cis)"
else
  fail "Workflow manifest: $BMB_COUNT bmb + $CIS_COUNT cis references remain"
fi

# ==================== SECTION 11: Platform Hygiene ====================
echo -e "\n${BOLD}[11/24] Platform Hygiene${NC}"

# No Claude Code refs in user-facing files
CC_REFS=0
for check_file in .github/copilot-instructions.md README.md .dexCore/_dev/docs/CONTRIBUTING.md; do
  if [ -f "$check_file" ]; then
    COUNT=$(grep -ci "claude code" "$check_file" 2>/dev/null || echo 0)
    COUNT=$(echo "$COUNT" | tr -d '[:space:]')
    CC_REFS=$((CC_REFS + COUNT))
  fi
done
if [ "$CC_REFS" -eq 0 ]; then
  pass "Platform hygiene: 0 Claude Code refs in user-facing files"
else
  fail "Platform hygiene: $CC_REFS Claude Code references found"
fi

# No standalone EA-1.0 refs in key files (hybrid "EA-1.0, updated EA-2.0" is OK)
EA10_REFS=0
for check_file in .github/copilot-instructions.md README.md .dexCore/core/agents/dex-master.md; do
  if [ -f "$check_file" ]; then
    COUNT=$(grep -cE 'EA-1\.0[^-]' "$check_file" 2>/dev/null || echo 0)
    HYBRID=$(grep -cE 'EA-1\.0.*updated' "$check_file" 2>/dev/null || echo 0)
    COUNT=$(echo "$COUNT" | tr -d '[:space:]')
    HYBRID=$(echo "$HYBRID" | tr -d '[:space:]')
    EA10_REFS=$((EA10_REFS + COUNT - HYBRID))
  fi
done
if [ "$EA10_REFS" -eq 0 ]; then
  pass "Version hygiene: 0 EA-1.0 refs in key files"
else
  fail "Version hygiene: $EA10_REFS EA-1.0 references remain"
fi

# LICENSE file exists
if [ -f "LICENSE" ]; then
  pass "LICENSE file exists"
else
  fail "LICENSE file MISSING"
fi

# ==================== SECTION 12: Number Consistency ====================
echo -e "\n${BOLD}[12/24] Number Consistency${NC}"

# Count actual values
ACTUAL_AGENTS=$(tail -n +2 .dexCore/_cfg/agent-manifest.csv | wc -l | tr -d ' ')
ACTUAL_SKILLS=$(find .github/skills -name "SKILL.md" 2>/dev/null | wc -l | tr -d ' ')
ACTUAL_WORKFLOWS=$(find .dexCore -name "workflow.yaml" 2>/dev/null | wc -l | tr -d ' ')
ACTUAL_AGENT_FILES=$(ls .github/agents/*.agent.md 2>/dev/null | wc -l | tr -d ' ')

pass "Actual counts: ${ACTUAL_AGENTS} agents, ${ACTUAL_SKILLS} skills, ${ACTUAL_WORKFLOWS} workflows, ${ACTUAL_AGENT_FILES} .agent.md"

# Check README claims match reality
if grep -qiE "${ACTUAL_SKILLS} (skills|knowledge packs)" README.md 2>/dev/null; then
  pass "README skill count matches reality ($ACTUAL_SKILLS)"
else
  warn "README skill count may not match reality ($ACTUAL_SKILLS actual)"
fi

# Guard: No hardcoded exact agent/workflow counts in user-facing docs (use 40+ instead)
HARDCODED_COUNTS=0
for guard_file in README.md .claude/CLAUDE.md; do
  if [ -f "$guard_file" ]; then
    HC=$(grep -cE '\b(39|40|41|42|43|44|45) (agents|Agents|workflows|Workflows|specialized|expert|production|structured)' "$guard_file" 2>/dev/null || echo 0)
    HC=$(echo "$HC" | tr -d '[:space:]')
    HARDCODED_COUNTS=$((HARDCODED_COUNTS + HC))
  fi
done
if [ "$HARDCODED_COUNTS" -eq 0 ]; then
  pass "No hardcoded exact counts in user-facing docs (using 40+ pattern)"
else
  fail "Found $HARDCODED_COUNTS hardcoded exact agent/workflow counts — use '40+' instead"
fi

# ==================== SECTION 13: Workflow YAML Validation ====================
echo -e "\n${BOLD}[13/24] Workflow YAML Validation${NC}"

WORKFLOW_PASS=0
WORKFLOW_FAIL=0
for wf in $(find .dexCore -name "workflow.yaml" -not -path "*/workflow-template/*"); do
  WF_NAME=$(basename "$(dirname "$wf")")
  # Check basic structure
  if grep -q "name:" "$wf" 2>/dev/null; then
    WORKFLOW_PASS=$((WORKFLOW_PASS + 1))
  else
    fail "Workflow $WF_NAME: MISSING name field"
    WORKFLOW_FAIL=$((WORKFLOW_FAIL + 1))
  fi
  if grep -q "description:" "$wf" 2>/dev/null; then
    WORKFLOW_PASS=$((WORKFLOW_PASS + 1))
  else
    fail "Workflow $WF_NAME: MISSING description field"
    WORKFLOW_FAIL=$((WORKFLOW_FAIL + 1))
  fi
done
pass "Workflow YAML validation: $WORKFLOW_PASS checks passed across $(find .dexCore -name 'workflow.yaml' -not -path '*/workflow-template/*' | wc -l | tr -d ' ') workflows"
if [ "$WORKFLOW_FAIL" -gt 0 ]; then
  fail "Workflow YAML: $WORKFLOW_FAIL fields missing"
fi

# ==================== SECTION 14: Agent Persona Consistency ====================
echo -e "\n${BOLD}[14/24] Agent Persona Consistency${NC}"

for agent_file in .github/agents/*.agent.md; do
  name=$(basename "$agent_file" .agent.md)
  # Skip self-contained agents (no separate persona file)
  if echo "$name" | grep -qE "dhl-|onboarding"; then
    pass "Agent $name: self-contained (no persona file)"
    continue
  fi
  # Extract persona path from activation step (dxm/agents, _dev/agents, or custom-agents)
  PERSONA_PATH=$(grep -o '\.dexCore/[a-z/_-]*/[a-z_-]*.md' "$agent_file" 2>/dev/null | grep -E '(agents|custom-agents)/' | head -1 || true)
  if [ -n "$PERSONA_PATH" ] && [ -f "$PERSONA_PATH" ]; then
    pass "Agent $name: persona file exists ($PERSONA_PATH)"
  elif [ -n "$PERSONA_PATH" ]; then
    fail "Agent $name: persona file MISSING ($PERSONA_PATH)"
  else
    warn "Agent $name: no persona path found in activation"
  fi
done

# ==================== SECTION 15: Cross-Reference Integrity ====================
echo -e "\n${BOLD}[15/24] Cross-Reference Integrity${NC}"

# Check key paths mentioned in copilot-instructions.md
CRITICAL_PATHS=(
  ".dexCore/core/tasks/workflow.xml"
  ".dexCore/_cfg/config.yaml"
  ".dexCore/_cfg/agent-manifest.csv"
  ".dexCore/_cfg/workflow-manifest.csv"
  "myDex/.dex/config/profile.yaml.example"
  ".dexCore/_dev/tools/validate.sh"
  ".dexCore/_dev/tools/dexhub-dashboard.html"
  ".dexCore/_dev/docs/SILO-ARCHITECTURE.md"
)
for ref_path in "${CRITICAL_PATHS[@]}"; do
  if [ -e "$ref_path" ]; then
    pass "Cross-ref: $ref_path exists"
  else
    fail "Cross-ref: $ref_path MISSING (referenced in docs)"
  fi
done

# ==================== SECTION 16: Onboarding Logic ====================
echo -e "\n${BOLD}[16/24] Onboarding Logic${NC}"

QUESTIONS_FILE=".dexCore/_cfg/onboarding-questions.yaml"
if [ -f "$QUESTIONS_FILE" ]; then
  pass "Onboarding questions file exists"
  TOTAL_Q=$(grep -c "^  - id:" "$QUESTIONS_FILE" 2>/dev/null || grep -c "^- id:" "$QUESTIONS_FILE" 2>/dev/null || echo 0)
  TOTAL_Q=$(echo "$TOTAL_Q" | tr -d '[:space:]')
  pass "Onboarding total questions: $TOTAL_Q"
  # Check for text_de and text_en in questions
  DE_COUNT=$(grep -c "text_de:" "$QUESTIONS_FILE" 2>/dev/null || echo 0)
  DE_COUNT=$(echo "$DE_COUNT" | tr -d '[:space:]')
  EN_COUNT=$(grep -c "text_en:" "$QUESTIONS_FILE" 2>/dev/null || echo 0)
  EN_COUNT=$(echo "$EN_COUNT" | tr -d '[:space:]')
  if [ "$DE_COUNT" -gt 0 ] && [ "$EN_COUNT" -gt 0 ]; then
    pass "Onboarding: bilingual (DE: $DE_COUNT, EN: $EN_COUNT)"
  else
    warn "Onboarding: missing translations (DE: $DE_COUNT, EN: $EN_COUNT)"
  fi
else
  fail "Onboarding questions file MISSING"
fi

# Check MINIMAL onboarding exists in mydex-agent
if grep -q "onboarding-minimal" .dexCore/core/agents/mydex-agent.md 2>/dev/null; then
  pass "MINIMAL onboarding variant defined"
else
  fail "MINIMAL onboarding variant MISSING"
fi

if grep -q "onboarding-smart" .dexCore/core/agents/mydex-agent.md 2>/dev/null; then
  pass "SMART onboarding variant defined"
else
  fail "SMART onboarding variant MISSING"
fi

if grep -q "onboarding-complete" .dexCore/core/agents/mydex-agent.md 2>/dev/null; then
  pass "VOLLSTAENDIG onboarding variant defined"
else
  fail "VOLLSTAENDIG onboarding variant MISSING"
fi

# ==================== SECTION 17: Guardrail Pattern Enforcement ====================
echo -e "\n${BOLD}[17/24] Guardrail Pattern Enforcement${NC}"

# Primary tail for guardrail checks: CLAUDE.md if present, else copilot-instructions.md
GUARD_TAIL=".claude/CLAUDE.md"
[ "$HAS_CLAUDE_TAIL" = "0" ] && GUARD_TAIL=".github/copilot-instructions.md"

# Check G3 enforcement
if grep -q "Root-Forbidden" "$GUARD_TAIL" && grep -q "Smart Routing" "$GUARD_TAIL" 2>/dev/null; then
  pass "G3: Root-Forbidden + Smart Routing in $GUARD_TAIL"
else
  fail "G3: Missing Root-Forbidden enforcement in $GUARD_TAIL"
fi

# Check G5 consent pattern
if grep -q "WAIT for explicit" "$GUARD_TAIL" 2>/dev/null; then
  pass "G5: Consent pattern (WAIT for explicit) in $GUARD_TAIL"
else
  fail "G5: Consent pattern missing in $GUARD_TAIL"
fi

# Check G6 no hallucinated paths
if grep -q "Verify with file system" "$GUARD_TAIL" 2>/dev/null || grep -q "verify.*file system" "$GUARD_TAIL" 2>/dev/null; then
  pass "G6: No hallucinated paths rule in $GUARD_TAIL"
else
  warn "G6: Hallucinated paths rule may be missing in $GUARD_TAIL"
fi

# Check hook enforcement — Claude-Code-specific (skills/hooks live in .claude/)
if [ "$HAS_CLAUDE_TAIL" = "0" ]; then
  skip "Claude Code hook checks (PostToolUse, post-write-check.sh) — enterprise bundle has no .claude/"
else
  if [ -f ".claude/settings.json" ] && grep -q "PostToolUse" .claude/settings.json 2>/dev/null; then
    pass "Guardrail hook: PostToolUse hook configured"
  else
    warn "Guardrail hook: No PostToolUse hook in settings.json"
  fi

  if [ -f ".claude/skills/dexhub-testing/scripts/post-write-check.sh" ]; then
    pass "Guardrail hook: post-write-check.sh exists"
    if [ -x ".claude/skills/dexhub-testing/scripts/post-write-check.sh" ]; then
      pass "Guardrail hook: post-write-check.sh is executable"
    else
      fail "Guardrail hook: post-write-check.sh NOT executable"
    fi
  else
    fail "Guardrail hook: post-write-check.sh MISSING"
  fi
fi

# ==================== SECTION 18: DexMemory & Chronicle Structure ====================
echo -e "\n${BOLD}[18/24] DexMemory & Chronicle Structure${NC}"

# DexMemory infrastructure
if [ -d "myDex/.dex/chronicle" ]; then
  pass "DexMemory: chronicle/ directory exists"
else
  fail "DexMemory: chronicle/ directory MISSING"
fi

if [ -d "myDex/.dex/decisions" ]; then
  pass "DexMemory: decisions/ directory exists"
else
  fail "DexMemory: decisions/ directory MISSING"
fi

if [ -f "myDex/.dex/chronicle/README.md" ]; then
  pass "DexMemory: chronicle/README.md exists"
else
  warn "DexMemory: chronicle/README.md missing"
fi

if [ -f "myDex/.dex/decisions/README.md" ]; then
  pass "DexMemory: decisions/README.md exists"
else
  warn "DexMemory: decisions/README.md missing"
fi

# Chronicle template
if [ -f ".dexCore/dxm/templates/project/chronicle/DAILY-LOG-TEMPLATE.md" ]; then
  pass "Chronicle: daily log template exists"
else
  fail "Chronicle: daily log template MISSING"
fi

# DexMemory architecture doc
if [ -f ".dexCore/_dev/docs/SILO-ARCHITECTURE.md" ]; then
  pass "DexMemory: architecture document exists"
else
  fail "DexMemory: architecture document MISSING"
fi

# .gitignore protects private data
if grep -q "profile.yaml\|config/\*.yaml" .gitignore 2>/dev/null; then
  pass "Privacy: profile.yaml is gitignored (via *.yaml pattern)"
else
  fail "Privacy: profile.yaml NOT in .gitignore"
fi

if grep -q ".mcp.json" .gitignore 2>/dev/null; then
  pass "Privacy: .mcp.json is gitignored (MCP tokens)"
else
  fail "Privacy: .mcp.json NOT in .gitignore — OAuth tokens could leak!"
fi

if grep -q "CONTEXT.md" .gitignore 2>/dev/null; then
  pass "Privacy: CONTEXT.md is gitignored"
else
  fail "Privacy: CONTEXT.md NOT in .gitignore"
fi

if grep -q "chronicle/" .gitignore 2>/dev/null; then
  pass "Privacy: chronicle/ is gitignored"
else
  warn "Privacy: chronicle/ may not be gitignored"
fi

# ==================== SECTION 19: SSOT Instruction Drift Detection ====================
echo -e "\n${BOLD}[19/24] SSOT Instruction Drift Detection${NC}"

if [ "$HAS_CLAUDE_TAIL" = "0" ]; then
  skip "SSOT drift check — enterprise bundle has only Copilot tail; compiler-check compares both tails in dev mode only"
else
  if [ -f ".dexCore/_dev/tools/build-instructions.sh" ]; then
    if bash .dexCore/_dev/tools/build-instructions.sh check >/dev/null 2>&1; then
      pass "Instruction outputs are in sync with sources (SHARED.md + tails)"
    else
      fail "Instructions STALE — run: bash .dexCore/_dev/tools/build-instructions.sh"
    fi
  else
    warn "build-instructions.sh not found — cannot check SSOT drift"
  fi
fi

# Verify generated files exist (per-tail)
for gen_file in .claude/CLAUDE.md .github/copilot-instructions.md; do
  if [ -f "$gen_file" ]; then
    pass "Generated file exists: $gen_file"
  elif [ "$gen_file" = ".claude/CLAUDE.md" ] && [ "$HAS_CLAUDE_TAIL" = "0" ]; then
    skip "$gen_file (enterprise bundle — Claude tail stripped per PLATFORM-POLICY)"
  else
    fail "Generated file MISSING: $gen_file"
  fi
done

# ==================== SECTION 20: Files-Manifest Integrity ====================
echo -e "\n${BOLD}[20/24] Files-Manifest Integrity${NC}"

if [ -f ".dexCore/_cfg/files-manifest.csv" ]; then
  MANIFEST_TOTAL=$(tail -n +2 .dexCore/_cfg/files-manifest.csv | wc -l | tr -d ' ')
  MANIFEST_MISSING=0
  MANIFEST_HASH_FAIL=0
  MANIFEST_CHECKED=0

  # Check file existence for ALL entries, hash-check a sample of critical files
  while IFS=',' read -r type name module path hash; do
    # Skip header
    [ "$type" = "type" ] && continue

    # Strip quotes
    path="${path%\"}"
    path="${path#\"}"
    hash="${hash%\"}"
    hash="${hash#\"}"

    # Skip empty paths
    [ -z "$path" ] && continue

    if [ ! -e "$path" ]; then
      MANIFEST_MISSING=$((MANIFEST_MISSING + 1))
      # Only report first 5 missing files to avoid flooding
      if [ "$MANIFEST_MISSING" -le 5 ]; then
        fail "Files-Manifest: MISSING $path"
      fi
    fi
  done < .dexCore/_cfg/files-manifest.csv

  if [ "$MANIFEST_MISSING" -eq 0 ]; then
    pass "Files-Manifest: all $MANIFEST_TOTAL tracked files exist"
  elif [ "$MANIFEST_MISSING" -gt 5 ]; then
    fail "Files-Manifest: $MANIFEST_MISSING files missing (showing first 5 above)"
  fi

  # Hash-check critical files (manifests, configs, truth-manifest, dex-master)
  CRITICAL_PATTERNS="manifest\|config\.yaml\|truth-manifest\|SHARED\.md\|dex-master\.md"
  while IFS=',' read -r type name module path hash; do
    [ "$type" = "type" ] && continue
    path="${path%\"}"
    path="${path#\"}"
    hash="${hash%\"}"
    hash="${hash#\"}"

    [ -z "$path" ] || [ -z "$hash" ] && continue
    echo "$path" | grep -q "$CRITICAL_PATTERNS" || continue
    [ ! -f "$path" ] && continue

    MANIFEST_CHECKED=$((MANIFEST_CHECKED + 1))
    ACTUAL_HASH=$(shasum -a 256 "$path" 2>/dev/null | cut -d' ' -f1)
    if [ "$ACTUAL_HASH" != "$hash" ]; then
      MANIFEST_HASH_FAIL=$((MANIFEST_HASH_FAIL + 1))
      warn "Files-Manifest: hash mismatch for $path"
    fi
  done < .dexCore/_cfg/files-manifest.csv

  if [ "$MANIFEST_CHECKED" -gt 0 ] && [ "$MANIFEST_HASH_FAIL" -eq 0 ]; then
    pass "Files-Manifest: $MANIFEST_CHECKED critical file hashes verified"
  elif [ "$MANIFEST_HASH_FAIL" -gt 0 ]; then
    warn "Files-Manifest: $MANIFEST_HASH_FAIL/$MANIFEST_CHECKED critical hash mismatches (run rebuild or update manifest)"
  fi
else
  warn "Files-Manifest not found — skipping integrity check"
fi

# ==================== SECTION 21: Source File Semantic Consistency ====================
echo -e "\n${BOLD}[21/24] Source File Semantic Consistency (SHARED vs peer files)${NC}"

# Detect contradictions between SHARED.md and the platform-specific tails.
# Catches the class of bug where SHARED.md asserts a new paradigm but a tail
# still uses old paradigm language (e.g., D1 Agent Boundary refactor drift).

SHARED=".dexCore/core/instructions/SHARED.md"
# All peer files in the instructions dir that must stay consistent with SHARED.
# Includes tails AND truth-manifest (added 2026-04-18 after Phase 4 Reality Sync
# found truth-manifest.md had drifted with "permanent orchestrator" wording).
PEER_FILES=(
  ".dexCore/core/instructions/claude-specific.md"
  ".dexCore/core/instructions/copilot-specific.md"
  ".dexCore/core/instructions/truth-manifest.md"
)

# Deprecated phrases — if SHARED has moved past them, peers must too.
# Each entry: phrase|reason
DEPRECATED_PHRASES=(
  "DexMaster is ALWAYS active|Old meta-layer paradigm (pre-D1)"
  "FIRST RESPONDER|Old meta-layer paradigm (pre-D1)"
  "Evaluate intent on EVERY message|Old meta-layer paradigm (pre-D1)"
  "permanent first responder|Contradicts on-demand agent model (D1)"
  "permanent orchestrator|Contradicts on-demand agent model (D1)"
  "Level 1.*Orchestration.*Level 2.*Level 3|Old DexMaster scope-levels (pre-D1)"
  "always_load_on:|Old always-active load semantic (pre-D1); use load_on: instead"
)

CONSISTENCY_ISSUES=0
for entry in "${DEPRECATED_PHRASES[@]}"; do
  phrase="${entry%%|*}"
  reason="${entry##*|}"

  # Check if SHARED has already moved past this phrase
  if grep -qE "$phrase" "$SHARED" 2>/dev/null; then
    continue
  fi

  # SHARED has moved past it. Check peer files.
  for peer_file in "${PEER_FILES[@]}"; do
    [ -f "$peer_file" ] || continue
    if grep -qE "$phrase" "$peer_file" 2>/dev/null; then
      fail "Source consistency: $(basename "$peer_file") uses deprecated phrase '$phrase' ($reason)"
      CONSISTENCY_ISSUES=$((CONSISTENCY_ISSUES + 1))
    fi
  done
done

# Contradictions to new paradigm
if grep -q "loaded on demand" "$SHARED" 2>/dev/null; then
  for peer_file in "${PEER_FILES[@]}"; do
    [ -f "$peer_file" ] || continue
    if grep -qE "DexMaster is active\b" "$peer_file" 2>/dev/null; then
      fail "Source consistency: $(basename "$peer_file") says 'DexMaster is active' — contradicts 'loaded on demand' in SHARED.md"
      CONSISTENCY_ISSUES=$((CONSISTENCY_ISSUES + 1))
    fi
  done
fi

if [ "$CONSISTENCY_ISSUES" -eq 0 ]; then
  pass "Source file semantic consistency: SHARED.md + ${#PEER_FILES[@]} peer files aligned"
fi

# ==================== SECTION 22: CONTEXT.md Session State Schema (D1 Layer-2) ====================
echo -e "\n${BOLD}[22/24] CONTEXT.md Session State Schema (D1 Layer-2)${NC}"

# CONTEXT.md is gitignored per-user state. Check schema ONLY if file exists.
# Does not FAIL if absent (fresh users won't have one).
CTX_FILE="myDex/.dex/CONTEXT.md"
CTX_SCHEMA=".dexCore/_dev/docs/CONTEXT-SCHEMA.md"

if [ ! -f "$CTX_SCHEMA" ]; then
  fail "CONTEXT-SCHEMA.md missing at $CTX_SCHEMA — D1 Layer-2 schema doc required"
else
  pass "CONTEXT-SCHEMA.md present"
fi

if [ ! -f "$CTX_FILE" ]; then
  pass "CONTEXT.md absent (fresh user) — nothing to validate"
else
  CTX_ISSUES=0

  # If CONTEXT.md exists, check for Session block presence (optional — legacy files may lack it)
  if grep -q "^## Session" "$CTX_FILE" 2>/dev/null; then
    pass "CONTEXT.md has ## Session block"

    # Extract session state
    CTX_STATE=$(grep -A10 "^## Session" "$CTX_FILE" | grep -E "^state:" | head -1 | sed 's/^state: *//' | tr -d '"')
    CTX_AGENT=$(grep -A10 "^## Session" "$CTX_FILE" | grep -E "^active_agent:" | head -1 | sed 's/^active_agent: *//' | tr -d '"')

    # Validate state value
    case "$CTX_STATE" in
      IDLE|CODE-MODE|AGENT:*|null|"")
        pass "CONTEXT.md state value valid ($CTX_STATE)"
        ;;
      *)
        warn "CONTEXT.md state value unknown: '$CTX_STATE' (expected IDLE | CODE-MODE | AGENT:{name})"
        CTX_ISSUES=$((CTX_ISSUES + 1))
        ;;
    esac

    # If AGENT:{X}, verify agent exists in manifest
    if echo "$CTX_STATE" | grep -qE "^AGENT:"; then
      AGENT_NAME="${CTX_STATE#AGENT:}"
      if [ -f .dexCore/_cfg/agent-manifest.csv ] && grep -qE "^${AGENT_NAME}," .dexCore/_cfg/agent-manifest.csv 2>/dev/null; then
        pass "CONTEXT.md active_agent '$AGENT_NAME' exists in manifest"
      else
        warn "CONTEXT.md references agent '$AGENT_NAME' not in manifest (may be stale)"
        CTX_ISSUES=$((CTX_ISSUES + 1))
      fi
    fi

    # Validate activated_at is ISO-8601 (if set and not null)
    CTX_ACTIVATED=$(grep -A10 "^## Session" "$CTX_FILE" | grep -E "^activated_at:" | head -1 | sed 's/^activated_at: *//' | tr -d '"')
    if [ -n "$CTX_ACTIVATED" ] && [ "$CTX_ACTIVATED" != "null" ]; then
      # ISO-8601: YYYY-MM-DDTHH:MM:SS(Z|+HH:MM)
      if echo "$CTX_ACTIVATED" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(Z|[+-][0-9]{2}:[0-9]{2})?$'; then
        pass "CONTEXT.md activated_at is valid ISO-8601 ($CTX_ACTIVATED)"
      else
        warn "CONTEXT.md activated_at not valid ISO-8601: '$CTX_ACTIVATED'"
        CTX_ISSUES=$((CTX_ISSUES + 1))
      fi
    fi
  else
    # Legacy CONTEXT.md without Session block — not an error, but note it
    pass "CONTEXT.md present without Session block (legacy format, will be extended on next agent transition)"
  fi
fi

# ==================== SECTION 23: Feature Registry Consistency ====================
echo -e "\n${BOLD}[23/24] Feature Registry (features.yaml) Consistency${NC}"

FEATURES_FILE=".dexCore/_cfg/features.yaml"

if [ ! -f "$FEATURES_FILE" ]; then
  fail "features.yaml missing at $FEATURES_FILE"
else
  pass "features.yaml present"

  # Pick YAML tool (ruby preferred — stdlib on macOS)
  FEAT_YAML_TOOL=""
  if command -v ruby >/dev/null 2>&1 && ruby -ryaml -e '' 2>/dev/null; then
    FEAT_YAML_TOOL="ruby"
  elif command -v python3 >/dev/null 2>&1 && python3 -c "import yaml" 2>/dev/null; then
    FEAT_YAML_TOOL="python3"
  fi

  if [ -z "$FEAT_YAML_TOOL" ]; then
    warn "features.yaml checks skipped — no YAML parser (install ruby or pip install pyyaml)"
  else
    # Valid YAML
    if [ "$FEAT_YAML_TOOL" = "ruby" ]; then
      if ruby -ryaml -e "YAML.load_file('$FEATURES_FILE')" 2>/dev/null; then
        pass "features.yaml parses as valid YAML"
      else
        fail "features.yaml fails YAML parse"
      fi
    else
      if python3 -c "import yaml; yaml.safe_load(open('$FEATURES_FILE'))" 2>/dev/null; then
        pass "features.yaml parses as valid YAML"
      else
        fail "features.yaml fails YAML parse"
      fi
    fi

    # Required fields on every feature + unique IDs + test-file existence for enabled/always_on
    if [ "$FEAT_YAML_TOOL" = "ruby" ]; then
      REGISTRY_REPORT=$(ruby -ryaml -e "
        data = YAML.load_file('$FEATURES_FILE') rescue (puts 'PARSE_FAIL'; exit 1)
        section_keys = ['core','onboarding','agents','knowledge','parser','connectors','llm','workflows','quality','meta','bugs','roadmap']
        required = ['id','name','status']
        allowed_status = %w[always_on enabled disabled deferred broken experimental]
        seen_ids = {}
        missing_field = []
        bad_status = []
        duplicate = []
        missing_test = []
        section_keys.each do |s|
          next unless data[s]
          data[s].each do |f|
            required.each { |r| missing_field << \"#{s}:#{f['id']||'<no-id>'} missing #{r}\" unless f[r] }
            bad_status << \"#{s}:#{f['id']}=#{f['status']}\" unless allowed_status.include?(f['status'])
            if f['id']
              if seen_ids[f['id']]
                duplicate << f['id']
              else
                seen_ids[f['id']] = true
              end
            end
            # For enabled/always_on: if tests: non-empty, files must exist (exclude parenthetical note entries)
            if %w[enabled always_on].include?(f['status']) && f['tests'].is_a?(Array) && !f['tests'].empty?
              f['tests'].each do |t|
                # Strip any parenthetical after the path (e.g. 'tests/e2e/01.test.sh (structural 15 + live 4)')
                t_path = t.to_s.split(/\s+[(]/).first.strip
                next if t_path.start_with?('self-hosting') || t_path.empty?
                # Integration-module tests (tests/e2e/integrations/*) are REMOVABLE
                # per PLATFORM-POLICY.md. build-for-enterprise.sh strips these.
                # Skip the file-existence check for them — they're allowed absent
                # in stripped enterprise bundles. Dev-mode catches missing integration
                # tests via actual test execution (run-all.sh).
                next if t_path.start_with?('tests/e2e/integrations/')
                unless File.exist?(t_path)
                  missing_test << \"#{s}:#{f['id']} references missing test file: #{t_path}\"
                end
              end
            end
          end
        end
        puts 'MISSING_FIELD_COUNT=' + missing_field.length.to_s
        puts 'BAD_STATUS_COUNT=' + bad_status.length.to_s
        puts 'DUPLICATE_COUNT=' + duplicate.length.to_s
        puts 'MISSING_TEST_COUNT=' + missing_test.length.to_s
        puts 'TOTAL_FEATURES=' + seen_ids.length.to_s
        puts 'MISSING_FIELD=' + missing_field.first(3).join('; ')
        puts 'BAD_STATUS=' + bad_status.first(3).join('; ')
        puts 'DUPLICATE=' + duplicate.first(3).join('; ')
        puts 'MISSING_TEST=' + missing_test.first(3).join('; ')
      " 2>/dev/null)
    else
      REGISTRY_REPORT=$(python3 -c "
import yaml, os
data = yaml.safe_load(open('$FEATURES_FILE'))
section_keys = ['core','onboarding','agents','knowledge','parser','connectors','llm','workflows','quality','meta','bugs','roadmap']
required = ['id','name','status']
allowed_status = ['always_on','enabled','disabled','deferred','broken','experimental']
seen_ids = {}
missing_field = []
bad_status = []
duplicate = []
missing_test = []
for s in section_keys:
    if not data.get(s): continue
    for f in data[s]:
        for r in required:
            if r not in f or f[r] is None:
                missing_field.append(f\"{s}:{f.get('id','<no-id>')} missing {r}\")
        if f.get('status') not in allowed_status:
            bad_status.append(f\"{s}:{f.get('id')}={f.get('status')}\")
        if f.get('id'):
            if f['id'] in seen_ids:
                duplicate.append(f['id'])
            else:
                seen_ids[f['id']] = True
        if f.get('status') in ('enabled','always_on') and isinstance(f.get('tests'), list) and f['tests']:
            for t in f['tests']:
                t_path = str(t).split(' (')[0].strip()
                if t_path.startswith('self-hosting') or not t_path: continue
                # Integration-module tests (tests/e2e/integrations/*) are removable
                # per PLATFORM-POLICY.md. Skip file-existence check.
                if t_path.startswith('tests/e2e/integrations/'): continue
                if not os.path.exists(t_path):
                    missing_test.append(f\"{s}:{f['id']} references missing test file: {t_path}\")
print('MISSING_FIELD_COUNT=' + str(len(missing_field)))
print('BAD_STATUS_COUNT=' + str(len(bad_status)))
print('DUPLICATE_COUNT=' + str(len(duplicate)))
print('MISSING_TEST_COUNT=' + str(len(missing_test)))
print('TOTAL_FEATURES=' + str(len(seen_ids)))
print('MISSING_FIELD=' + '; '.join(missing_field[:3]))
print('BAD_STATUS=' + '; '.join(bad_status[:3]))
print('DUPLICATE=' + '; '.join(duplicate[:3]))
print('MISSING_TEST=' + '; '.join(missing_test[:3]))
" 2>/dev/null)
    fi

    MF=$(echo "$REGISTRY_REPORT" | grep '^MISSING_FIELD_COUNT=' | cut -d= -f2)
    BS=$(echo "$REGISTRY_REPORT" | grep '^BAD_STATUS_COUNT=' | cut -d= -f2)
    DU=$(echo "$REGISTRY_REPORT" | grep '^DUPLICATE_COUNT=' | cut -d= -f2)
    MT=$(echo "$REGISTRY_REPORT" | grep '^MISSING_TEST_COUNT=' | cut -d= -f2)
    TF=$(echo "$REGISTRY_REPORT" | grep '^TOTAL_FEATURES=' | cut -d= -f2)

    if [ "${MF:-0}" -eq 0 ]; then
      pass "features.yaml: all ${TF:-0} features have id/name/status"
    else
      fail "features.yaml: $MF features missing required fields: $(echo "$REGISTRY_REPORT" | grep '^MISSING_FIELD=' | cut -d= -f2-)"
    fi

    if [ "${BS:-0}" -eq 0 ]; then
      pass "features.yaml: all status values in allowed set"
    else
      fail "features.yaml: $BS features have invalid status: $(echo "$REGISTRY_REPORT" | grep '^BAD_STATUS=' | cut -d= -f2-)"
    fi

    if [ "${DU:-0}" -eq 0 ]; then
      pass "features.yaml: no duplicate feature IDs"
    else
      fail "features.yaml: $DU duplicate IDs: $(echo "$REGISTRY_REPORT" | grep '^DUPLICATE=' | cut -d= -f2-)"
    fi

    if [ "${MT:-0}" -eq 0 ]; then
      pass "features.yaml: all test paths on enabled/always_on features exist"
    else
      fail "features.yaml: $MT enabled features reference missing test files: $(echo "$REGISTRY_REPORT" | grep '^MISSING_TEST=' | cut -d= -f2-)"
    fi
  fi
fi

# ==================== SECTION 24: Session Anchor Consistency ====================
# Exists to catch the 2026-04-19 cross-repo incident pattern: a session
# operating in worktree X committing content meant for worktree Y.
# Anchor file declares this repo's identity; §24 verifies runtime context
# matches that declaration.
#
# Enterprise-build skip (2026-04-20 fix): when running inside a stripped
# enterprise bundle (no .git directory + anchor stripped by build-for-
# enterprise.sh), §24 becomes meaningless — we're not in a dev worktree.
# Detect this and skip cleanly instead of failing.
echo -e "\n${BOLD}[24/24] Session Anchor (worktree-identity consistency)${NC}"

ANCHOR_FILE=".dexcore-session-anchor"

if [ ! -d ".git" ] && [ ! -f "$ANCHOR_FILE" ]; then
  # Enterprise bundle or extracted tarball — §24 is N/A here
  warn "Session-anchor check skipped — no .git and no anchor (enterprise bundle or extracted tarball; §24 is a dev-worktree-only guard)"
elif [ ! -f "$ANCHOR_FILE" ]; then
  fail "Session-anchor missing — expected $ANCHOR_FILE (see 2026-04-19 cross-repo incident)"
else
  pass "Session-anchor file present"

  EXPECTED_ORIGIN=$(grep -E "^expected_origin:" "$ANCHOR_FILE" | head -1 | sed -E 's/^expected_origin: *"?([^"]*)"?/\1/')
  EXPECTED_ORIGIN_ALT=$(grep -E "^expected_origin_alternate:" "$ANCHOR_FILE" | head -1 | sed -E 's/^expected_origin_alternate: *"?([^"]*)"?/\1/')
  EXPECTED_PATH_FRAG=$(grep -E "^expected_worktree_path_contains:" "$ANCHOR_FILE" | head -1 | sed -E 's/^expected_worktree_path_contains: *"?([^"]*)"?/\1/')

  # Check git remote origin
  # Normalize: strip optional .git suffix + optional trailing slash so that
  # https://github.com/foo/bar  https://github.com/foo/bar.git
  # git@github.com:foo/bar.git   git@github.com:foo/bar
  # are all considered equivalent.
  normalize_git_url() {
    echo "$1" | sed -E 's#\.git/?$##; s#/$##'
  }

  ACTUAL_ORIGIN=$(git config --get remote.origin.url 2>/dev/null || echo "")
  ACTUAL_NORM=$(normalize_git_url "$ACTUAL_ORIGIN")
  EXP_NORM=$(normalize_git_url "$EXPECTED_ORIGIN")
  EXP_ALT_NORM=$(normalize_git_url "$EXPECTED_ORIGIN_ALT")

  if [ -z "$ACTUAL_ORIGIN" ]; then
    warn "Session-anchor: git remote.origin.url not set (unusual checkout?)"
  elif [ "$ACTUAL_NORM" = "$EXP_NORM" ] || [ "$ACTUAL_NORM" = "$EXP_ALT_NORM" ]; then
    pass "Session-anchor: git remote origin matches expected (normalized: $ACTUAL_NORM)"
  else
    fail "Session-anchor: remote origin '$ACTUAL_ORIGIN' does NOT match expected '$EXPECTED_ORIGIN' or alt '$EXPECTED_ORIGIN_ALT' — wrong repo?"
  fi

  # Check worktree path contains expected fragment
  ACTUAL_PATH=$(pwd)
  if [ -n "$EXPECTED_PATH_FRAG" ] && echo "$ACTUAL_PATH" | grep -q "$EXPECTED_PATH_FRAG"; then
    pass "Session-anchor: worktree path contains expected fragment ('$EXPECTED_PATH_FRAG')"
  elif [ -z "$EXPECTED_PATH_FRAG" ]; then
    warn "Session-anchor: no expected_worktree_path_contains declared"
  else
    fail "Session-anchor: worktree '$ACTUAL_PATH' missing expected fragment '$EXPECTED_PATH_FRAG' — wrong worktree?"
  fi

  # Check current branch is in expected_branches (list)
  EXPECTED_BRANCHES=$(grep -E "^expected_branches:" "$ANCHOR_FILE" | head -1 | sed -E 's/^expected_branches: *\[(.*)\]/\1/' | tr -d '"' | tr ',' ' ')
  ACTUAL_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
  BRANCH_OK=0
  for b in $EXPECTED_BRANCHES; do
    # Strip whitespace
    b_trim=$(echo "$b" | tr -d '[:space:]')
    [ "$b_trim" = "$ACTUAL_BRANCH" ] && BRANCH_OK=1 && break
  done
  if [ "$BRANCH_OK" -eq 1 ]; then
    pass "Session-anchor: current branch ($ACTUAL_BRANCH) in expected_branches list"
  else
    warn "Session-anchor: branch '$ACTUAL_BRANCH' not in expected list '$EXPECTED_BRANCHES' — may be feature branch or wrong repo"
  fi
fi

# ==================== SUMMARY ====================
echo ""
echo -e "${BOLD}========================================${NC}"
TOTAL=$((PASS + FAIL + WARN))
echo -e "${BOLD} Results: ${GREEN}${PASS} PASS${NC} / ${RED}${FAIL} FAIL${NC} / ${YELLOW}${WARN} WARN${NC} (${TOTAL} total)"
echo -e "${BOLD}========================================${NC}"

if [ "$FAIL" -eq 0 ]; then
  echo -e "\n${GREEN}${BOLD}All checks passed!${NC}"
  exit 0
else
  echo -e "\n${RED}${BOLD}${FAIL} check(s) failed — review output above.${NC}"
  exit 1
fi
