#!/usr/bin/env bash
# DexHub Parser — Ollama VLM backend adapter (parser.ollama_vlm_backend)
# ==========================================================
# Image / vision backend built on a local Ollama instance running any
# VLM (visual language model). Produces text descriptions + OCR output
# from image inputs. compliance: local_vlm_required — the backend is
# INHERENTLY local; the compliance value tells upstream callers that
# cloud-backed VLM fallbacks are a different kind of backend and must
# NOT be silently substituted.
#
# Supported vision models the adapter auto-discovers (in priority order,
# first-available wins unless --model overrides):
#   llama3.2-vision, llava-llama3, llava, bakllava, moondream,
#   minicpm-v, llava-phi3
#
# Config:
#   OLLAMA_HOST env var (default http://localhost:11434) — respect for
#   LAN-style deployments (e.g. a shared Ollama on a workstation).
#
# Feature: parser.ollama_vlm_backend
# Phase:   5.3.c (first slice — adapter scaffold + structural tests.
#                 Behavioral live validation requires a VLM model pulled
#                 into Ollama; gated by CLAUDE_E2E_LIVE_VLM=1)
# Pattern: .dexCore/_dev/docs/BACKEND-ADAPTER-PATTERN.md
#
# Usage:
#   bash ollama-vlm.sh --detect                        # probe + JSON
#   bash ollama-vlm.sh --detect --format text          # human-readable
#   bash ollama-vlm.sh --detect --model llava          # force model
#   bash ollama-vlm.sh --extract image.png             # run, JSON out
#   bash ollama-vlm.sh --extract image.png --prompt "Transcribe text"
#   bash ollama-vlm.sh --extract image.png --format text
#
# Status (--detect) ∈ { ready | not_installed | partial | probe_failed | blocked }:
#   ready         — Ollama daemon reachable AND at least one VLM model pulled
#   not_installed — ollama CLI not on PATH
#   partial       — ollama installed but daemon unreachable OR no VLM model pulled
#   probe_failed  — binary found but version call errored
#   blocked       — reserved (future remote-VLM backend + local_only policy)
#
# Exit codes (per BACKEND-ADAPTER-PATTERN):
#   0  success / graceful degradation (default)
#   1  bad args / unknown flag
#   2  --extract --require while backend missing
#   3  --extract on a missing file
#   4  extract crashed — Ollama returned an error or malformed response

set -uo pipefail

MODE=""
FILE=""
FORMAT="json"
REQUIRE=0
MODEL_OVERRIDE=""
EXTRACT_PROMPT="Describe this image in detail. If text is visible, transcribe it verbatim."
OLLAMA_ENDPOINT="${OLLAMA_HOST:-http://localhost:11434}"

# Priority order for model auto-detection (first-available wins).
# Keep generic enough to survive Ollama catalog churn; specific-enough
# to avoid picking a non-VLM model.
KNOWN_VISION_MODELS=(
  "llama3.2-vision"
  "llava-llama3"
  "llava"
  "bakllava"
  "moondream"
  "minicpm-v"
  "llava-phi3"
)

while [ $# -gt 0 ]; do
  case "$1" in
    --detect)    MODE="detect"; shift ;;
    --extract)   MODE="extract"; FILE="${2:-}"; shift 2 ;;
    --format)    FORMAT="$2"; shift 2 ;;
    --require)   REQUIRE=1; shift ;;
    --model)     MODEL_OVERRIDE="$2"; shift 2 ;;
    --prompt)    EXTRACT_PROMPT="$2"; shift 2 ;;
    --endpoint)  OLLAMA_ENDPOINT="$2"; shift 2 ;;
    --help|-h)
      sed -n '2,36p' "${BASH_SOURCE[0]}"
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

# ─── Probe helpers ──────────────────────────────────────────────────
# Returns the first VLM model present on the Ollama daemon, or empty.
# Reads /api/tags (cheap GET). Respects --model override.
discover_vision_model() {
  local tags_json
  tags_json=$(curl -sS --max-time 2 "$OLLAMA_ENDPOINT/api/tags" 2>/dev/null || echo "")
  [ -z "$tags_json" ] && { echo ""; return; }

  if [ -n "$MODEL_OVERRIDE" ]; then
    if echo "$tags_json" | ruby -rjson -e '
      d = JSON.parse(STDIN.read) rescue {"models" => []}
      wanted = ARGV[0]
      exit((d["models"] || []).any? { |m| (m["name"] || "").start_with?(wanted) } ? 0 : 1)
    ' "$MODEL_OVERRIDE" 2>/dev/null; then
      echo "$MODEL_OVERRIDE"
    else
      echo ""
    fi
    return
  fi

  for candidate in "${KNOWN_VISION_MODELS[@]}"; do
    if echo "$tags_json" | ruby -rjson -e '
      d = JSON.parse(STDIN.read) rescue {"models" => []}
      wanted = ARGV[0]
      exit((d["models"] || []).any? { |m| (m["name"] || "").start_with?(wanted) } ? 0 : 1)
    ' "$candidate" 2>/dev/null; then
      echo "$candidate"
      return
    fi
  done
  echo ""
}

