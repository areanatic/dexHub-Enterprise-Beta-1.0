#!/usr/bin/env bash
# DexHub L2 Tank — Ingest
# ==========================================================
# Ingests markdown source files into the SQLite knowledge tank.
# Status: Phase 5.2.b-ingest — REAL CHUNKER + INSERT.
# Embeddings NOT yet computed (5.2.b-embed is next slice).
#
# Behavior:
#   - Compute SHA-256 of source file
#   - If source_path already in DB with same source_hash: skip (no-op)
#   - If source_path in DB with different source_hash: delete old chunks,
#     re-ingest (handles edits)
#   - Run chunker (l2-chunker.awk, heading-aware splits)
#   - Generate SQL via ruby (handles NUL-delim safely) → insert in transaction
#   - Log ingest_runs audit row
#
# Usage:
#   bash l2-ingest.sh --source PATH [--source PATH...]
#   bash l2-ingest.sh --source-dir DIR --glob '*.md'
#   bash l2-ingest.sh --db CUSTOM.sqlite --source foo.md
#   bash l2-ingest.sh --dry-run --source foo.md
#
# Source types (auto-detected from path):
#   myDex/.dex/wiki/*      → source_type = 'wiki'
#   myDex/.dex/chronicle/* → source_type = 'chronicle'
#   otherwise              → source_type = 'ingest'
#
# Exit codes:
#   0   success
#   1   bad args
#   2   sqlite3 / awk / ruby not available
#   3   source file missing
#   4   DB not initialized

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"

DEFAULT_DB="$REPO_ROOT/myDex/.dex/l2/tank.sqlite"
DB="$DEFAULT_DB"
CHUNKER="$SCRIPT_DIR/l2-chunker.awk"
SOURCES=()
SOURCE_DIR=""
GLOB="*.md"
DRY_RUN=0
MAX_CHUNK_SIZE=2048

while [ $# -gt 0 ]; do
  case "$1" in
    --db)         DB="$2"; shift 2 ;;
    --source)     SOURCES+=("$2"); shift 2 ;;
    --source-dir) SOURCE_DIR="$2"; shift 2 ;;
    --glob)       GLOB="$2"; shift 2 ;;
    --dry-run)    DRY_RUN=1; shift ;;
    --max-chunk)  MAX_CHUNK_SIZE="$2"; shift 2 ;;
    --help|-h)
      sed -n '2,35p' "${BASH_SOURCE[0]}"
      exit 0
      ;;
    *)
      echo "ERROR: unknown arg: $1" >&2
      exit 1
      ;;
  esac
done

# ─── Dep checks ───────────────────────────────────────────────────
command -v sqlite3 >/dev/null 2>&1 || { echo "ERROR: sqlite3 not installed" >&2; exit 2; }
command -v awk >/dev/null 2>&1     || { echo "ERROR: awk not installed" >&2; exit 2; }
command -v ruby >/dev/null 2>&1    || { echo "ERROR: ruby not installed (required for NUL-safe SQL generation)" >&2; exit 2; }
[ -f "$CHUNKER" ] || { echo "ERROR: chunker missing: $CHUNKER" >&2; exit 2; }

# Expand --source-dir + --glob
if [ -n "$SOURCE_DIR" ]; then
  if [ ! -d "$SOURCE_DIR" ]; then
    echo "ERROR: --source-dir not a directory: $SOURCE_DIR" >&2
    exit 3
  fi
  while IFS= read -r -d '' f; do
    SOURCES+=("$f")
  done < <(find "$SOURCE_DIR" -maxdepth 1 -type f -name "$GLOB" -print0 2>/dev/null)
fi

if [ "${#SOURCES[@]}" -eq 0 ]; then
  echo "ERROR: no sources given (use --source FILE or --source-dir DIR)" >&2
  exit 1
fi

# ─── DB check ──────────────────────────────────────────────────────
if [ "$DRY_RUN" = "0" ]; then
  if [ ! -f "$DB" ]; then
    echo "ERROR: DB not initialized: $DB" >&2
    echo "       Run: bash $SCRIPT_DIR/l2-init.sh --db $DB" >&2
    exit 4
  fi
  if ! sqlite3 "$DB" "SELECT value FROM meta WHERE key='schema_version'" >/dev/null 2>&1; then
    echo "ERROR: DB schema incomplete — run l2-init.sh --db $DB" >&2
    exit 4
  fi
