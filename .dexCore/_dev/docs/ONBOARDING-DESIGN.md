# Onboarding Design Document

**Status:** Updated 2026-04-25 (D4) — single canonical onboarding (5 questions). Original v5.0 3-variant design (MINIMAL/SMART/VOLLSTÄNDIG) collapsed per user direktive "Es gibt nur ein Onboarding".
**Phase:** 5.1.b (originally) / D4 consolidation (2026-04-25)
**Author:** Claude Opus 4.7 (original) + Opus 4.7 (D4 consolidation)
**Supersedes:** v4.3 (3-variant) and v5.0-experimental (also 3-variant). The single-onboarding design described here IS the canonical 1.0+ flow.
**Companion file:** `.dexCore/_cfg/onboarding-questions.yaml`

> **D4 NOTE (2026-04-25):** This doc historically described a 3-variant model (MINIMAL/SMART/VOLLSTÄNDIG) plus a 4-layer information architecture (Layer A/B/C/D). The current canonical onboarding is just **Layer A (5 questions)**. Layers B/C remain deferred to Phase 5.2+ as documented. Layer D (VOLLSTÄNDIG opt-in survey) was retired — its question set (Q40-41 + Q44-49) moved to *profile editing post-onboarding. Sections below that describe the variant model are kept as historical context for ADR-trail purposes; the canonical truth is in `metadata.onboarding` of `onboarding-questions.yaml`.

---

## TL;DR

v4.3 asks 42 questions cold (~18 minutes). Every competitor (Cursor, Copilot, Continue.dev, Cody, Claude Code — 2026 current) asks **zero**. Industry completion-rate ceiling is 3-7 questions. v4.3 SMART at 18-21 is already 3× that. Full 42 is ~6× the ceiling.

v5.0 redesigns around a **3-layer information model**:

- **Layer A — Asked (5 questions, SMART core):** things that cannot be inferred from repo
- **Layer B — Inferred-and-confirmed (~15-20 items):** auto-detect from repo, batch-confirm
- **Layer C — Progressive disclosure:** ask only when the user first triggers the gating feature
- **Layer D — VOLLSTÄNDIG as opt-in survey:** the 42-question path preserved as `*mydex-advanced`

**This document ships Layer A + enterprise Layer A additions (Q43-Q49). Layers B and C are designed but deferred to Phase 5.2+ because they require repo-scanner and event-hook implementation.**

---

## 1. Why this redesign exists

User directive 2026-04-19:
> *"21 Fragen manchmal redundant, keine Sinn. Review holistisch. Research online + lokal."*

And the Enterprise Compliance constraint from the same day:
> *"Enterprise Compliance first — für ALLE Solutions, auch als Workaround."*

Three diagnosed problems from Phase 5.1 holistic review (see `ONBOARDING-HOLISTIC-REVIEW-2026-04-19.md`):

1. **Ask-vs-Infer imbalance.** DexHub asks 42; industry asks 0. Over-asking.
2. **Enterprise-compliance dimension completely absent.** 0 of 7 compliance-critical fields exist (data-handling, connectors, LLM-providers, audit, network-topology, regulations, git-restrictions).
3. **Schema-coverage mismatches.** Q21/Q22 collisions in profile.yaml.example; Q40-42 wrongly placed in SMART; ~half the 42 questions have no downstream agent consumer.

---

## 2. What v5.0 ships

### Layer A — 5 asked questions (SMART core)

| ID | Field | Type | Rationale for asking |
|---|---|---|---|
| Q0 | `personalization.name` | text | User's choice of address, not inferrable |
| Q1 | `personalization.language` | single_select (de/en/bilingual) | Interaction language preference |
| Q3 | `technical.experience_level` | single_select (junior/intermediate/senior/expert) | Shapes explanation depth; self-reported more accurate than git-log-inferred |
| Q4 | `identity.team_size` | single_select (solo/small/medium/large) | Affects coordination patterns; partially inferrable but user-reported more accurate |
| **Q43** | `company.data_handling_policy` | single_select (local_only / lan_only / cloud_llm_allowed / hybrid) | **NEW — P0 enterprise gate. Everything downstream depends on this answer** |

### Layer A — Enterprise extension (VOLLSTÄNDIG only, 7 new fields)

| ID | Field | Enterprise Priority | What it filters |
|---|---|---|---|
| Q43 | `company.data_handling_policy` | P0 | Master gate for cloud-LLM vs local-only |
| Q44 | `company.approved_llm_providers` | P0 | Which LLM integrations DexHub surfaces |
| Q45 | `company.available_connectors` | P0 | Connector wizard menu |
| Q46 | `company.audit_requirements` | P0 | Whether DexHub produces audit trails |
| Q47 | `company.network_topology` | P1 | Outbound call routing (proxy, VPN, air-gapped) |
| Q48 | `company.compliance_certifications` | P1 | Regulation-specific constraints |
| Q49 | `company.forbidden_git_targets` | P1 | Push-destination guard (prevents azamani1-style mistakes) |

