# Bug Report Template

## YAML Front Matter

```yaml
---
id: BUG-{COUNTER}
type: bug
status: open
priority: {low|medium|high|critical}
created: {ISO-8601-TIMESTAMP}
author: {GIT-USERNAME}
tags: [{COMMA-SEPARATED-TAGS}]
github_issue: null
---
```

## Markdown Body

```markdown
# {TITLE}

## Problem
{USER-DESCRIPTION}

## Steps to Reproduce
{STEPS or "Not provided"}

## Expected vs Actual
{EXPECTED-ACTUAL or "Not provided"}

## Additional Context
- DexHub Version: EA-1.0
- Created via: Dev-Mode *bug
```

## Prompts

1. **Title**: "Title (short description):"
2. **Description**: "Describe the problem (no character limit):"
3. **Steps**: "Steps to reproduce (or 'skip'):"
4. **Expected/Actual**: "Expected behavior vs actual behavior (or 'skip'):"
5. **Priority**: "Priority [low/medium/high/critical] (default: medium):"
6. **Tags**: "Tags (comma-separated, or 'skip'):"

## Output File

`.dexCore/_dev/todos/bugs.md`
