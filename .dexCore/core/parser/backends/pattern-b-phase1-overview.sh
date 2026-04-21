#!/usr/bin/env bash
# DexHub Parser — Pattern B Phase 1 Overview adapter
# ==========================================================
# First phase of the 6-phase Pattern B raster pipeline documented in
# parser.pattern_b_raster_6phase (scaffold). Ships STANDALONE so users
# who only need a holistic visual overview of a PDF / image do not wait
# for the full 6-phase implementation.
#
# Pipeline (Phase 1 only):
#   1. Input file (PDF or image)
#   2. If PDF: rasterize first page to PNG via pdftoppm or sips
#   3. Downscale PNG to ≤1800px long edge via sips / convert
#   4. Feed PNG to ollama_vlm adapter with an "overview" prompt
#   5. Return adapter-pattern JSON with content = VLM overview text
#
# Phase 1 is valuable standalone for:
#   - Summarizing image-heavy PDFs (Figma boards, Miro exports)
#   - Understanding scanned documents without per-region OCR cost
#   - Priming a second pass over the same doc (future Phases 2-6)
#
# Not a replacement for pattern_a (text-layer PDFs) — this is raster-only
# and returns DESCRIPTION, not verbatim content. Use pattern_a first; fall
# back to this when text layer is absent / layout matters more than text.
#
# Install options the user chooses (never automated):
#   macOS:   sips is built-in. `brew install poppler` for pdftoppm.
#   Linux:   `apt install poppler-utils imagemagick` (or sips-equivalent via
#            GraphicsMagick / ImageMagick `convert`).
#   VLM:     `ollama pull llama3.2-vision` (~7.8GB) OR any VLM listed at
#            https://ollama.com/search?c=vision — same model catalog as the
#            ollama_vlm adapter since this wraps that backend.
#
# Feature: parser.pattern_b_phase1_overview
# Phase:   5.3.k (Phase 1 only; Phases 2-6 remain deferred in
#                 parser.pattern_b_raster_6phase on the 1.1 roadmap)
# Pattern: .dexCore/_dev/docs/BACKEND-ADAPTER-PATTERN.md
#
# Usage:
#   bash pattern-b-phase1-overview.sh --detect
#   bash pattern-b-phase1-overview.sh --detect --format text
#   bash pattern-b-phase1-overview.sh --extract path/to/file.pdf
#   bash pattern-b-phase1-overview.sh --extract path/to/image.png
#   bash pattern-b-phase1-overview.sh --extract file.pdf --model llava
#   bash pattern-b-phase1-overview.sh --extract file.pdf --prompt "..."
#
# Status field ∈ { ready | not_installed | partial | probe_failed | blocked }:
#   ready         — raster tool + Ollama daemon + VLM model all present
#   not_installed — no raster tool on PATH OR ollama not installed
#   partial       — tools present but Ollama daemon unreachable
#                   OR no vision model pulled
#   probe_failed  — probe crashed for an unexpected reason
#   blocked       — reserved (future cloud-VLM policy gate)
#
# Exit codes:
#   0  success / graceful degradation
#   1  bad args
#   2  --extract --require while backend not ready
#   3  --extract on missing file
#   4  extract crashed (raster or VLM step failed)

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

MODE=""
FILE=""
FORMAT="json"
REQUIRE=0
MODEL_OVERRIDE=""
OVERVIEW_PROMPT="Describe this document/image holistically. Identify the overall layout and any major regions (tables, charts, body text, diagrams, images). Note salient visual elements and reading order. Be concise — a single paragraph, no bullets."
MAX_PX=1800

while [ $# -gt 0 ]; do
  case "$1" in
    --detect)    MODE="detect"; shift ;;
    --extract)   MODE="extract"; FILE="${2:-}"; shift 2 ;;
    --format)    FORMAT="$2"; shift 2 ;;
    --require)   REQUIRE=1; shift ;;
    --model)     MODEL_OVERRIDE="$2"; shift 2 ;;
    --prompt)    OVERVIEW_PROMPT="$2"; shift 2 ;;
    --max-px)    MAX_PX="$2"; shift 2 ;;
    --help|-h)
      sed -n '2,58p' "${BASH_SOURCE[0]}"
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

# ─── Helper: pick a raster tool ─────────────────────────────────────
# Priority: sips (macOS built-in, fastest) > pdftoppm (poppler, Linux
# common) > convert (ImageMagick, Linux fallback). Note: sips cannot
# rasterize PDF directly on all macOS versions — we use pdftoppm
# specifically for the PDF-to-PNG step when available, sips as fallback.
pick_raster_tool() {
  if command -v sips >/dev/null 2>&1; then
    echo "sips"
  elif command -v convert >/dev/null 2>&1; then
    echo "convert"
  else
    echo ""
  fi
}

