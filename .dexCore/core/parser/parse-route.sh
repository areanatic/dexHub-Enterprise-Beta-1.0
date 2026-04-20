#!/usr/bin/env bash
# DexHub Parser — Routing decision layer (parser.router)
# ==========================================================
# Given a file path, decides which parser backend should handle it.
# Does NOT invoke the backend — that's 5.3.f (inbox_auto_parse) and the
# individual backend scripts (kreuzberg, ollama_vlm, pattern_a).
#
# Routing inputs:
#   1. File type (via detect-mime.sh — extension-based for Beta 1.0)
#   2. File size (oversize → defer to pattern_b raster pipeline, 1.1+)
#   3. capabilities.yaml (myDex/.dex/config/) — which backends installed
#   4. profile.yaml company.data_handling_policy (policy gate, mirrors
#      the L2 Tank backend-routing pattern)
#
# Output (JSON, stable contract):
#   {
#     "file": "/path/to/x.pdf",
#     "type": "pdf",
#     "size_bytes": 1234567,
#     "backend": "kreuzberg" | "ollama_vlm" | "pattern_a" | "native" | "defer" | "none",
#     "reason": "short human explanation",
#     "status": "ready" | "backend_missing" | "policy_blocked" | "deferred" | "unsupported",
#     "policy": "local_only" | "lan_only" | "cloud_llm_allowed" | "hybrid" | "unset",
#     "hint": "concrete next step for the user (install / enable / configure)"
#   }
#
# Beta 1.0 routing tree (minimum-viable):
#   text/code/data/email  → native (just read the file, no backend needed)
#   pdf (small, <100MB)   → kreuzberg if installed, else native-fallback (pdftotext)
#   pdf (large, ≥100MB)   → defer to pattern_b_raster_6phase (1.1 roadmap)
#   office (docx, etc.)   → kreuzberg if installed, else unsupported
#   image                 → ollama_vlm if installed + policy-ok, else unsupported
#   archive               → unsupported (Beta 1.0 scope)
#   unknown               → unsupported (honest — don't guess)
#
# Always exits 0. "Nothing to route" is an answer, not an error.
#
# Usage:
#   bash parse-route.sh <filepath>                      # JSON to stdout
#   bash parse-route.sh --format text <filepath>        # one-liner summary
#   bash parse-route.sh --capabilities /custom.yaml ... # override capabilities.yaml
#   bash parse-route.sh --profile /custom.yaml ...      # override profile.yaml
#
# Feature: parser.router
# Phase:   5.3.a

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

DEFAULT_CAPS="$REPO_ROOT/myDex/.dex/config/capabilities.yaml"
DEFAULT_PROFILE="$REPO_ROOT/myDex/.dex/config/profile.yaml"

CAPS="$DEFAULT_CAPS"
PROFILE="$DEFAULT_PROFILE"
FORMAT="json"
FILE=""
# Files at or above this size get deferred to the raster 6-phase pipeline
# (not implemented — 1.1 roadmap). Aligns with the "oversize" budget
# already learned from the 2026-04-08 RZP screenshot incident.
OVERSIZE_BYTES=$((100 * 1024 * 1024))   # 100 MB

while [ $# -gt 0 ]; do
  case "$1" in
    --format)       FORMAT="$2"; shift 2 ;;
    --capabilities) CAPS="$2"; shift 2 ;;
    --profile)      PROFILE="$2"; shift 2 ;;
    --oversize)     OVERSIZE_BYTES="$2"; shift 2 ;;
    --help|-h)
      sed -n '2,52p' "${BASH_SOURCE[0]}"
      exit 0
      ;;
    -*)
      echo "ERROR: unknown flag: $1" >&2
      exit 1
      ;;
    *)
      FILE="$1"
      shift
      ;;
  esac
done

if [ -z "$FILE" ]; then
  echo "ERROR: file path required. Usage: parse-route.sh <file>" >&2
  exit 1
fi

# ─── Detect file type + size ────────────────────────────────────────
DETECT="$SCRIPT_DIR/detect-mime.sh"
if [ ! -x "$DETECT" ]; then
  echo "ERROR: detect-mime.sh missing or not executable at $DETECT" >&2
  exit 1
fi
DETECT_JSON=$("$DETECT" --format json "$FILE" 2>/dev/null || echo "{}")
TYPE=$(printf "%s" "$DETECT_JSON"  | ruby -rjson -e 'd=JSON.parse(STDIN.read) rescue {}; puts d["type"] || "unknown"' 2>/dev/null)
SIZE=$(printf "%s" "$DETECT_JSON"  | ruby -rjson -e 'd=JSON.parse(STDIN.read) rescue {}; puts d["size_bytes"] || 0' 2>/dev/null)
EXISTS=$(printf "%s" "$DETECT_JSON" | ruby -rjson -e 'd=JSON.parse(STDIN.read) rescue {}; puts d["exists"] ? "true" : "false"' 2>/dev/null)

# Default so bash arithmetic doesn't blow up on malformed SIZE
[ -z "$SIZE" ] || ! [[ "$SIZE" =~ ^[0-9]+$ ]] && SIZE=0

