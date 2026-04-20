#!/usr/bin/env bash
# DexHub L2 Tank — Backend Detection
# ==========================================================
# Detects whether an embedding-capable backend is available on
# this machine. Safe to call anytime — no side effects, no DB
# writes, no network calls beyond a cheap Ollama /api/tags probe.
#
# This script is the graceful-degradation cornerstone: L2 Tank
# always works (keyword-only via FTS5); semantic search is opt-in
# and only activates when a backend is present. Users without
# Ollama see honest messaging explaining what they can do, not
# error noise.
#
# Feature: knowledge.l2_tank_backend_routing
# Phase:   5.2.b-embed-detect
#
# Usage:
#   bash l2-detect-backend.sh                # text output, human-readable
#   bash l2-detect-backend.sh --format json  # machine-parseable
#   bash l2-detect-backend.sh --quiet        # exit code only (0 always)
#
# Status field ∈ { "ready", "partial", "none", "blocked" }:
#   ready    — Ollama running + required model pulled + policy allows
#   partial  — Ollama running but model missing (user needs one `pull`)
#   none     — Ollama not installed or not running
#   blocked  — Policy forbids the configured backend (cloud backend +
#              data_handling_policy=local_only without override)
#
# Exit code: always 0. Status lives in the output, not the exit code —
# detection is informational, never an error.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"

FORMAT="text"
QUIET=0
# Default model — configurable via meta.default_embedding_backend in DB,
# but detect works without a DB. For model-pull check, we parse
# the backend string "<provider>/<model>" and check if <model> is listed.
DEFAULT_BACKEND="ollama/nomic-embed-text"

# Optional DB to read meta.default_embedding_backend from
DB=""
# Ollama endpoint — default is the canonical local daemon address.
# Overridable so tests and users with non-default Ollama installs can probe
# the right host. Also lets us simulate "no backend" in structural tests by
# pointing at an unreachable URL.
OLLAMA_ENDPOINT="http://localhost:11434"

while [ $# -gt 0 ]; do
  case "$1" in
    --format)   FORMAT="$2"; shift 2 ;;
    --quiet)    QUIET=1; shift ;;
    --db)       DB="$2"; shift 2 ;;
    --backend)  DEFAULT_BACKEND="$2"; shift 2 ;;
    --endpoint) OLLAMA_ENDPOINT="$2"; shift 2 ;;
    --help|-h)
      sed -n '2,34p' "${BASH_SOURCE[0]}"
      exit 0
      ;;
    *)
      echo "ERROR: unknown arg: $1" >&2
      exit 1
      ;;
  esac
done

# ─── Resolve backend (DB overrides default if DB given + reachable) ───
BACKEND="$DEFAULT_BACKEND"
if [ -n "$DB" ] && [ -f "$DB" ] && command -v sqlite3 >/dev/null 2>&1; then
  DB_BACKEND=$(sqlite3 "$DB" "SELECT value FROM meta WHERE key='default_embedding_backend'" 2>/dev/null || echo "")
  if [ -n "$DB_BACKEND" ]; then
    BACKEND="$DB_BACKEND"
  fi
fi

PROVIDER="${BACKEND%%/*}"
MODEL="${BACKEND#*/}"

# ─── Check Ollama availability ──────────────────────────────────────
OLLAMA_INSTALLED="false"
OLLAMA_RUNNING="false"
# OLLAMA_ENDPOINT set at the top from --endpoint argv or default
MODEL_PULLED="false"

if command -v ollama >/dev/null 2>&1; then
  OLLAMA_INSTALLED="true"
fi

# Probe the Ollama daemon only if we're asking about an Ollama backend.
# Cheap: GET /api/tags returns ~1KB or connection refused.
if [ "$PROVIDER" = "ollama" ] && [ "$OLLAMA_INSTALLED" = "true" ]; then
  if command -v curl >/dev/null 2>&1; then
    TAGS_JSON=$(curl -sS --max-time 2 "$OLLAMA_ENDPOINT/api/tags" 2>/dev/null || echo "")
    if [ -n "$TAGS_JSON" ]; then
      OLLAMA_RUNNING="true"
      # Check model presence in the returned list
      if echo "$TAGS_JSON" | grep -q "\"name\":\"${MODEL}\""; then
        MODEL_PULLED="true"
      elif echo "$TAGS_JSON" | grep -q "\"name\":\"${MODEL}:"; then
        # Tagged variant (e.g. "nomic-embed-text:latest")
        MODEL_PULLED="true"
      fi
    fi
  fi
fi

# ─── Resolve policy ─────────────────────────────────────────────────
PROFILE_FILE="$REPO_ROOT/myDex/.dex/config/profile.yaml"
POLICY="unset"
POLICY_SOURCE="no profile.yaml (assuming cloud_llm_allowed)"
if [ -f "$PROFILE_FILE" ]; then
  POLICY_SOURCE="profile.yaml"
  # Minimal YAML extraction — no yq dependency
  FOUND=$(grep -E "^[[:space:]]+data_handling_policy:" "$PROFILE_FILE" 2>/dev/null | head -1 || echo "")
  if [ -n "$FOUND" ]; then
    # Extract value after colon, strip quotes + whitespace
    POLICY=$(printf "%s" "$FOUND" | sed 's/.*data_handling_policy:[[:space:]]*//; s/["'\'']//g; s/[[:space:]]*$//')
  fi
