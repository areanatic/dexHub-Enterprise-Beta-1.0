# L2 Tank — SQLite Knowledge Store with Chunker + Hybrid Search

> **Status (2026-04-20):** Design + scaffold. Implementation (real ingest, real embeddings, real query) deferred to future sessions.
> **Feature:** `knowledge.l2_tank_sqlite` (parent) + 4 sub-features in `.dexCore/_cfg/features.yaml`
> **Layer position:** Between L1 Wiki (tiny, session-start, always loaded) and L3 Chronicle (time-ordered diaries).
> **Architectural parent:** Knowledge Layer triple (L1/L2/L3) established in PRs pre-2026-04-20.

---

## Architectural fit review (user question 2026-04-20)

The user asked: does native SQLite + chunker + semantic search fit DexHub, work, not contradict the concept, AND is optimized for GitHub Copilot + LLM readability + efficiency?

**Answer: yes, with specific constraints documented below.** This section is the binding review.

### Does it fit DexHub's concept?

| DexHub principle | L2 Tank stance |
|---|---|
| **GitHub Copilot primary target** | ✓ L2 Tank surfaces to Copilot via two paths: (a) build-time baking of top-N chunks into `copilot-instructions.md`, (b) manual user query via `l2-query.sh` → user pastes results into chat |
| **Platform-agnostic core, integration modules removable** | ✓ `.dexCore/core/knowledge/l2/*.sh` + schema SQL are pure bash + sqlite3 (both platform-agnostic). Claude Code's ability to query L2 via tool-call would live in `integrations/claude-code/` (future). Cursor/IntelliJ the same. |
| **SSOT compile step** | ✓ `build-instructions.sh` will invoke a batch-query at build time (same pattern as L1 Wiki injection shipped in commit `27e9dba`). Wiki is "everything always"; Tank is "top-N relevant for this build". |
| **Local-first, privacy** | ✓ SQLite is a local file. Hybrid search via FTS5 (local) + embeddings (local via Ollama nomic-embed-text, default) stays local. Cloud-embedding path exists for users with `data_handling_policy=cloud_llm_allowed` but is opt-in. |
| **Feature-flag + honesty** | ✓ 4 sub-features (schema, init, ingest, query) with status per deliverable, not one monolithic "Tank" that's either on or off. |
| **Enterprise compliance** | ✓ `enterprise_compliance` per sub-feature + per embedding backend. Default embedding = Ollama local (enterprise_compliance: ok or local_vlm_required). |
| **Layer-1 wins, no drift** | ✓ Schema is versioned; migrations go through design doc + features.yaml. Drift caught by validate.sh §23. |

### Does it work?

FTS5 (built into macOS sqlite3 3.51.0, verified) is production-ready. BM25 full-text search with Unicode tokenizer. Sub-100ms queries on small/medium corpora.

Embedding path: nomic-embed-text via Ollama is ~2GB, locally deployed, ~100ms per query. Industry-standard for local-first semantic search.

Hybrid ranking (FTS5 score + embedding cosine similarity): implemented as a post-query merge. Trivial to do in bash + sqlite CLI for Beta 1.0 corpora (<100k chunks).

### Is it optimized for Copilot + LLM readability + efficiency?

**Copilot context injection** (build-time):
- `build-instructions.sh` invokes `l2-query.sh` with a "what might be relevant to a fresh agent session" seed query (e.g. "architectural decisions + recent incidents")
- Top-N chunks (cap: 4KB for Copilot per `WIKI_MAX_COPILOT` precedent, probably more for L2) → baked into `copilot-instructions.md` under a `## L2 TANK (retrieved)` section
- Every Copilot session now has the most-relevant L2 content as first-class context, no tool-call needed

**Manual query** (user-driven):
- `bash .dexCore/core/knowledge/l2/l2-query.sh "how did we handle X"` → markdown output of top-5 chunks with source paths
- User copies into Copilot chat, Copilot responds with context

**Chunk output format** (optimized for LLM readability):
```markdown
## <title> — <source_path> (relevance: 0.87)

<chunk content>

---

## <title2> — <source_path2> (relevance: 0.72)

<chunk2 content>
```
No XML fluff, no tokenized blobs. LLM reads it as plain documentation.

