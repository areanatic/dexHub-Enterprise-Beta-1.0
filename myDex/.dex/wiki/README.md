# Your L1 Wiki

This directory is your personal L1 Knowledge Layer. Markdown files you place here become the **highest-trust context** for DexHub agents working in this project.

## How to use

1. Read `.dexCore/_dev/docs/L1-WIKI-PATTERN.md` — the pattern overview
2. Pick a template from `.dexCore/core/wiki-templates/`
3. Copy it here, rename to a topic (e.g. `institutional-knowledge.md`, `project-glossary.md`)
4. Fill it in. Keep each file ≤2 KB.
5. Re-visit quarterly. Delete stale entries.

## What's tracked vs private

- **This `README.md`** — framework-shipped, tracked in git
- **Your `*.md` entries** — private, gitignored by default (see `.gitignore` → `myDex/.dex/wiki/*`)
- **`*.template.md` files** — if you copy templates here with the `.template.md` suffix, they stay tracked as reference

## Session-start injection — honest status

As of 2026-04-20, entries you place here are **authored but not automatically loaded** into every session. Agents read them on request. Automatic injection ships with `knowledge.ingest_pipeline` (Phase 5.2.d).

Authoring now is still valuable:
- Agents that grep your workspace find these entries
- When 5.2.d lands, your existing entries activate automatically
- You can explicitly `@wiki` them via DexMaster (planned Phase 5.2.b)

## Recommended starter set

Pick one to three. More than three at the start usually means aspiration, not signal.

1. `institutional-knowledge.md` — "we tried X, it broke Y" lessons
2. `project-glossary.md` — 10-20 terms whose team-specific meaning matters
3. `architecture-notes.md` — the 3-5 architectural decisions an agent must know

## Escape hatch

If an entry grows too large (>2 KB) or becomes research-shaped, move it to `.dexCore/_dev/docs/` (framework) or `myDex/drafts/` (scratch) and leave a one-line pointer here.
