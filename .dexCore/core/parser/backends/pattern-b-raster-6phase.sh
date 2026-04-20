#!/usr/bin/env bash
# DexHub Parser — Pattern B Raster 6-Phase Pipeline (parser.pattern_b_raster_6phase)
# ==========================================================
# SCAFFOLD ONLY (2026-04-21 session-7). Status=deferred to 1.1.
# This adapter exists to (a) reserve the backend ID in the probe+router
# contract, (b) emit the correct BACKEND-ADAPTER-PATTERN JSON shape so
# downstream callers (capabilities-probe, parse-route) can list it
# uniformly with shipped adapters, and (c) document the 6-phase
# architecture in code so the next implementer has a concrete target.
#
# === The 6 phases (architecture target for 1.1) ===
#
#   Phase 1: OVERVIEW         — Downscale PDF to ≤1800px overview PNG
#                                via sips (macOS) or convert (ImageMagick,
#                                Linux). Full document fits in one VLM
#                                context window at this size. Fast +
#                                cheap — ~1s / page.
#   Phase 2: CLUSTER-DETECT   — Run overview PNG through VLM (ollama_vlm
#                                + vision model) with prompt: "identify
#                                regions containing distinct content
#                                (tables, charts, body text, diagrams).
#                                Return bounding boxes + labels."
#                                Produces a region-list JSON.
#   Phase 3: HI-RES CROPS     — For each region, crop the ORIGINAL
#                                (full-res) PDF page to that bounding
#                                box + export as a dedicated PNG. sips
#                                / convert again.
#   Phase 4: PER-CLUSTER VLM  — Each crop through VLM with a region-
#                                specific prompt ("this is a table —
#                                return markdown", "this is a chart —
#                                describe + extract data", etc.).
#                                Parallelizable.
#   Phase 5: SYNTHESIS        — Combine all per-cluster outputs into a
#                                coherent markdown document, preserving
#                                reading order. VLM again, with the
#                                overview + cluster outputs as context.
#   Phase 6: VERIFY           — Sanity check: VLM receives final output
#                                + overview PNG, asked "does this md
#                                faithfully represent the document?".
#                                Flag hallucinations / omissions.
#
# === Why deferred from Beta 1.0 ===
#
#   - Multi-phase VLM pipeline = 5-20× the token cost of pattern_a.
#     Justified for image-heavy content (Figma/Miro/scanned PDFs)
#     where text layer is absent or unreliable. Overkill for normal
#     PDFs (which pattern_a handles faster + cheaper).
#   - Clustering step needs either VLM bounding-box output (accurate
#     but prompt-engineering-heavy) or heuristic region detection
#     (OpenCV / page-segmenter). Neither is in Beta 1.0 scope.
#   - Routing integration: parse-route.sh needs to decide
#     WHEN to prefer Pattern B over Pattern A / kreuzberg. Heuristics:
#     file size ≥100MB, page-count-to-text-density ratio, explicit
#     user opt-in. Design pending.
#
# === Current behavior (scaffold) ===
#
#   --detect  → status=deferred, hint_type=install_backend (with hints
#               naming all three required tools: poppler-utils, sips
#               OR ImageMagick convert, ollama with vision model)
#   --extract → status=deferred, exits 0 gracefully (never attempts
#               extraction), error message names the feature + phase
#
# Feature: parser.pattern_b_raster_6phase
# Phase:   1.1 (SCAFFOLDED in session-7 2026-04-21; REAL IMPL pending)
# Pattern: .dexCore/_dev/docs/BACKEND-ADAPTER-PATTERN.md

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
      sed -n '2,66p' "${BASH_SOURCE[0]}"
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
probe_pattern_b() {
  local has_poppler has_raster has_ollama
  has_poppler=$(command -v pdftoppm >/dev/null 2>&1 && echo "true" || echo "false")
  if command -v sips >/dev/null 2>&1 || command -v convert >/dev/null 2>&1; then
    has_raster="true"
  else
    has_raster="false"
  fi
  has_ollama=$(command -v ollama >/dev/null 2>&1 && echo "true" || echo "false")

  # Even when every dependency is present, this adapter is SCAFFOLD
  # status — the 6-phase pipeline itself hasnt been implemented. We
  # return status=deferred to signal "reserved but not ready".
  # hint_type=install_backend because the USER ACTION to enable it
  # (once the impl lands) is installing the dependency bundle.
  local status="deferred"
  local hint_type="install_backend"
  local setup_hint
  setup_hint="Scaffold only — 6-phase raster pipeline is on the 1.1 roadmap (parser.pattern_b_raster_6phase). "
  setup_hint+="When shipped, requires: "
  setup_hint+="poppler-utils (pdftoppm — brew install poppler / apt install poppler-utils), "
  setup_hint+="sips (macOS built-in) OR ImageMagick (brew install imagemagick / apt install imagemagick), "
  setup_hint+="AND Ollama with a vision model (ollama pull llama3.2-vision). "
  setup_hint+="Current tool status on this machine: pdftoppm=${has_poppler}, raster=${has_raster}, ollama=${has_ollama}."

  if [ "$FORMAT" = "text" ]; then
    echo "Pattern B (Raster 6-Phase Pipeline) adapter — SCAFFOLD"
    echo "  Status:      DEFERRED (1.1 roadmap)"
    echo "  hint_type:   $hint_type"
    echo "  pdftoppm:    $has_poppler"
    echo "  sips|convert: $has_raster"
    echo "  ollama:      $has_ollama"
    echo "  Next step:   $setup_hint"
    return 0
  fi

  ruby -rjson -e '
    puts JSON.pretty_generate({
      "backend"      => "pattern_b_raster_6phase",
      "binary"       => "",
      "version"      => "",
      "status"       => ARGV[0],
      "setup_hint"   => ARGV[1],
      "hint_type"    => ARGV[2],
      "supported"    => ["pdf", "image"],
      "compliance"   => "local_vlm_required",
      "scaffold"     => true,
      "phases"       => ["overview", "cluster_detect", "hi_res_crops",
                          "per_cluster_vlm", "synthesis", "verify"]
    })
  ' "$status" "$setup_hint" "$hint_type"
}

