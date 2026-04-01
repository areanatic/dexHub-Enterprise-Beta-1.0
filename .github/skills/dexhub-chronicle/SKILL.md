---
name: dexhub-chronicle
description: DexHub Chronicle System — 3-tier documentation model for session logging, milestones, and project activity tracking. Use when writing daily logs, updating changelogs, or managing project chronicles.
---

# Chronicle System (FEATURE-008)

## 3-Tier Documentation Model

| Tier | File | Purpose | Update Frequency |
|------|------|---------|------------------|
| **1** | `CHANGELOG.md` | Milestones, major achievements | At milestones |
| **2** | `chronicle/YYYY-MM-DD.md` | Daily detail logs, sessions | Every session |
| **3** | `INDEX.md` Activity Log | Quick-access recent activity | Auto-extracted from chronicle |

## Chronicle Structure

```
chronicle/
├── 2026-02-21.md     ← Today's log (multiple sessions)
├── 2026-02-20.md     ← Yesterday
├── README.md         ← Chronicle instructions
└── archive/          ← Logs >30 days old
    └── 2026-01/      ← Archived by month
```

## Daily Log Format (YYYY-MM-DD.md)

```markdown
# Chronicle: YYYY-MM-DD

**Project:** {project_name}
**Day:** {weekday}, YYYY-MM-DD
**Status:** [Active | Paused | Blocked | Review]

---

## Summary
> One-sentence summary of the day.

---

## Sessions

### Session 1
**Focus:** {session_focus}

**What was done:**
- Action 1

**Decisions made:**
- Decision: Rationale

**Insights:**
- Important learning

**Blockers:**
- Any blockers

---

## Files Changed
| File | Action | Notes |
|------|--------|-------|
| `path/to/file` | Created/Modified | Description |

---

## Open Questions
- [ ] Question 1

---

## Tomorrow's Plan
- [ ] Next step 1

---

**Total Sessions:** N
**Time Invested:** Xh
```

## Chronicle Save Rules

| Trigger | Action | Priority |
|---------|--------|----------|
| **Session Start** | Create/append to today's chronicle | Required |
| **Session End** | Complete session block, update summary | Required |
| **Milestone** | Update CHANGELOG.md + chronicle | Required |
| **Decision Made** | Add to "Decisions made" section | High |
| **Blocker Encountered** | Add to "Blockers" section | High |
| **File Changed** | Add to "Files Changed" table | Normal |
| **Insight Discovered** | Add to "Insights" section | Normal |

## How to Save

1. **On Session Start:** Check if `chronicle/{today}.md` exists → YES: Append new session block | NO: Create from template
2. **On Session End:** Complete current session block (What was done, Files Changed, Total Sessions)
3. **On Milestone:** Add to CHANGELOG.md (Tier 1) → Mark in chronicle (Tier 2) → Update INDEX.md (Tier 3)

## Content Type Mapping

| Content Type | Location | Update Rule |
|--------------|----------|-------------|
| **Daily work** | `chronicle/YYYY-MM-DD.md` | Every session |
| **Milestones** | `CHANGELOG.md` | On feature/release completion |
| **Project status** | `INDEX.md` Activity Log | Auto-extract from chronicle/ |
| **External files** | `inputs/manifest.csv` | On import (>=20 files) |
| **Decisions** | chronicle/ + INDEX.md | Document immediately |
| **Archive** | `chronicle/archive/YYYY-MM/` | Auto after 30 days |
