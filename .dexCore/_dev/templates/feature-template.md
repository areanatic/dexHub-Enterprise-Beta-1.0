# Feature Request Template

## YAML Front Matter

```yaml
---
id: FEATURE-{COUNTER}
type: feature
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

## User Story
{USER-STORY}

## Acceptance Criteria
{CRITERIA or "To be defined"}

## Additional Context
- DexHub Version: EA-1.0
- Created via: Dev-Mode *feature
```

## Prompts

1. **Title**: "Title (short description):"
2. **User Story**: "As a [type of user], I want [goal] so that [benefit]: (or describe freely)"
3. **Acceptance Criteria**: "Acceptance criteria (or 'skip'):"
4. **Priority**: "Priority [low/medium/high/critical] (default: medium):"
5. **Tags**: "Tags (comma-separated, or 'skip'):"

## Output File

`.dexCore/_dev/todos/features.md`
