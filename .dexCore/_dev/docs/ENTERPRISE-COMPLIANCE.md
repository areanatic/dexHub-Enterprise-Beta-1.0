# DexHub Enterprise Compliance Matrix

> **Status:** Living document. Version 0.1.0, created 2026-04-19.
> **Authority:** Governs which DexHub features are safe to use in enterprise-grade deployments (DHL-class, regulated industries, data-sovereignty-mandated contexts).
> **Source-of-truth:** Every feature's compliance stance is tracked in [`.dexCore/_cfg/features.yaml`](../../.dexCore/_cfg/features.yaml) under the `enterprise_compliance` field. This doc is the human-readable companion.

---

## 1. Why Enterprise Compliance is a first-class constraint

DexHub is built for Enterprise use. User directive, 2026-04-19:

> *"Enterprise Compliance first — für ALLE Solutions, auch als Workaround"*

The operational implication: before any new feature ships, it must be classified on the compliance axis. Features that can't satisfy Enterprise constraints must be either (a) labelled as optional opt-in with consent gate, (b) deferred, or (c) declared unfit and removed.

## 2. The five compliance statuses

Each feature in [`features.yaml`](../../.dexCore/_cfg/features.yaml) carries an `enterprise_compliance` value from this set:

| Status | Meaning | Action for Enterprise Deployment |
|---|---|---|
| `ok` | Fully compliant. Data stays local. No external API calls. No 3rd-party dependency that routes user data. | Safe to enable in strict mode |
| `local_vlm_required` | Compliant only when backed by local LLM (Ollama + local VLM). Cloud LLM path disallowed for enterprise use. | Enable only with Ollama installed; block cloud-LLM routing |
| `cloud_with_consent` | Calls out to cloud service. OK if user/org has explicit contractual consent (e.g. Copilot with approved tenant, Jira Cloud with approved workspace) | Require explicit per-deployment consent gate; document data flow |
| `research_pending` | Compliance stance not yet researched. Must be completed before marking shipping-ready | Block in strict mode until clarified |
| `not_applicable` | Meta-feature (e.g. a docs file), no data flow involved | Safe |

## 3. The Enterprise Mode toggle (planned, `meta.enterprise_mode_toggle`)

A single feature flag that, when enabled, filters out anything not `ok` or (with consent grant) `cloud_with_consent` / `local_vlm_required`. In particular:
- Disables all cloud-only features without signed consent
- Forces Ollama as LLM backend for parsing / knowledge
- Blocks any connector wizard that hasn't received explicit URL + consent from operator
- Requires `signed_consents.yaml` file (planned) listing approved cloud endpoints

Status of this meta-toggle itself: `deferred`, phase `future`. **The matrix below works without it — it's the guardrail for `ok` classification discipline today.**

---

## 4. Per-feature compliance matrix (snapshot 2026-04-19)

### Core infrastructure

| Feature | Compliance | Notes |
|---|---|---|
| `core.dexmaster_orchestrator` | ok | Pure prompt engineering; no data leaves disk |
| `core.ssot_compile_step` | ok | Bash + sha256sum; local only |
| `core.agent_boundary_state_model` | ok | CONTEXT.md persistence is local file |
| `core.validate_sh` | ok | Bash checks, local files |
| `core.post_write_check_hook` | ok | Hook runs locally |

### Onboarding

| Feature | Compliance | Notes |
|---|---|---|
| `onboarding.smart_v5` | ok | Questions + answers → local profile.yaml (5-Q default flow) |
| `onboarding.vollstandig_v5` | ok | Same (12-Q enterprise-compliance + custom instructions variant) |
| `onboarding.minimal_v5` | ok | Same (2-Q language + data-handling consent only) |
| `onboarding.data_handling_gate` | ok | P0 enterprise-compliance question (Q43) populates `company.data_handling_policy` |
| `onboarding.inferred_layer_b` | ok | Deferred (1.1) — repo scanner for auto-inference |
| `onboarding.progressive_layer_c` | ok | Deferred (1.1) — event-triggered questions |