pick_pdf_rasterizer() {
  if command -v pdftoppm >/dev/null 2>&1; then
    echo "pdftoppm"
  elif command -v sips >/dev/null 2>&1; then
    # macOS sips learned PDF rasterization via -s format png in recent
    # versions; try as fallback even though pdftoppm is preferred.
    echo "sips"
  elif command -v convert >/dev/null 2>&1; then
    echo "convert"
  else
    echo ""
  fi
}

# ─── Detect ─────────────────────────────────────────────────────────
probe_pattern_b_phase1() {
  local raster_tool pdf_tool vlm_probe vlm_status vlm_model vlm_hint
  raster_tool=$(pick_raster_tool)
  pdf_tool=$(pick_pdf_rasterizer)

  # Probe ollama_vlm adapter in JSON mode — we depend on it wholly.
  vlm_probe=$(bash "$SCRIPT_DIR/ollama-vlm.sh" --detect ${MODEL_OVERRIDE:+--model "$MODEL_OVERRIDE"} --format json 2>/dev/null || echo "{}")
  vlm_status=$(echo "$vlm_probe" | ruby -rjson -e 'puts JSON.parse(STDIN.read)["status"] rescue "probe_failed"' 2>/dev/null)
  vlm_model=$(echo "$vlm_probe"  | ruby -rjson -e 'puts JSON.parse(STDIN.read)["model"] rescue ""' 2>/dev/null)
  vlm_hint=$(echo "$vlm_probe"   | ruby -rjson -e 'puts JSON.parse(STDIN.read)["setup_hint"] rescue ""' 2>/dev/null)

  local status hint_type setup_hint
  if [ -z "$raster_tool" ] && [ -z "$pdf_tool" ]; then
    status="not_installed"
    hint_type="install_backend"
    setup_hint="No raster tool found. Install one: macOS sips (built-in), pdftoppm (brew install poppler / apt install poppler-utils), or ImageMagick convert (brew install imagemagick / apt install imagemagick). Also needed: Ollama with a vision model — ${vlm_hint:-see ollama_vlm adapter --detect}."
  elif [ "$vlm_status" = "not_installed" ]; then
    status="not_installed"
    hint_type="install_backend"
    setup_hint="Raster tool ready (${raster_tool:-$pdf_tool}) but VLM missing. ${vlm_hint}"
  elif [ "$vlm_status" = "partial" ]; then
    status="partial"
    hint_type="missing_dependency"
    setup_hint="Raster tool ready (${raster_tool:-$pdf_tool}) + Ollama installed, but VLM not ready. ${vlm_hint}"
  elif [ "$vlm_status" = "ready" ]; then
    status="ready"
    hint_type="ok"
    setup_hint="Ready. Raster tool=${raster_tool:-$pdf_tool}, PDF rasterizer=${pdf_tool:-<none, PDFs not supported>}, VLM model=${vlm_model}. Use --extract PATH."
  else
    status="probe_failed"
    hint_type="missing_dependency"
    setup_hint="VLM probe returned unexpected status '$vlm_status'. Run: bash .dexCore/core/parser/backends/ollama-vlm.sh --detect --format text"
  fi

  if [ "$FORMAT" = "text" ]; then
    echo "Pattern B Phase 1 Overview adapter"
    echo "  Raster tool:  ${raster_tool:-<none>}"
    echo "  PDF tool:     ${pdf_tool:-<none>}"
    echo "  VLM status:   $vlm_status"
    echo "  VLM model:    ${vlm_model:-<none>}"
    echo "  Status:       $(echo "$status" | tr '[:lower:]' '[:upper:]')"
    echo "  hint_type:    $hint_type"
    echo "  Next step:    $setup_hint"
    return 0
  fi

  ruby -rjson -e '
    puts JSON.pretty_generate({
      "backend"         => "pattern_b_phase1_overview",
      "raster_tool"     => ARGV[0],
      "pdf_rasterizer"  => ARGV[1],
      "vlm_status"      => ARGV[2],
      "vlm_model"       => ARGV[3],
      "status"          => ARGV[4],
      "setup_hint"      => ARGV[5],
      "hint_type"       => ARGV[6],
      "supported"       => ["pdf", "png", "jpg", "jpeg", "gif", "webp", "bmp", "tiff"],
      "compliance"      => "local_vlm_required",
      "max_px"          => ARGV[7].to_i,
      "phases_covered"  => ["overview"],
      "phases_deferred" => ["cluster_detect", "hi_res_crops", "per_cluster_vlm", "synthesis", "verify"]
    })
  ' "${raster_tool:-}" "${pdf_tool:-}" "$vlm_status" "${vlm_model:-}" "$status" "$setup_hint" "$hint_type" "$MAX_PX"
}

