#!/usr/bin/env bash
# DexHub Parser — capabilities probe (parser.guided_setup_wizard)
# ==========================================================
# Probes every registered backend adapter via its --detect mode and
# writes / merges the result into myDex/.dex/config/capabilities.yaml.
# This is the "wizard plumbing" — the conversational wrapper (the
# *parser-setup DexMaster menu entry) is a follow-up slice that calls
# this script under the hood.
#
# Why a probe script exists: before this slice, users had to hand-edit
# capabilities.yaml (copy the .example template → edit installed flags
# per backend → re-edit on every install change). Two known_issues
# flagged this on kreuzberg + ollama_vlm adapters:
#   "Router decides 'backend=X' when capabilities.yaml declares
#    installed=true; it does NOT yet auto-probe via the adapter's
#    --detect. That unification is a natural follow-up slice — most
#    valuable once guided_setup_wizard (5.3.g) automates
#    capabilities.yaml maintenance."
# This script ships the automation.
#
# Registered backends (first-slice scope):
#   - kreuzberg       → .dexCore/core/parser/backends/kreuzberg.sh
#   - ollama_vlm      → .dexCore/core/parser/backends/ollama-vlm.sh
# Add more backends here as adapters land (pattern_a, cloud OCR, …).
#
# Feature: parser.guided_setup_wizard
# Phase:   5.3.g (first slice — probe + write. Chat-wrapper is future.)
#
# Usage:
#   bash capabilities-probe.sh                   # probe + write default path
#   bash capabilities-probe.sh --dry-run         # probe + print, no write
#   bash capabilities-probe.sh --format json     # per-backend probe JSON
#   bash capabilities-probe.sh --format text     # human-readable (default when TTY)
#   bash capabilities-probe.sh --out FILE.yaml   # write alternate path
#   bash capabilities-probe.sh --backend kreuzberg  # probe one only
#
# Exit codes:
#   0  success (whether all backends ready, none ready, or mixed — probe
#      is informational)
#   1  bad args
#   2  ruby not available (required for safe YAML merge)

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
BACKENDS_DIR="$SCRIPT_DIR/backends"
DEFAULT_OUT="$REPO_ROOT/myDex/.dex/config/capabilities.yaml"

OUT="$DEFAULT_OUT"
DRY_RUN=0
FORMAT=""
ONLY_BACKEND=""

# Known adapters — extend this list as new backends ship. Each entry
# pairs a backend id (matches features.yaml parser.<id>_backend + the
# key under capabilities.yaml parser.backends.<id>) with the adapter
# script filename under backends/.
KNOWN_BACKENDS=(
  "kreuzberg:kreuzberg.sh"
  "ollama_vlm:ollama-vlm.sh"
  "pattern_a_vector_text:pattern-a-vector-text.sh"
  "pattern_b_phase1_overview:pattern-b-phase1-overview.sh"
)

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --format)  FORMAT="$2"; shift 2 ;;
    --out)     OUT="$2"; shift 2 ;;
    --backend) ONLY_BACKEND="$2"; shift 2 ;;
    --help|-h)
      sed -n '2,35p' "${BASH_SOURCE[0]}"
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

command -v ruby >/dev/null 2>&1 || {
  echo "ERROR: ruby not installed (required for safe YAML merge)" >&2
  exit 2
}

# Default format: text if TTY, json otherwise
if [ -z "$FORMAT" ]; then
  if [ -t 1 ]; then FORMAT="text"; else FORMAT="json"; fi
fi

# ─── Probe each backend via its adapter --detect ────────────────────
probe_backend() {
  local id="$1" adapter="$2"
  local adapter_path="$BACKENDS_DIR/$adapter"
  if [ ! -x "$adapter_path" ]; then
    # Emit a synthetic JSON so merge logic can still work — but flag it
    ruby -rjson -e '
      puts JSON.generate({
        "backend"    => ARGV[0],
        "status"     => "adapter_missing",
        "version"    => nil,
        "compliance" => "unknown",
        "setup_hint" => "Adapter script not executable at " + ARGV[1]
      })
    ' "$id" "$adapter_path"
    return
  fi

  bash "$adapter_path" --detect --format json 2>/dev/null || {
    # Adapter crashed — synthesize
    ruby -rjson -e '
      puts JSON.generate({
        "backend"    => ARGV[0],
        "status"     => "probe_failed",
        "version"    => nil,
        "compliance" => "unknown",
        "setup_hint" => "Adapter crashed during --detect"
      })
    ' "$id"
  }
}

