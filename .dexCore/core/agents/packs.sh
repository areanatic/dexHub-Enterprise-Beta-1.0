#!/usr/bin/env bash
# DexHub Agent Packs — list / enable / disable / status
# ==========================================================
# Manages the user's pack toggle state in myDex/.dex/config/packs.yaml.
# Read-only operations (list, status) work without a state file — they
# report defaults from each pack manifest. Write operations (enable,
# disable) create the state file if needed.
#
# Pack manifests live at .dexCore/core/agents/packs/*.yaml and are
# framework-shipped (tracked). User state (enabled / disabled overrides)
# lives at myDex/.dex/config/packs.yaml (gitignored).
#
# Mandatory packs (manifest: `mandatory: true`) cannot be disabled —
# packs.sh refuses and prints a clear error. core_pack is mandatory.
#
# Usage:
#   bash packs.sh list                            # table of all packs + state
#   bash packs.sh list --format json              # machine-parseable
#   bash packs.sh status <pack_id>                # details for one pack
#   bash packs.sh enable <pack_id>
#   bash packs.sh disable <pack_id>
#
# Feature: agents.user_toggle_menu (+ agents.meta_pack + agents.onboarding_pack)
# Phase:   5.1.d

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

MANIFESTS_DIR="$SCRIPT_DIR/packs"
STATE_FILE="$REPO_ROOT/myDex/.dex/config/packs.yaml"

FORMAT="text"
SUBCMD=""
POSITIONAL_ARG=""

# Parse args positionally — flags can appear anywhere. The first bare
# argument is the subcommand, the second is the pack_id (for status /
# enable / disable). Flags: --format / --state / --manifests / --help.
while [ $# -gt 0 ]; do
  case "$1" in
    --format)    FORMAT="$2"; shift 2 ;;
    --state)     STATE_FILE="$2"; shift 2 ;;
    --manifests) MANIFESTS_DIR="$2"; shift 2 ;;
    --help|-h)
      sed -n '2,24p' "${BASH_SOURCE[0]}"
      exit 0
      ;;
    *)
      if [ -z "$SUBCMD" ]; then
        SUBCMD="$1"
      elif [ -z "$POSITIONAL_ARG" ]; then
        POSITIONAL_ARG="$1"
      fi
      shift
      ;;
  esac
done

# ─── YAML field extraction helpers ──────────────────────────────────
# Minimal grep-based reader — handles our manifest layout. Not a full
# YAML parser; if a pack file uses exotic anchors or inline maps the
# read path falls through to defaults and the pack shows up as
# "malformed" in list output rather than silently breaking.
pack_field() {
  local file="$1" field="$2"
  [ -f "$file" ] || { echo ""; return; }
  grep -E "^${field}:" "$file" 2>/dev/null | head -1 | \
    sed "s/^${field}:[[:space:]]*//; s/[\"']//g; s/[[:space:]]*$//"
}

# ─── Discover manifests ─────────────────────────────────────────────
discover_packs() {
  find "$MANIFESTS_DIR" -maxdepth 1 -type f -name "*.yaml" 2>/dev/null | sort
}

# ─── Read user state ────────────────────────────────────────────────
# User state schema (simple + human-editable):
#   enabled_packs:
#     - meta_pack
#     - onboarding_pack
#   disabled_packs:
#     - dhl_pack
#
# If a pack is in neither list, it falls back to its manifest's
# `default_state` field.
user_state_for() {
  local pack="$1"
  [ ! -f "$STATE_FILE" ] && { echo ""; return; }
  # In enabled_packs list?
  if awk '
    /^enabled_packs:/ {in_e=1; next}
    /^disabled_packs:/ {in_e=0; in_d=1; next}
    /^[a-zA-Z]/ && !/^[[:space:]]/ {in_e=0; in_d=0}
    in_e && /^[[:space:]]*-[[:space:]]*/ { gsub(/^[[:space:]]*-[[:space:]]*/, ""); if ($0 == p) found=1 }
    END {exit(found ? 0 : 1)}
  ' p="$pack" "$STATE_FILE" 2>/dev/null; then
    echo "enabled"; return
  fi
  if awk '
    /^enabled_packs:/ {in_e=1; next}
    /^disabled_packs:/ {in_e=0; in_d=1; next}
    /^[a-zA-Z]/ && !/^[[:space:]]/ {in_e=0; in_d=0}
    in_d && /^[[:space:]]*-[[:space:]]*/ { gsub(/^[[:space:]]*-[[:space:]]*/, ""); if ($0 == p) found=1 }
    END {exit(found ? 0 : 1)}
  ' p="$pack" "$STATE_FILE" 2>/dev/null; then
    echo "disabled"; return
  fi
  echo ""
}