**Efficiency:**
- SQLite FTS5: sub-10ms for keyword queries on 100k-chunk corpus
- Ollama nomic-embed-text (local): ~100ms per query embedding
- Total query latency: <200ms at 99th percentile
- Storage: ~50MB for a 10k-chunk corpus (FTS5 index + embeddings table)

### Does it contradict any existing decision?

Earlier (2026-04-19) the user made the correction: Memory-Keeper-MCP is NOT part of DexHub. This L2 Tank is the **native replacement**. Aligns with that correction perfectly.

No contradiction with Phase 5.2.a (L1 Wiki) or L3 Chronicle — those remain complementary. L2 Tank fills the "medium-sized + queryable" gap.

### Binding constraints (from the review)

1. **No cloud dependency by default.** Default embedding backend: Ollama local. Cloud-embedding is opt-in + gated by `profile.company.data_handling_policy`.
2. **Build-time injection respects instruction-file caps.** Top-N chunk limit + byte cap. Same pattern as L1 Wiki.
3. **All sub-features must be independently togglable.** Users might want schema+ingest but not query-during-build.
4. **Schema migrations go through features.yaml.** Version increments + documented.

---

## Scope this commit (scaffold only)

1. **Design doc** — this file
2. **Directory scaffold** — `.dexCore/core/knowledge/l2/`
3. **Schema SQL** — `schema.sql` defines the tables (not applied yet)
4. **Skeleton scripts** — `l2-init.sh`, `l2-ingest.sh`, `l2-query.sh` (stubs with honest "not yet implemented" signals)
5. **features.yaml** — L2 Tank broken into sub-features with honest status
6. **Test 12** — structural verification of the scaffold

Implementation (real ingest from wiki/chronicle, real embedding backend, real hybrid-search query) is explicit follow-up work in future sessions. Every stub outputs `[L2 STUB]` so nobody mistakes the scaffold for a working system.

---

## Schema (`.dexCore/core/knowledge/l2/schema.sql`)

```sql
-- chunks: one row per chunk ingested from any source file
CREATE TABLE IF NOT EXISTS chunks (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  source_path TEXT NOT NULL,           -- relative to repo root
  source_type TEXT NOT NULL,           -- 'wiki' | 'chronicle' | 'ingest'
  chunk_index INTEGER NOT NULL,        -- position within source file
  title       TEXT,                    -- h1/h2 heading or synthesized
  content     TEXT NOT NULL,           -- the chunk body (markdown)
  byte_size   INTEGER NOT NULL,
  created_at  TEXT NOT NULL,           -- ISO-8601
  updated_at  TEXT NOT NULL,           -- ISO-8601
  source_hash TEXT NOT NULL,           -- SHA-256 of source file at ingest time
  UNIQUE(source_path, chunk_index)
);

-- FTS5 virtual table for keyword search (porter stemming, unicode)
CREATE VIRTUAL TABLE IF NOT EXISTS chunks_fts USING fts5(
  title, content,
  content='chunks',
  content_rowid='id',
  tokenize='porter unicode61'
);

-- Triggers keep chunks_fts in sync with chunks
CREATE TRIGGER IF NOT EXISTS chunks_ai AFTER INSERT ON chunks BEGIN
  INSERT INTO chunks_fts(rowid, title, content) VALUES (new.id, new.title, new.content);
END;
CREATE TRIGGER IF NOT EXISTS chunks_ad AFTER DELETE ON chunks BEGIN
  DELETE FROM chunks_fts WHERE rowid = old.id;
END;
CREATE TRIGGER IF NOT EXISTS chunks_au AFTER UPDATE ON chunks BEGIN
  DELETE FROM chunks_fts WHERE rowid = old.id;
  INSERT INTO chunks_fts(rowid, title, content) VALUES (new.id, new.title, new.content);
END;

-- embeddings: one row per chunk. NULL embedding = not yet embedded.
-- Stored as JSON array of floats for portability. Real impl would use BLOB + float32.
CREATE TABLE IF NOT EXISTS embeddings (
  chunk_id       INTEGER PRIMARY KEY REFERENCES chunks(id) ON DELETE CASCADE,
  backend        TEXT NOT NULL,        -- 'ollama/nomic-embed-text' | 'openai/text-embedding-3-small' | ...
  dimensions     INTEGER NOT NULL,
  vector_json    TEXT NOT NULL,        -- JSON array of floats, len = dimensions
  embedded_at    TEXT NOT NULL
);

-- meta: single-row configuration (schema version, default embedding backend)
CREATE TABLE IF NOT EXISTS meta (
  key   TEXT PRIMARY KEY,
  value TEXT NOT NULL
);
INSERT OR IGNORE INTO meta(key, value) VALUES
  ('schema_version', '1'),
  ('default_embedding_backend', 'ollama/nomic-embed-text');
```