# Collect probe results into a single JSON array (one entry per backend)
PROBE_RESULTS="[]"
for entry in "${KNOWN_BACKENDS[@]}"; do
  id="${entry%%:*}"
  adapter="${entry#*:}"
  if [ -n "$ONLY_BACKEND" ] && [ "$ONLY_BACKEND" != "$id" ]; then
    continue
  fi
  result=$(probe_backend "$id" "$adapter")
  PROBE_RESULTS=$(printf '%s' "$PROBE_RESULTS" | ruby -rjson -e '
    arr = JSON.parse(STDIN.read) rescue []
    arr << JSON.parse(ARGV[0]) rescue nil
    puts JSON.generate(arr)
  ' "$result")
done

# ─── Format: emit probe results to stdout ───────────────────────────
if [ "$FORMAT" = "json" ]; then
  printf '%s' "$PROBE_RESULTS" | ruby -rjson -e 'puts JSON.pretty_generate(JSON.parse(STDIN.read))'
else
  printf '%s\n' "DexHub Parser — Capability Probe"
  printf '%s\n' "================================="
  printf "\n"
  printf '%-16s %-14s %-30s %s\n' "BACKEND" "STATUS" "VERSION" "HINT"
  printf '%-16s %-14s %-30s %s\n' "-------" "------" "-------" "----"
  printf '%s' "$PROBE_RESULTS" | ruby -rjson -e '
    JSON.parse(STDIN.read).each do |r|
      ver = r["version"].to_s
      ver = ver[0..27] + "…" if ver.length > 28
      hint = r["setup_hint"].to_s
      hint = hint[0..60] + "…" if hint.length > 60
      printf "%-16s %-14s %-30s %s\n",
        r["backend"].to_s[0..15],
        r["status"].to_s[0..13],
        ver,
        hint
    end
  '
  printf "\n"
fi

# ─── Write / merge capabilities.yaml ────────────────────────────────
# Never blindly overwrite. Read existing file, MERGE the probe results
# (update installed/version fields; preserve notes/preferences).
# If file doesn't exist, synthesize from the probe results.

if [ "$DRY_RUN" = "1" ]; then
  # Write the advisory message to STDERR so stdout stays clean
  # (JSON output must be parseable by downstream tools without needing
  # a post-filter for trailing human-prose).
  printf '%s\n' "(dry-run — no write to $OUT)" >&2
  exit 0
fi

# Compute the new YAML via ruby (minimal, dependency-free — no yq)
mkdir -p "$(dirname "$OUT")"

NEW_YAML=$(printf '%s' "$PROBE_RESULTS" | ruby -rjson -ryaml -e '
  probe_results = JSON.parse(STDIN.read)
  out_path = ARGV[0]

  # Load existing file via ruby stdlib YAML (Psych). Replaces the old
  # line-based parser that stripped ALL quote characters — including
  # internal ones in user-edited notes. Upgrading to a real YAML parser
  # (shipped 2026-04-21 session-7 TODO #5) fixes the known limitation
  # documented on parser.guided_setup_wizard: hand-edited notes can now
  # contain quote marks, apostrophes, colons, or any other YAML-string
  # characters and round-trip cleanly across re-probes.
  #
  # Emit remains line-based (structured deterministic output with
  # sentinel comments) — YAML.dump would not preserve the header/
  # auto-maintained comments and would reorder keys.
  existing_backends = {}
  preferences_block = ""
  if File.file?(out_path)
    begin
      # YAML.safe_load(File.read(...)) rather than safe_load_file:
      # Psych::safe_load_file was added in Psych 3.1 and isnt present
      # on older rubies (including the stock macOS Ruby 2.6). Feeding
      # File.read output is portable and semantically identical.
      loaded = YAML.safe_load(File.read(out_path), aliases: true) || {}
      backends = loaded.dig("parser", "backends")
      if backends.is_a?(Hash)
        backends.each do |id, fields|
          next unless fields.is_a?(Hash)
          existing_backends[id.to_s] = {}
          fields.each do |k, v|
            existing_backends[id.to_s][k.to_s] = v.nil? ? nil : v.to_s
          end
        end
      end
      prefs = loaded.dig("parser", "preferences")
      if prefs.is_a?(Hash)
        pref_lines = ["  preferences:"]
        prefs.each do |k, v|
          val_str =
            if v.nil?
              "null"
            elsif v == true || v == false || v.is_a?(Numeric)
              v.to_s
            else
              # strings get quoted to survive round-trip stable
              v.to_s.inspect
            end
          pref_lines << "    #{k}: #{val_str}"
        end
        preferences_block = pref_lines.join("\n") + "\n"
      end
    rescue => e
      # Malformed / unsafe / version-incompatible YAML — treat as empty
      # and let the probe rebuild from scratch. Same failure-mode as the
      # old line-based parser: exotic input → defaults. Rescue is broad
      # by design (covers Psych::SyntaxError, Psych::DisallowedClass, and
      # older-Ruby NoMethodError on newer APIs).
      existing_backends = {}
      preferences_block = ""
    end
  end

  # Merge: probe result updates installed + version + compliance.
  # Store values UNQUOTED here (the loader above also strips quotes so
  # round-tripping is consistent). Quoting is applied at emit time for
  # fields that need it — see the emit loop below. This avoids the 2026-04-22
  # idempotency bug where notes drifted from quoted → unquoted across
  # re-probes because init-time quotes got stripped by the loader but
  # emit-time did not re-quote.
  probe_results.each do |r|
    id = r["backend"]
    existing_backends[id] ||= {}
    existing_backends[id]["installed"]  = (r["status"] == "ready") ? "true" : "false"
    existing_backends[id]["version"]    = r["version"].nil? || r["version"].to_s.empty? ? "null" : r["version"].to_s
    existing_backends[id]["compliance"] = r["compliance"] || "ok"
    existing_backends[id]["last_probe"] = Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ")
    existing_backends[id]["probe_status"] = r["status"].to_s
    existing_backends[id]["notes"] ||= "Auto-generated by capabilities-probe.sh."
  end

  # Emit YAML — minimal + human-editable
  out = []
  out << "# DexHub Parser — capabilities.yaml"
  out << "# ==========================================================="
  out << "# Auto-maintained by .dexCore/core/parser/capabilities-probe.sh"
  out << "# Last probe: #{Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ")}"
  out << "#"
  out << "# Hand-editable: your notes + preferences are preserved across"
  out << "# re-probes. installed/version/compliance/last_probe/probe_status"
  out << "# are owned by the probe script."
  out << ""
  out << "schema_version: \"1\""
  out << ""
  out << "parser:"
  out << "  backends:"
  # Fields that need YAML-string quoting at emit time (to survive the
  # load-step quote-strip and stay byte-identical across re-probes).
  # installed + compliance are plain YAML identifiers (true/false/ok/…)
  # and stay unquoted. version is unquoted when "null", quoted otherwise.
  quoted_fields = %w[last_probe probe_status notes]
  existing_backends.each do |id, fields|
    out << "    #{id}:"
    ["installed", "version", "compliance", "last_probe", "probe_status", "notes"].each do |k|
      v = fields[k]
      next if v.nil?
      if quoted_fields.include?(k) || (k == "version" && v.to_s != "null")
        # .inspect adds surrounding quotes and escapes internal quotes
        v_out = v.to_s.inspect
      else
        v_out = v.to_s
      end
      out << "      #{k}: #{v_out}"
    end
    out << ""
  end
  if preferences_block.empty?
    out << "  preferences:"
    out << "    default_pdf_backend: null"
    out << "    default_image_backend: null"
    out << "    prefer_native_fallback: true"
  else
    out << preferences_block.rstrip
  end
  puts out.join("\n")
' "$OUT")

# Write atomically: tmp + mv
TMP=$(mktemp -t dexhub-caps-XXXXXX).yaml
trap 'rm -f "$TMP"' EXIT INT TERM
printf '%s\n' "$NEW_YAML" > "$TMP"

# If the existing file has content identical to new output, skip rewrite
if [ -f "$OUT" ] && cmp -s "$TMP" "$OUT"; then
  printf '%s\n' "capabilities.yaml unchanged (no writes)" >&2
else
  mv "$TMP" "$OUT"
  printf '%s\n' "capabilities.yaml updated → $OUT" >&2
fi
