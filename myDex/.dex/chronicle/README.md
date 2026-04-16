# Chronicle

Session history logs, created on `*save` or `*exit`.

## Format

Each file: `YYYY-MM-DD.md` (one per day, appended if multiple sessions)

```markdown
# Session Log — YYYY-MM-DD

## Context
- **Project:** project-name
- **Agent(s):** @agent-names
- **Duration:** approximate

## Completed
- Task descriptions with output locations

## Decisions
- Referenced decision IDs

## Open Items
- Remaining tasks

## Notes
- Observations, preference changes, learnings
```

## When Are Chronicle Entries Created?

- User says `*save`, `*exit`, "Session speichern", or similar
- DexMaster creates a summary of the session
- If auto-save already captured everything, chronicle adds narrative context

## Automatic vs Manual

Auto-save (CONTEXT.md) runs silently after every task.
Chronicle is optional — it provides the detailed "story" of a session.
If you close VS Code without `*save`, no chronicle is written, but CONTEXT.md has all essential state.
