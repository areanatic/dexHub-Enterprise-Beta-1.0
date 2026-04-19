# L1 Wiki Pattern — Institutional Knowledge Layer

> **Status (2026-04-20):** Scaffold shipped. Session-start injection pipeline deferred to Phase 5.2.d (ingest + query).
> **Feature:** `knowledge.l1_wiki` in `.dexCore/_cfg/features.yaml`
> **Owner:** user (workspace) + framework (templates)
> **Related:** L2 Tank (SQLite, deferred 5.2.b), L3 Chronicle (already exists)

---

## What is L1 Wiki

L1 Wiki is the **highest-trust tier** of the DexHub Knowledge Layer. It is a small set of short markdown files that describe the user's project-specific truth: team glossary, architecture notes, institutional knowledge, decisions-made-long-ago-that-still-matter.

The defining property of L1 is **injection at session start** — these files are short enough and important enough that every DexHub session loads them unconditionally, so agents never have to re-discover them.

L1 is distinct from:
- **L2 Tank** — larger corpus (SQLite + semantic search), queried on-demand
- **L3 Chronicle** — session diaries, time-ordered, not pre-loaded

Analogy: L1 is your team's whiteboard. L2 is your team's Confluence. L3 is your team's Slack history.

---

## Directory layout

```
myDex/.dex/wiki/                              # USER WORKSPACE (private, partly gitignored)
├── README.md                                 # Shipped by framework, tracked
└── *.md                                      # User-added entries, gitignored

.dexCore/core/wiki-templates/                 # FRAMEWORK-SHIPPED TEMPLATES (tracked)
├── README.md                                 # Template index
├── institutional-knowledge.template.md       # Long-lived truth template
├── project-glossary.template.md              # Terms-of-art template
└── architecture-notes.template.md            # System context template
```

The `myDex/.dex/wiki/` directory is the user's workspace. Framework ships templates in `.dexCore/core/wiki-templates/`; user copies the ones they want.

---

## What belongs in L1

Keep the bar high. An entry earns its L1 slot only if it would be strictly worse to re-discover every session.

Good L1 candidates:
- **Team glossary** — 10-20 domain terms that mean something different inside your team than outside
- **Architecture notes** — the 3-5 decisions that any agent touching your codebase must know
- **Institutional knowledge** — "we tried X in 2023, it failed because Y" (prevents re-proposal)
- **Project-specific conventions** — e.g. "we always use X library for Y because Z, don't suggest alternatives"

Bad L1 candidates (belong in L2 or L3):
- Changelogs — chronological, goes to L3 chronicle
- Full API docs — large, goes to L2 Tank
- Research notes — typically one-off, goes to drafts/ or L3
- Per-feature PRDs — too large, L2

---

## Recommended entry shape

```markdown
---
title: <short descriptor>
last_reviewed: <YYYY-MM-DD>
status: active | archived
why_l1: <one-line reason this earns a session-start slot>
---

# <Title>

## Facts
<what is true, in ≤200 words>

## Why this matters
<when an agent needs to invoke this knowledge>

## Counter-examples
<when this rule does NOT apply — prevents over-generalization>
```

Keep each file ≤2 KB. If it grows beyond that, it probably belongs in L2.

---

## Session-start injection (Phase 5.2.d)

The scaffold (this doc + templates + user-wiki README) ships today.

The runtime pipeline that reads `myDex/.dex/wiki/*.md` and appends to every new agent session's system prompt is `knowledge.ingest_pipeline` — deferred to Phase 5.2.d. Until then, L1 Wiki entries are **authored but not automatically loaded**. Agents can still read them manually on request.

When 5.2.d ships, the injection contract will be:
1. On new session, enumerate `myDex/.dex/wiki/*.md` (excluding `README.md` and `*.template.md`)
2. For each file ≤2 KB with `status: active`, append content to the agent's pre-task context
3. If total size exceeds 20 KB, skip remaining and log a warning
4. Re-read cadence: per-session (not per-turn), cheap

---

## Relation to profile.yaml

`profile.yaml` captures personal preferences (name, language, role, code style). L1 Wiki captures project-specific truth. Do not put user preferences in the wiki, and do not put project truth in the profile.

Rule of thumb: if it would change when the user switches projects, it belongs in L1 Wiki. If it stays true across projects, it belongs in `profile.yaml`.

---

## Gitignore rules

See the project `.gitignore`. Framework-shipped files in `myDex/.dex/wiki/` (currently only `README.md`) are tracked. User-added entries are private by default.

---

## Bootstrapping checklist

1. Read this doc
2. Read `.dexCore/core/wiki-templates/README.md` — the template index
3. Copy 1-3 templates into `myDex/.dex/wiki/` — start small
4. Fill them in using the entry shape above
5. Re-visit after 2 weeks, keep only what you actually referenced

Small wiki > aspirational wiki. Delete entries that go stale.
