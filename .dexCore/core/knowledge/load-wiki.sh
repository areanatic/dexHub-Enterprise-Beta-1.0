#!/usr/bin/env bash
# DexHub L1 Wiki Loader
# ==========================================================
# Enumerates user's L1 wiki entries from myDex/.dex/wiki/,
# filters framework-shipped files, respects size caps, and
# outputs a formatted block suitable for appending to an
# agent's session context.
#
# Designed for Phase 5.2.d. Feature: knowledge.l1_wiki_injection.
# Author notes: see .dexCore/_dev/docs/L1-WIKI-INJECTION.md.
#
# Usage:
#   bash .dexCore/core/knowledge/load-wiki.sh
#   bash .dexCore/core/knowledge/load-wiki.sh --wiki-dir /custom/path
#   bash .dexCore/core/knowledge/load-wiki.sh --max-total 20480 --max-file 2048
#   bash .dexCore/core/knowledge/load-wiki.sh --summary-only
#
# Exit codes:
#   0   success (possibly empty output if no entries)
#   1   bad arguments
#   2   wiki dir unreadable
#
# Safety:
#   - Read-only: script never modifies files.
#   - Skips README.md (framework-shipped) and *.template.md
#     (template files; should be copied to user-named entry).
#   - Respects status: archived frontmatter field — skips.
#   - Truncates oversized files at byte boundary with a clear
#     [truncated] marker to prevent context-window blowouts.

set -euo pipefail

# ─── Defaults ──────────────────────────────────────────────
WIKI_DIR=""
MAX_TOTAL=20480   # 20 KB
MAX_FILE=2048     # 2 KB per file (per L1-WIKI-PATTERN.md)
SUMMARY_ONLY=0

# Resolve default wiki dir from project root.
# Script lives at: <repo>/.dexCore/core/knowledge/load-wiki.sh
# Project root is three levels up from SCRIPT_DIR.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_WIKI="$(cd "$SCRIPT_DIR/../../.." && pwd)/myDex/.dex/wiki"

# ─── Arg parsing ───────────────────────────────────────────
while [ $# -gt 0 ]; do
  case "$1" in
    --wiki-dir)
      WIKI_DIR="$2"
      shift 2
      ;;
    --max-total)
      MAX_TOTAL="$2"
      shift 2
      ;;
    --max-file)
      MAX_FILE="$2"
      shift 2
      ;;
    --summary-only)
      SUMMARY_ONLY=1
      shift
      ;;
    --help|-h)
      sed -n '2,25p' "${BASH_SOURCE[0]}"
      exit 0
      ;;
    *)
      echo "ERROR: unknown arg: $1" >&2
      echo "Run with --help for usage." >&2
      exit 1
      ;;
  esac
done

WIKI_DIR="${WIKI_DIR:-$DEFAULT_WIKI}"

# ─── Validation ────────────────────────────────────────────
if [ ! -d "$WIKI_DIR" ]; then
  # Not an error — may simply not be initialized yet
  if [ "$SUMMARY_ONLY" = "1" ]; then
    echo "0 entries loaded, 0 skipped, 0 bytes total (wiki dir not present: $WIKI_DIR)"
  fi
  exit 0
fi

if [ ! -r "$WIKI_DIR" ]; then
  echo "ERROR: wiki dir not readable: $WIKI_DIR" >&2
  exit 2
fi

# ─── Enumerate ─────────────────────────────────────────────
# Sorted alphabetically (users can prefix with 01-, 02- for order)
ENTRIES_LOADED=0
ENTRIES_SKIPPED=0
BYTES_TOTAL=0
LOADED_CONTENT=""

# Pre-scan to see if we have any user-authored entries
HAS_USER_ENTRY=0
while IFS= read -r -d '' file; do
  base="$(basename "$file")"
  [ "$base" = "README.md" ] && continue
  case "$base" in *.template.md) continue ;; esac
  HAS_USER_ENTRY=1
  break
done < <(find "$WIKI_DIR" -maxdepth 1 -type f -name "*.md" -print0 2>/dev/null | sort -z)

# Silent exit on fresh install (only README.md, no user entries)
if [ "$HAS_USER_ENTRY" = "0" ]; then
  if [ "$SUMMARY_ONLY" = "1" ]; then
    echo "0 entries loaded, 0 skipped, 0 bytes total"
  fi
  exit 0
fi

# Main enumeration
while IFS= read -r -d '' file; do
  base="$(basename "$file")"

  # Filter: framework-shipped or template
  if [ "$base" = "README.md" ]; then
    ENTRIES_SKIPPED=$((ENTRIES_SKIPPED + 1))
    continue
  fi
  case "$base" in
    *.template.md)
      ENTRIES_SKIPPED=$((ENTRIES_SKIPPED + 1))
      continue
      ;;
  esac

  # Filter: archived status in frontmatter (if present)
  if head -20 "$file" 2>/dev/null | grep -qE "^status:[[:space:]]*archived"; then
    ENTRIES_SKIPPED=$((ENTRIES_SKIPPED + 1))
    continue
  fi

  # Size check: skip if this file alone would blow the total cap
  filesize=$(wc -c < "$file" 2>/dev/null | tr -d '[:space:]')
  [ -z "$filesize" ] && filesize=0

  # Skip if adding this file's (possibly truncated) size breaks total cap
  effective=$filesize
  [ "$effective" -gt "$MAX_FILE" ] && effective="$MAX_FILE"
  if [ $((BYTES_TOTAL + effective)) -gt "$MAX_TOTAL" ]; then
    ENTRIES_SKIPPED=$((ENTRIES_SKIPPED + 1))
    continue
  fi

  # Load (with per-file truncation if needed)
  ENTRIES_LOADED=$((ENTRIES_LOADED + 1))
  BYTES_TOTAL=$((BYTES_TOTAL + effective))

  if [ "$SUMMARY_ONLY" = "0" ]; then
    LOADED_CONTENT+=$'\n\n## '"$base"$'\n\n'
    if [ "$filesize" -gt "$MAX_FILE" ]; then
      LOADED_CONTENT+="$(head -c "$MAX_FILE" "$file")"
      LOADED_CONTENT+=$'\n\n[truncated — file exceeds per-file cap of '"$MAX_FILE"' bytes, see '"$file"' for full]'
    else
      LOADED_CONTENT+="$(cat "$file")"
    fi
  fi
done < <(find "$WIKI_DIR" -maxdepth 1 -type f -name "*.md" -print0 2>/dev/null | sort -z)

# ─── Output ────────────────────────────────────────────────
if [ "$SUMMARY_ONLY" = "1" ]; then
  echo "$ENTRIES_LOADED entries loaded, $ENTRIES_SKIPPED skipped, $BYTES_TOTAL bytes total"
  exit 0
fi

if [ "$ENTRIES_LOADED" -eq 0 ]; then
  # No loadable entries (all were skipped) — silent exit.
  exit 0
fi

cat <<HEADER
# ═══════════════════════════════════════════════════════════
# L1 WIKI (user's institutional knowledge)
# Loaded $ENTRIES_LOADED entries, $BYTES_TOTAL bytes. Source: $WIKI_DIR
# ═══════════════════════════════════════════════════════════
HEADER

printf '%s' "$LOADED_CONTENT"

cat <<FOOTER


# ═══════════════════════════════════════════════════════════
# END L1 WIKI — next: standard session context
# ═══════════════════════════════════════════════════════════
FOOTER
