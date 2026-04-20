# Your L2 Tank

This directory holds your personal L2 Knowledge Tank — a SQLite database with chunked + searchable content ingested from L1 Wiki, L3 Chronicle, and documents you drop into `myDex/inbox/`.

## TL;DR

```bash
# 1. One-time init
bash .dexCore/core/knowledge/l2/l2-init.sh

# 2. Feed it content
bash .dexCore/core/knowledge/l2/l2-ingest.sh --source myDex/.dex/wiki/*.md

# 3. Ask it things
bash .dexCore/core/knowledge/l2/l2-query.sh "how did we handle X"

# Anytime — see what's there
bash .dexCore/core/knowledge/l2/l2-status.sh
```

## Two search modes

L2 Tank supports **two search modes**, and it is honest about which one it is using every time you query.

### Keyword-only (always works)

- Built on SQLite FTS5 + BM25 ranking
- No installs, no network, no extra dependencies beyond what DexHub already needs (`sqlite3`, `ruby`, `awk` — all standard on macOS)
- Finds chunks whose words match your query
- Fast: sub-10ms on tanks with 100k+ chunks
- This is what you get out of the box

### Hybrid keyword + semantic (optional, opt-in)

- Adds semantic similarity via local embeddings
- Finds chunks with the **same meaning** even if they use different words
  - e.g. asking `"how do we authenticate users?"` can surface a chunk that only mentions `"login flow"` or `"session tokens"`
- Requires [Ollama](https://ollama.com) + a small embedding model (~137 MB, one-time pull)
- 100% local — embeddings are computed on your machine, nothing leaves the device
- Hybrid ranking blends BM25 (exact-word match) with cosine similarity (meaning match)

### Which one am I getting?

Run `bash .dexCore/core/knowledge/l2/l2-status.sh` to see. Every query also prints a `Mode:` banner at the top:

```
# L2 TANK — results for "authentication"

  Mode: KEYWORD-ONLY (BM25 via FTS5)  ·  enable semantic: ollama pull nomic-embed-text

(3 shown, 12 matched, top 5)
...
```

When Ollama is installed AND `nomic-embed-text` is pulled AND you have run `l2-embed.sh`, the banner flips to `HYBRID`.

## Enabling semantic search

```bash
# 1. Install Ollama (if you haven't): https://ollama.com
# 2. Pull the embedding model (one-time, ~137 MB)
ollama pull nomic-embed-text

# 3. Check detection picks it up
bash .dexCore/core/knowledge/l2/l2-detect-backend.sh
# Expected: Status: READY, Semantic search: AVAILABLE

# 4. Generate embeddings for already-ingested chunks
#    (Phase 5.2.b-embed — ships in an upcoming slice. Today this is a no-op stub.)
bash .dexCore/core/knowledge/l2/l2-embed.sh
```

If you decide **not** to install Ollama, L2 Tank still works — keyword search is the entire Beta 1.0 experience by default, and the framework never blocks on a missing embedding backend.

## Which embedding model? (the minimal one)

DexHub defaults to **`nomic-embed-text`** — chosen deliberately:

| Model | Size | Dimensions | Fit for L2 Tank |
|---|---|---|---|
| `all-minilm` | ~45 MB | 384 | Too small — noticeable quality drop |
| **`nomic-embed-text`** | **~137 MB** | **768** | **Sweet spot — local, fast, solid quality** |
| `mxbai-embed-large` | ~670 MB | 1024 | Overkill for Beta 1.0 scale |

Only used for **embeddings**, never for generation / chat — so your compute + memory footprint stays minimal. No LLM cost. No cloud round-trip.

You can override via the meta table:

```bash
sqlite3 myDex/.dex/l2/tank.sqlite "UPDATE meta SET value='ollama/all-minilm' WHERE key='default_embedding_backend'"
```

## Enterprise compliance

The backend router respects `profile.company.data_handling_policy` (set via onboarding Q43):

- `local_only` / `lan_only` → only Ollama-backed models run. Cloud embedding backends are blocked.
- `cloud_llm_allowed` / `hybrid` → cloud backends (OpenAI, Anthropic embeddings) opt-in with consent — implementation ships in 5.2.b-enterprise-audit.

Default backend is local. Enterprise users never get cloud embeddings unless they explicitly opt in.

## What lives here

- **`tank.sqlite`** — your knowledge DB (private, gitignored)
- **`tank.sqlite-wal`**, **`tank.sqlite-shm`** — SQLite internals (gitignored)
- **`copilot-seed-query.txt`** — optional; when present, `build-instructions.sh` runs a single query through L2 and bakes the top chunks into `copilot-instructions.md` at build time (see `knowledge.l2_tank_wire_copilot`)
- **`README.md`** — this doc (tracked, framework-shipped)

Your content is local. Nothing leaves your machine unless you explicitly opt into cloud embeddings.

## Architecture

See `.dexCore/_dev/docs/L2-TANK.md` for the full design + phase chronology.

L2 Tank is part of the Knowledge Layer triple:

| Layer | Scale | Retrieval | Contents |
|---|---|---|---|
| **L1 Wiki** | <20KB | Session-start (always loaded) | Glossary, architecture notes |
| **L2 Tank** | MB-GB | On-demand + build-time seed query | Chunked + searchable everything |
| **L3 Chronicle** | unbounded | Ingested into L2 | Session diaries, time-ordered |

L2 ingests from L1 and L3; it does not replace them.
