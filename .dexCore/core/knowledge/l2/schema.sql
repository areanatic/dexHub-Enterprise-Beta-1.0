-- DexHub L2 Tank — SQLite Schema v1
-- ============================================================
-- Native knowledge store. Hybrid keyword (FTS5) + semantic (embeddings)
-- search over chunked Markdown from L1 Wiki + L3 Chronicle + user docs.
--
-- Applied by: .dexCore/core/knowledge/l2/l2-init.sh
-- Design:     .dexCore/_dev/docs/L2-TANK.md
-- Feature:    knowledge.l2_tank_schema (features.yaml)
-- ============================================================

-- chunks: one row per chunk ingested from any source file
CREATE TABLE IF NOT EXISTS chunks (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  source_path TEXT NOT NULL,
  source_type TEXT NOT NULL,
  chunk_index INTEGER NOT NULL,
  title       TEXT,
  content     TEXT NOT NULL,
  byte_size   INTEGER NOT NULL,
  created_at  TEXT NOT NULL,
  updated_at  TEXT NOT NULL,
  source_hash TEXT NOT NULL,
  UNIQUE(source_path, chunk_index)
);

-- Index for source-file-based lookups (e.g. "re-ingest this file → delete old chunks first")
CREATE INDEX IF NOT EXISTS idx_chunks_source_path ON chunks(source_path);
CREATE INDEX IF NOT EXISTS idx_chunks_source_type ON chunks(source_type);

-- FTS5 virtual table for keyword search
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

-- embeddings: one row per chunk. NULL (absent) = not yet embedded.
-- vector_json stored as JSON array of floats for portability and inspectability.
-- Real implementation in 5.2.b-embed may switch to BLOB for throughput.
CREATE TABLE IF NOT EXISTS embeddings (
  chunk_id       INTEGER PRIMARY KEY REFERENCES chunks(id) ON DELETE CASCADE,
  backend        TEXT NOT NULL,
  dimensions     INTEGER NOT NULL,
  vector_json    TEXT NOT NULL,
  embedded_at    TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_embeddings_backend ON embeddings(backend);

-- meta: single-row configuration (schema version, default backend, etc.)
CREATE TABLE IF NOT EXISTS meta (
  key   TEXT PRIMARY KEY,
  value TEXT NOT NULL
);
INSERT OR IGNORE INTO meta(key, value) VALUES
  ('schema_version', '1'),
  ('default_embedding_backend', 'ollama/nomic-embed-text'),
  ('created_at', datetime('now'));

-- ingest_runs: audit log — what was ingested, when, how many chunks
CREATE TABLE IF NOT EXISTS ingest_runs (
  id              INTEGER PRIMARY KEY AUTOINCREMENT,
  started_at      TEXT NOT NULL,
  finished_at     TEXT,
  source_count    INTEGER,
  chunks_added    INTEGER,
  chunks_updated  INTEGER,
  chunks_deleted  INTEGER,
  backend         TEXT,
  notes           TEXT
);