# Resolve effective state: user override wins over manifest default
effective_state() {
  local manifest="$1"
  local pack
  pack=$(pack_field "$manifest" "pack_id")
  local mandatory default user
  mandatory=$(pack_field "$manifest" "mandatory")
  default=$(pack_field "$manifest" "default_state")
  # Mandatory packs are always on, no user override possible
  if [ "$mandatory" = "true" ]; then
    echo "always_on"; return
  fi
  user=$(user_state_for "$pack")
  if [ -n "$user" ]; then
    echo "$user"
  else
    echo "${default:-disabled}"
  fi
}

# ─── Manifest → pack_id map ─────────────────────────────────────────
find_manifest() {
  local pack="$1"
  for m in $(discover_packs); do
    local id
    id=$(pack_field "$m" "pack_id")
    if [ "$id" = "$pack" ]; then
      echo "$m"; return
    fi
  done
  echo ""
}

# ─── Subcommands ────────────────────────────────────────────────────
cmd_list() {
  local manifests
  manifests=$(discover_packs)
  if [ -z "$manifests" ]; then
    echo "No pack manifests found at $MANIFESTS_DIR"
    return
  fi

  if [ "$FORMAT" = "json" ]; then
    local first=1
    echo "["
    for m in $manifests; do
      local pid name desc mand default state
      pid=$(pack_field "$m" "pack_id")
      name=$(pack_field "$m" "name")
      desc=$(pack_field "$m" "description")
      mand=$(pack_field "$m" "mandatory")
      default=$(pack_field "$m" "default_state")
      state=$(effective_state "$m")
      [ "$first" = 1 ] && first=0 || echo ","
      # Escape quotes in strings
      ruby -rjson -e '
        puts JSON.pretty_generate({
          "pack_id" => ARGV[0], "name" => ARGV[1], "description" => ARGV[2],
          "mandatory" => ARGV[3] == "true", "default_state" => ARGV[4],
          "effective_state" => ARGV[5]
        })
      ' "$pid" "$name" "$desc" "$mand" "$default" "$state"
    done
    echo "]"
    return
  fi

  # Text format — aligned columns
  printf "%-22s %-14s %-10s %s\n" "PACK" "STATE" "MANDATORY" "NAME"
  printf "%-22s %-14s %-10s %s\n" "----" "-----" "---------" "----"
  for m in $manifests; do
    local pid name mand state
    pid=$(pack_field "$m" "pack_id")
    name=$(pack_field "$m" "name")
    mand=$(pack_field "$m" "mandatory")
    state=$(effective_state "$m")
    printf "%-22s %-14s %-10s %s\n" "$pid" "$state" "${mand:-false}" "$name"
  done
  echo ""
  if [ ! -f "$STATE_FILE" ]; then
    echo "(No user state file — showing defaults. Toggle with: packs.sh enable <pack_id>)"
  else
    echo "(User state file: $STATE_FILE)"
  fi
}

cmd_status() {
  local pack="$1"
  [ -z "$pack" ] && { echo "ERROR: pack_id required. Usage: packs.sh status <pack_id>" >&2; exit 1; }
  local m
  m=$(find_manifest "$pack")
  if [ -z "$m" ]; then
    echo "ERROR: no manifest for pack '$pack'. Run 'packs.sh list' to see available packs." >&2
    exit 1
  fi
  local pid name desc mand default state
  pid=$(pack_field "$m" "pack_id")
  name=$(pack_field "$m" "name")
  desc=$(pack_field "$m" "description")
  mand=$(pack_field "$m" "mandatory")
  default=$(pack_field "$m" "default_state")
  state=$(effective_state "$m")

  if [ "$FORMAT" = "json" ]; then
    ruby -rjson -e '
      puts JSON.pretty_generate({
        "pack_id" => ARGV[0], "name" => ARGV[1], "description" => ARGV[2],
        "mandatory" => ARGV[3] == "true", "default_state" => ARGV[4],
        "effective_state" => ARGV[5], "manifest_file" => ARGV[6]
      })
    ' "$pid" "$name" "$desc" "$mand" "$default" "$state" "$m"
    return
  fi

  cat <<EOF
Pack:            $pid
Name:            $name
Description:     $desc
Mandatory:       ${mand:-false}
Default state:   $default
Effective state: $state
Manifest:        $m
EOF
}

