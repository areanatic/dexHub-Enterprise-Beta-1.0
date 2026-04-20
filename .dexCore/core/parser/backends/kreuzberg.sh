#!/usr/bin/env bash
# DexHub Parser — Kreuzberg backend adapter (parser.kreuzberg_backend)
# ==========================================================
# Thin shell wrapper around the Kreuzberg document-parsing CLI
# (https://github.com/kreuzberg-dev/kreuzberg — Rust, MIT, 91+ formats).
# This adapter is the first backend to ship under the Parser Router
# architecture (parse-route.sh). It follows the proven
# detect-first / graceful-fallback pattern from the L2 Tank's Ollama
# adapter: probe cheaply, degrade honestly, never block.
#
# Install options the user chooses (never automated by us):
#   brew install kreuzberg-dev/tap/kreuzberg     # macOS, curated tap
#   cargo install kreuzberg-cli                   # any Rust toolchain
#   docker pull ghcr.io/kreuzberg-dev/kreuzberg   # containerized
# We detect `kreuzberg` on PATH only. Docker-only installs are out of
# scope for this adapter (future: optional `--runner docker` flag).
#
# Feature: parser.kreuzberg_backend
# Phase:   5.3.b (first slice — adapter scaffold, structural tests;
#                 live behavior validation requires user install)
#
# Usage:
#   bash kreuzberg.sh --detect                       # probe + JSON status
#   bash kreuzberg.sh --detect --format text         # human-readable
#   bash kreuzberg.sh --extract PATH                 # run parse, JSON out
#   bash kreuzberg.sh --extract PATH --format text   # plain text only
#
# Status field ∈ { ready | not_installed | probe_failed | blocked }:
#   ready         — `kreuzberg` on PATH + version probe returned
#   not_installed — nothing on PATH named kreuzberg
#   probe_failed  — binary found but version call crashed (unusual)
#   blocked       — policy gate refuses (cloud backends — not kreuzberg
#                   today; placeholder for symmetry with L2 adapter)
#
# Exit codes:
#   0   success (detection reports status in JSON; extract success)
#   1   bad args / empty input
#   2   extract requested but backend not installed AND --require was set
#   3   extract requested but file missing
#   4   extract crashed — backend bug or unsupported format

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
      sed -n '2,30p' "${BASH_SOURCE[0]}"
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
# Cheap: `command -v` + a single `--version` call. No file operations,
# no network, no side effects.
probe_kreuzberg() {
  local bin status version install_hint hint_type
  bin=$(command -v kreuzberg 2>/dev/null || echo "")
  if [ -z "$bin" ]; then
    status="not_installed"
    hint_type="install_backend"
    version=""
    install_hint="brew install kreuzberg-dev/tap/kreuzberg  (macOS) · cargo install kreuzberg-cli  (any) · docker pull ghcr.io/kreuzberg-dev/kreuzberg"
  else
    # Some binaries have --version, some -V — try both before declaring
    # probe_failed. We pipe stderr because kreuzberg may write version
    # banners to stderr depending on the build.
    version=$("$bin" --version 2>&1 | head -1 | tr -d '\r' || echo "")
    if [ -z "$version" ]; then
      version=$("$bin" -V 2>&1 | head -1 | tr -d '\r' || echo "")
    fi
    if [ -z "$version" ]; then
      status="probe_failed"
      hint_type="probe_error"
      install_hint="Binary at $bin responded to neither --version nor -V. Reinstall or use a different tool."
    else
      status="ready"
      hint_type="ok"
      install_hint="Ready — invoke via 'bash kreuzberg.sh --extract PATH'."
    fi
  fi

  if [ "$FORMAT" = "text" ]; then
    echo "Kreuzberg adapter"
    echo "  Binary:      ${bin:-<not found>}"
    echo "  Version:     ${version:-<unknown>}"
    echo "  Status:      $(echo "$status" | tr '[:lower:]' '[:upper:]')"
    echo "  Next step:   $install_hint"
    return 0
  fi

  # JSON (default) — escape everything via ruby so version strings with
  # quotes survive round-trip cleanly.
  ruby -rjson -e '
    puts JSON.pretty_generate({
      "backend"      => "kreuzberg",
      "binary"       => ARGV[0],
      "version"      => ARGV[1],
      "status"       => ARGV[2],
      "setup_hint"   => ARGV[3],
      "hint_type"    => ARGV[4],
      "supported"    => ["pdf", "docx", "xlsx", "pptx", "odt", "rtf",
                          "html", "epub", "md", "txt", "csv"],
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
  # We call the same probe + check status.
  local probe_status probe_bin
  probe_status=$(probe_kreuzberg | ruby -rjson -e 'puts JSON.parse(STDIN.read)["status"] rescue "probe_failed"' 2>/dev/null)
  probe_bin=$(probe_kreuzberg | ruby -rjson -e 'puts JSON.parse(STDIN.read)["binary"] rescue ""' 2>/dev/null)

  if [ "$probe_status" != "ready" ]; then
    # Graceful — emit a JSON result with status=not_installed, or fail
    # with exit 2 if the caller asked --require.
    if [ "$FORMAT" = "text" ]; then
      echo "kreuzberg adapter: backend status=$probe_status — cannot extract."
      echo "Install: brew install kreuzberg-dev/tap/kreuzberg (or cargo install kreuzberg-cli)."
    else
      ruby -rjson -e '
        puts JSON.pretty_generate({
          "backend"  => "kreuzberg",
          "file"     => ARGV[0],
          "status"   => ARGV[1],
          "content"  => nil,
          "error"    => "backend not ready — cannot extract",
          "hint"     => "Install kreuzberg (see --detect for options)"
        })
      ' "$file" "$probe_status"
    fi
    [ "$REQUIRE" = "1" ] && exit 2
    exit 0
  fi

  # Invoke kreuzberg. Output format mirrors the research doc's contract:
  # Kreuzberg prints extracted text to stdout + JSON metadata on request.
  # We capture both; the simple adapter surfaces stdout as .content and
  # wraps with metadata we control.
  local raw
  raw=$("$probe_bin" extract "$file" 2>&1) || {
    if [ "$FORMAT" = "text" ]; then
      echo "kreuzberg extract failed for $file:"
      echo "$raw"
    else
      ruby -rjson -e '
        puts JSON.pretty_generate({
          "backend" => "kreuzberg",
          "file"    => ARGV[0],
          "status"  => "extract_failed",
          "content" => nil,
          "error"   => ARGV[1]
        })
      ' "$file" "$raw"
    fi
    exit 4
  }

  if [ "$FORMAT" = "text" ]; then
    printf "%s\n" "$raw"
    return 0
  fi

  ruby -rjson -e '
    puts JSON.pretty_generate({
      "backend" => "kreuzberg",
      "file"    => ARGV[0],
      "status"  => "ok",
      "content" => STDIN.read
    })
  ' "$file" <<< "$raw"
}

case "$MODE" in
  detect)  probe_kreuzberg ;;
  extract) extract_file "$FILE" ;;
esac