probe_ollama_vlm() {
  local bin="" ollama_version="" daemon_running="false" model="" status install_hint
  bin=$(command -v ollama 2>/dev/null || echo "")

  if [ -z "$bin" ]; then
    status="not_installed"
    # Honor --model override here too: if the user told us which model
    # they want, the install hint names THEIR choice, not a generic
    # default. Without this, `--model starcoder-vision` on a fresh box
    # silently says "pull llama3.2-vision" — user's intent disappears.
    # (Caught by 2026-04-21 critical review.)
    if [ -n "$MODEL_OVERRIDE" ]; then
      install_hint="Install Ollama (https://ollama.com), then: ollama pull $MODEL_OVERRIDE"
    else
      install_hint="Install Ollama (https://ollama.com), then: ollama pull llama3.2-vision  (or llava — any VLM listed at https://ollama.com/search?c=vision)"
    fi
  else
    ollama_version=$("$bin" --version 2>&1 | head -1 | tr -d '\r' || echo "")

    if curl -sS --max-time 2 "$OLLAMA_ENDPOINT/api/tags" >/dev/null 2>&1; then
      daemon_running="true"
      model=$(discover_vision_model)
      if [ -n "$model" ]; then
        status="ready"
        install_hint="Ready with model '$model'. Use --extract PATH or --model NAME to pick another."
      else
        status="partial"
        if [ -n "$MODEL_OVERRIDE" ]; then
          install_hint="Override model '$MODEL_OVERRIDE' not pulled. Try: ollama pull $MODEL_OVERRIDE"
        else
          install_hint="Ollama running but no VLM pulled. Try: ollama pull llama3.2-vision  (or llava / moondream / bakllava / minicpm-v / llava-phi3)"
        fi
      fi
    else
      status="partial"
      install_hint="ollama installed but daemon not reachable at $OLLAMA_ENDPOINT. Try: ollama serve  (or open the Ollama.app)"
    fi
  fi

  if [ "$FORMAT" = "text" ]; then
    echo "Ollama VLM adapter"
    echo "  Binary:        ${bin:-<not found>}"
    echo "  Ollama vers.:  ${ollama_version:-<unknown>}"
    echo "  Endpoint:      $OLLAMA_ENDPOINT"
    echo "  Daemon:        $([ "$daemon_running" = "true" ] && echo "reachable" || echo "not reachable")"
    echo "  Model:         ${model:-<none pulled>}"
    echo "  Status:        $(echo "$status" | tr '[:lower:]' '[:upper:]')"
    echo "  Next step:     $install_hint"
    return 0
  fi

  ruby -rjson -e '
    puts JSON.pretty_generate({
      "backend"        => "ollama_vlm",
      "binary"         => ARGV[0],
      "version"        => ARGV[1],
      "endpoint"       => ARGV[2],
      "daemon_running" => ARGV[3] == "true",
      "model"          => ARGV[4],
      "status"         => ARGV[5],
      "setup_hint"     => ARGV[6],
      "supported"      => ["png", "jpg", "jpeg", "gif", "webp", "bmp", "tiff"],
      "compliance"     => "local_vlm_required"
    })
  ' "${bin:-}" "${ollama_version:-}" "$OLLAMA_ENDPOINT" "$daemon_running" "${model:-}" "$status" "$install_hint"
}

