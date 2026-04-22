# Live-Verification Status — DexHub Enterprise Beta 1.0

**Stand:** 2026-04-22 Session 10 Phase 5

This document tracks which behavioral (live-runtime) paths have been verified against real backends / tokens / models — vs. which still rely purely on structural tests (bash parse, JSON shape, dependency presence) and would benefit from a live run.

## Why two tiers

DexHub's test harness runs in **two modes**:

- **Tier 1 — Structural (always-green in CI):** files exist, scripts parse, config is valid YAML, dependencies are declared, JSON outputs have the right shape. No network, no paid API calls, no model loads. This is what `tests/e2e/run-all.sh` runs by default.

- **Tier 5 — Behavioral / Live (opt-in via `CLAUDE_E2E_LIVE_*` env vars):** actually call Ollama, actually parse a PDF with kreuzberg, actually run a multi-turn onboarding walkthrough with a real LLM. Costs time and sometimes tokens; requires dependencies installed on the test runner.

Tier 1 proves "the code is wired together and parses". Tier 5 proves "the thing works in the real world on this machine". Both matter.

## Current status (2026-04-22 Beta 1.0)

| Live Path | Env Var | Needs | Status | Last Verified |
|---|---|---|---|---|
| **L2 Tank Embed** (semantic embeddings via Ollama/nomic) | `CLAUDE_E2E_LIVE_EMBED=1` | Ollama daemon + `nomic-embed-text` model pulled | ✅ **21/21 PASS** | 2026-04-22 (session 10 Phase 5, re-verified after session-7 fix) |
| **L2 Tank Hybrid Query** (BM25+cosine semantic routing) | `CLAUDE_E2E_LIVE_EMBED=1` | Same as above + Ruby | ✅ **20/20 PASS** | 2026-04-22 (session 10 Phase 5) |
| **Kreuzberg Backend** (PDF/Office parser live) | `CLAUDE_E2E_LIVE_KREUZBERG=1` | `brew install kreuzberg-dev/tap/kreuzberg` (~100 MB) | ⚠️ **Structural PASS; behavioral pending** | — (not installed on current runner) |
| **Ollama VLM Backend** (Vision-LLM image parse) | `CLAUDE_E2E_LIVE_VLM=1` | Ollama daemon + vision model (`ollama pull moondream` ~1.7 GB, or `llava:7b` ~4.7 GB, or `llama3.2-vision` ~7.8 GB) | ⚠️ **Structural PASS; behavioral pending** | — (no vision model pulled; `llama3.2:1b` present is NOT a vision model) |
| **Pattern A — vector-text** (poppler pdftotext for text-layer PDFs) | `CLAUDE_E2E_LIVE_PATTERN_A=1` | `brew install poppler` (~10 MB) | ⚠️ **Structural PASS; behavioral pending** | — |
| **Pattern B Phase 1 — raster-overview** | `CLAUDE_E2E_LIVE_PATTERN_B_PHASE=1` | sips (macOS native) + VLM | ⚠️ **Structural PASS; behavioral pending** | — (phase 2-6 deferred to 1.1) |
| **SMART v5 Walkthrough** (full onboarding multi-turn via Claude runner) | `CLAUDE_E2E_LIVE_WALKTHROUGH=1` | Anthropic CLI + API credit (~$3-5 per run on Claude Opus) | ⚠️ **Structural PASS; behavioral pending** | — (scripted only; live multi-turn deferred) |
| **Inbox Shortcut Setup** (macOS symlink / Linux .desktop / Windows .lnk) | `CLAUDE_E2E_LIVE_INBOX_SETUP=1` | OS-native tools (already present on most systems) | ⚠️ **Structural PASS; Windows behavioral pending** | — (macOS + Linux scaffolds exist; Windows .lnk needs a real Windows test runner) |

## Session-10 Phase-5 additions