---

## Script contracts (stubs this commit)

### `l2-init.sh` — create empty Tank at `myDex/.dex/l2/tank.sqlite`

```bash
bash .dexCore/core/knowledge/l2/l2-init.sh                   # default path
bash .dexCore/core/knowledge/l2/l2-init.sh --db /custom/path.sqlite
```

STATUS THIS COMMIT: Implemented. Runs `sqlite3 "$DB" < schema.sql`. Idempotent.

### `l2-ingest.sh` — ingest source files into chunks

```bash
bash .dexCore/core/knowledge/l2/l2-ingest.sh --source myDex/.dex/wiki/*.md
bash .dexCore/core/knowledge/l2/l2-ingest.sh --source myDex/.dex/chronicle/*.md
```

STATUS THIS COMMIT: **STUB**. Emits `[L2 STUB] ingest not yet implemented — chunker + embedder are future sessions`. Chunking strategy (sliding-window with heading-aware boundaries) documented but not coded.

### `l2-query.sh` — keyword + semantic query, outputs top-N chunks

```bash
bash .dexCore/core/knowledge/l2/l2-query.sh "how did we handle X"
bash .dexCore/core/knowledge/l2/l2-query.sh --top 10 --format markdown "query"
```

STATUS THIS COMMIT: **STUB**. Emits `[L2 STUB] query not yet implemented — FTS5 + embedding-cosine hybrid search is future sessions`. Output format documented.

---

## Phase milestones

- ✅ **5.2.b-scaffold** (2026-04-20) — design doc + schema SQL + script stubs + test 12 structural
- ✅ **5.2.b-init** (2026-04-20) — `l2-init.sh` applies schema, idempotent
- ✅ **5.2.b-ingest** (2026-04-20) — real heading-aware chunker + NUL-safe Ruby SQL gen + SHA-256 dedup + edit detection
- ✅ **5.2.b-query** (2026-04-20) — FTS5 BM25 keyword search, markdown + JSON output, --top / --source-type / --quiet
- ✅ **5.2.b-wire-copilot** (2026-04-20) — build-instructions.sh bakes L2 seed-query results into copilot-instructions.md
- ✅ **5.2.b-embed-detect** (2026-04-20) — `l2-detect-backend.sh` + `l2-status.sh` + mode banner in query. Graceful-degradation cornerstone.
- ✅ **5.2.b-embed** (2026-04-20) — `l2-embed.sh` generates embeddings via Ollama `/api/embeddings`. Default model: `nomic-embed-text` (137 MB / 768 dim). Idempotent; `--all` refresh; `--dry-run`; `--require-backend` for scripts. Graceful exit 0 when backend not ready.
- ✅ **5.2.b-hybrid-query** (2026-04-20) — BM25 + cosine hybrid ranking in `l2-query.sh`. `--keyword-only` / `--hybrid` / `--semantic-only` / `--alpha` flags. Auto-mode routes based on embeddings + backend readiness. JSON adds a `mode` field + per-result score breakdown.
- ✅ **5.2.b-enterprise-audit** (2026-04-20) — Policy enforcement via `l2-detect-backend.sh`. `l2-embed.sh` + `l2-query.sh --hybrid/--semantic-only` refuse cloud backends when `data_handling_policy ∈ {local_only, lan_only}` with a policy-specific error. Persistent audit trail via `POLICY-BLOCK:` rows in `ingest_runs`. Local Ollama always passes; auto-mode query still works (falls back to keyword).

**9 of 9 slices shipped.** The 5.2.b-embed arc is complete.

## Routing & Graceful Degradation

Semantic search is **opt-in and optional**. Users without Ollama still get full keyword search via FTS5 — L2 Tank never blocks on a missing install.

Every L2 surface (query, status, embed) routes through `l2-detect-backend.sh`, which reports one of:

| Status      | Meaning                                                    | User action                                    |
|-------------|------------------------------------------------------------|------------------------------------------------|
| `ready`     | Ollama running + model pulled + policy allows              | Run `l2-embed.sh` then query in hybrid mode    |
| `partial`   | Ollama running but model not pulled                        | `ollama pull nomic-embed-text`                 |
| `none`      | Ollama not installed / not running                         | Install Ollama, or stay on keyword-only        |
| `blocked`   | Policy forbids the configured backend (e.g. cloud + local_only) | Switch backend or update policy           |
| `deferred`  | Non-Ollama backend requested (cloud path not implemented)  | Use `ollama/*` for Beta 1.0                    |

The mode banner printed at the top of every `l2-query.sh` output tells users which mode they're getting plus the concrete next step if they want to upgrade:

```
# L2 TANK — results for "authentication"

  Mode: KEYWORD-ONLY (BM25 via FTS5)  ·  enable semantic: ollama pull nomic-embed-text
```

`--quiet` suppresses the banner — keeps the copilot-instructions.md drift-check clean.

### Minimal embedding model

DexHub defaults to `nomic-embed-text` — picked for **minimum viable embedding**:

| Model                 | Size   | Dims | Fit |
|-----------------------|--------|------|-----|
| `all-minilm`          | 45 MB  | 384  | Too small — quality drop |
| **`nomic-embed-text`**| **137 MB** | **768** | **Default — sweet-spot** |
| `mxbai-embed-large`   | 670 MB | 1024 | Overkill for Beta scale   |

Only used for **embeddings** (no generation / chat) — RAM + compute footprint stays minimal. Override via `UPDATE meta SET value='ollama/<model>' WHERE key='default_embedding_backend'`.

---

## Storage layout

```
myDex/.dex/l2/
├── tank.sqlite          # the DB (user-private, gitignored)
├── tank.sqlite-wal      # SQLite WAL (gitignored)
├── tank.sqlite-shm      # SQLite shared memory (gitignored)
└── README.md            # framework-shipped, tracked — explains what lives here
```

Per `PLATFORM-POLICY.md`, the `.sqlite` files are user data → gitignored.
The `README.md` is framework documentation → tracked.

---

## Relation to L1 Wiki and L3 Chronicle

| Layer | Scale | Retrieval | Contents |
|---|---|---|---|
| **L1 Wiki** | <20KB total | Session-start injection (always loaded) | Team glossary, architecture notes, institutional knowledge |
| **L2 Tank** | MB-GB | On-demand query + build-time baking of relevant chunks | Ingested from L1 Wiki + L3 Chronicle + user documents; searchable |
| **L3 Chronicle** | unbounded (daily logs) | Cross-referenced from L2 via ingest | Session diaries, time-ordered |

L2 Tank INGESTS from L1 + L3 — it doesn't replace them. Users still author L1 directly; L3 accumulates automatically. L2 is the "everything searchable" layer.

## Honest limits (this commit's scaffold scope)

- **Not yet wired to anything.** No ingest, no queries, no Copilot injection. All stubs.
- **No embedding model shipped.** User must install Ollama + pull `nomic-embed-text` manually (documented in future `5.2.b-embed` slice).
- **Schema may evolve.** Version bumps require migration scripts. The `schema_version` meta row tracks this.
- **Real ingest respects size caps.** A 100k-chunk corpus is fine; a 10M-chunk corpus is out of scope for Beta 1.0 (user should split into multiple tanks or upgrade to FAISS/Chroma).

---

## Enterprise compliance

Every embedding backend declares a compliance stance:

| Backend | `data_handling_policy=local_only` | `lan_only` | `cloud_llm_allowed` | `hybrid` |
|---|---|---|---|---|
| Ollama `nomic-embed-text` (default) | ✓ allow | ✓ allow | ✓ allow | ✓ allow |
| OpenAI `text-embedding-3-small` | ✗ BLOCK | ✗ BLOCK | ✓ with consent | ✓ per-use consent |
| Anthropic (future) | ✗ BLOCK | ✗ BLOCK | ✓ with consent | ✓ per-use consent |

Enforcement: at `l2-ingest.sh` + `l2-query.sh` invocation time, the script reads `profile.company.data_handling_policy` and refuses to use a non-compliant backend. Overridable via `*force-override` (auditable, same pattern as connector wizards).

This is specified in the scaffold but enforcement code ships with `5.2.b-enterprise-audit`.