# ─── Raster helpers ─────────────────────────────────────────────────
# Determine file type (pdf / image / other) from extension + magic bytes.
# Extension takes priority (fast); magic bytes as tiebreaker.
detect_file_kind() {
  local file="$1"
  local ext lc_ext
  ext="${file##*.}"
  lc_ext=$(echo "$ext" | tr '[:upper:]' '[:lower:]')
  case "$lc_ext" in
    pdf) echo "pdf"; return ;;
    png|jpg|jpeg|gif|webp|bmp|tif|tiff) echo "image"; return ;;
  esac
  # Fallback: magic bytes
  local head_hex
  head_hex=$(head -c 4 "$file" 2>/dev/null | xxd -p 2>/dev/null || echo "")
  case "$head_hex" in
    25504446*) echo "pdf" ;;       # %PDF
    89504e47*) echo "image" ;;     # PNG
    ffd8ff*)   echo "image" ;;     # JPEG
    47494638*) echo "image" ;;     # GIF
    *)         echo "other" ;;
  esac
}

# PDF → PNG (first page) at a reasonable initial resolution.
# pdftoppm produces PREFIX-1.png (or PREFIX.png if single page and -singlefile).
# We use -singlefile to get a deterministic output path.
pdf_to_png() {
  local pdf="$1" out_prefix="$2" tool="$3"
  case "$tool" in
    pdftoppm)
      pdftoppm -png -singlefile -r 150 -f 1 -l 1 "$pdf" "$out_prefix" 2>/dev/null
      ;;
    sips)
      # sips --setProperty format png input.pdf --out output.png (macOS)
      sips -s format png "$pdf" --out "${out_prefix}.png" >/dev/null 2>&1
      ;;
    convert)
      convert -density 150 "${pdf}[0]" "${out_prefix}.png" 2>/dev/null
      ;;
    *) return 1 ;;
  esac
  [ -f "${out_prefix}.png" ]
}

# Downscale image to have long-edge ≤ MAX_PX via sips/convert. No-op if
# already smaller. Writes OUT_PATH.
downscale_png() {
  local in_path="$1" out_path="$2" max_px="$3" tool="$4"
  case "$tool" in
    sips)
      # sips --resampleHeightWidthMax N (long-edge resize)
      sips --resampleHeightWidthMax "$max_px" "$in_path" --out "$out_path" >/dev/null 2>&1
      ;;
    convert)
      # ImageMagick: resize keeps aspect, > only shrinks (no upscale)
      convert "$in_path" -resize "${max_px}x${max_px}>" "$out_path" 2>/dev/null
      ;;
    *) return 1 ;;
  esac
  [ -f "$out_path" ]
}

