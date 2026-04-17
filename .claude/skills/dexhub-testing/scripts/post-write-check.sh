#!/bin/bash
# DexHub Post-Write Guardrail Check
# Runs after every Edit/Write via CLI agent hooks
# Exit 0 = OK, Exit 2 = BLOCK (shows error to user)

INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)

# Skip if no file path
[ -z "$FILE" ] && exit 0

# G3: Root-Forbidden Check
PROJ_ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
DIR=$(dirname "$FILE")
BASE=$(basename "$FILE")

if [ "$DIR" = "$PROJ_ROOT" ]; then
  case "$BASE" in
    CONTRIBUTING.md|LICENSE|NOTICE|README.md|.gitignore|.gitattributes) ;;
    *) echo "G3 VIOLATION: Cannot write '$BASE' to project root. Use Smart Routing." >&2; exit 2 ;;
  esac
fi

# Byte Limit: copilot-instructions.md max 30500 bytes
if echo "$FILE" | grep -q 'copilot-instructions.md'; then
  SIZE=$(wc -c < "$FILE" 2>/dev/null)
  if [ "${SIZE:-0}" -gt 30500 ]; then
    echo "BYTE LIMIT: copilot-instructions.md is $SIZE bytes (max 30500)" >&2
    exit 2
  fi
fi

# Platform Hygiene: No platform-specific tool names in user-facing files
if echo "$FILE" | grep -qE 'copilot-instructions|README\.md|CONTRIBUTING'; then
  if grep -qi "claude code" "$FILE" 2>/dev/null; then
    COUNT=$(grep -ci "claude code" "$FILE" 2>/dev/null)
    echo "WARNING: $COUNT platform-specific reference(s) in $BASE (should be platform-neutral)" >&2
    # Warning only, don't block
  fi
fi

exit 0
