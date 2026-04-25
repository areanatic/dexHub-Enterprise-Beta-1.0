# DexHub Changelog

> Development changelog for DexHub Enterprise Beta

## [1.0.0] — 2026-04-22 🎉 First public Beta 1.0 release

Session 10 ships 13 atomic commits closing Phase 1 + Phase 3-7 of the
pre-release plan. All 274 validate.sh checks green; enterprise bundle
build + verify green; live-verified EMBED + HYBRID (41 live assertions).

### Added in session 10
- `.dexCore/_dev/docs/INSTALLATION.md` — step-by-step for Non-Devs (DE)
- `.dexCore/_dev/docs/FIRST-5-MINUTES.md` — guided first-use tour (DE)
- `.dexCore/_dev/docs/FAQ.md` — 15+ Non-Dev questions (DE)
- `.dexCore/_dev/docs/TROUBLESHOOTING.md` — symptom → cause → fix (DE)
- `.dexCore/_dev/docs/LIVE-VERIFICATION.md` — Tier1/5 status per path
- `.dexCore/_dev/docs/ROADMAP-1.1.md` — explicit 1.1 backlog with specs
- `myDex/projects/` skeleton + README.md (pre-1.1 Drop-In prep)
- validate.sh §28 — Copilot-activation ↔ source-persona drift-check (46 stubs)
- Registry entry `quality.validate_sh_§28_copilot_drift`
- Q40/Q41 personal-instruction placeholders (dialect, style, tone examples)
- Completion summary + edit-hint spec in onboarding-questions.yaml
- Section: DEPRECATED_PHRASES in validate.sh §21 extended with
  "100% Local-First" + "100% local, no cloud APIs" (future drift guard)

### Changed in session 10
- **Messaging (P0-H):** "100% Local-First" → "Data-Local, LLM-of-Your-Choice"
  across SHARED.md + regenerated CLAUDE.md + copilot-instructions.md +
  2 skill files + dex-master + mydex-agent + myDex/README. Honest framing:
  working data stays local; LLM engine is user's choice; connectors are
  opt-in per Enterprise Compliance Matrix.
- **l3_chronicle (P0-A):** enabled → always_on (infrastructure, not toggleable).
  counts_block + README Feature Matrix synced.
- **post_write_check_hook (P0-B):** docs-path fixed to actual location
  (.claude/skills/dexhub-testing/scripts/), Claude-Code-only note added,
  Copilot fallback to prompt-text documented.
- **Agent renames (E3+E4):** TestArch Pro → Kalpana (Test Automation
  Architect), Atlas → Yamuna (Knowledge Reconstruction Expert). Technical
  commands @testarch-pro / @atlas preserved for backward-compat.
  agent-manifest.csv displayNames updated (matches Mona pattern).
- **README:** count-disambiguation note (46 Copilot activations vs 43
  source personas vs 14 dxm agents — all correct, each in its scope);
  install-URL typo fixed (dexhub-ea-beta → dexHub-Enterprise-Beta-1.0);
  Getting-Started-Docs block linking the 4 new Non-Dev docs.

### Removed in session 10 (P0-I Option A — Onboarding Consolidation)
- `onboarding.smart_v4_3_1` (enabled → removed, referenced archived YAML)
- `onboarding.vollstandig_v4_3` (enabled → removed)
- `onboarding.legacy_path_preserved` (enabled → removed, depended on above)
- `.dexCore/_cfg/onboarding-questions.yaml` v4.3 content archived to
  `.dexCore/_archive/onboarding-v4.3-2026-04-22/` with SHA256SUMS +
  MANIFEST.md + restore procedure
- `.dexCore/_cfg/onboarding-questions-v5.0.yaml` renamed to canonical
  `.dexCore/_cfg/onboarding-questions.yaml`
- `.dexCore/_dev/docs/ONBOARDING-V5-DESIGN.md` renamed to
  `.dexCore/_dev/docs/ONBOARDING-DESIGN.md`
- Enterprise bundle strip-list extended: `.dexCore/_dev/portfolio/` +
  `.dexCore/_dev/docs/adr/` no longer ship with the enterprise bundle

