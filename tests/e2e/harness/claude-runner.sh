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

# Live-mode gate: tests must opt-in via CLAUDE_E2E_LIVE=1.
# Reasons: headless invocations cost API tokens + take time, and nested sessions
# require env adjustments. Default-off keeps CI fast and cheap.
live_mode_enabled() {
  [ "${CLAUDE_E2E_LIVE:-0}" = "1" ]
}

# claude_prompt "prompt text" [extra-args]
# Returns the raw text response (via -p --output-format=text).
# CLAUDECODE is unset for the child so dev-session nesting guard doesn't block.
# Quiet mode: stderr suppressed unless CLAUDE_E2E_VERBOSE=1
claude_prompt() {
  local prompt="$1"
  shift
  # Guard against set -u with empty extra args: ${arr[@]+"${arr[@]}"} is the
  # portable idiom for "expand only if array has elements".
  local extra_args=()
  if [ "$#" -gt 0 ]; then
    extra_args=("$@")
  fi

  if ! check_claude_installed; then
    return 1
  fi

  # env -u CLAUDECODE bypasses the nested-session guard when running under an
  # outer Claude Code dev session (documented in Anthropic runtime).
  if [ "${CLAUDE_E2E_VERBOSE:-0}" = "1" ]; then
    env -u CLAUDECODE claude -p "$prompt" --output-format=text \
      ${extra_args[@]+"${extra_args[@]}"}
  else
    env -u CLAUDECODE claude -p "$prompt" --output-format=text \
      ${extra_args[@]+"${extra_args[@]}"} 2>/dev/null
  fi
}

# claude_prompt_json "prompt text" — returns JSON structure
claude_prompt_json() {
  local prompt="$1"
  if ! check_claude_installed; then
    return 1
  fi
  env -u CLAUDECODE claude -p "$prompt" --output-format=json 2>/dev/null
}

# Multi-turn gate: OPT-IN because each walkthrough costs real API tokens.
# Set CLAUDE_E2E_LIVE_WALKTHROUGH=1 to enable. Each walkthrough may cost
# a few USD depending on conversation length. DO NOT run in CI default.
walkthrough_mode_enabled() {
  [ "${CLAUDE_E2E_LIVE_WALKTHROUGH:-0}" = "1" ]
}

# Start a new conversation, capture session_id + result text.
# Usage:
#   start_conversation "prompt text"
#   session_id=$LAST_CLAUDE_SESSION_ID
#   response=$LAST_CLAUDE_RESPONSE
start_conversation() {
  local prompt="$1"
  if ! check_claude_installed; then return 1; fi

  local raw
  raw=$(env -u CLAUDECODE claude -p "$prompt" --output-format=json 2>/dev/null)

  if [ -z "$raw" ]; then
    export LAST_CLAUDE_SESSION_ID=""
    export LAST_CLAUDE_RESPONSE=""
    return 1
  fi

  # Extract session_id + result using ruby (stdlib json is always present)
  local parsed
  parsed=$(echo "$raw" | ruby -rjson -e '
    d = JSON.parse(STDIN.read) rescue nil
    if d && d["session_id"]
      puts "SID=#{d["session_id"]}"
      puts "===RESULT==="
      puts d["result"].to_s
    else
      puts "SID="
      puts "===RESULT==="
    end
  ' 2>/dev/null)

  export LAST_CLAUDE_SESSION_ID=$(echo "$parsed" | grep '^SID=' | head -1 | sed 's/^SID=//')
  export LAST_CLAUDE_RESPONSE=$(echo "$parsed" | awk '/===RESULT===/{flag=1; next} flag')
}

# Resume an existing session with a new prompt.
# Usage:
#   resume_conversation "$LAST_CLAUDE_SESSION_ID" "next user message"
#   response=$LAST_CLAUDE_RESPONSE
resume_conversation() {
  local session_id="$1"
  local prompt="$2"
  if ! check_claude_installed; then return 1; fi
  [ -z "$session_id" ] && return 1

  local raw
  raw=$(env -u CLAUDECODE claude -p "$prompt" --resume "$session_id" --output-format=json 2>/dev/null)

  local parsed
  parsed=$(echo "$raw" | ruby -rjson -e '
    d = JSON.parse(STDIN.read) rescue nil
    if d
      puts "SID=#{d["session_id"]}"
      puts "===RESULT==="
      puts d["result"].to_s
    else
      puts "SID="
      puts "===RESULT==="
    end
  ' 2>/dev/null)

  export LAST_CLAUDE_SESSION_ID=$(echo "$parsed" | grep '^SID=' | head -1 | sed 's/^SID=//')
  export LAST_CLAUDE_RESPONSE=$(echo "$parsed" | awk '/===RESULT===/{flag=1; next} flag')
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