# ─── Read capabilities.yaml (which backends are installed) ──────────
# Grep-based extraction — handles the simple key-value layout in our
# template. Users who hand-craft weird YAML get defaults (= backend
# missing) and should re-run the guided_setup_wizard when that ships.
cap_backend_installed() {
  local name="$1"
  [ ! -f "$CAPS" ] && { echo "false"; return; }
  # Find the "$name:" block and look for "installed: true" in the next 4 lines.
  if awk -v target="$name:" '
    $0 ~ "^    "target {in_block=1; next}
    in_block && /^    [a-z]+:/ {in_block=0}
    in_block && /installed:[[:space:]]*true/ {found=1; exit}
    END {exit(found ? 0 : 1)}
  ' "$CAPS" 2>/dev/null; then
    echo "true"
  else
    echo "false"
  fi
}

# ─── Read profile.company.data_handling_policy ──────────────────────
POLICY="unset"
if [ -f "$PROFILE" ]; then
  FOUND=$(grep -E "^[[:space:]]+data_handling_policy:" "$PROFILE" 2>/dev/null | head -1 || echo "")
  if [ -n "$FOUND" ]; then
    POLICY=$(printf "%s" "$FOUND" | sed 's/.*data_handling_policy:[[:space:]]*//; s/["'\'']//g; s/[[:space:]]*$//')
  fi
fi
[ "$POLICY" = "null" ] || [ -z "$POLICY" ] && POLICY="unset"

# ─── Routing decision tree ──────────────────────────────────────────
BACKEND="none"
REASON=""
STATUS="ready"
HINT=""

if [ "$EXISTS" = "false" ]; then
  BACKEND="none"
  STATUS="unsupported"
  REASON="file does not exist"
  HINT="Check the path and retry."
else
  case "$TYPE" in
    text|code|data|email)
      BACKEND="native"
      STATUS="ready"
      REASON="plain-text type — readable without a backend"
      ;;
    pdf)
      if [ "$SIZE" -ge "$OVERSIZE_BYTES" ]; then
        BACKEND="defer"
        STATUS="deferred"
        REASON="large PDF (${SIZE} bytes ≥ oversize threshold) — raster 6-phase pipeline (roadmap 1.1)"
        HINT="Large-PDF handling ships post-Beta-1.0. Consider splitting the file."
      elif [ "$(cap_backend_installed kreuzberg)" = "true" ]; then
        BACKEND="kreuzberg"
        STATUS="ready"
        REASON="PDF + kreuzberg installed (native PDF extraction, 91+ formats)"
      else
        # Fallback — can we do a best-effort text extract with system pdftotext?
        if command -v pdftotext >/dev/null 2>&1; then
          BACKEND="native"
          STATUS="ready"
          REASON="kreuzberg not installed — falling back to system pdftotext"
          HINT="For richer PDF extraction: install kreuzberg (see parser.kreuzberg_backend)."
        else
          BACKEND="none"
          STATUS="backend_missing"
          REASON="PDF requires a backend (kreuzberg or system pdftotext)"
          HINT="Install kreuzberg or poppler-utils (ships pdftotext)."
        fi
      fi
      ;;
    office)
      if [ "$(cap_backend_installed kreuzberg)" = "true" ]; then
        BACKEND="kreuzberg"
        STATUS="ready"
        REASON="office document + kreuzberg installed"
      else
        BACKEND="none"
        STATUS="backend_missing"
        REASON="office formats require kreuzberg"
        HINT="Install kreuzberg (see parser.kreuzberg_backend, Phase 5.3.b)."
      fi
      ;;
    image)
      if [ "$(cap_backend_installed ollama_vlm)" = "true" ]; then
        # Policy gate: ollama_vlm is local, so always OK — but if a future
        # remote VLM backend shows up and policy=local_only, block.
        BACKEND="ollama_vlm"
        STATUS="ready"
        REASON="image + ollama_vlm installed (local OCR)"
      else
        BACKEND="none"
        STATUS="backend_missing"
        REASON="images require ollama_vlm (local VLM)"
        HINT="Install Ollama + a vision model (see parser.ollama_vlm_backend, Phase 5.3.c)."
      fi
      ;;
    archive)
      BACKEND="none"
      STATUS="unsupported"
      REASON="archive formats are not parsed in Beta 1.0"
      HINT="Extract the archive first, then parse individual files."
      ;;
    unknown|*)
      BACKEND="none"
      STATUS="unsupported"
      REASON="unsupported file type (no backend claims this extension)"
      HINT="Drop a plain-text export if you can; otherwise this format is not yet handled."
      ;;
  esac
fi

# ─── Output ─────────────────────────────────────────────────────────
if [ "$FORMAT" = "text" ]; then
  printf "%s %s (%s bytes) → backend=%s  status=%s\n" \
    "$FILE" "$TYPE" "$SIZE" "$BACKEND" "$STATUS"
  [ -n "$REASON" ] && printf "  reason: %s\n" "$REASON"
  [ -n "$HINT" ] && printf "  hint:   %s\n" "$HINT"
  exit 0
fi

# JSON (default)
ruby -rjson -e '
  out = {
    "file"       => ARGV[0],
    "type"       => ARGV[1],
    "size_bytes" => ARGV[2].to_i,
    "backend"    => ARGV[3],
    "reason"     => ARGV[4],
    "status"     => ARGV[5],
    "policy"     => ARGV[6],
    "hint"       => ARGV[7]
  }
  puts JSON.pretty_generate(out)
' "$FILE" "$TYPE" "$SIZE" "$BACKEND" "$REASON" "$STATUS" "$POLICY" "$HINT"
