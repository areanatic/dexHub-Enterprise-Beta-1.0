---
title: Architecture Notes
last_reviewed: YYYY-MM-DD
status: active
why_l1: The 3-5 architectural decisions any agent touching this codebase must know before making proposals.
---

# Architecture Notes

## What this file is

The **load-bearing architectural decisions** that shape this project. An agent making changes without knowing these will produce plausible-looking work that fights the codebase.

Keep this to 3-5 entries. If it grows, split into `architecture-<topic>.md` files.

## Format per decision

```
### <Decision headline>
- **Since:** <YYYY-MM-DD>
- **Choice:** <what we decided, one sentence>
- **Alternatives considered:** <what we ruled out and why>
- **Consequences:** <what this decision forces / forbids downstream>
- **When to revisit:** <condition under which this would change>
```

## Decisions

### <Decision headline>
- **Since:** <date>
- **Choice:** <...>
- **Alternatives considered:** <...>
- **Consequences:** <...>
- **When to revisit:** <...>

---

### <Decision headline>
- **Since:** <date>
- **Choice:** <...>
- **Alternatives considered:** <...>
- **Consequences:** <...>
- **When to revisit:** <...>

---

## Non-decisions (things that are NOT architecture here)

Occasionally agents will propose introducing a pattern that contradicts one of the above. To save time, list things that are deliberately NOT part of this architecture:

- <Pattern> — we don't use this because <reason>
- <Framework> — we don't use this because <reason>

## Maintenance

- When a major refactor happens, this file changes. Update `last_reviewed` + add a new entry.
- Delete or archive entries that no longer reflect reality — stale architecture notes are worse than no notes.
- Keep entries short. ADRs for full decisions live in `.dexCore/_dev/docs/adr/`; this file is the session-start summary.

## Anti-patterns this file prevents

- Proposing patterns the team has already rejected
- Fighting the codebase by accident
- Repeating "why didn't you just use X?" debates every session
