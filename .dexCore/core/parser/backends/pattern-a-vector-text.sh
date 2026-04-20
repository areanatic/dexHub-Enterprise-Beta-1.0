#!/usr/bin/env bash
# DexHub Parser — Pattern A Vector+Text backend (parser.pattern_a_vector_text)
# ==========================================================
# Cheap/fast PDF text extraction via poppler's pdftotext CLI. Designed
# for PDFs that are primarily vector-based with embedded text (Figma
# exports, design mockups, Miro boards) — the fast path where kreuzberg's
# richer layout parsing is overkill.
#
# Role in the Parser arc:
#   - kreuzberg   → PDF + Office + rich layout (highest quality, slower)
#   - pattern_a   → PDF ONLY, fast, layout-preserving text via pdftotext
#   - ollama_vlm  → Image + PDF-as-image via VLM (when text layer absent)
#
# Why this exists separately from the "native" fallback in parse-route.sh:
# the router's native fallback was always meant to be the last resort.
# Shipping pattern_a as a first-class adapter gives us (a) explicit user
# install prompts via capabilities-probe, (b) consistent hint_type contract,
# (c) room for future enhancements (e.g. optional sips preview PNG on macOS).
# The router's pdftotext fallback continues to exist for users who ignore
# the probe step — honest degradation, not a broken state.
#
# Install options the user chooses:
#   macOS:  brew install poppler
#   Linux:  apt-get install poppler-utils  (or equivalent)
#   (Most Homebrew + macOS dev boxes already have pdftotext via other tools.)
#
# Feature: parser.pattern_a_vector_text
# Phase:   5.3.d (first slice — adapter scaffold + hint_type contract)
# Pattern: .dexCore/_dev/docs/BACKEND-ADAPTER-PATTERN.md
#
# Usage (same contract as kreuzberg.sh):
#   bash pattern-a-vector-text.sh --detect
#   bash pattern-a-vector-text.sh --detect --format text
#   bash pattern-a-vector-text.sh --extract PATH
#   bash pattern-a-vector-text.sh --extract PATH --format text
#   bash pattern-a-vector-text.sh --extract PATH --require   (exit 2 if not ready)
#
# Status field ∈ { ready | not_installed | probe_failed | blocked }
# hint_type field ∈ { ok | install_backend | probe_error | policy_blocked }
#
# Exit codes (same as kreuzberg.sh):
#   0  success or graceful-degradation
#   1  bad args / no args
#   2  --extract --require AND backend not ready
#   3  --extract on missing file
#   4  --extract crashed

set -uo pipefail

MODE=""
FILE=""
FORMAT="json"
REQUIRE=0

while [ $# -gt 0 ]; do
  case "$1" in
    --detect)    MODE="detect"; shift ;;
    --extract)   MODE="extract"; FILE="${2:-}"; shift 2 ;;
    --format)    FORMAT="$2"; shift 2 ;;
    --require)   REQUIRE=1; shift ;;
    --help|-h)
      sed -n '2,42p' "${BASH_SOURCE[0]}"
      exit 0
      ;;
    -*)
      echo "ERROR: unknown flag: $1" >&2
      exit 1
      ;;
    *)
      if [ -z "$FILE" ] && [ "$MODE" = "extract" ]; then
        FILE="$1"
      else
        echo "ERROR: unexpected positional arg: $1" >&2
        exit 1
      fi
      shift
      ;;
  esac
done

[ -z "$MODE" ] && { echo "ERROR: specify --detect or --extract PATH" >&2; exit 1; }

# ─── Detect ─────────────────────────────────────────────────────────
probe_pattern_a() {
  local bin status version install_hint hint_type
  bin=$(command -v pdftotext 2>/dev/null || echo "")
  if [ -z "$bin" ]; then
    status="not_installed"
    hint_type="install_backend"
    version=""
    install_hint="brew install poppler  (macOS)  ·  apt-get install poppler-utils  (Linux)"
  else
    # pdftotext emits version to stderr on older poppler; capture both.
    version=$("$bin" -v 2>&1 | head -1 | tr -d '\r' || echo "")
    if [ -z "$version" ]; then
      status="probe_failed"
      hint_type="probe_error"
      install_hint="Binary at $bin did not respond to -v. Reinstall poppler: brew reinstall poppler (macOS) or apt-get install --reinstall poppler-utils (Linux)."
    else
      status="ready"
      hint_type="ok"
      install_hint="Ready — invoke via 'bash pattern-a-vector-text.sh --extract PATH'."
    fi
  fi

  if [ "$FORMAT" = "text" ]; then
    echo "Pattern A (Vector+Text) adapter"
    echo "  Binary:      ${bin:-<not found>}"
    echo "  Version:     ${version:-<unknown>}"
    echo "  Status:      $(echo "$status" | tr '[:lower:]' '[:upper:]')"
    echo "  hint_type:   $hint_type"
    echo "  Next step:   $install_hint"
    return 0
  fi

  ruby -rjson -e '
    puts JSON.pretty_generate({
      "backend"      => "pattern_a_vector_text",
      "binary"       => ARGV[0],
      "version"      => ARGV[1],
      "status"       => ARGV[2],
      "setup_hint"   => ARGV[3],
      "hint_type"    => ARGV[4],
      "supported"    => ["pdf"],
      "compliance"   => "ok"
    })
  ' "${bin:-}" "${version:-}" "$status" "$install_hint" "$hint_type"
}

