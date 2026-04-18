#!/bin/bash
# DexHub E2E Test — Claude Code Runner
# Phase 5.0 Test Harness Foundation (2026-04-19)
#
# Wraps Claude Code headless mode for scripted test sessions.
# Usage:
#   source harness/claude-runner.sh
#   response=$(claude_prompt "hi")
#   echo "$response" | grep -q "DexMaster"

# Check Claude Code is installed
check_claude_installed() {
  if ! command -v claude >/dev/null 2>&1; then
    echo "ERROR: 'claude' CLI not found. Install Claude Code to run E2E tests." >&2
    return 1
  fi
  return 0
}

# claude_prompt "prompt text" [extra-args]
# Returns the raw text response (via -p --output-format=text)
# Quiet mode: stderr suppressed unless CLAUDE_E2E_VERBOSE=1
claude_prompt() {
  local prompt="$1"
  shift
  local extra_args=("$@")
  local stderr_redirect="2>/dev/null"
  [ "${CLAUDE_E2E_VERBOSE:-0}" = "1" ] && stderr_redirect=""

  if ! check_claude_installed; then
    return 1
  fi

  # Headless one-shot prompt
  eval "claude -p \"\$prompt\" --output-format=text ${extra_args[*]} $stderr_redirect"
}

# claude_prompt_json "prompt text" — returns JSON structure
claude_prompt_json() {
  local prompt="$1"
  if ! check_claude_installed; then
    return 1
  fi
  claude -p "$prompt" --output-format=json 2>/dev/null
}

# assert_claude_response_contains "prompt" "expected-pattern" [description]
assert_claude_response_contains() {
  local prompt="$1"
  local pattern="$2"
  local desc="${3:-Claude response to '$prompt' contains '$pattern'}"

  local response
  response=$(claude_prompt "$prompt")

  if [ -z "$response" ]; then
    fail "$desc" "Empty response from claude (is it installed?)"
    return 1
  fi

  if echo "$response" | grep -qE "$pattern" 2>/dev/null; then
    pass "$desc"
    return 0
  else
    fail "$desc" "Pattern not found in response. First 200 chars: ${response:0:200}"
    return 1
  fi
}

# skip_if_no_claude — mark test as skipped if Claude Code not installed
# Useful for CI environments without Claude Code
skip_if_no_claude() {
  if ! check_claude_installed; then
    echo -e "  \033[1;33m⊘\033[0m Skipping: Claude Code not installed"
    # Exit with 77 = "skipped" in some test frameworks
    exit 77
  fi
}
