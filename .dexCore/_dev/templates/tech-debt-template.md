# Technical Debt Template

## YAML Front Matter

```yaml
---
id: DEBT-{COUNTER}
type: tech-debt
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

## Description
{DESCRIPTION}

## Impact
{IMPACT or "Not assessed"}

## Suggested Solution
{SOLUTION or "To be determined"}

## Additional Context
- DexHub Version: EA-1.0
- Created via: Dev-Mode *tech-debt
```

## Prompts

1. **Title**: "Title (what needs refactoring):"
2. **Description**: "Describe the technical debt:"
3. **Impact**: "Impact if not addressed (or 'skip'):"
4. **Suggested Solution**: "Suggested solution (or 'skip'):"
5. **Priority**: "Priority [low/medium/high/critical] (default: medium):"
6. **Tags**: "Tags (comma-separated, or 'skip'):"

## Output File

`.dexCore/_dev/todos/tech-debt.md`
