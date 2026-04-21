# DexHub Changelog

> Development changelog for DexHub Enterprise Beta

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