# ─── Extract ────────────────────────────────────────────────────────
extract_file() {
  local file="$1"
  [ -z "$file" ] && { echo "ERROR: --extract requires a file path" >&2; exit 1; }
  [ ! -f "$file" ] && { echo "ERROR: file not found: $file" >&2; exit 3; }

  # Must be ready (or --require bypasses only the not-installed exit).
  # The probe function honors the outer $FORMAT — if a caller invoked
  # --extract with --format text (like inbox-auto-parse.sh), a naive
  # `probe | ruby JSON.parse` would choke on text output. Force JSON
  # locally for the internal status check; restore outer FORMAT after.
  local probe_status probe_bin saved_format="$FORMAT"
  FORMAT=json
  probe_status=$(probe_pattern_a | ruby -rjson -e 'puts JSON.parse(STDIN.read)["status"] rescue "probe_failed"' 2>/dev/null)
  probe_bin=$(probe_pattern_a | ruby -rjson -e 'puts JSON.parse(STDIN.read)["binary"] rescue ""' 2>/dev/null)
  FORMAT="$saved_format"

  if [ "$probe_status" != "ready" ]; then
    if [ "$REQUIRE" = "1" ]; then
      echo "ERROR: pdftotext not ready (status=$probe_status) and --require was set" >&2
      exit 2
    fi
    # Graceful degradation — JSON with status=not_installed, exit 0
    if [ "$FORMAT" = "text" ]; then
      echo "Pattern A adapter: backend status=$probe_status — cannot extract."
      echo "Install poppler: brew install poppler (macOS) or apt-get install poppler-utils (Linux)."
      return 0
    fi
    ruby -rjson -e '
      puts JSON.pretty_generate({
        "backend"  => "pattern_a_vector_text",
        "file"     => ARGV[0],
        "status"   => ARGV[1],
        "content"  => nil,
        "error"    => "pdftotext not ready (probe status=" + ARGV[1] + ")",
        "hint"     => "Install poppler: brew install poppler (macOS) or apt-get install poppler-utils (Linux)."
      })
    ' "$file" "$probe_status"
    return 0
  fi

  # Extract. -layout preserves visual structure; -raw is faster but
  # scrambles reading order on multi-column PDFs. Default: -layout.
  # stderr captured so a pdftotext crash surfaces as error field, not
  # a mix into content.
  local content extract_stderr extract_exit
  extract_stderr=$(mktemp -t pa-err-XXXXXX)
  content=$("$probe_bin" -layout "$file" - 2>"$extract_stderr")
  extract_exit=$?

  if [ "$extract_exit" != "0" ]; then
    local err_msg
    err_msg=$(head -c 500 "$extract_stderr" 2>/dev/null || echo "")
    rm -f "$extract_stderr"
    if [ "$FORMAT" = "text" ]; then
      echo "ERROR: pdftotext failed (exit $extract_exit): $err_msg" >&2
      exit 4
    fi
    ruby -rjson -e '
      puts JSON.pretty_generate({
        "backend"  => "pattern_a_vector_text",
        "file"     => ARGV[0],
        "status"   => "extract_failed",
        "content"  => nil,
        "error"    => "pdftotext exit=" + ARGV[1] + ": " + ARGV[2],
        "hint"     => "Check that the file is a valid PDF. Non-PDF inputs or encrypted PDFs can trigger this."
      })
    ' "$file" "$extract_exit" "$err_msg"
    exit 4
  fi
  rm -f "$extract_stderr"

  if [ "$FORMAT" = "text" ]; then
    printf '%s' "$content"
    return 0
  fi

  # JSON (default) — content goes through ruby to handle arbitrary bytes.
  printf '%s' "$content" | ruby -rjson -e '
    content = STDIN.read
    puts JSON.pretty_generate({
      "backend"  => "pattern_a_vector_text",
      "file"     => ARGV[0],
      "status"   => "ok",
      "content"  => content,
      "bytes"    => content.bytesize,
      "error"    => nil,
      "hint"     => nil
    })
  ' "$file"
}

case "$MODE" in
  detect)  probe_pattern_a ;;
  extract) extract_file "$FILE" ;;
  *)       echo "ERROR: invalid mode" >&2; exit 1 ;;
esac
