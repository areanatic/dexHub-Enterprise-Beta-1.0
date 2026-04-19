# L1 Wiki Session-Start Injection

> **Status (2026-04-20):** Scaffold shipped. Script works standalone. Wiring into actual session-start (Claude Code / Copilot / agent boot) is a follow-up.
> **Feature:** `knowledge.l1_wiki_injection` in `.dexCore/_cfg/features.yaml`
> **Activates:** `knowledge.l1_wiki` scaffold (commit `019af7c`) from authoring-surface to runtime-loadable

## The missing link

Today's L1 Wiki scaffold (commit `019af7c`) lets users AUTHOR wiki entries in `myDex/.dex/wiki/`. But entries are not auto-loaded into agent sessions — as `L1-WIKI-PATTERN.md` honestly notes. This doc defines the injection contract, and `.dexCore/core/knowledge/load-wiki.sh` implements the enumeration + formatting step.

Actual hookup to Claude Code / Copilot / Ollama session-start is platform-specific and deferred, but the core enumeration logic is complete and testable today.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  myDex/.dex/wiki/                                           │
│  ├── README.md              ← FRAMEWORK SHIPPED (skip)      │
│  ├── institutional.md       ← USER AUTHORED  (load)         │
│  ├── project-glossary.md    ← USER AUTHORED  (load)         │
│  └── foo.template.md        ← TEMPLATE       (skip)         │
└──────────────────┬──────────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────────┐
│  .dexCore/core/knowledge/load-wiki.sh                       │
│    - Enumerates *.md files                                  │
│    - Filters: skip README.md + *.template.md                │
│    - Size cap: 20 KB total (user configurable)              │
│    - Individual file cap: 2 KB (per L1-WIKI-PATTERN.md)     │
│    - Status filter: frontmatter `status: active` only       │
│    - Outputs: formatted session-prompt block                │
└──────────────────┬──────────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────────┐
│  Downstream consumers (PLATFORM-SPECIFIC, DEFERRED):        │
│                                                             │
│  Claude Code:  append output to CONTEXT.md at session       │
│                start, so agents reading CONTEXT.md pick it  │
│                up. Or: wire into SSOT compile step so       │
│                .claude/CLAUDE.md gets the block.            │
│                                                             │
│  Copilot:      append to .github/copilot-instructions.md    │
│                via SSOT compile step (wiki content becomes  │
│                part of every Copilot session).              │
│                                                             │
│  Manual:       agents can invoke load-wiki.sh on request    │
│                (works today; just no auto-inject yet).      │
└─────────────────────────────────────────────────────────────┘
```

## Script contract

Location: `.dexCore/core/knowledge/load-wiki.sh`

Usage:
```bash
# Default: enumerate + print
bash .dexCore/core/knowledge/load-wiki.sh

# Custom wiki directory (testing)
bash .dexCore/core/knowledge/load-wiki.sh --wiki-dir /path/to/wiki

# Size caps (defaults: total 20KB, per-file 2KB)
bash .dexCore/core/knowledge/load-wiki.sh --max-total 20480 --max-file 2048

# Machine-readable status
bash .dexCore/core/knowledge/load-wiki.sh --summary-only
#   Output: N entries loaded, M skipped, T bytes total
```

Output shape (when entries found):
```
# ═══════════════════════════════════════════════════════════
# L1 WIKI (user's institutional knowledge)
# Loaded 3 entries, 4521 bytes. Source: myDex/.dex/wiki/
# ═══════════════════════════════════════════════════════════

## institutional.md

<file content here, truncated to 2KB if larger>

## project-glossary.md

<file content>

# ═══════════════════════════════════════════════════════════
# END L1 WIKI — next: standard session context
# ═══════════════════════════════════════════════════════════
```

When no wiki entries exist (only `README.md`): exits silently with code 0, no output. Prevents polluting sessions on fresh installs.

## Frontmatter contract

Per `L1-WIKI-PATTERN.md`, authored entries SHOULD include:

```markdown
---
title: <short>
last_reviewed: YYYY-MM-DD
status: active | archived
why_l1: <reason this earns a session-start slot>
---
```

The script filters `status: archived` out — only `active` (or missing status field) loads. Authors can park old entries by flipping status to `archived` without deleting them.

## Honest limits

- **No validation of frontmatter quality** — script checks syntax, not content. Users authoring aspirational L1 entries still pollute context; no tool can auto-detect "this should be in L2 instead".
- **Size cap is advisory, not cryptographic** — user can override with `--max-total`. Intended to prevent accidental 500KB wiki from destroying agent context windows.
- **Not wired to session start yet** — the pipeline exists; the hookup is platform-specific and remains a scaffold deliverable.
- **Order is filesystem-dependent** — files are enumerated in alphabetical order. Users wanting specific order should prefix with numbers (`01-foo.md`, `02-bar.md`).

## Phase milestones

- ✅ **5.2.a** (2026-04-20 morning, commit `019af7c`) — authoring scaffold: pattern doc, templates, user README
- ✅ **5.2.d-scaffold** (2026-04-20 late, this commit) — load-wiki.sh + design doc + test 10 structural verification
- ⬜ **5.2.d-wire-claude-code** — append load-wiki.sh output to CONTEXT.md at Claude Code session start (integration point: SSOT compile step OR a `.claude/hooks/SessionStart` hook)
- ⬜ **5.2.d-wire-copilot** — bake wiki content into `.github/copilot-instructions.md` via SSOT compile (so GitHub Copilot users see it)
- ⬜ **5.2.b** — L2 Tank (SQLite + chunker + semantic search) for anything too big for L1
