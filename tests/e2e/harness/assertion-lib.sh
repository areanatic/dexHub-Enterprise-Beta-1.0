#!/bin/bash
# DexHub E2E Test — Assertion Library
# Phase 5.0 Test Harness Foundation (2026-04-19)
#
# Source this in every test: source "$(dirname "$0")/harness/assertion-lib.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

# Counters (export so sub-shells can update)
export TEST_PASS=${TEST_PASS:-0}
export TEST_FAIL=${TEST_FAIL:-0}
export TEST_NAME="${TEST_NAME:-unknown}"

# Print banner
test_banner() {
  local name="$1"
  echo ""
  echo -e "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}  TEST: $name${NC}"
  echo -e "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  export TEST_NAME="$name"
}

# pass "description"
pass() {
  echo -e "  ${GREEN}✓${NC} $1"
  TEST_PASS=$((TEST_PASS + 1))
}

# fail "description" ["detail"]
fail() {
  local desc="${1:-unnamed failure}"
  local detail="${2:-}"
  echo -e "  ${RED}✗${NC} $desc" >&2
  [ -n "$detail" ] && echo -e "    ${YELLOW}→${NC} $detail" >&2
  TEST_FAIL=$((TEST_FAIL + 1))
}

# assert_file_exists <path> [description]
assert_file_exists() {
  local path="$1"
  local desc="${2:-File exists: $path}"
  if [ -f "$path" ]; then
    pass "$desc"
    return 0
  else
    fail "$desc" "Path not found: $path"
    return 1
  fi
}

# assert_dir_exists <path> [description]
assert_dir_exists() {
  local path="$1"
  local desc="${2:-Directory exists: $path}"
  if [ -d "$path" ]; then
    pass "$desc"
    return 0
  else
    fail "$desc" "Directory not found: $path"
    return 1
  fi
}

# assert_file_contains <path> <pattern> [description]
assert_file_contains() {
  local path="$1"
  local pattern="$2"
  local desc="${3:-File $path contains pattern: $pattern}"
  if [ ! -f "$path" ]; then
    fail "$desc" "File does not exist: $path"
    return 1
  fi
  if grep -qE "$pattern" "$path" 2>/dev/null; then
    pass "$desc"
    return 0
  else
    fail "$desc" "Pattern not found in file"
    return 1
  fi
}

# assert_file_not_contains <path> <pattern> [description]
assert_file_not_contains() {
  local path="$1"
  local pattern="$2"
  local desc="${3:-File $path does NOT contain: $pattern}"
  if [ ! -f "$path" ]; then
    fail "$desc" "File does not exist: $path"
    return 1
  fi
  if grep -qE "$pattern" "$path" 2>/dev/null; then
    fail "$desc" "Pattern unexpectedly found"
    return 1
  else
    pass "$desc"
    return 0
  fi
}

# assert_equal <actual> <expected> [description]
assert_equal() {
  local actual="$1"
  local expected="$2"
  local desc="${3:-Value equals '$expected'}"
  if [ "$actual" = "$expected" ]; then
    pass "$desc"
    return 0
  else
    fail "$desc" "Expected: '$expected', got: '$actual'"
    return 1
  fi
}

# assert_command_succeeds <command> [description]
# Usage: assert_command_succeeds "ls /tmp" "Can list /tmp"
assert_command_succeeds() {
  local cmd="$1"
  local desc="${2:-Command succeeds: $cmd}"
  if eval "$cmd" >/dev/null 2>&1; then
    pass "$desc"
    return 0
  else
    fail "$desc" "Command failed: $cmd"
    return 1
  fi
}

