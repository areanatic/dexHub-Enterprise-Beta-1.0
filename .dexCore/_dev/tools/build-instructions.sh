#!/usr/bin/env bash
# DexHub Build-Instructions (E2.3)
#
# Zweck: Compile Step — baut platform-native Instruction-Files aus SSOT.
# Input:  .dexCore/core/instructions/{SHARED,claude-specific,copilot-specific}.md
# Output: .github/copilot-instructions.md  (concatenation-based)
#         .claude/CLAUDE.md                 (@import-based, wenn Claude-native @import funktioniert)
#
# Modes:
#   build     — regenerate outputs (default)
#   check     — drift check only (exit 1 if outputs are stale)
#   dry-run   — show what would be built, no writes
#
# Usage:
#   ./.dexCore/_dev/tools/build-instructions.sh           # build
#   ./.dexCore/_dev/tools/build-instructions.sh check     # drift check (for CI/pre-commit)
#   ./.dexCore/_dev/tools/build-instructions.sh dry-run   # preview

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

SHARED="$REPO_ROOT/.dexCore/core/instructions/SHARED.md"
CLAUDE_TAIL="$REPO_ROOT/.dexCore/core/instructions/claude-specific.md"
COPILOT_TAIL="$REPO_ROOT/.dexCore/core/instructions/copilot-specific.md"

COPILOT_OUT="$REPO_ROOT/.github/copilot-instructions.md"
CLAUDE_OUT="$REPO_ROOT/.claude/CLAUDE.md"

# L1 Wiki injection (Phase 5.2.d wire — activates knowledge.l1_wiki_injection
# scaffold for each platform target). See .dexCore/_dev/docs/L1-WIKI-INJECTION.md.
# Per-platform size caps balance user-wiki room vs instruction-file budgets:
#   Copilot: 1000 bytes (tight — copilot-instructions.md has 30.5KB cap per validate §1)
#   Claude:  4096 bytes (more lenient — Claude context windows are larger)
# When the user wiki (myDex/.dex/wiki/) has no authored entries, load-wiki.sh
# outputs nothing — injection is a no-op. Drift-check accounts for this.
LOAD_WIKI="$REPO_ROOT/.dexCore/core/knowledge/load-wiki.sh"
WIKI_MAX_COPILOT=1000
WIKI_MAX_CLAUDE=4096

# L2 Tank injection (Phase 5.2.b-wire-copilot). Opt-in per user:
# if myDex/.dex/l2/copilot-seed-query.txt exists + non-empty, build-time
# query returns top-N chunks which get baked into copilot-instructions.md.
# When the seed file is absent or empty, L2 injection is silent (no change).
# Tank must also be initialized (tank.sqlite exists); otherwise silent.
L2_QUERY="$REPO_ROOT/.dexCore/core/knowledge/l2/l2-query.sh"
L2_TANK_DB="$REPO_ROOT/myDex/.dex/l2/tank.sqlite"
L2_SEED_FILE="$REPO_ROOT/myDex/.dex/l2/copilot-seed-query.txt"
L2_MAX_COPILOT=2000      # bytes — leaves headroom within 35KB copilot cap
L2_MAX_CLAUDE=4096       # more lenient for Claude
L2_TOP_N=3               # fewer but higher-quality chunks

MODE="${1:-build}"

# --- Validation ---
validate_inputs() {
  for f in "$SHARED" "$CLAUDE_TAIL" "$COPILOT_TAIL"; do
    if [ ! -f "$f" ]; then
      echo "FAIL: Source file missing: $f"
      exit 2
    fi
    if [ ! -s "$f" ]; then
      echo "FAIL: Source file empty: $f"
      exit 2
    fi
  done
}

# --- L1 Wiki block helper ---
# Invokes load-wiki.sh with the given size cap. Outputs empty on no entries.
wiki_block() {
  local max_total="$1"
  if [ -x "$LOAD_WIKI" ]; then
    bash "$LOAD_WIKI" --max-total "$max_total" --max-file 2048 2>/dev/null || true
  fi
}