# ─── Extract ────────────────────────────────────────────────────────
extract_file() {
  local file="$1"
  [ -z "$file" ] && { echo "ERROR: --extract requires a file path" >&2; exit 1; }
  [ ! -f "$file" ] && { echo "ERROR: file not found: $file" >&2; exit 3; }

  local probe probe_status probe_model
  probe=$(probe_ollama_vlm 2>/dev/null)
  probe_status=$(echo "$probe" | ruby -rjson -e 'puts JSON.parse(STDIN.read)["status"] rescue "probe_failed"' 2>/dev/null)
  probe_model=$(echo "$probe" | ruby -rjson -e 'puts JSON.parse(STDIN.read)["model"] rescue ""' 2>/dev/null)

  if [ "$probe_status" != "ready" ]; then
    if [ "$FORMAT" = "text" ]; then
      echo "ollama_vlm adapter: backend status=$probe_status — cannot extract."
      echo "Hint: $(echo "$probe" | ruby -rjson -e 'puts JSON.parse(STDIN.read)["setup_hint"] rescue ""' 2>/dev/null)"
    else
      ruby -rjson -e '
        probe = JSON.parse(ARGV[1]) rescue {}
        puts JSON.pretty_generate({
          "backend"  => "ollama_vlm",
          "file"     => ARGV[0],
          "status"   => probe["status"] || "probe_failed",
          "content"  => nil,
          "error"    => "backend not ready — cannot extract",
          "hint"     => probe["setup_hint"] || "Run --detect for diagnostics"
        })
      ' "$file" "$probe"
    fi
    [ "$REQUIRE" = "1" ] && exit 2
    exit 0
  fi

  local body
  body=$(ruby -rjson -rbase64 -e '
    file, model, prompt = ARGV
    img_b64 = Base64.strict_encode64(File.binread(file))
    puts JSON.generate({
      "model"   => model,
      "prompt"  => prompt,
      "images"  => [img_b64],
      "stream"  => false
    })
  ' "$file" "$probe_model" "$EXTRACT_PROMPT")

  if [ -z "$body" ]; then
    echo "ERROR: failed to encode request body" >&2
    exit 4
  fi

  local resp
  resp=$(curl -sS --max-time 300 -X POST "$OLLAMA_ENDPOINT/api/generate" \
    -H "Content-Type: application/json" \
    -d "$body" 2>/dev/null || echo "")

  if [ -z "$resp" ]; then
    if [ "$FORMAT" = "text" ]; then
      echo "ollama_vlm extract failed for $file: HTTP request failed or returned empty."
    else
      ruby -rjson -e '
        puts JSON.pretty_generate({
          "backend" => "ollama_vlm",
          "file"    => ARGV[0],
          "status"  => "extract_failed",
          "content" => nil,
          "error"   => "HTTP request failed or returned empty",
          "hint"    => "Check Ollama daemon is running at " + ARGV[1]
        })
      ' "$file" "$OLLAMA_ENDPOINT"
    fi
    exit 4
  fi

  local parsed
  parsed=$(echo "$resp" | ruby -rjson -e '
    begin
      r = JSON.parse(STDIN.read)
      if r["error"]
        puts JSON.generate({"status" => "extract_failed", "error" => r["error"]})
      elsif r["response"]
        puts JSON.generate({
          "status"      => "ok",
          "content"     => r["response"],
          "model_used"  => r["model"],
          "eval_count"  => r["eval_count"],
          "total_ms"    => (r["total_duration"] || 0) / 1_000_000
        })
      else
        puts JSON.generate({"status" => "extract_failed", "error" => "unexpected response shape"})
      end
    rescue JSON::ParserError => e
      puts JSON.generate({"status" => "extract_failed", "error" => "invalid JSON response: #{e.message}"})
    end
  ')

  local status
  status=$(echo "$parsed" | ruby -rjson -e 'puts JSON.parse(STDIN.read)["status"]' 2>/dev/null)

  if [ "$status" != "ok" ]; then
    if [ "$FORMAT" = "text" ]; then
      echo "ollama_vlm extract failed for $file:"
      echo "$parsed"
    else
      ruby -rjson -e '
        p = JSON.parse(ARGV[1])
        puts JSON.pretty_generate({
          "backend" => "ollama_vlm",
          "file"    => ARGV[0],
          "status"  => p["status"],
          "content" => nil,
          "error"   => p["error"]
        })
      ' "$file" "$parsed"
    fi
    exit 4
  fi

  if [ "$FORMAT" = "text" ]; then
    echo "$parsed" | ruby -rjson -e 'puts JSON.parse(STDIN.read)["content"]'
    return 0
  fi

  ruby -rjson -e '
    p = JSON.parse(ARGV[1])
    puts JSON.pretty_generate({
      "backend"    => "ollama_vlm",
      "file"       => ARGV[0],
      "status"     => p["status"],
      "content"    => p["content"],
      "model_used" => p["model_used"],
      "eval_count" => p["eval_count"],
      "total_ms"   => p["total_ms"]
    })
  ' "$file" "$parsed"
}

case "$MODE" in
  detect)  probe_ollama_vlm ;;
  extract) extract_file "$FILE" ;;
esac
