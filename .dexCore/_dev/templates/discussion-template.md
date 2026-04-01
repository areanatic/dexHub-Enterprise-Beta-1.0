# Discussion Topic Template

## YAML Front Matter

```yaml
---
id: DISCUSS-{COUNTER}
type: discussion
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

## Context
{CONTEXT}

## Initial Thoughts
{THOUGHTS or "Open for discussion"}

## Questions
{QUESTIONS or "General discussion"}

## Responses
<!-- Team members add responses here -->

## Additional Context
- DexHub Version: EA-1.0
- Created via: Dev-Mode *discuss
```

## Prompts

1. **Title**: "Title (what to discuss):"
2. **Context**: "Context/background for this discussion:"
3. **Initial Thoughts**: "Your initial thoughts/position (or 'skip'):"
4. **Questions**: "Questions for the team (or 'skip'):"
5. **Priority**: "Priority [low/medium/high/critical] (default: medium):"
6. **Tags**: "Tags (comma-separated, or 'skip'):"

## Output File

`.dexCore/_dev/todos/discussions.md`
