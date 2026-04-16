#!/usr/bin/env bash
# DexHub Pre-Push Scanner
#
# Zweck: Verhindert dass unerwünschte Files nach azamani1 (DHL Enterprise Git) gepusht werden.
# Regel: `.claude/` und Claude-spezifische Artefakte dürfen NIEMALS nach azamani1.
#
# Nutzung:
#   ./.dexCore/_dev/tools/pre-push-scan.sh <remote-name>
#
# Exit-Codes:
#   0 = safe to push
#   1 = BLOCKED (Content nicht erlaubt für diesen Remote)
#   2 = script error

set -euo pipefail

REMOTE="${1:-}"
if [ -z "$REMOTE" ]; then
  echo "Usage: $0 <remote-name>"
  exit 2
fi

# Bestimme ob Remote ein Enterprise-Target ist
REMOTE_URL=$(git remote get-url "$REMOTE" 2>/dev/null || echo "")
if [ -z "$REMOTE_URL" ]; then
  echo "FAIL: Remote '$REMOTE' not found"
  exit 2
fi

IS_ENTERPRISE=false
case "$REMOTE_URL" in
  *git.dhl.com*|*enterprise*)
    IS_ENTERPRISE=true
    ;;
esac

if [ "$IS_ENTERPRISE" = "false" ]; then
  echo "OK: $REMOTE ($REMOTE_URL) is not an enterprise target — no enterprise rules apply."
  exit 0
fi

echo "=== Pre-Push Scan: ENTERPRISE target ==="
echo "Remote: $REMOTE"
echo "URL: $REMOTE_URL"
echo ""

# Was würde gepusht werden?
BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || echo "DETACHED")
if [ "$BRANCH" = "DETACHED" ]; then
  echo "FAIL: Cannot push from detached HEAD"
  exit 1
fi

# Bug A fix: Use --verify so rev-parse fails cleanly instead of echoing the
# literal ref string on stdout (which would poison RANGE and silently no-op the scan).
if REMOTE_SHA=$(git rev-parse --verify -q "refs/remotes/$REMOTE/$BRANCH" 2>/dev/null); then
  RANGE="$REMOTE/$BRANCH..$BRANCH"
  echo "Update push — scanning $RANGE..."
else
  REMOTE_SHA=""
  # New branch push — fall back to commits unique vs origin/master merge-base.
  if MERGE_BASE=$(git merge-base origin/master HEAD 2>/dev/null); then
    RANGE="$MERGE_BASE..HEAD"
    echo "New branch push — scanning $RANGE (merge-base with origin/master)..."
  else
    RANGE="$BRANCH"
    echo "New branch push — scanning all $BRANCH commits..."
  fi
fi

FORBIDDEN_PATHS=(
  ".claude/"
  ".claude/settings.json"
  ".claude/settings.local.json"
  ".claude/CLAUDE.md"
  ".claude/sessions/"
  ".claude/skills/"
)

FORBIDDEN_PATTERNS=(
  "claude-code"
  "anthropic\\.com"
  "sk-ant-api"
  "DexMaster"
)

VIOLATIONS=0

# Check 1: Forbidden paths in files-to-be-pushed
echo ""
echo "=== Check 1: Forbidden paths ==="
for path in "${FORBIDDEN_PATHS[@]}"; do
  HITS=$(git diff --name-only "$RANGE" 2>/dev/null | grep -F "$path" || true)
  if [ -n "$HITS" ]; then
    echo "BLOCKED: Found forbidden path '$path':"
    echo "$HITS" | sed 's/^/  - /'
    VIOLATIONS=$((VIOLATIONS + 1))
  fi
done
[ $VIOLATIONS -eq 0 ] && echo "  OK: no forbidden paths"

# Check 2: Secrets in diff
# Note: this script's own source file contains the secret patterns as literals
# in the regex. Exclude the script itself from the diff so we don't self-match.
echo ""
echo "=== Check 2: Secret patterns in diff ==="
SECRET_HITS=$(git diff "$RANGE" -- . ':(exclude).dexCore/_dev/tools/pre-push-scan.sh' 2>/dev/null | grep -E '^\+' | grep -E '(sk-ant-api|ghp_[A-Za-z0-9]{30,}|github_pat_|xoxb-|AKIA[0-9A-Z]{16}|-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY|api[_-]?key\s*[:=]\s*["'"'"'][A-Za-z0-9_\-]{16,}["'"'"'])' || true)
if [ -n "$SECRET_HITS" ]; then
  echo "BLOCKED: Potential secrets found in added lines:"
  echo "$SECRET_HITS" | head -10 | sed 's/^/  /'
  VIOLATIONS=$((VIOLATIONS + 1))
else
  echo "  OK: no obvious secrets"
fi

# Check 3: Personal data patterns (G8)
echo ""
echo "=== Check 3: Personal data patterns (G8) ==="
# Bug C fix: locally disable pipefail so `head -10` closing early doesn't SIGPIPE-kill the scan.
set +o pipefail
PII_HITS=$(git diff --name-only "$RANGE" 2>/dev/null | while read -r f; do
  if [ -f "$f" ]; then
    if grep -l -E '(@deutschepost\.de|@dhl\.com)' "$f" 2>/dev/null; then
      echo "$f"
    fi
  fi
done | head -10)
set -o pipefail
if [ -n "$PII_HITS" ]; then
  echo "WARN: Files with internal email domains (review before push):"
  echo "$PII_HITS" | sed 's/^/  - /'
  # Warn only, don't block
else
  echo "  OK: no internal email domains"
fi

echo ""
echo "=== Summary ==="
if [ $VIOLATIONS -eq 0 ]; then
  echo "SAFE to push to $REMOTE"
  exit 0
else
  echo "BLOCKED: $VIOLATIONS violation(s) found."
  echo ""
  echo "Enterprise-Rule: .claude/ and Claude-specific artifacts must never be pushed to git.dhl.com."
  echo "Fix: Unstage/rebase the affected files before pushing."
  exit 1
fi
