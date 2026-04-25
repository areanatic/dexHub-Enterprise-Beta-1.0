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
- If CONTEXT.md was updated during the session (agent-driven), chronicle adds narrative context on top

## Agent-driven vs Manual

CONTEXT.md updates are **agent-driven** during state transitions — DexMaster decides when to write (state changes, agent activations, *save commands). It is NOT a background service that runs after every task. Honest convention per SHARED.md §DexMemory.

Chronicle is optional — it provides the detailed "story" of a session.
If you close VS Code without `*save`, no chronicle is written. CONTEXT.md state reflects only the last agent-driven write.