> v4.3 flows archived 2026-04-22 (see `.dexCore/_archive/onboarding-v4.3-2026-04-22/`).
> The previous `smart_v4_3`, `vollstandig_v4_3` and `legacy_path_preserved` features
> were removed in P0-I Option A consolidation; *mydex-advanced now routes to v5 VOLLSTÄNDIG.

### Agents

| Feature | Compliance | Notes |
|---|---|---|
| `agents.core_pack` | ok | Agent files are prompt templates; no data flow |
| `agents.dis_pack` | ok | Same |
| `agents.game_pack` | ok | Same |
| `agents.dhl_pack` | ok | DHL-specific advice prompts, no data egress |
| `agents.meta_pack` | ok | Brownfield analysis runs on local code |
| `agents.onboarding_pack` | ok | Guided prompts for connector setup |
| `agents.user_toggle_menu` | ok | UI feature, local |

### Knowledge Layer

| Feature | Compliance | Notes |
|---|---|---|
| `knowledge.l1_wiki` | ok | Local markdown files |
| `knowledge.l2_tank_sqlite` | ok | Native SQLite, local disk, no MCP cloud dep |
| `knowledge.l3_chronicle` | ok | Local markdown + CONTEXT.md |
| `knowledge.ingest_pipeline` | ok | Local processing, no egress |
| `knowledge.query_interface` | ok | Local-only retrieval UX |

### Parser

| Feature | Compliance | Notes |
|---|---|---|
| `parser.router` | ok | Orchestration, no data flow |
| `parser.kreuzberg_backend` | ok | MIT license, Rust+Python, local pip install, no telemetry |
| `parser.ollama_vlm_backend` | local_vlm_required | Ollama is local-by-default — satisfies enterprise |
| `parser.pattern_a_vector_text` | ok | poppler-utils local |
| `parser.pattern_b_raster_6phase` | local_vlm_required | MUST be paired with Ollama for enterprise; cloud-VLM path is explicitly forbidden |
| `parser.inbox_auto_parse` | ok | Local file processing |
| `parser.guided_setup_wizard` | ok | Local setup flow |
| `parser.capabilities_yaml` | ok | Local config |
| `parser.license_audit_enforcer` | ok | Blocks AGPL/GPL/commercial backends (PyMuPDF, MinerU, Marker) |

### Connectors

| Feature | Compliance | Notes |
|---|---|---|
| `connectors.atlassian_wizard` | cloud_with_consent | Jira/Confluence cloud or on-prem; consent = tenant URL + token + documented data-path |
| `connectors.github_wizard` | cloud_with_consent | github.com (cloud) or GitHub Enterprise (on-prem); consent via `gh auth` |
| `connectors.figma_wizard` | cloud_with_consent | figma.com API; consent via token provision |
| `connectors.known_config_database` | ok | Local YAML database |
| `connectors.research_fallback_persistence` | research_pending | Unknown-config research may involve web-search — compliance to be defined before shipping |

### LLM Integration

| Feature | Compliance | Notes |
|---|---|---|
| `llm.ollama_local` | ok | Local-only, enterprise default |
| `llm.copilot_primary` | cloud_with_consent | GitHub Copilot; requires org-approved tenant (standard enterprise practice) |
| `llm.claude_code` | cloud_with_consent | Anthropic API; requires org-approved key/workspace |
| `llm.github_models_api_fallback` | cloud_with_consent | Currently broken anyway |

### Workflows

| Feature | Compliance | Notes |
|---|---|---|
| `workflows.xml_engine` | ok | Spec definition, local |
| `workflows.runner_backend` | ok | Would run locally if it existed (currently broken) |
| `workflows.46_workflow_files` | ok | Local YAML |

### Quality Gates

| Feature | Compliance | Notes |
|---|---|---|
| `quality.e2e_harness` | ok | Local bash tests |
| `quality.e2e_live_mode` | cloud_with_consent | Costs API tokens against user's Claude subscription |
| `quality.validate_sh_§3_strict` | ok | Local |
| `quality.validate_sh_§21_policy` | ok | Local |
| `quality.validate_sh_§23_features_yaml` | ok | Local |
| `quality.copilot_smoke_weekly` | cloud_with_consent | Live Copilot testing = uses cloud subscription |

