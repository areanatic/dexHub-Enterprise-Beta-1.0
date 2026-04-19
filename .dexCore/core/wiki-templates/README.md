# DexHub L1 Wiki Templates

Framework-shipped templates for the L1 Knowledge Layer (`myDex/.dex/wiki/`).

**Background:** see `.dexCore/_dev/docs/L1-WIKI-PATTERN.md`.

## Usage

```bash
# Copy a template into your user wiki
cp .dexCore/core/wiki-templates/institutional-knowledge.template.md \
   myDex/.dex/wiki/institutional-knowledge.md

# Fill it in, commit nothing (the wiki is gitignored beyond README.md)
```

## Available templates

| Template | Purpose |
|---|---|
| `institutional-knowledge.template.md` | Long-lived truths that would be expensive to re-discover ("we tried X, it broke Y") |
| `project-glossary.template.md` | Terms-of-art: words that mean something specific inside your team |
| `architecture-notes.template.md` | The 3-5 architectural decisions any agent touching your code must know |

## Authoring rules

- Keep each file ≤2 KB
- Include `last_reviewed` frontmatter field — stale entries should be pruned
- Prefer 5 focused entries over 20 aspirational ones
- If an entry gets long, move it to `.dexCore/_dev/docs/` or `myDex/drafts/` and link from the wiki

## Session-start injection

Templates and populated wiki entries are **not auto-loaded** until Phase 5.2.d ships the ingest pipeline. Until then, agents read on request. Authoring them now is still valuable — they become searchable context for any agent that chooses to grep the workspace.
