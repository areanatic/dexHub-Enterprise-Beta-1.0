# Research Topic Template

## YAML Front Matter

```yaml
---
id: RESEARCH-{COUNTER}
type: research
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

## Background
{BACKGROUND}

## Key Questions
{QUESTIONS or "To be defined"}

## Resources
{RESOURCES or "None yet"}

## Findings
<!-- Add research findings here -->

## Additional Context
- DexHub Version: EA-1.0
- Created via: Dev-Mode *research
```

## Prompts

1. **Title**: "Title (what to research):"
2. **Background**: "Background/context for this research:"
3. **Questions**: "Key questions to answer (or 'skip'):"
4. **Resources**: "Initial resources/links (or 'skip'):"
5. **Priority**: "Priority [low/medium/high/critical] (default: medium):"
6. **Tags**: "Tags (comma-separated, or 'skip'):"

## Output File

`.dexCore/_dev/todos/research.md`