fi

# ─── Helpers ───────────────────────────────────────────────────────
sql_escape() {
  printf "%s" "$1" | sed "s/'/''/g"
}

infer_source_type() {
  local path="$1"
  case "$path" in
    *myDex/.dex/wiki/*)      echo "wiki" ;;
    *myDex/.dex/chronicle/*) echo "chronicle" ;;
    *)                       echo "ingest" ;;
  esac
}

relpath() {
  local abs="$1"
  if [ "${abs#$REPO_ROOT/}" != "$abs" ]; then
    echo "${abs#$REPO_ROOT/}"
  else
    echo "$abs"
  fi
}

# ─── Ingest one file ──────────────────────────────────────────────
ingest_file() {
  local file="$1"
  local abs_file rel_path src_type src_hash existing_hash

  if [ ! -f "$file" ]; then
    echo "  SKIP: $file (missing)"
    return
  fi

  # Type guard: l2-ingest is markdown/text-native. Binary files (PDF,
  # images, Office) must go through the parser router first. Without
  # this check, binaries ran through the awk chunker produced zero
  # chunks silently — an "OK: 0 chunks" line that confused users into
  # thinking ingestion succeeded. (UX finding 2026-04-21 review.)
  DETECT_MIME="$REPO_ROOT/.dexCore/core/parser/detect-mime.sh"
  if [ -x "$DETECT_MIME" ]; then
    ft=$("$DETECT_MIME" "$file" 2>/dev/null | awk '{print $1}')
    case "$ft" in
      text|code|data|email)
        : # text-like — proceed
        ;;
      pdf|office|image|archive|unknown)
        echo "  SKIP: $file (type=$ft — l2-ingest is text-only)"
        echo "        Route it through the parser first:"
        echo "          bash $REPO_ROOT/.dexCore/core/parser/parse-route.sh $file"
        echo "        Then pipe the extracted text back into l2-ingest.sh."
        echo "        (Phase 5.3.f parser.inbox_auto_parse will automate this loop.)"
        return
        ;;
    esac
  fi

  abs_file="$(cd "$(dirname "$file")" && pwd)/$(basename "$file")"
  rel_path="$(relpath "$abs_file")"
  src_type="$(infer_source_type "$rel_path")"
  src_hash="$(shasum -a 256 "$file" | cut -d' ' -f1)"

  if [ "$DRY_RUN" = "1" ]; then
    echo "  DRY-RUN: would ingest $rel_path (type=$src_type hash=${src_hash:0:12})"
    # Preview chunks
    awk -v MAX_SIZE="$MAX_CHUNK_SIZE" -f "$CHUNKER" < "$file" | \
      ruby -e '
        STDIN.binmode
        data = STDIN.read
        data.split("\0").each_with_index do |rec, i|
          next if rec.empty?
          parts = rec.split("\t", 3)
          title, size, _content = parts
          printf "    chunk %d: [%s] (%s bytes)\n", i, title || "?", size || "?"
        end
      '
    return
  fi

  # Dedup check
  existing_hash=$(sqlite3 "$DB" "SELECT source_hash FROM chunks WHERE source_path = '$(sql_escape "$rel_path")' LIMIT 1" 2>/dev/null || echo "")
  if [ -n "$existing_hash" ]; then
    if [ "$existing_hash" = "$src_hash" ]; then
      echo "  SKIP: $rel_path (unchanged, hash=${src_hash:0:12})"
      return
    else
      sqlite3 "$DB" "DELETE FROM chunks WHERE source_path = '$(sql_escape "$rel_path")'" 2>/dev/null
      echo "  UPDATE: $rel_path (source changed, re-ingesting)"
    fi
  fi

  # Chunk + generate SQL via ruby (NUL-safe)
  local sql_file
  sql_file=$(mktemp -t dexhub-l2-sql-XXXXXX).sql

  awk -v MAX_SIZE="$MAX_CHUNK_SIZE" -f "$CHUNKER" < "$file" | \
    ruby -e '
      STDIN.binmode
      data = STDIN.read
      rel_path, src_type, src_hash = ARGV
      puts "BEGIN TRANSACTION;"
      chunk_index = 0
      data.split("\0").each do |rec|
        next if rec.empty?
        parts = rec.split("\t", 3)
        next if parts.length < 3
        title, byte_size, content = parts
        # SQLite single-quote escape
        esc_title   = title.gsub("'\''", "'\'''\''")
        esc_content = content.gsub("'\''", "'\'''\''")
        esc_rel     = rel_path.gsub("'\''", "'\'''\''")
        esc_type    = src_type.gsub("'\''", "'\'''\''")
        esc_hash    = src_hash.gsub("'\''", "'\'''\''")
        puts "INSERT INTO chunks (source_path, source_type, chunk_index, title, content, byte_size, created_at, updated_at, source_hash) VALUES ('\''#{esc_rel}'\'', '\''#{esc_type}'\'', #{chunk_index}, '\''#{esc_title}'\'', '\''#{esc_content}'\'', #{byte_size.to_i}, datetime('\''now'\''), datetime('\''now'\''), '\''#{esc_hash}'\'');"
        chunk_index += 1
      end
      puts "COMMIT;"
    ' "$rel_path" "$src_type" "$src_hash" > "$sql_file"

  if sqlite3 "$DB" < "$sql_file" 2>/dev/null; then
    local n
    n=$(sqlite3 "$DB" "SELECT COUNT(*) FROM chunks WHERE source_path='$(sql_escape "$rel_path")'" 2>/dev/null)
    echo "  OK:     $rel_path ($n chunks, type=$src_type)"
  else
    echo "  FAIL:   $rel_path (sqlite3 error)"
    echo "  SQL file: $sql_file (kept for debug)"
    return
  fi

  rm -f "$sql_file"
}

# ─── Main ──────────────────────────────────────────────────────────
TOTAL_SOURCES=${#SOURCES[@]}
echo "L2 Ingest:  $TOTAL_SOURCES source file(s)  →  $DB"
if [ "$DRY_RUN" = "1" ]; then
  echo "            (DRY RUN — no DB writes)"
fi
echo ""

RUN_ID=""
if [ "$DRY_RUN" = "0" ]; then
  RUN_ID=$(sqlite3 "$DB" "INSERT INTO ingest_runs (started_at, source_count, chunks_added, chunks_updated, chunks_deleted, backend, notes) VALUES (datetime('now'), $TOTAL_SOURCES, 0, 0, 0, NULL, 'l2-ingest.sh v1 (no embeddings yet)'); SELECT last_insert_rowid();" 2>/dev/null)
fi

for src in "${SOURCES[@]}"; do
  ingest_file "$src"
done

if [ -n "$RUN_ID" ]; then
  FINAL_CHUNK_COUNT=$(sqlite3 "$DB" "SELECT COUNT(*) FROM chunks" 2>/dev/null || echo 0)
  sqlite3 "$DB" "UPDATE ingest_runs SET finished_at=datetime('now'), chunks_added=$FINAL_CHUNK_COUNT WHERE id=$RUN_ID" 2>/dev/null || true
fi

if [ "$DRY_RUN" = "0" ]; then
  echo ""
  TOTAL_CHUNKS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM chunks" 2>/dev/null || echo "?")
  echo "Tank state: $TOTAL_CHUNKS chunks total"

  # UX: one-time tip about semantic search when the backend looks reachable
  # but embeddings aren't populated. Silent (no chrome) when backend not
  # ready — users without Ollama should not be nagged.
  DETECT="$SCRIPT_DIR/l2-detect-backend.sh"
  if [ -x "$DETECT" ]; then
    SEMANTIC_READY=$("$DETECT" --db "$DB" --format json 2>/dev/null | ruby -rjson -e 'd=JSON.parse(STDIN.read) rescue {}; puts (d["semantic_available"] ? "true" : "false")' 2>/dev/null || echo "false")
    EMB_COUNT=$(sqlite3 "$DB" "SELECT COUNT(*) FROM embeddings" 2>/dev/null || echo 0)
    if [ "$SEMANTIC_READY" = "true" ] && [ "$EMB_COUNT" = "0" ]; then
      echo ""
      echo "Tip:        Ollama + embedding model detected. Run"
      echo "            bash $SCRIPT_DIR/l2-embed.sh"
      echo "            to populate embeddings for hybrid semantic search."
    fi
  fi
fi
