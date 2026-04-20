#!/usr/bin/env bash
# DexHub Parser — Inbox orchestrator (parser.inbox_auto_parse)
# ==========================================================
# Consumes files in myDex/inbox/ (or user-configured path), routes each
# through parse-route.sh, invokes the right backend adapter to extract
# text, pipes the extracted text into l2-ingest.sh (L2 Knowledge Tank),
# and archives the original to myDex/inbox/.processed/ with a timestamp.
#
# This is the slice that makes the Parser arc END-TO-END USABLE. Drop
# a file in the inbox → run this script → file is in the Tank.
#
# Feature: parser.inbox_auto_parse
# Phase:   5.3.f (first slice — one-shot mode, no watcher, no chat wrapper)
# Pattern: .dexCore/_dev/docs/BACKEND-ADAPTER-PATTERN.md
#
# Usage:
#   bash inbox-auto-parse.sh                       # process all pending files
#   bash inbox-auto-parse.sh --dry-run             # show plan, no processing
#   bash inbox-auto-parse.sh --inbox PATH          # override inbox location
#   bash inbox-auto-parse.sh --format json         # machine-readable output
#   bash inbox-auto-parse.sh --no-archive          # don't move originals
#   bash inbox-auto-parse.sh --one-file PATH       # process a single file
#
# Configuration precedence for inbox location:
#   1. --inbox PATH flag
#   2. $DEXHUB_INBOX environment variable
#   3. inbox_folder field in .dexCore/_cfg/config.yaml
#   4. Default: <repo-root>/myDex/inbox/
#
# Safety contract:
#   - Originals are ARCHIVED (moved to .processed/<timestamp>-<name>), never
#     silently deleted. --no-archive keeps them in place.
#   - Per-file errors don't abort the batch; other files still process.
#   - Exits 0 if batch completes (even with some files failed). Check
#     the per-file JSON records for individual outcomes.
#   - Exit codes: 0 success | 1 bad args | 2 missing deps | 3 inbox missing

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
PARSE_ROUTE="$SCRIPT_DIR/parse-route.sh"
KREUZBERG="$SCRIPT_DIR/backends/kreuzberg.sh"
OLLAMA_VLM="$SCRIPT_DIR/backends/ollama-vlm.sh"
PATTERN_A="$SCRIPT_DIR/backends/pattern-a-vector-text.sh"
L2_INGEST="$REPO_ROOT/.dexCore/core/knowledge/l2/l2-ingest.sh"
L2_INIT="$REPO_ROOT/.dexCore/core/knowledge/l2/l2-init.sh"
L2_TANK_DB="$REPO_ROOT/myDex/.dex/l2/tank.sqlite"
CONFIG_YAML="$REPO_ROOT/.dexCore/_cfg/config.yaml"

DRY_RUN=0
FORMAT=""
NO_ARCHIVE=0
ONE_FILE=""
INBOX_OVERRIDE=""

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run)    DRY_RUN=1; shift ;;
    --format)     FORMAT="$2"; shift 2 ;;
    --no-archive) NO_ARCHIVE=1; shift ;;
    --one-file)   ONE_FILE="$2"; shift 2 ;;
    --inbox)      INBOX_OVERRIDE="$2"; shift 2 ;;
    --help|-h)
      sed -n '2,37p' "${BASH_SOURCE[0]}"
      exit 0
      ;;
    -*)
      echo "ERROR: unknown flag: $1" >&2
      exit 1
      ;;
    *)
      echo "ERROR: unexpected positional arg: $1" >&2
      exit 1
      ;;
  esac
done

# ─── Resolve inbox path ─────────────────────────────────────────────
INBOX=""
INBOX_SOURCE="default"
if [ -n "$INBOX_OVERRIDE" ]; then
  INBOX="$INBOX_OVERRIDE"
  INBOX_SOURCE="--inbox flag"
elif [ -n "${DEXHUB_INBOX:-}" ]; then
  INBOX="$DEXHUB_INBOX"
  INBOX_SOURCE="DEXHUB_INBOX env"