fi
# Normalize: "null" or empty → unset
if [ "$POLICY" = "null" ] || [ -z "$POLICY" ]; then
  POLICY="unset"
fi

# ─── Determine backend policy compliance ────────────────────────────
# Ollama local = always allowed. Cloud backends (openai, anthropic) =
# blocked when policy=local_only.
POLICY_OK="true"
POLICY_NOTE=""
case "$PROVIDER" in
  ollama)
    POLICY_OK="true"
    POLICY_NOTE="local backend — always allowed"
    ;;
  openai|anthropic)
    case "$POLICY" in
      local_only|lan_only)
        POLICY_OK="false"
        POLICY_NOTE="cloud backend blocked under policy '$POLICY'"
        ;;
      *)
        POLICY_OK="true"
        POLICY_NOTE="cloud backend allowed under policy '$POLICY'"
        ;;
    esac
    ;;
  *)
    POLICY_OK="true"
    POLICY_NOTE="unknown provider — assuming allowed"
    ;;
esac

# ─── Compute overall status ─────────────────────────────────────────
STATUS="none"
SEMANTIC_AVAILABLE="false"
SETUP_HINT=""

if [ "$POLICY_OK" = "false" ]; then
  STATUS="blocked"
  SETUP_HINT="Switch to ollama/<local-model> or change profile.company.data_handling_policy"
elif [ "$PROVIDER" = "ollama" ]; then
  if [ "$OLLAMA_INSTALLED" = "false" ]; then
    STATUS="none"
    SETUP_HINT="Install Ollama (https://ollama.com), then: ollama pull $MODEL"
  elif [ "$OLLAMA_RUNNING" = "false" ]; then
    STATUS="none"
    SETUP_HINT="Start Ollama: ollama serve (or open the Ollama app), then: ollama pull $MODEL"
  elif [ "$MODEL_PULLED" = "false" ]; then
    STATUS="partial"
    SETUP_HINT="ollama pull $MODEL  (~137 MB for nomic-embed-text, one-time)"
  else
    STATUS="ready"
    SEMANTIC_AVAILABLE="true"
    SETUP_HINT="Backend ready. Run l2-embed.sh to populate embeddings."
  fi
else
  # Non-Ollama providers (openai, anthropic, …) — real implementation
  # lives in 5.2.b-enterprise-audit + future cloud-backend slices.
  STATUS="deferred"
  SETUP_HINT="Cloud-backend path not implemented yet. For Beta 1.0, use ollama/nomic-embed-text (local, privacy-preserving)."
fi

# ─── Output ─────────────────────────────────────────────────────────
if [ "$QUIET" = "1" ]; then
  exit 0
fi

if [ "$FORMAT" = "json" ]; then
  cat <<EOF
{
  "backend": "$BACKEND",
  "provider": "$PROVIDER",
  "model": "$MODEL",
  "ollama_installed": $OLLAMA_INSTALLED,
  "ollama_running": $OLLAMA_RUNNING,
  "ollama_endpoint": "$OLLAMA_ENDPOINT",
  "model_pulled": $MODEL_PULLED,
  "policy": "$POLICY",
  "policy_source": "$POLICY_SOURCE",
  "policy_ok": $POLICY_OK,
  "policy_note": "$POLICY_NOTE",
  "status": "$STATUS",
  "semantic_available": $SEMANTIC_AVAILABLE,
  "setup_hint": "$SETUP_HINT"
}
EOF
  exit 0
fi

# Text output
echo "L2 Tank — Backend Detection"
echo "==========================="
echo ""
echo "  Backend:         $BACKEND"
if [ "$PROVIDER" = "ollama" ]; then
  if [ "$OLLAMA_INSTALLED" = "false" ]; then
    echo "  Ollama:          NOT INSTALLED"
  elif [ "$OLLAMA_RUNNING" = "false" ]; then
    echo "  Ollama:          installed, daemon NOT RUNNING"
  else
    echo "  Ollama:          installed + daemon running at $OLLAMA_ENDPOINT"
  fi
  if [ "$MODEL_PULLED" = "true" ]; then
    echo "  Model:           $MODEL (pulled)"
  else
    echo "  Model:           $MODEL (NOT PULLED)"
  fi
else
  echo "  Provider:        $PROVIDER (non-local)"
  echo "  Model:           $MODEL"
fi
echo "  Policy:          $POLICY  (source: $POLICY_SOURCE)"
echo "  Compliance:      $POLICY_NOTE"
echo ""
echo "  Status:          $(echo "$STATUS" | tr '[:lower:]' '[:upper:]')"
if [ "$SEMANTIC_AVAILABLE" = "true" ]; then
  echo "  Semantic search: AVAILABLE"
else
  echo "  Semantic search: not available (keyword-only)"
fi
echo ""
if [ -n "$SETUP_HINT" ]; then
  echo "  Next step:       $SETUP_HINT"
  echo ""
fi
echo "  Keyword search (BM25) works regardless — L2 Tank always provides"
echo "  keyword-only query via l2-query.sh, no install required."
