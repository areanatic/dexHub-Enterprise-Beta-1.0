# Design Proposal Template

## YAML Front Matter

```yaml
---
id: DESIGN-{COUNTER}
type: design
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

## Problem Statement
{PROBLEM}

## Proposed Solution
{SOLUTION}

## Alternatives Considered
{ALTERNATIVES or "None documented"}

## Mockups/Diagrams
<!-- Add visual references here -->

## Additional Context
- DexHub Version: EA-1.0
- Created via: Dev-Mode *design
```

## Prompts

1. **Title**: "Title (design topic):"
2. **Problem Statement**: "What problem does this design solve:"
3. **Proposed Solution**: "Describe the proposed design:"
4. **Alternatives**: "Alternative approaches considered (or 'skip'):"
5. **Priority**: "Priority [low/medium/high/critical] (default: medium):"
6. **Tags**: "Tags (comma-separated, or 'skip'):"

## Output File

`.dexCore/_dev/todos/design.md`