### Layer A — Power user (VOLLSTÄNDIG, kept from v4.3)

- Q40 `custom_instructions.always_do`
- Q41 `custom_instructions.never_do`

(Q42 `domain_knowledge` free-text moves to progressive disclosure triggered on first relevant use.)

**Total asked in v5.0 VOLLSTÄNDIG: 12 questions, ~3-5 minutes.** Contrast with v4.3's 42 questions × 17-22 min. Cut by factor of 3.5-4x.

### Layer B (designed, deferred to Phase 5.2)

Post-SMART batch confirmation. Auto-detect from repo:
- `tech.primary_language` — from file extensions + lock files
- `tech.primary_framework` — from dependency manifests
- `tech.test_framework` — from test configs + test file patterns
- `tech.build_tool` — webpack/vite/tsconfig/build.gradle/Makefile
- `tech.package_manager` — lock-file presence
- `tech.commit_style` — git log conventional-commits detection
- `tech.linting_tool` — eslint/prettier/ruff config presence
- `identity.team_size_inferred` — git log unique-author count (90d)
- `work.domain_inferred` — directory structure heuristics

UX: "I see you use TypeScript + React + Vitest. Confirm? [Yes / Edit]"

Implementation blocker: needs repo-scanner module. Design in `onboarding-questions.yaml` → `inferred_layer_b_candidates`. Target phase: 5.2 when we're building Knowledge Layer L2 Tank (scanner can piggyback).

### Layer C (designed, deferred to Phase 5.2)

Event-triggered progressive disclosure:
- First MCP connector install → "VPN access? Tenant URL?"
- First parser use → "Local-only OCR required?"
- First push → "Which git targets are approved?" (if Q49 empty)
- First multi-agent workflow → "Sequential or parallel coordination?"
- First persona switch → role-detail questions

Implementation blocker: needs event-hook system. Target phase: 5.2+ (piggyback on feature-flag enforcement logic).

### Layer D — Legacy preserved

v4.3 full 42-question survey stays. Activation via `*mydex-advanced`. Framed as "deep personalization investment" not "required".

---

## 3. Fixes shipped alongside the v5.0 draft (v4.3.1 patch)

These fix real bugs in the current v4.3 that surfaced during the holistic review:

### 3.1 File location fix (CRITICAL)

**Problem:** `myDex/.dex/config/onboarding-questions.yaml` was **gitignored**. New users cloning the repo didn't get the onboarding questions — DexMaster would reference a missing file.

**Fix:** Moved to `.dexCore/_cfg/onboarding-questions.yaml` (tracked, manifest-area — same pattern as agent-manifest.csv, files-manifest.csv, features.yaml). 8 files with references updated (mydex-agent.md × 2, validate.sh, profile-schema, 2 E2E tests, features.yaml, holistic-review doc).

**Rationale for .dexCore/_cfg/ (not myDex/ with .example suffix):** This is a product-template, not user-customizable. Users who want a local override can still use the gitignored `myDex/.dex/config/onboarding-questions.yaml` path; mydex-agent reads `.dexCore/_cfg/` first and checks `myDex/.dex/config/` as an override.

### 3.2 Q21/Q22 label collision in profile.yaml.example

**Problem:** `copilot_enabled` was labelled `# Q21` and `preferred_model` was labelled `# Q22`, but Q21 in onboarding-questions.yaml maps to `workflow.extra_time_use` and Q22 maps to `tech.primary_stack`. Same IDs pointing to different fields = ambiguity for agents reading the profile.

**Fix:** In `profile.yaml.example`, removed the wrong Q21/Q22 labels from `ai.copilot_enabled` and `ai.preferred_model`. Added honest comment: these fields are set by agent inference or user edit, not asked in v4.3 onboarding.

### 3.3 Q40-42 mis-labelled as SMART

**Problem:** v4.3 SMART variant listed question IDs `[..., 40, 41, 42]`. Q40/41 are "custom instructions always_do/never_do" and Q42 is "domain_knowledge 2000-char free-text" — these are **expert-user features**, not essential onboarding.

**Fix:** v4.3 bumped to v4.3.1. SMART variant now `[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 14, 15, "18a", 20, 21, 31, 38, 39]` — 18 questions. Q40-42 moved to VOLLSTÄNDIG-only.