### Live-verified in session 10 (DF3, partial — 2 of 7 paths)
- CLAUDE_E2E_LIVE_EMBED=1 on test 17 → 21/21 PASS
  Real 768-dim vectors from nomic-embed-text, idempotent, require-backend
- CLAUDE_E2E_LIVE_EMBED=1 on test 18 → 20/20 PASS
  Semantic match proven: "how do users log in" → "Authentication"
- Status of other 5 paths (KREUZBERG / VLM / PATTERN_A / WALKTHROUGH /
  INBOX_SETUP) documented in LIVE-VERIFICATION.md

### Deferred to 1.1 (with explicit specs in ROADMAP-1.1.md)
- G1 Guided-Install Wizard (interactive install helper)
- O1 Copilot Token Quick-Win (SHARED.md compression + skills extraction)
- F1-F4 Project Migration Agents (Drop-In, Pull-Repo, Push-Repo, Per-
  Project-Chronicle)
- Living-Docs Pattern (automated drift-detection code ↔ docs)
- O2/O3/O4/DF1/DF2/DF4/DF5 polish items

### Registry state at 1.0 release
- **85 features total** (8 always_on + 58 enabled + 19 deferred + 0 broken + 0 experimental)
- **43 source agent personas** · **46 Copilot activations** · **46 workflows** · **12 skills**
- **28 validate.sh sections** (27 + new §28 Copilot drift-check)
- **274 validate.sh checks PASS** · **0 FAIL** · **0 WARN**

---

## [Unreleased] — post-EB-1.0 hardening (2026-04-02 → 2026-04-21)

### Added — L2 Knowledge Tank (closed 2026-04-21 session 5)
- SQLite-backed tank with `l2-init.sh`, `l2-ingest.sh`, `l2-query.sh`
- Optional semantic search via Ollama embeddings (`l2-embed.sh` +
  `l2-detect-backend.sh` + `l2-status.sh`)
- Hybrid keyword+semantic ranking (`--keyword-only` / `--hybrid` /
  `--semantic-only` / `--alpha`)
- Enterprise compliance gate with `POLICY-BLOCK:` audit rows in
  `ingest_runs`
- L1 Wiki scaffold (pattern doc + 3 templates)

### Added — Document Parser Arc (closed 2026-04-22 session 8)
- Parser router (`parse-route.sh`) + MIME detection (`detect-mime.sh`)
- 4 backend adapters:
  - `pattern_a_vector_text` (poppler pdftotext, text-layer PDFs)
  - `pattern_b_phase1_overview` (raster → VLM overview description,
    first of 6 phases; 2-6 deferred to 1.1)
  - `kreuzberg` (brew install optional — 91+ formats)
  - `ollama_vlm` (local VLM via llama3.2-vision / llava / moondream etc.)
- Capabilities probe (`capabilities-probe.sh`) with auto-probe-on-stale
- Inbox auto-parse orchestrator (`*inbox` menu) — drop file → L2 tank
- Inbox watcher (`*inbox-watch`) — fswatch / inotify / poll auto-select,
  foreground process (daemon mode deferred to 1.1)
- Inbox desktop-shortcut setup (`*inbox-setup`) — macOS symlink /
  Linux .desktop / Windows .lnk scaffold (live-verify deferred)

### Added — Platform & Quality Infrastructure
- Agent Packs (`packs.sh` + 3 manifests + `*packs` / `*enable-pack` /
  `*disable-pack` DexMaster menu)
- Saved Consent Tracking (profile schema v1.2, `*consents` /
  `*revoke-consent`)
- SMART v5.0 onboarding + live walkthrough test
- `validate.sh` 22 → **27 sections**:
  - §23 feature registry consistency (single source of truth)
  - §24 session-anchor (worktree-identity guard, post-2026-04-19 incident)
  - §25 README ↔ features.yaml counts consistency
  - §26 counts_block ↔ actual registry consistency
  - §27 test-file shell-syntax validity (`bash -n` on all test paths)
- Enterprise-bundle build script with `--verify` mode
- Feature registry schema with 6 status buckets + enterprise_compliance
  + depends_on + known_issues

