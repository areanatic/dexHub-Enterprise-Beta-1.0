# DexHub 1.1 Roadmap

**Status:** Planning · Target: Post-1.0 release
**Last updated:** 2026-04-22 (session 10 Phase 6)

This is the **explicit backlog** of features/polish items that were scoped for 1.0 but consciously deferred to keep 1.0 shippable. Nothing here is "forgotten" — each entry has a rationale for deferral + a clear spec.

---

## Decision principle for "defer vs ship in 1.0"

1.0 ships what is **correct + honestly documented + validated**. 1.1 gets:
- Pure optimizations (tokens, speed) that don't affect correctness
- Bigger refactors that need their own scoped session
- Optional UX polish where current docs already cover the gap
- Items that require user-local tooling we cannot automate

---

## P0 for 1.1 (first release-block)

### G1 — Guided-Install Wizard UX

**Spec:** Interactive bash wrapper around `capabilities-probe.sh` that:
1. Runs probe, parses "not_installed" + "partial" backends
2. Per missing backend, detects user's OS (macOS/Linux/Windows + WSL)
3. Shows OS-specific install command with clear explanation
4. Asks y/n to open browser (model catalog / install docs) or copy command to clipboard
5. Re-runs probe after install to confirm
6. Chains: parser → nomic-embed → vision-model → kreuzberg in sensible order

**Current gap:** Non-Dev user sees `"status": "not_installed"` in raw JSON. INSTALLATION.md Step 5 covers it but requires reading. Wizard would close the last-mile onboarding gap.

**Effort estimate:** 4-5 h (script ~150 lines + OS-detection logic + tests/e2e for each OS-branch-mock)

**Dependencies:** none — builds on existing probe script.

### O1 — Copilot Token Quick-Win

**Spec:** Compress SHARED.md from 499 lines → ~300 lines + extract 200 lines to lazy-loadable skills. Net effect on Copilot: 735 lines/2.5K tokens per session-start → ~500 lines/1.7K tokens (-32%).

**Targets for extraction:**
- Dev-Mode details (→ skill `dexhub-dev-mode`)
- Meta-Agents enumeration (→ skill `dexhub-meta-agents`)
- Detailed XML tag reference (→ skill `dexhub-core`)

**Targets for deletion (redundant with README):**
- ITS AI Gilden paragraph (fits better in README)
- "You are DexHub-aware!" meta-commentary
- Duplicate governance policies (already in validate.sh docs)

**Current gap:** 735 lines works fine — just inefficient. Every token saved is a session-start saving, adds up over many sessions but not blocking.

**Effort estimate:** 8-10 h (careful SSOT refactor + skill authoring + build script updates + A/B test of compression quality)

**Dependencies:** none — but O1 + O2 (skills menu) + O4 (full compression) want to ship as a bundle so users see the skill system coherently.

### F1-F4 — Project Migration Agents

**Spec:**
- F1 Drop-In-Detection (extends `@mydex-project-manager`)
- F2 Pull-Repo Agent (new — `@pull-repo`)
- F3 Push-Repo Agent (new — `@push-repo`, Enterprise-compliance-relevant)
- F4 Per-Project-Chronicle (routing logic so each project gets own chronicle)

**Current gap:** `myDex/projects/` skeleton is prepared (shipped in 1.0 commit 2d6f4cc). Manual workflow works today. Agents would make it conversational.

**Effort estimate:** 30.5 h total (5.5 + 8 + 11.5 + 5.5)

**Dependencies:** `myDex/projects/` exists ✅. No other blockers.

---

## P1 for 1.1

### Living-Docs Pattern

**Spec:** Automated drift-detection between code and docs. When a feature's spec (feature.yaml) changes but its README mention doesn't, validate.sh §29 (new) fails. Optional auto-compile of README's Feature Matrix from features.yaml.

**User rationale (session 10):** "Wir entwickeln, entwickeln und vergessen aber, oh, da haben wir das geändert, das haben wir geändert und so weiter. In unseren Commits, aber in unserer Applikation selbst wird das nicht dokumentiert."

**Effort:** 3-4 h (beta version — grep-based drift-check) or 8-10 h (full version — auto-compile README from yaml).

### O2 — `*skills` Menu

**Spec:** DexMaster menu entry showing available skills (analogous to `*list-agents`). Lazy-loading hints per skill.

**Blocked on:** O1/O4 (need meaningful skill inventory first — otherwise empty menu).

### O3 — Export / Import Dev-Entries

**Spec:** Dev-Mode adds `*export-entry <id>` and `*import-entry <file>` for cross-DexHub-instance sync of bugs/features/tech-debt entries.

**Effort:** 3-4 h.

### DF1 — FEATURE-CATALOG auto-gen

**Spec:** Build script that regenerates `.dexCore/_dev/todos/features.md` (and possibly README Feature Matrix) from features.yaml. Makes counts + statuses auto-consistent.

**Effort:** 4-5 h.

### DF2 — Proactive Skill-Suggest

**Spec:** DexMaster detects keywords in user messages and suggests relevant skill loads. LLM-based with ranking.

**Blocked on:** O2 (need skill menu first).

### DF4 — `compile-agents.sh`

**Spec:** SSOT compile from `.dexCore/*/agents/*.md` (source personas) to `.github/agents/*.agent.md` (Copilot activations). Closes drift-risk caught by validate.sh §28 (still TODO).

**Effort:** 3-4 h.

### DF5 — Archive-First Pattern review

**Spec:** Formalize Archive-First as validated Ground Rule #2, add tooling (auto-manifest-generator) so archives get SHA256SUMS + MANIFEST.md without manual work.

**Effort:** 1-2 h (docs) or 3-4 h (+ tooling).

---

## P2 for 1.1 (polish)

### Windows `.lnk` behavioral-live-verification

Requires a Windows test runner. Currently scaffolded in test 27 but not behaviorally verified. Low priority — most enterprise users are on macOS/Linux.

### VLM on-demand pulling helper

Wizard that detects "user asked for image parsing but no VLM pulled" → offers to `ollama pull moondream` with one confirmation step.

### Walkthrough live-verification

`CLAUDE_E2E_LIVE_WALKTHROUGH=1` actually hitting Anthropic API for full SMART v5 multi-turn. Costs ~$3-5 per run. Only do before major onboarding changes, not routine CI.

### Pattern B phases 2-6

Currently phase 1 (overview) enabled in 1.0. Phases 2 (cluster detect), 3 (hi-res crops), 4 (per-cluster VLM), 5 (synthesis), 6 (verify) are deferred.

---

## Governance

- When 1.0 ships: rename this doc to `ROADMAP.md` and add a "1.0 shipped" section showing what made it in.
- Each 1.1-item gets a feature-flag entry in `features.yaml` with `status: deferred` + `phase: "1.1"`. DexHub's registry becomes the source of truth.
- Every 1.1 PR must reference which backlog-item it closes.