# ─── Extract ────────────────────────────────────────────────────────
extract_file() {
  local file="$1"
  [ -z "$file" ] && { echo "ERROR: --extract requires a file path" >&2; exit 1; }
  [ ! -f "$file" ] && { echo "ERROR: file not found: $file" >&2; exit 3; }

  if [ "$REQUIRE" = "1" ]; then
    echo "ERROR: Pattern B is scaffold-only (deferred to 1.1) and --require was set" >&2
    exit 2
  fi

  if [ "$FORMAT" = "text" ]; then
    echo "Pattern B adapter: scaffold only. 6-phase raster pipeline not yet implemented."
    echo "Track progress: parser.pattern_b_raster_6phase in .dexCore/_cfg/features.yaml"
    return 0
  fi

  ruby -rjson -e '
    puts JSON.pretty_generate({
      "backend"  => "pattern_b_raster_6phase",
      "file"     => ARGV[0],
      "status"   => "deferred",
      "content"  => nil,
      "bytes"    => 0,
      "error"    => "Pattern B scaffold — 6-phase raster pipeline deferred to 1.1. Adapter reserves the ID but does not extract.",
      "hint"     => "Use pattern_a_vector_text for PDFs with a text layer, or ollama_vlm for image-only content. Pattern B targets the hybrid oversize/visual-board case that neither currently handles well."
    })
  ' "$file"
}

case "$MODE" in
  detect)  probe_pattern_b ;;
  extract) extract_file "$FILE" ;;
  *)       echo "ERROR: invalid mode" >&2; exit 1 ;;
esac