# assert_yaml_valid <path> [description]
assert_yaml_valid() {
  local path="$1"
  local desc="${2:-Valid YAML: $path}"
  if [ ! -f "$path" ]; then
    fail "$desc" "File does not exist: $path"
    return 1
  fi
  # Try ruby first (stdlib, always available on macOS), fall back to python+yaml, then basic
  if command -v ruby >/dev/null 2>&1 && ruby -ryaml -e '' 2>/dev/null; then
    if ruby -ryaml -e "YAML.load_file('$path')" 2>/dev/null; then
      pass "$desc"
      return 0
    else
      fail "$desc" "Ruby yaml parse failed"
      return 1
    fi
  elif command -v python3 >/dev/null 2>&1 && python3 -c "import yaml" 2>/dev/null; then
    if python3 -c "import yaml; yaml.safe_load(open('$path'))" 2>/dev/null; then
      pass "$desc"
      return 0
    else
      fail "$desc" "Python yaml parse failed"
      return 1
    fi
  else
    # Fallback: basic indentation/colon check
    if grep -qE "^[a-zA-Z_][a-zA-Z0-9_]*:" "$path" 2>/dev/null; then
      pass "$desc (basic check only — install python3-yaml or ruby for strict)"
      return 0
    else
      fail "$desc" "No YAML-like structure found"
      return 1
    fi
  fi
}

# Test summary — call at end of test file
test_summary() {
  local total=$((TEST_PASS + TEST_FAIL))
  echo ""
  echo -e "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  if [ "$TEST_FAIL" -eq 0 ]; then
    echo -e "${BOLD}  ${GREEN}[$TEST_NAME] PASS: $TEST_PASS/$total${NC}"
  else
    echo -e "${BOLD}  ${RED}[$TEST_NAME] FAIL: $TEST_FAIL of $total${NC}"
  fi
  echo -e "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

  # Exit code: 0 if all pass, 1 if any fail
  [ "$TEST_FAIL" -eq 0 ]
}

# Ensure we're run from Beta repo root
ensure_beta_root() {
  if [ ! -f ".dexCore/_cfg/config.yaml" ] || [ ! -d "myDex" ]; then
    echo -e "${RED}ERROR: E2E tests must run from DexHub Beta repo root${NC}" >&2
    echo "Current dir: $(pwd)" >&2
    exit 2
  fi
}

# ─────────────────────────────────────────────────────────────────────
# PLATFORM INTEGRATION STUBS
# ─────────────────────────────────────────────────────────────────────
# These are no-op stubs for platform-specific helpers. Integration
# modules (e.g. tests/e2e/integrations/claude-code/claude-runner.sh)
# OVERRIDE these with real implementations when sourced.
#
# Why this exists:
# Per PLATFORM-POLICY.md, integration modules are removable for
# enterprise builds. When a module is absent (stripped by
# build-for-enterprise.sh), tests that merely check `if
# live_mode_enabled; then ...` auto-skip cleanly instead of breaking
# with "function not found".
#
# Override contract: integration modules should redefine these
# functions AFTER sourcing assertion-lib.sh. Bash function redefinition
# simply replaces the prior definition — no guard needed.
# ─────────────────────────────────────────────────────────────────────

check_claude_installed() {
  # Stub: returns 1 = "not installed / integration module not loaded"
  return 1
}

live_mode_enabled() {
  # Stub: returns 1 = "live mode disabled / no integration available"
  return 1
}

walkthrough_mode_enabled() {
  # Stub: returns 1 = "multi-turn walkthrough disabled / no integration"
  return 1
}

claude_prompt() {
  echo "ERROR: claude_prompt called but claude-code integration module not loaded" >&2
  return 1
}

claude_prompt_json() {
  echo "ERROR: claude_prompt_json called but claude-code integration module not loaded" >&2
  return 1
}

assert_claude_response_contains() {
  local desc="${3:-platform helper}"
  fail "$desc" "claude-code integration module not loaded (stripped or missing)"
  return 1
}

start_conversation() {
  echo "ERROR: start_conversation called but claude-code integration module not loaded" >&2
  return 1
}

resume_conversation() {
  echo "ERROR: resume_conversation called but claude-code integration module not loaded" >&2
  return 1
}

skip_if_no_claude() {
  echo -e "  \033[1;33m⊘\033[0m Skipping: claude-code integration module not loaded" >&2
  exit 77
}