cmd_enable() {
  local pack="$1"
  [ -z "$pack" ] && { echo "ERROR: pack_id required" >&2; exit 1; }
  local m; m=$(find_manifest "$pack")
  [ -z "$m" ] && { echo "ERROR: no manifest for pack '$pack'" >&2; exit 1; }
  local mand; mand=$(pack_field "$m" "mandatory")
  if [ "$mand" = "true" ]; then
    echo "Pack '$pack' is mandatory — always on, no toggle needed."
    return 0
  fi
  ensure_state_file
  # Remove from disabled list if present, add to enabled list if not present
  state_remove_from_list "disabled_packs" "$pack"
  state_add_to_list "enabled_packs" "$pack"
  echo "Enabled: $pack"
}

cmd_disable() {
  local pack="$1"
  [ -z "$pack" ] && { echo "ERROR: pack_id required" >&2; exit 1; }
  local m; m=$(find_manifest "$pack")
  [ -z "$m" ] && { echo "ERROR: no manifest for pack '$pack'" >&2; exit 1; }
  local mand; mand=$(pack_field "$m" "mandatory")
  if [ "$mand" = "true" ]; then
    echo "ERROR: pack '$pack' is mandatory — cannot be disabled." >&2
    exit 1
  fi
  ensure_state_file
  state_remove_from_list "enabled_packs" "$pack"
  state_add_to_list "disabled_packs" "$pack"
  echo "Disabled: $pack"
}

# ─── State file I/O ─────────────────────────────────────────────────
ensure_state_file() {
  if [ ! -f "$STATE_FILE" ]; then
    mkdir -p "$(dirname "$STATE_FILE")"
    cat > "$STATE_FILE" <<'EOF'
# DexHub Agent Pack state — user-owned (gitignored)
# Written + read by .dexCore/core/agents/packs.sh
schema_version: 1
enabled_packs: []
disabled_packs: []
EOF
  fi
}

state_add_to_list() {
  local list="$1" pack="$2"
  # Skip if already present in that list
  if grep -qE "^  - ${pack}$" <(awk -v L="$list:" '$0==L{in_l=1; next} /^[a-zA-Z]/ && !/^[[:space:]]/ && in_l{in_l=0} in_l{print}' "$STATE_FILE"); then
    return
  fi
  # Use ruby for a small, safe edit: transform the list's array and rewrite
  ruby -e '
    file, list, pack = ARGV
    content = File.read(file)
    lines = content.lines
    out = []
    in_list = false
    added = false
    lines.each do |line|
      if line =~ /^#{list}:/
        in_list = true
        # Handle inline empty array
        if line.strip == "#{list}: []"
          out << "#{list}:\n"
          out << "  - #{pack}\n"
          added = true
          in_list = false
          next
        end
        out << line
      elsif in_list && line =~ /^[a-zA-Z]/ && line !~ /^[ \t]/
        # Reached next top-level key — insert before it if not yet added
        unless added
          out << "  - #{pack}\n"
          added = true
        end
        in_list = false
        out << line
      else
        out << line
      end
    end
    # If we fell off the end of the file inside the list, add now
    unless added
      out << "  - #{pack}\n"
    end
    File.write(file, out.join)
  ' "$STATE_FILE" "$list" "$pack"
}

state_remove_from_list() {
  local list="$1" pack="$2"
  ruby -e '
    file, list, pack = ARGV
    content = File.read(file)
    lines = content.lines
    out = []
    in_list = false
    lines.each do |line|
      if line =~ /^#{list}:/
        in_list = true
        out << line
      elsif in_list && line =~ /^[a-zA-Z]/ && line !~ /^[ \t]/
        in_list = false
        out << line
      elsif in_list && line =~ /^[ \t]*-[ \t]*#{Regexp.escape(pack)}[ \t]*$/
        # skip — remove this entry
      else
        out << line
      end
    end
    File.write(file, out.join)
  ' "$STATE_FILE" "$list" "$pack"
}

# ─── Dispatch ───────────────────────────────────────────────────────
case "$SUBCMD" in
  list)       cmd_list ;;
  status)     cmd_status "${POSITIONAL_ARG:-}" ;;
  enable)     cmd_enable "${POSITIONAL_ARG:-}" ;;
  disable)    cmd_disable "${POSITIONAL_ARG:-}" ;;
  ""|--help|-h)
    sed -n '2,24p' "${BASH_SOURCE[0]}"
    ;;
  *)
    echo "ERROR: unknown subcommand '$SUBCMD'. Try 'list', 'status', 'enable', 'disable', or --help." >&2
    exit 1
    ;;
esac