### 3.4 E2E test update

`tests/e2e/01-onboarding-smart.test.sh` — SMART count range widened to 5-25 (covers v4.3.1 at 18 and v5.0 at 5, future-proof).

---

## 4. Migration path

### For existing users with v4.3 profiles

- Existing `profile.yaml` files remain valid — schema is additive (new `company.*` fields default to null)
- First session after v5.0 activation: DexMaster notices missing `company.data_handling_policy`, asks once (short), user can skip
- Legacy 42-question path preserved via `*mydex-advanced`

### For new users (fresh install)

- Default path: SMART v5 (5 questions, 60-90 sec)
- If `data_handling_policy = local_only` in SMART: DexMaster short-circuits cloud-LLM/connector features immediately
- VOLLSTÄNDIG v5 (12 questions, 3-5 min) as optional "I want enterprise setup" path
- VOLLSTÄNDIG v4.3 (42 questions, full survey) available via `*mydex-advanced` for power users who want deep personalization

### Activation plan

- **Phase 5.1.b (now):** v5.0 YAML shipped as `experimental` in features.yaml. Not yet default. mydex-agent wiring pending.
- **Phase 5.1.a.2:** Multi-turn claude-runner walkthrough test validates SMART v5 produces profile.yaml end-to-end
- **Phase 5.1.b.2 (follow-up commit):** mydex-agent `*mydex` command defaults to v5.0 variant selector, routes to `.dexCore/_cfg/onboarding-questions.yaml`
- **When walkthrough tests pass:** Promote v5.0 to `enabled`, v4.3.1 stays as `enabled` (legacy path), marked `deprecated` in post-1.0 release

---

## 5. What we explicitly do NOT ship in this commit

Honest scope-boundary:

- **mydex-agent wiring to v5.0** — the agent still defaults to v4.3.1. The v5.0 YAML is design-ready but not yet the default flow. Next commit.
- **Layer B repo scanner** — deferred to Phase 5.2 (needs scanner module)
- **Layer C event-hook system** — deferred to Phase 5.2+
- **Profile-schema v1.1 additions** — `company.*` fields need schema extension; decided to add alongside mydex-agent wiring so all changes land together
- **Multi-turn walkthrough test** — Phase 5.1.a.2, after this commit
- **Deprecation of v4.3.1** — kept alive through 1.1 minimum

---

## 6. Feature-flag registration

In `.dexCore/_cfg/features.yaml`, this commit registers:

| Feature ID | Status | Phase |
|---|---|---|
| `onboarding.smart_v5` | enabled | 5.1.b (DEFAULT) |
| `onboarding.vollstandig_v5` | enabled | 5.1.b |
| `onboarding.minimal_v5` | enabled | 5.1.b |
| `onboarding.data_handling_gate` | enabled | 5.1.b (Q43 enterprise-compliance gate) |
| `onboarding.inferred_layer_b` | deferred | 5.2 |
| `onboarding.progressive_layer_c` | deferred | 5.2 |

> **Historical note:** `onboarding.smart_v4_3_1`, `onboarding.vollstandig_v4_3`, and `onboarding.legacy_path_preserved` were removed in 2026-04-22 session 10 P0-I Option A (SMART v5 becomes the only canonical flow; v4.3 YAML archived).

---

## 7. Open design questions (for follow-up)

1. Should Q43 gate apply retroactively to existing v4.3 profiles? (User re-consent on first v5.0-session?)
2. Should DexMaster periodically re-check enterprise answers? (Annually, or after company policy change?)
3. Layer B repo-scanner: own module or leverage `codebase-analyzer` meta-agent?
4. Team-profile support (`roadmap.team_profile_support`): should SMART ask team-size or defer to a team-profile onboarding?
5. When v5.0 becomes default, should we auto-migrate v4.3 `ai.copilot_enabled = true` users to `company.data_handling_policy = cloud_llm_allowed` silently or ask?

These are tracked in `onboarding-questions.yaml` → `open_questions` and in `features.yaml` as `known_issues` on relevant entries.

---

## 8. Verification

Gates at commit time:

| Gate | Result |
|---|---|
| `bash tests/e2e/run-all.sh` (default) | 51/0/0 (structural) |
| `bash .dexCore/_dev/tools/validate.sh` | 260/0/0 (22 sections) |
| `ruby -ryaml -e` on both YAMLs | parses clean |

E2E-Test will be extended in 5.1.a.2 with multi-turn claude-runner (Anthropic SDK or `claude --continue`) to actually drive SMART v5 end-to-end.

---

**Written 2026-04-19 by Opus 4.7. Design shipped. Implementation wiring deferred to follow-up commit.**