elif [ -f "$CONFIG_YAML" ]; then
  # Use ruby for safe YAML-value extraction (strips quotes + inline
  # comments reliably). Shell sed/awk on this line has eaten trailing
  # quotes before — ruby sidesteps the whole class of parse bugs.
  cfg_inbox=$(ruby -e '
    val = nil
    File.foreach(ARGV[0]) do |line|
      next unless line =~ /^inbox_folder:\s*(.+?)(\s*#.*)?$/
      v = $1.strip
      # Strip wrapping quotes if present
      v = v[1..-2] if v.length >= 2 && ((v.start_with?("\"") && v.end_with?("\"")) || (v.start_with?("'"'"'") && v.end_with?("'"'"'")))
      val = v
      break
    end
    puts val if val
  ' "$CONFIG_YAML" 2>/dev/null)
  if [ -n "$cfg_inbox" ]; then
    case "$cfg_inbox" in
      ./*) INBOX="$REPO_ROOT/${cfg_inbox#./}" ;;
      /*)  INBOX="$cfg_inbox" ;;
      *)   INBOX="$REPO_ROOT/$cfg_inbox" ;;
    esac
    INBOX_SOURCE="config.yaml"
  fi
fi
[ -z "$INBOX" ] && { INBOX="$REPO_ROOT/myDex/inbox"; INBOX_SOURCE="default"; }

if [ -z "$FORMAT" ]; then
  if [ -t 1 ]; then FORMAT="text"; else FORMAT="json"; fi
fi

# ─── Dependency checks ──────────────────────────────────────────────
for dep in ruby sqlite3 find; do
  command -v "$dep" >/dev/null 2>&1 || { echo "ERROR: $dep not installed" >&2; exit 2; }
done
[ -x "$PARSE_ROUTE" ] || { echo "ERROR: parse-route.sh missing at $PARSE_ROUTE" >&2; exit 2; }

# ─── Inbox existence ────────────────────────────────────────────────
if [ ! -d "$INBOX" ]; then
  echo "ERROR: inbox directory missing at $INBOX (source: $INBOX_SOURCE)" >&2
  echo "       Create it: mkdir -p \"$INBOX\"" >&2
  echo "       Or drop files into a different path via --inbox PATH." >&2
  exit 3
fi

ARCHIVE_DIR="$INBOX/.processed"
[ "$NO_ARCHIVE" = "0" ] && [ "$DRY_RUN" = "0" ] && mkdir -p "$ARCHIVE_DIR"

# Auto-init the L2 Tank if it's missing. Without this, first-run users
# (and clean CI runners) hit an l2-ingest "DB not initialized" error and
# see ingest_failed across the whole batch. l2-init.sh is idempotent —
# safe to call even when the DB already exists. (2026-04-21 CI finding:
# local env had a tank from earlier tests; CI didn't.)
if [ "$DRY_RUN" = "0" ] && [ ! -f "$L2_TANK_DB" ] && [ -x "$L2_INIT" ]; then
  "$L2_INIT" >/dev/null 2>&1 || true
fi

# ─── Collect pending files ──────────────────────────────────────────
PENDING=()
if [ -n "$ONE_FILE" ]; then
  [ -f "$ONE_FILE" ] || { echo "ERROR: --one-file: $ONE_FILE not found" >&2; exit 3; }
  PENDING=("$ONE_FILE")
else
  while IFS= read -r -d '' f; do
    bn="$(basename "$f")"
    case "$bn" in
      .*|README.md|README.txt) continue ;;
    esac
    PENDING+=("$f")
  done < <(find "$INBOX" -maxdepth 1 -type f -print0 2>/dev/null | sort -z)
fi

# ─── Dispatch per file ──────────────────────────────────────────────
dispatch_file() {
  local file="$1"
  local route_json type backend route_status
  route_json=$("$PARSE_ROUTE" --format json "$file" 2>/dev/null || echo "{}")

  type=$(printf '%s' "$route_json" | ruby -rjson -e 'd=JSON.parse(STDIN.read) rescue {}; puts d["type"] || "unknown"' 2>/dev/null)
  backend=$(printf '%s' "$route_json" | ruby -rjson -e 'd=JSON.parse(STDIN.read) rescue {}; puts d["backend"] || "none"' 2>/dev/null)
  route_status=$(printf '%s' "$route_json" | ruby -rjson -e 'd=JSON.parse(STDIN.read) rescue {}; puts d["status"] || "unknown"' 2>/dev/null)

  if [ "$DRY_RUN" = "1" ]; then
    ruby -rjson -e '
      puts JSON.generate({
        "file" => ARGV[0], "status" => "dry_run",
        "route_type" => ARGV[1], "backend" => ARGV[2],
        "route_status" => ARGV[3],
        "archived_to" => nil, "error" => nil, "extracted_bytes" => 0
      })
    ' "$file" "$type" "$backend" "$route_status"
    return
  fi

  case "$route_status" in
    unsupported|backend_missing|deferred|blocked)
      ruby -rjson -e '
        puts JSON.generate({
          "file" => ARGV[0], "status" => "routed_but_backend_unavailable",
          "route_type" => ARGV[1], "backend" => ARGV[2],
          "route_status" => ARGV[3],
          "archived_to" => nil,
          "extracted_bytes" => 0,
          "error" => "Router status=" + ARGV[3] + " — cannot proceed"
        })
      ' "$file" "$type" "$backend" "$route_status"
      return
      ;;
  esac

  local extract_tmp extract_exit bytes=0
  extract_tmp=$(mktemp -t dexhub-inbox-ext-XXXXXX).md
  trap 'rm -f "$extract_tmp"' RETURN

  case "$backend" in
    native)
      # Native backend handles two sub-cases. The route decides which:
      #   text|code|data|email → direct cp (file is already readable text)
      #   pdf                  → shell to pdftotext (route sets backend=native
      #                           + type=pdf only when kreuzberg is absent AND
      #                           pdftotext is on PATH — see parse-route.sh)
      # Without the type-aware branch, PDFs silently got `cp`'d into an .md
      # temp file, l2-ingest's extension-based type-guard accepted it as text,
      # and binary bytes were indexed as garbage chunks (status=ok, false success).
      # Found 2026-04-21 review; this is the fix.
      case "$type" in
        text|code|data|email)
          cp "$file" "$extract_tmp"
          extract_exit=0
          ;;
        pdf)
          if command -v pdftotext >/dev/null 2>&1; then
            pdftotext -layout "$file" "$extract_tmp" 2>/dev/null
            extract_exit=$?
          else
            extract_exit=127
          fi
          ;;
        *)
          # Router gave us native for a type the native path can't handle.
          extract_exit=98
          ;;
      esac
      ;;
    kreuzberg)
      if [ -x "$KREUZBERG" ]; then
        "$KREUZBERG" --extract "$file" --format text > "$extract_tmp" 2>/dev/null
        extract_exit=$?
      else
        extract_exit=127
      fi
      ;;
    pattern_a_vector_text)
      if [ -x "$PATTERN_A" ]; then
        "$PATTERN_A" --extract "$file" --format text > "$extract_tmp" 2>/dev/null
        extract_exit=$?
      else
        extract_exit=127
      fi
      ;;
    ollama_vlm)
      if [ -x "$OLLAMA_VLM" ]; then
        "$OLLAMA_VLM" --extract "$file" --format text > "$extract_tmp" 2>/dev/null
        extract_exit=$?
      else
        extract_exit=127
      fi
      ;;
    *)
      extract_exit=99
      ;;
  esac

  [ -f "$extract_tmp" ] && bytes=$(wc -c < "$extract_tmp" | tr -d ' ')

  if [ "$extract_exit" != "0" ] || [ "$bytes" = "0" ]; then
    rm -f "$extract_tmp"
    ruby -rjson -e '
      puts JSON.generate({
        "file" => ARGV[0], "status" => "extract_failed",
        "backend" => ARGV[1], "route_status" => ARGV[2],
        "archived_to" => nil,
        "extracted_bytes" => 0,
        "error" => "Backend exit=" + ARGV[3] + " or empty output"
      })
    ' "$file" "$backend" "$route_status" "$extract_exit"
    return
  fi

  if [ ! -x "$L2_INGEST" ]; then
    rm -f "$extract_tmp"
    ruby -rjson -e '
      puts JSON.generate({
        "file" => ARGV[0], "status" => "ingest_failed",
        "backend" => ARGV[1], "extracted_bytes" => ARGV[2].to_i,
        "archived_to" => nil,
        "error" => "l2-ingest.sh missing or not executable"
      })
    ' "$file" "$backend" "$bytes"
    return
  fi

  local ingest_out ingest_exit
  ingest_out=$("$L2_INGEST" --source "$extract_tmp" 2>&1)
  ingest_exit=$?
  rm -f "$extract_tmp"

  if [ "$ingest_exit" != "0" ]; then
    ruby -rjson -e '
      puts JSON.generate({
        "file" => ARGV[0], "status" => "ingest_failed",
        "backend" => ARGV[1], "extracted_bytes" => ARGV[2].to_i,
        "archived_to" => nil,
        "error" => "l2-ingest exit=" + ARGV[3] + ": " + ARGV[4][0..200]
      })
    ' "$file" "$backend" "$bytes" "$ingest_exit" "$ingest_out"
    return
  fi

  local archive_path=""
  if [ "$NO_ARCHIVE" = "0" ]; then
    local ts bn
    ts=$(date -u +"%Y%m%dT%H%M%SZ")
    bn=$(basename "$file")
    archive_path="$ARCHIVE_DIR/${ts}-${bn}"
    mv "$file" "$archive_path" 2>/dev/null || archive_path=""
  fi

  ruby -rjson -e '
    puts JSON.generate({
      "file" => ARGV[0], "status" => "ok",
      "backend" => ARGV[1], "extracted_bytes" => ARGV[2].to_i,
      "archived_to" => (ARGV[3].empty? ? nil : ARGV[3]),
      "error" => nil
    })
  ' "$file" "$backend" "$bytes" "$archive_path"
}

# ─── Main loop ──────────────────────────────────────────────────────
results_json="[]"
for f in "${PENDING[@]+"${PENDING[@]}"}"; do
  rec=$(dispatch_file "$f")
  results_json=$(printf '%s' "$results_json" | ruby -rjson -e '
    arr = JSON.parse(STDIN.read) rescue []
    arr << (JSON.parse(ARGV[0]) rescue nil)
    puts JSON.generate(arr.compact)
  ' "$rec")
done

# ─── Output ─────────────────────────────────────────────────────────
if [ "$FORMAT" = "json" ]; then
  printf '%s' "$results_json" | ruby -rjson -e '
    arr = JSON.parse(STDIN.read) rescue []
    puts JSON.pretty_generate({
      "inbox" => ARGV[0],
      "inbox_source" => ARGV[1],
      "dry_run" => ARGV[2] == "1",
      "count" => arr.length,
      "results" => arr
    })
  ' "$INBOX" "$INBOX_SOURCE" "$DRY_RUN"
  exit 0
fi

echo "DexHub Inbox — Auto-Parse"
echo "========================="
echo "  Inbox:        $INBOX  (source: $INBOX_SOURCE)"
[ "$DRY_RUN" = "1" ] && echo "  Mode:         DRY RUN (no processing)"
[ "$NO_ARCHIVE" = "1" ] && echo "  Archive:      off (originals stay in inbox)"
echo ""

total=$(printf '%s' "$results_json" | ruby -rjson -e 'puts JSON.parse(STDIN.read).length' 2>/dev/null)
if [ "${total:-0}" = "0" ]; then
  echo "  No files pending in inbox."
  echo ""
  echo "  Drop files here: $INBOX"
  echo "  Then run this script again. Or invoke DexMaster *inbox."
  exit 0
fi

printf '%s' "$results_json" | ruby -rjson -e '
  arr = JSON.parse(STDIN.read)
  puts "  Files processed: #{arr.length}"
  puts ""
  arr.each do |r|
    icon = case r["status"]
           when "ok"                                then "✅"
           when "dry_run"                           then "🔍"
           when "routed_but_backend_unavailable"    then "⏸️ "
           when "extract_failed", "ingest_failed"   then "❌"
           else                                          "❓"
           end
    name = File.basename(r["file"])
    puts "  #{icon}  #{name}  (#{r["backend"]}, #{r["status"]})"
    puts "     → archived to #{r["archived_to"]}" if r["archived_to"]
    puts "     → error: #{r["error"]}" if r["error"]
  end
'