### Meta + Bugs + Roadmap

| Feature | Compliance | Notes |
|---|---|---|
| `meta.features_yaml` | ok | Registry file |
| `meta.enterprise_compliance_doc` | ok | This doc |
| `meta.enterprise_mode_toggle` | ok | Planned toggle (local config) |
| `meta.readme_honesty_pass` | ok | Docs only |
| `bugs.workflow_runner_missing` | ok | Would be local when fixed |
| `bugs.mcp_config_7_layer_bug` | ok | Currently blocks Atlassian MCP — users are cloud-with-consent once fixed |
| `bugs.github_models_api_deprecated` | cloud_with_consent | Will be again once fixed |
| `roadmap.cross_project_knowledge` | ok | Local aggregation |
| `roadmap.auto_project_detection` | ok | Local heuristics |
| `roadmap.team_profile_support` | ok | Depends on delivery channel (local fileshare) |
| `roadmap.marketplace_integrations_skills_workflows` | research_pending | Community-contribution hosting model unclear |
| `roadmap.audio_transcription` | local_vlm_required | Must be Ollama-backed for enterprise |

---

## 5. Summary counts (enterprise-relevant)

From `features.yaml` snapshot 2026-04-19 (60 features total):

| Compliance status | Count | Enterprise-safe-by-default? |
|---|---|---|
| `ok` | ~46 | Yes, enable freely |
| `local_vlm_required` | ~3 | Yes, if Ollama present |
| `cloud_with_consent` | ~6 | Yes, with signed consent |
| `research_pending` | ~2 | **No** — must be classified before shipping |
| `not_applicable` | 0 | — |

(Exact numbers re-computed at every registry change; run `ruby -ryaml -e "require 'yaml'; ..."` to verify.)

---

## 6. Enforcement protocol

### For every new feature PR

1. Add an entry to `.dexCore/_cfg/features.yaml` with correct fields
2. Classify `enterprise_compliance` honestly
3. If classification is `research_pending` — open an issue, resolve before merging to main
4. If classification is `cloud_with_consent` — document the consent mechanism in this doc
5. If classification is `local_vlm_required` — ensure the feature degrades gracefully when Ollama absent (e.g. feature stays `disabled` with clear user message)

### Validation

`validate.sh §23` (deferred to follow-up commit) will enforce:
- Every `enabled` feature has a compliance value ≠ `research_pending`
- Every README feature claim matches a feature with status `always_on` or `enabled`
- No feature with status `broken` is promoted as shipping

### Audit cadence

This matrix is audited:
- At every Phase milestone (5.1, 5.2, 5.3, …)
- Before any public release (tag `v1.0-beta`, `v1.0`)
- On every explicit user request

The `last_audit` field in `features.yaml` is updated each time.

---

## 7. Research-pending items (MUST resolve before Beta 1.0 public)

Two features sit at `research_pending` today. Both need classification before general-availability label can be claimed:

1. **`connectors.research_fallback_persistence`** — when a connector URL isn't in our known-config DB, DexHub may do a mini web-research step. That research may hit public internet. Question: is that acceptable in DHL-class context? Options: (a) block in enterprise mode, (b) allow but log, (c) allow only against whitelisted search endpoints. **Decision due: Phase 5.4.**

2. **`roadmap.marketplace_integrations_skills_workflows`** — community-contributed packs imply download-from-somewhere. Compliance question: what hosting model (GitHub repo only? DHL Artifactory? Air-gapped bundle? Signed by whom?). **Decision due: before 2.0.**

---

## 8. What this doc does NOT cover

This matrix tracks feature-level compliance. It does not cover:

- Data handling inside documents users feed into DexHub (that's the user's responsibility; documented in README)
- Specific regulatory certifications (SOC2, ISO 27001, GDPR Art. 30 records) — those are deployment-level, not feature-level
- Vulnerability management / dependency auditing — handled separately via `.github/workflows/` and standard package audit tools

---

**Written 2026-04-19 by Opus 4.7. Version 0.1.0. Updated on every feature addition.**
