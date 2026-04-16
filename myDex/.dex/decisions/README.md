# Decisions

This folder contains decisions captured by DexMaster during sessions.

## Format

Each decision is a markdown file: `NNN-short-description.md`

```markdown
# Short Title

- **ID:** NNN
- **Date:** YYYY-MM-DD
- **Project:** project-name | system
- **Scope:** project | system
- **Decision:** What was decided
- **Reason:** Why this was chosen
- **Alternatives:** What was considered but rejected
- **Impact:** What this affects
```

## How Decisions Are Captured

DexMaster automatically detects decision patterns in conversation:
- "Lass uns X nehmen" → Architecture Decision
- "X statt Y, weil Z" → Tech Decision
- "Ab jetzt immer X" → Preference (goes to profile.yaml instead)

You will see a brief `📌 Notiert: ...` confirmation. No action needed.

## Viewing Decisions

Ask DexMaster: "Welche Entscheidungen haben wir getroffen?"