### Changed
- Agent count: 43 → 46 Copilot `.agent.md` files
- Workflow count: 45 → 46 structured workflows
- Build-for-enterprise strips `.claude/` + `tests/e2e/integrations/` +
  `.dexcore-session-anchor` + `LEARNINGS-CLAUDE-CODE-REMOVABILITY.md`

### Deferred (roadmap honesty — 19 features flagged)
- Pattern B Phases 2-6 (cluster-detect, hi-res crops, per-cluster VLM,
  synthesis, verify)
- Native Workflow-Runner execution backend
- Watcher daemon mode (systemd/launchd integration)
- Voice/video parsing (Voxtral)
- Team shared profiles (1.3)
- Cross-project knowledge layer + Community marketplace (2.0)
- Auto-project-creation from inbox (2.0)
- 3 agent packs (creative, games, DHL-DS)
- 2 5.1.debt items (§3 tightening, §21 policy in SHARED.md)
- Copilot live smoke test (recurring)
- Parser blocklist + integrations registry (5.3.b / 5.4.a / 5.4.c)
- Profile auto-detect from repo + lazy-gating question (5.2)
- Knowledge ingestion + RAG (5.2.d)

### Fixed
- 2026-04-13 Flowable MCP deep discovery (paused, pending Mirjam role
  decision)
- 2026-04-17 Agent Boundary state model + D1 Layer-1/2 persistence
- 2026-04-19 Tier 0-4 cleanup: 3 Playground-only "broken" features
  removed + 1 fixed (Atlassian MCP install.sh v2.0 wizard). broken
  count 6 → 0.
- 2026-04-19 Onboarding SMART v4.3.1 → v5.0 default, v4.3.1 via
  `*mydex-advanced`
- 2026-04-19 Session-anchor mechanism (worktree-identity validation
  after cross-repo incident)
- 2026-04-22 session 7 CI-red streak: XDG env-var unset discipline
  across test-27 XDG cases
- 2026-04-22 session 8 Pattern B Phase 1 hardening: 0-byte PNG guard +
  VLM sub-adapter exit-code capture + --require test coverage on
  ready boxes

### Registry status at close (2026-04-21)
- 87 total features: 7 always_on / 61 enabled / 0 disabled / 19
  deferred / 0 broken / 0 experimental
- validate: 273 / 0 / 0
- E2E: 703 dev / 704 CI-sim / 680 enterprise
- build-for-enterprise --verify: PASS
- HEAD: `d5ba4b4` on origin/main (areanatic)

## [EB-1.0] — 2026-04-01

### Initial Enterprise Beta Release

**Agents:**
- 43 agents (26 user-facing + 18 meta-agents)
- 46 .agent.md files for GitHub Copilot integration
- 3 integration onboarding agents (Atlassian, GitHub, Figma)
- All agent names aligned with manifest

**Workflows:**
- 45 guided workflows across 4 phases
- All workflow paths verified (0 broken references)
- Brainstorming checklist.md created

**Skills:**
- 12 lazy-loaded knowledge packs
- Platform Awareness skill (IDE vs Copilot)

**Integrations:**
- Atlassian MCP (Jira + Confluence)
- GitHub Enterprise MCP
- Figma MCP + REST client
- Generic setup wizards (no hardcoded URLs)

**Infrastructure:**
- validate.sh (168+ automated checks)
- files-manifest.csv fully migrated to .dexCore paths
- All legacy naming cleaned (bmb→dxb, bmm→dxm, cis→dis)
- Guardrails G1-G7 + Safety Rules + Archive Protocol

**Knowledge Base (recovered from prior versions):**
- 8 analysis documents (platform compatibility, methodology comparison, etc.)
- 5 architecture documents (ADR-002, meta-layer deep dive, etc.)
- 8 use case documents
- MASTERPLAN-EA-1.5 strategic document

### Migration from EA-1.5
- ~190 path corrections (dex/→.dexCore/, cis/→dis/, outputs/→drafts/)
- Profile schema aligned (Q1 language: de/en, Q2 path fixed)
- GitHub MCP genericized (no DHL-specific URLs)
- 150KB strategic knowledge recovered from older instances