# ─── Extract ────────────────────────────────────────────────────────
extract_file() {
  local file="$1"
  [ -z "$file" ] && { echo "ERROR: --extract requires a file path" >&2; exit 1; }
  [ ! -f "$file" ] && { echo "ERROR: file not found: $file" >&2; exit 3; }

  # Probe first (JSON mode internally, same pattern as ollama-vlm
  # extract_file — see session-7 fix 2026-04-22 for why we force
  # FORMAT=json during the internal probe).
  local probe probe_status saved_format="$FORMAT"
  FORMAT=json
  probe=$(probe_pattern_b_phase1 2>/dev/null)
  FORMAT="$saved_format"
  probe_status=$(echo "$probe" | ruby -rjson -e 'puts JSON.parse(STDIN.read)["status"] rescue "probe_failed"' 2>/dev/null)

  if [ "$probe_status" != "ready" ]; then
    local hint
    hint=$(echo "$probe" | ruby -rjson -e 'puts JSON.parse(STDIN.read)["setup_hint"] rescue ""' 2>/dev/null)
    if [ "$FORMAT" = "text" ]; then
      echo "pattern_b_phase1_overview: backend status=$probe_status — cannot extract."
      echo "Hint: $hint"
    else
      ruby -rjson -e '
        puts JSON.pretty_generate({
          "backend" => "pattern_b_phase1_overview",
          "file"    => ARGV[0],
          "status"  => ARGV[1],
          "content" => nil,
          "error"   => "backend not ready — cannot extract",
          "hint"    => ARGV[2]
        })
      ' "$file" "$probe_status" "$hint"
    fi
    [ "$REQUIRE" = "1" ] && exit 2
    exit 0
  fi

  # Prepare scratch dir (trap for cleanup)
  local tmp
  tmp=$(mktemp -d 2>/dev/null || mktemp -d -t pattern-b-phase1)
  # shellcheck disable=SC2064
  trap "rm -rf '$tmp'" EXIT

  local kind
  kind=$(detect_file_kind "$file")
  local downscale_in downscale_out
  downscale_in="$tmp/src.png"
  downscale_out="$tmp/overview.png"

  case "$kind" in
    pdf)
      local pdf_tool raster_tool
      pdf_tool=$(pick_pdf_rasterizer)
      raster_tool=$(pick_raster_tool)
      if [ -z "$pdf_tool" ]; then
        emit_error "$file" "No PDF rasterizer available (pdftoppm / sips / convert). Install poppler-utils (brew install poppler / apt install poppler-utils)."
        exit 4
      fi
      if ! pdf_to_png "$file" "$tmp/src" "$pdf_tool"; then
        emit_error "$file" "PDF rasterization failed with tool=$pdf_tool. Check PDF is not encrypted/corrupted."
        exit 4
      fi
      if ! downscale_png "$downscale_in" "$downscale_out" "$MAX_PX" "$raster_tool"; then
        # No raster tool, or downscale failed — fall back to using the
        # direct rasterized output; it may be larger than MAX_PX but at
        # least it produced an image we can feed to VLM.
        cp "$downscale_in" "$downscale_out"
      fi
      ;;
    image)
      local raster_tool
      raster_tool=$(pick_raster_tool)
      if [ -z "$raster_tool" ]; then
        cp "$file" "$downscale_out"
      else
        if ! downscale_png "$file" "$downscale_out" "$MAX_PX" "$raster_tool"; then
          cp "$file" "$downscale_out"
        fi
      fi
      ;;
    *)
      emit_error "$file" "Unsupported file kind '$kind'. Pattern B Phase 1 handles PDF + common image formats (png/jpg/gif/webp/bmp/tif)."
      exit 4
      ;;
  esac

  if [ ! -f "$downscale_out" ]; then
    emit_error "$file" "Overview PNG missing after raster pipeline — unexpected internal failure."
    exit 4
  fi

  # Delegate to ollama_vlm for the actual vision call. Force JSON so we
  # can parse content reliably regardless of outer --format.
  local vlm_out vlm_content vlm_bytes overview_bytes
  vlm_out=$(bash "$SCRIPT_DIR/ollama-vlm.sh" \
    --extract "$downscale_out" \
    ${MODEL_OVERRIDE:+--model "$MODEL_OVERRIDE"} \
    --prompt "$OVERVIEW_PROMPT" \
    --format json 2>/dev/null)

  vlm_content=$(echo "$vlm_out" | ruby -rjson -e 'puts JSON.parse(STDIN.read)["content"] rescue ""' 2>/dev/null)
  vlm_bytes=$(echo "$vlm_out"   | ruby -rjson -e 'puts JSON.parse(STDIN.read)["bytes"].to_s' 2>/dev/null)
  overview_bytes=$(wc -c < "$downscale_out" 2>/dev/null | tr -d ' ')

  if [ -z "$vlm_content" ]; then
    emit_error "$file" "VLM returned no overview content. Check ollama_vlm --detect."
    exit 4
  fi

  if [ "$FORMAT" = "text" ]; then
    echo "$vlm_content"
    return 0
  fi

  ruby -rjson -e '
    puts JSON.pretty_generate({
      "backend"        => "pattern_b_phase1_overview",
      "file"           => ARGV[0],
      "status"         => "ready",
      "content"        => ARGV[1],
      "bytes"          => ARGV[2].to_i,
      "overview_png_bytes" => ARGV[3].to_i,
      "phase"          => "overview",
      "phases_covered" => ["overview"],
      "max_px"         => ARGV[4].to_i
    })
  ' "$file" "$vlm_content" "${vlm_bytes:-0}" "${overview_bytes:-0}" "$MAX_PX"
}

emit_error() {
  local file="$1" msg="$2"
  if [ "$FORMAT" = "text" ]; then
    echo "pattern_b_phase1_overview extract failed for $file: $msg"
  else
    ruby -rjson -e '
      puts JSON.pretty_generate({
        "backend" => "pattern_b_phase1_overview",
        "file"    => ARGV[0],
        "status"  => "extract_failed",
        "content" => nil,
        "error"   => ARGV[1]
      })
    ' "$file" "$msg"
  fi
}

case "$MODE" in
  detect)  probe_pattern_b_phase1 ;;
  extract) extract_file "$FILE" ;;
  *)       echo "ERROR: invalid mode" >&2; exit 1 ;;
esac
