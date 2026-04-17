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

echo -e "${BOLD}========================================${NC}"
echo -e "${BOLD} DexHub EA — Validation Suite${NC}"
echo -e "${BOLD}========================================${NC}"
echo ""

# ==================== SECTION 1: Byte Limits ====================
echo -e "${BOLD}[1/20] Byte Limits${NC}"

BYTES=$(wc -c < .github/copilot-instructions.md)
if [ "$BYTES" -le 30500 ]; then
  pass "copilot-instructions.md: ${BYTES} bytes (limit: 30,500)"
else
  fail "copilot-instructions.md: ${BYTES} bytes EXCEEDS 30,500 limit"
fi

# ==================== SECTION 2: Bug Status ====================
echo -e "\n${BOLD}[2/20] Bug Status${NC}"

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
echo -e "\n${BOLD}[3/20] Cross-Platform Consistency (CLAUDE.md vs copilot-instructions.md)${NC}"

# GREETING action — check key phrase exists in both
if grep -q 'Display the.*EXACTLY as defined' .claude/CLAUDE.md && \
   grep -q 'Display the.*EXACTLY as defined' .github/copilot-instructions.md; then
  pass "GREETING action: 'Display EXACTLY as defined' in both"
else
  fail "GREETING action mismatch"
fi

# AGENT-REQUEST action
CLAUDE_AR=$(grep 'AGENT-REQUEST' .claude/CLAUDE.md | grep -o 'Load agent.*working\.' 2>/dev/null || echo "")
COPILOT_AR=$(grep 'AGENT-REQUEST' .github/copilot-instructions.md | grep -o 'Load agent.*working\.' 2>/dev/null || echo "")
if [ -n "$CLAUDE_AR" ] && [ "$CLAUDE_AR" = "$COPILOT_AR" ]; then
  pass "AGENT-REQUEST action identical"
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

# NEVER DO strengthened
if grep -qi 'Never invent, simplify, or rearrange' .claude/CLAUDE.md && grep -qi 'Never invent, simplify, or rearrange' .github/copilot-instructions.md; then
  pass "NEVER DO #1 strengthened in both"
else
  fail "NEVER DO #1 mismatch"
fi

# ==================== SECTION 4: File Existence ====================
echo -e "\n${BOLD}[4/20] Critical File Existence${NC}"

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
  else
    fail "$f MISSING"
  fi
done

# ==================== SECTION 5: Feature Validation ====================
echo -e "\n${BOLD}[5/20] Feature Artifact Validation${NC}"

# F-005: Guardrails G1-G6
for g in G1 G2 G3 G4 G5 G6; do
  if grep -q "$g:" .claude/CLAUDE.md && grep -q "$g:" .github/copilot-instructions.md; then
    pass "Guardrail $g in both instruction files"
  else
    fail "Guardrail $g missing"
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
if grep -q 'DexMemory' .claude/CLAUDE.md; then
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
if grep -q 'GREETING.*AGENT-REQUEST.*TASK-DIRECT' .claude/CLAUDE.md 2>/dev/null || \
   (grep -q 'GREETING' .claude/CLAUDE.md && grep -q 'TASK-DIRECT' .claude/CLAUDE.md); then
  pass "Intent Detection Protocol present"
else
  fail "Intent Detection Protocol missing"
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
echo -e "\n${BOLD}[6/20] Architecture Rules${NC}"

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
echo -e "\n${BOLD}[7/20] Sanity Checks${NC}"

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
echo -e "\n${BOLD}[8/20] Agent File Validation${NC}"

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
echo -e "\n${BOLD}[9/20] Skill Validation${NC}"

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
echo -e "\n${BOLD}[10/20] Manifest Sync${NC}"

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
echo -e "\n${BOLD}[11/20] Platform Hygiene${NC}"

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
echo -e "\n${BOLD}[12/20] Number Consistency${NC}"

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
echo -e "\n${BOLD}[13/20] Workflow YAML Validation${NC}"

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
echo -e "\n${BOLD}[14/20] Agent Persona Consistency${NC}"

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
echo -e "\n${BOLD}[15/20] Cross-Reference Integrity${NC}"

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
echo -e "\n${BOLD}[16/20] Onboarding Logic${NC}"

QUESTIONS_FILE="myDex/.dex/config/onboarding-questions.yaml"
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
echo -e "\n${BOLD}[17/20] Guardrail Pattern Enforcement${NC}"

# Check G3 enforcement in CLAUDE.md
if grep -q "Root-Forbidden" .claude/CLAUDE.md && grep -q "Smart Routing" .claude/CLAUDE.md 2>/dev/null; then
  pass "G3: Root-Forbidden + Smart Routing in CLAUDE.md"
else
  fail "G3: Missing Root-Forbidden enforcement in CLAUDE.md"
fi

# Check G5 consent pattern
if grep -q "WAIT for explicit" .claude/CLAUDE.md 2>/dev/null; then
  pass "G5: Consent pattern (WAIT for explicit) in CLAUDE.md"
else
  fail "G5: Consent pattern missing"
fi

# Check G6 no hallucinated paths
if grep -q "Verify with file system" .claude/CLAUDE.md 2>/dev/null || grep -q "verify.*file system" .claude/CLAUDE.md 2>/dev/null; then
  pass "G6: No hallucinated paths rule in CLAUDE.md"
else
  warn "G6: Hallucinated paths rule may be missing"
fi

# Check hook enforcement exists
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

# ==================== SECTION 18: DexMemory & Chronicle Structure ====================
echo -e "\n${BOLD}[18/20] DexMemory & Chronicle Structure${NC}"

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
echo -e "\n${BOLD}[19/20] SSOT Instruction Drift Detection${NC}"

if [ -f ".dexCore/_dev/tools/build-instructions.sh" ]; then
  if bash .dexCore/_dev/tools/build-instructions.sh check >/dev/null 2>&1; then
    pass "Instruction outputs are in sync with sources (SHARED.md + tails)"
  else
    fail "Instructions STALE — run: bash .dexCore/_dev/tools/build-instructions.sh"
  fi
else
  warn "build-instructions.sh not found — cannot check SSOT drift"
fi

# Verify generated files exist
for gen_file in .claude/CLAUDE.md .github/copilot-instructions.md; do
  if [ -f "$gen_file" ]; then
    pass "Generated file exists: $gen_file"
  else
    fail "Generated file MISSING: $gen_file"
  fi
done

# ==================== SECTION 20: Files-Manifest Integrity ====================
echo -e "\n${BOLD}[20/20] Files-Manifest Integrity${NC}"

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
