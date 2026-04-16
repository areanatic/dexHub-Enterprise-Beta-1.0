# workstreams.csv changelog

## v2 — 2026-04-15 (Layer 1 Block 3)

**Trigger:** Layer 1 Portfolio Buildout. v1 had 19 rows produced by Agent 1 during Layer 0. Layer 0 self-review flagged three gaps: (a) status fields were agent estimates not user-confirmed, (b) Nexus cross-references missing, (c) colleague-branches not represented. Block 2 (Cold Clones Inventory) added a fourth discovery: 1 unique commit in `bkp_181125`.

### Rows added (14 new)

- **layer-1-portfolio-buildout** — the current meta-workstream (this session).
- **nexus-voice-server** — NEXUS FastAPI WebSocket voice server on Mac Mini, R3 done. DexHub voice.js cross-over target.
- **nexusgram-telegram-bot** — NEXUS Telegram bot (@AstronOneBot). Known uncommitted + session-resume hang.
- **memory-bridge-v4-nexus** — authoritative Memory Bridge implementation in NEXUS. DexHub Memory Bridge is downstream.
- **security-guardian-rainer** — Rainer Muth's Security Guardian. VERIFIED integrated in Playground (`.dexCore/_cfg/project-guards.yaml` + `guardian-check.xml` both exist).
- **atlas-agent-yamuna** — Yamuna Boopathi's Atlas agent. VERIFIED integrated (`atlas-knowledge-reconstructor.md`).
- **custom-agent-discovery-yamuna** — Yamuna's BUG-012 auto-discovery mechanism. Partially integrated; no dedicated file found.
- **test-automation-agent-kavedagi** — kavedagi's test automation agent. NOT integrated in current Playground.
- **dexmaster-meta-layer-origin** — foundational commit `c79d6cf` from colleague-branch lineage. Live in SHARED.md; attribution missing.
- **colleague-branches-azamani1** — replaces v1's `azamani1-colleague-branches` row with updated content post-investigation.
- **cold-clone-bkp181125-dev-mode-v2** — 🔴 has unique commit `0205cf1` Dev-Mode v2.0 NOT in current Playground.
- **cold-clone-nov18-master-snapshot** — `dexHub Enterprise Alpha 1.0`, historical master snapshot.
- **cold-clone-dexhub-clean-start** — reference snapshot, keep per prior user decision.
- **cold-clone-kopie-21-02-26** — 823 MB git clone, same HEAD as azamani1 BUG-011 branch, bloat needs hand-check.
- **cold-clone-v2-test-bug011-dup** — 427 MB duplicate of Kopie.
- **cold-clone-test-041225-broken** — broken git repo (dangling HEAD).
- **cold-clones-plain-dirs-20** — 20 plain directories (ZIP extracts), 2 large outliers (107M + 103M) worth hand-check.
- **girlsday-2026-standalone** — replaces v1 `girlsday-2026` with confirmed standalone status.

### Rows modified (status updates from v1)

- **dexhub-enterprise-beta-migration**: `ACTIVE` → `BLOCKED_BY_LAYERS_1_4` (explicit dependency on recovery layers).
- **rzp-alba-prototyp**: `ACTIVE` → `ACTIVE_PARALLEL_SESSION` (clarifies ownership).
- **flowable-mcp-connector**: `PAUSED` → `PAUSED_WAITING_MIRJAM` (more specific blocker).
- **ollama-settings-wysiwyg**: `ABANDONED_UNRELEASED` → `NEEDS_USER_CONFIRM_STATUS` (remove agent estimate, flag for user).
- **girlsday-2026**: `UNCLEAR` → `STANDALONE_NOT_DEXHUB` (confirmed during Layer 0 investigation).
- **ea-2.0-release-prep**: `DEFERRED` → `DEFERRED_SUPERSEDED_BY_BETA` (explicit reason).
- **dexhub-enterprise-beta**: `TARGET` → `TARGET_PHASE_3_BLOCKED` (explicit Phase 3 dependency).
- **azamani1-colleague-branches**: `UNCATALOGED` → `CATALOGED_NOT_MERGED` (now investigated).
- **cold-clones-downloads**: v1 had a single catch-all row with status `UNCATALOGED`. v2 replaces it with 6 specific cold-clone rows (one per real git clone) + 1 aggregate row for the 20 plain directories.

### Rows removed (replaced, not deleted)

- `nexus` (v1) — v1 status was `UNCLEAR, Needs investigation`. Replaced by 3 specific Nexus-related rows: `nexus-voice-server`, `nexusgram-telegram-bot`, `memory-bridge-v4-nexus`. The Nexus investigation was done in Layer 0 via `nexus-bridge` agent; results captured in `NEXUS_CONTEXT_PRIMER_2026_04_15.md`.

### Row count

- v1: **19 rows** (1 header + 19 data)
- v2: **33 rows** (1 header + 33 data)
- Net: **+14 rows**, **8 rows with updated status**, **1 v1 row split into 6+1**

### Known `NEEDS_USER_CONFIRM` flags

These rows have status fields that are still session estimates, not user-confirmed:
- `ollama-settings-wysiwyg` (`NEEDS_USER_CONFIRM_STATUS`)
- `custom-agent-discovery-yamuna` (`PARTIALLY_INTEGRATED` — deeper check needed)

### Verification performed in Block 3 (not in Block 1/2)

1. `.dexCore/_cfg/project-guards.yaml` exists and matches Rainer's intent → `security-guardian-rainer` status → `INTEGRATED_VERIFIED`
2. `.dexCore/custom-agents/atlas-knowledge-reconstructor.md` exists → `atlas-agent-yamuna` status → `INTEGRATED_VERIFIED`
3. No test_automation agent file found in `.dexCore/` → `test-automation-agent-kavedagi` status → `NOT_INTEGRATED`
4. Custom agent discovery references in workflow files but no dedicated mechanism → `custom-agent-discovery-yamuna` status → `PARTIALLY_INTEGRATED`

---

## v1 — 2026-04-15 (Layer 0)

Initial 19-row portfolio. Agent 1 output during Ecosystem Reckoning research pass. Status fields were session estimates. First SoT for DexHub workstreams. Self-review 7/10: good starting shape, known gaps around Nexus + colleagues + cold clones.

---

**Next version:** v3 will likely add forward-merge plans for `test-automation-agent-kavedagi`, resolve `custom-agent-discovery-yamuna` partial state, and replace user-confirm flags with actual user decisions. Not in Layer 1 scope.