# --- L2 Tank block helper ---
# Runs l2-query.sh with user's seed query (if configured). Returns empty
# unless all conditions met:
#   1. L2_SEED_FILE exists and has non-empty content
#   2. L2_TANK_DB exists (tank initialized)
#   3. l2-query.sh is executable
#   4. query returns at least one match
# Output is wrapped in a header marker so agents can recognize the L2
# section distinctly from L1 Wiki and main instruction content.
l2_block() {
  local max_total="$1"
  [ -x "$L2_QUERY" ] || return 0
  [ -f "$L2_TANK_DB" ] || return 0
  [ -f "$L2_SEED_FILE" ] || return 0

  local seed
  seed="$(head -c 500 "$L2_SEED_FILE" | tr -d '\n' | sed 's/^ *//; s/ *$//')"
  [ -z "$seed" ] && return 0

  # Run quiet query — no chrome, just the chunks. Cap total output bytes.
  local raw
  raw=$(bash "$L2_QUERY" --db "$L2_TANK_DB" --top "$L2_TOP_N" --quiet "$seed" 2>/dev/null || true)
  [ -z "$raw" ] && return 0

  # Truncate to max_total
  local size=${#raw}
  if [ "$size" -gt "$max_total" ]; then
    # Hard truncate at max_total with marker (avoid splitting mid-utf8 char)
    raw="$(printf '%s' "$raw" | head -c "$max_total")"$'\n\n[L2 TRUNCATED — exceeds '"$max_total"' byte cap]'
  fi

  # Emit wrapped block
  cat <<L2_HEADER

# ═══════════════════════════════════════════════════════════
# L2 TANK (retrieved for seed query: "$seed")
# Top-$L2_TOP_N chunks, $size bytes, baked at build time.
# ═══════════════════════════════════════════════════════════

L2_HEADER
  printf '%s' "$raw"
  cat <<L2_FOOTER


# ═══════════════════════════════════════════════════════════
# END L2 TANK
# ═══════════════════════════════════════════════════════════
L2_FOOTER
}

# --- Copilot Build (concatenation + optional L1 wiki append) ---
build_copilot() {
  local target="$1"
  mkdir -p "$(dirname "$target")"

  {
    echo "# GitHub Copilot Instructions for DexHub"
    echo ""
    echo "<!-- AUTOGENERATED from .dexCore/core/instructions/SHARED.md + copilot-specific.md -->"
    echo "<!--   + L1 Wiki (myDex/.dex/wiki/) injected via load-wiki.sh -->"
    echo "<!-- Do not edit directly. Edit the sources and run build-instructions.sh. -->"
    echo "<!-- Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ) -->"
    echo ""
    cat "$SHARED"
    echo ""
    cat "$COPILOT_TAIL"
    # L1 Wiki injection — appears before L2 because wiki is "always loaded"
    # (small, high-trust); L2 is "seed-query baked" (can be larger, more
    # context-specific). Both empty when no user content = no pollution.
    wiki_block "$WIKI_MAX_COPILOT"
    l2_block "$L2_MAX_COPILOT"
  } > "$target"
}

# --- Claude Build (concatenation + optional L1 wiki append) ---
# Note: Claude Code is an integration module per PLATFORM-POLICY.md — this output
# is present in dev but removed from enterprise builds by build-for-enterprise.sh.
build_claude_concat() {
  local target="$1"
  mkdir -p "$(dirname "$target")"

  {
    echo "# DexHub Enterprise - Claude Code Instructions"
    echo ""
    echo "<!-- AUTOGENERATED from .dexCore/core/instructions/SHARED.md + claude-specific.md -->"
    echo "<!--   + L1 Wiki (myDex/.dex/wiki/) injected via load-wiki.sh -->"
    echo "<!-- Do not edit directly. Edit the sources and run build-instructions.sh. -->"
    echo "<!-- Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ) -->"
    echo ""
    cat "$SHARED"
    echo ""
    cat "$CLAUDE_TAIL"
    # L1 Wiki + L2 Tank injection — Claude gets larger caps.
    wiki_block "$WIKI_MAX_CLAUDE"
    l2_block "$L2_MAX_CLAUDE"
  } > "$target"
}

# Note: @import-based Claude output (requires Claude A/B test pass):
# build_claude_import() {
#   cat > "$CLAUDE_OUT" <<EOF
# # DexHub Claude Code Instructions (via native @import)
# @../.dexCore/core/instructions/SHARED.md
# @../.dexCore/core/instructions/claude-specific.md
# EOF
# }

# --- Compute hash of generated content ---
# Strips the "Generated:" header comment line so the hash is stable.
content_hash() {
  local file="$1"
  [ -f "$file" ] || { echo ""; return; }
  grep -v '<!-- Generated:' "$file" | shasum -a 256 | cut -d' ' -f1
}

# --- Compute expected hash from sources ---
# Header comment lines MUST match the build functions exactly (minus the Generated:
# line which is excluded from the hash by content_hash() + here).
expected_hash_copilot() {
  {
    echo "# GitHub Copilot Instructions for DexHub"
    echo ""
    echo "<!-- AUTOGENERATED from .dexCore/core/instructions/SHARED.md + copilot-specific.md -->"
    echo "<!--   + L1 Wiki (myDex/.dex/wiki/) injected via load-wiki.sh -->"
    echo "<!-- Do not edit directly. Edit the sources and run build-instructions.sh. -->"
    echo ""
    cat "$SHARED"
    echo ""
    cat "$COPILOT_TAIL"
    wiki_block "$WIKI_MAX_COPILOT"
    l2_block "$L2_MAX_COPILOT"
  } | shasum -a 256 | cut -d' ' -f1
}

expected_hash_claude() {
  {
    echo "# DexHub Enterprise - Claude Code Instructions"
    echo ""
    echo "<!-- AUTOGENERATED from .dexCore/core/instructions/SHARED.md + claude-specific.md -->"
    echo "<!--   + L1 Wiki (myDex/.dex/wiki/) injected via load-wiki.sh -->"
    echo "<!-- Do not edit directly. Edit the sources and run build-instructions.sh. -->"
    echo ""
    cat "$SHARED"
    echo ""
    cat "$CLAUDE_TAIL"
    wiki_block "$WIKI_MAX_CLAUDE"
    l2_block "$L2_MAX_CLAUDE"
  } | shasum -a 256 | cut -d' ' -f1
}

# --- Main ---
case "$MODE" in
  dry-run)
    validate_inputs
    echo "=== DRY RUN ==="
    echo "Sources:"
    echo "  $SHARED ($(wc -l < "$SHARED") lines)"
    echo "  $CLAUDE_TAIL ($(wc -l < "$CLAUDE_TAIL") lines)"
    echo "  $COPILOT_TAIL ($(wc -l < "$COPILOT_TAIL") lines)"
    echo ""
    echo "Would write:"
    echo "  $COPILOT_OUT"
    echo "  $CLAUDE_OUT"
    echo ""
    echo "Expected Copilot content hash: $(expected_hash_copilot)"
    echo "Expected Claude content hash:  $(expected_hash_claude)"
    ;;

  check)
    validate_inputs
    DRIFT=0

    if [ ! -f "$COPILOT_OUT" ]; then
      echo "FAIL: $COPILOT_OUT missing"
      DRIFT=1
    else
      ACTUAL=$(content_hash "$COPILOT_OUT")
      EXPECTED=$(expected_hash_copilot)
      if [ "$ACTUAL" != "$EXPECTED" ]; then
        echo "DRIFT: $COPILOT_OUT is out of sync with sources"
        echo "  actual:   $ACTUAL"
        echo "  expected: $EXPECTED"
        DRIFT=1
      fi
    fi

    if [ ! -f "$CLAUDE_OUT" ]; then
      echo "FAIL: $CLAUDE_OUT missing"
      DRIFT=1
    else
      ACTUAL=$(content_hash "$CLAUDE_OUT")
      EXPECTED=$(expected_hash_claude)
      if [ "$ACTUAL" != "$EXPECTED" ]; then
        echo "DRIFT: $CLAUDE_OUT is out of sync with sources"
        echo "  actual:   $ACTUAL"
        echo "  expected: $EXPECTED"
        DRIFT=1
      fi
    fi

    if [ $DRIFT -eq 0 ]; then
      echo "OK: all generated instruction files are in sync with sources"
      exit 0
    else
      echo ""
      echo "Run: ./.dexCore/_dev/tools/build-instructions.sh"
      exit 1
    fi
    ;;

  build)
    validate_inputs
    echo "=== Build Instructions ==="

    # Idempotency (added 2026-04-25 — fixes Codex-noted timestamp-drift):
    # Build to a tmp file, hash-strip Generated: line, compare with existing
    # file's hash-stripped content. Only overwrite if content actually changed.
    # This prevents the "every build dirties .claude/CLAUDE.md timestamp"
    # behavior that confused users (Codex Befund 1 / B3 demoted to NTH).

    TMP_COPILOT=$(mktemp -t copilot-build.XXXXXX)
    build_copilot "$TMP_COPILOT"
    if [ -f "$COPILOT_OUT" ] && [ "$(content_hash "$TMP_COPILOT")" = "$(content_hash "$COPILOT_OUT")" ]; then
      echo "UNCHANGED: $COPILOT_OUT (content identical, timestamp not refreshed)"
    else
      mv "$TMP_COPILOT" "$COPILOT_OUT"
      echo "OK: $COPILOT_OUT ($(wc -l < "$COPILOT_OUT") lines)"
      TMP_COPILOT=""
    fi
    [ -n "$TMP_COPILOT" ] && rm -f "$TMP_COPILOT"

    TMP_CLAUDE=$(mktemp -t claude-build.XXXXXX)
    build_claude_concat "$TMP_CLAUDE"
    if [ -f "$CLAUDE_OUT" ] && [ "$(content_hash "$TMP_CLAUDE")" = "$(content_hash "$CLAUDE_OUT")" ]; then
      echo "UNCHANGED: $CLAUDE_OUT (content identical, timestamp not refreshed)"
    else
      mv "$TMP_CLAUDE" "$CLAUDE_OUT"
      echo "OK: $CLAUDE_OUT ($(wc -l < "$CLAUDE_OUT") lines)"
      TMP_CLAUDE=""
    fi
    [ -n "$TMP_CLAUDE" ] && rm -f "$TMP_CLAUDE"

    echo ""
    echo "Note: Claude uses concatenation (safe default). Switch to @import-based"
    echo "      build only after the A/B @import test passes (see A_B_TEST_IMPORT_PROCEDURE)."
    ;;

  *)
    echo "Usage: $0 [build|check|dry-run]"
    exit 2
    ;;
esac
