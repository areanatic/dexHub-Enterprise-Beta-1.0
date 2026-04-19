# Your L2 Tank

This directory holds your personal L2 Knowledge Tank — a SQLite database with chunked + searchable content ingested from L1 Wiki, L3 Chronicle, and documents you drop into `myDex/inbox/`.

## How to use

```bash
# One-time setup
bash .dexCore/core/knowledge/l2/l2-init.sh
#   Creates tank.sqlite in this directory.

# Ingest content (ships in future phase 5.2.b-ingest)
bash .dexCore/core/knowledge/l2/l2-ingest.sh --source myDex/.dex/wiki/*.md
bash .dexCore/core/knowledge/l2/l2-ingest.sh --source myDex/.dex/chronicle/*.md

# Query (ships in future phase 5.2.b-query)
bash .dexCore/core/knowledge/l2/l2-query.sh "how did we handle X"
```

## What lives here

- **`tank.sqlite`** — your knowledge DB (private, gitignored)
- **`tank.sqlite-wal`**, **`tank.sqlite-shm`** — SQLite internal (gitignored)
- **`README.md`** — this doc (tracked, framework-shipped)

Your content is local. Nothing leaves your machine unless you explicitly opt into cloud embeddings (default is Ollama local).

## Scope (honest labels)

This directory structure ships in `5.2.b-scaffold`. The init script actually works. The ingest + query scripts are STUBS that emit `[L2 STUB]` signals — they do NOT yet ingest or query. Real implementation ships across future phases 5.2.b-ingest, 5.2.b-embed, 5.2.b-query, 5.2.b-wire-copilot.

Authoring L1 Wiki entries + populating L3 Chronicle today is still valuable — when L2 ingest ships, those will be the first sources.

## Architecture

See `.dexCore/_dev/docs/L2-TANK.md` for the full design doc.