- L2 Embed live re-verified on current Beta repo: **21/21 green**
  - Real 768-dim vectors from nomic-embed-text
  - Idempotent (second run skips already-embedded chunks)
  - `--require-backend` returns exit 4 when backend unavailable
  - `features.yaml` → `knowledge.l2_tank_embed.validated_at` bumped to `2026-04-22T02:50:00Z`

- L2 Hybrid Query live re-verified: **20/20 green**
  - Auto-mode routes to hybrid when embeddings + backend both ready
  - Semantic-only proof-point: query `"how do users log in"` → top match `"Authentication: session tokens + OAuth login"` via cosine alone (the exact phrase "log in" is not in the tank content — semantic match works)
  - `features.yaml` → `knowledge.l2_tank_hybrid_query.validated_at` bumped to `2026-04-22T02:52:00Z`

## What's next for Live-Verification

### Low-cost / high-value (recommended for Beta 1.0 if user runs them)

1. **Pull `moondream` VLM** (`ollama pull moondream`, ~1.7 GB, 1 minute on fiber)
   - Unlocks `CLAUDE_E2E_LIVE_VLM=1` on test 24 + 28 + pattern-b-phase1
   - Smallest vision model that produces real descriptions

2. **`brew install kreuzberg-dev/tap/kreuzberg`** (~100 MB, ~30 sec)
   - Unlocks `CLAUDE_E2E_LIVE_KREUZBERG=1` on test 23 + inbox flow
   - Essential for any PDF / Office parsing demo

3. **`brew install poppler`** (~10 MB, ~10 sec)
   - Unlocks `CLAUDE_E2E_LIVE_PATTERN_A=1` on test 28
   - Needed for text-layer PDFs (Pattern A)

### Higher-cost / lower-priority (defer to 1.1 unless specific user need)

4. **Walkthrough live-run** (~$3-5 Claude Opus tokens, ~5 min)
   - Only meaningful when the onboarding flow is being actively changed
   - Currently scripted-only which catches regressions cheaper

5. **Windows `.lnk` live test**
   - Needs a Windows test runner (VM or physical)
   - Out of scope for macOS/Linux dev environment
   - Scaffolded in test 27; behavioral assertion would need PowerShell + WScript.Shell COM

## Pragmatic verdict for Beta 1.0 Release

- **Critical** (must-have before v1.0 tag): L2 Embed + Hybrid ✅ done
- **Nice-to-have** (would strengthen release-story): Kreuzberg + VLM live-verification — user-action required (install + pull)
- **1.1 backlog**: Walkthrough multi-turn ($), Windows .lnk (runner), Pattern B Phases 2-6

If the user installs kreuzberg + pulls moondream before the v1.0.0 tag, Phase 5 could claim 4 of 7 live-paths verified. Without that, we claim 2 of 7 + documented-infrastructure for the rest. Both are honest; neither blocks the release.

## How to run live tests yourself

```bash
# L2 Embed (nomic-embed-text must be pulled):
CLAUDE_E2E_LIVE_EMBED=1 bash tests/e2e/17-l2-tank-embed.test.sh

# L2 Hybrid Query:
CLAUDE_E2E_LIVE_EMBED=1 bash tests/e2e/18-l2-tank-hybrid-query.test.sh

# Kreuzberg (install first):
CLAUDE_E2E_LIVE_KREUZBERG=1 bash tests/e2e/23-parser-kreuzberg-backend.test.sh

# Ollama VLM (pull a vision model first):
CLAUDE_E2E_LIVE_VLM=1 bash tests/e2e/24-parser-ollama-vlm-backend.test.sh

# Pattern A (install poppler first):
CLAUDE_E2E_LIVE_PATTERN_A=1 bash tests/e2e/28-parser-pattern-a-backend.test.sh

# Full suite with all live flags:
CLAUDE_E2E_LIVE_EMBED=1 CLAUDE_E2E_LIVE_KREUZBERG=1 CLAUDE_E2E_LIVE_VLM=1 \
CLAUDE_E2E_LIVE_PATTERN_A=1 bash tests/e2e/run-all.sh
```

All test scripts gracefully skip live blocks when their respective env var is unset.
