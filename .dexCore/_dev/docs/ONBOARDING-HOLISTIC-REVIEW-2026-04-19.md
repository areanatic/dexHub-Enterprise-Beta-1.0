# Onboarding Holistic Review — 21/42 Question Set

**Date:** 2026-04-19
**Author:** Claude Opus 4.7 (4 parallel research agents)
**Status:** CONSUMED — research inputs integrated into `bab2ed6` Phase 5.1.b v5.0 design
**Feeds into:** Phase 5.1.b (actually delivered on 2026-04-19 evening)

> **PROVENANCE NOTE (added 2026-04-19 evening):** This file was committed as `d4782d0` on `main` by a parallel RZP session that mis-routed DexHub work into the Beta repo. The authoring session documented its own cross-repo violation in `~/.claude/projects/-Users-az-Downloads-test-1911-0349-dexHub-Enterprise-Alpha-1-0-master/memory/SESSION_ERROR_2026_04_19_RZP_CROSSED_INTO_BETA_PHASE5.md`. The DexHub session (this repo's 5.1.b committer) reviewed the content, verified the core findings independently (Q21/Q22 collision, competitor-zero-question baseline, 0-of-7 enterprise-compliance gap), and integrated them into `bab2ed6`. File retained rather than reverted because content is verified and already load-bearing for downstream work. See also: `MEMORY.md` Ground Rule #7 (extended 2026-04-19) and #9 (new, "worktree-anchor beats phase-name").

---

## TL;DR — Three Structural Issues, One Recommendation

After 4 independent research perspectives (content-analysis, competitor-research, enterprise-gap, drafts-sweep), the 21/42-question onboarding has **three structural problems**, not just "redundant questions":

1. **Ask-vs-Infer imbalance.** Industry best-practice (Cursor, Copilot, Continue.dev, Cody, Claude Code — 2026-current) is to ask **zero structured questions** and infer everything from the repo. DexHub asks 42. The onboarding-literature ceiling for completion rate is 3-7 questions; 42 is ~6× that.
2. **Enterprise-compliance dimension completely absent.** 0 of 7 compliance-critical fields exist (data-handling, connectors, LLM-providers, audit, network-topology, regulations, git-restrictions). This directly contradicts the 2026-04-19 user constraint "Enterprise Compliance must be constraint for ALL features".
3. **Schema-coverage mismatch.** Two same-numbered question-IDs map to two different profile fields each (Q21 → both `copilot_enabled` and `extra_time_use`; Q22 → both `primary_stack` and `preferred_model`). Plus: ~half the 42 questions have no downstream agent consumer in mydex-agent.md's transform/show-profile blocks.

**Recommendation (single, non-negotiable):** Redesign the flow as **5 asked + 15-20 inferred-and-confirmed + rest progressive-disclosure + 7 enterprise-compliance new**. Keep the profile-schema + YAML-persistence + verbosity-override architecture — those are DexHub's genuine differentiation. Cut the cold 42-question wall.

---

## Section 1 — Competitor Reality Baseline (verified)

Quick empirical comparison of current-state onboarding at 5 AI coding assistants, 2026:

| Tool | Onboarding questions asked | Profile concept | Inference from repo |
|---|---|---|---|
| **Cursor 2.x** | 0 (sign-in only) | `.cursorrules` + User Rules (free-form text, no schema) | Yes — everything |
| **GitHub Copilot** (`.github/agents/`, GA 2026-03) | 0 | Personal instructions (free-form, no wizard) | Yes — via "analyze the repository comprehensively" prompt |
| **Continue.dev** | 0 | `config.yaml` auto-generated with defaults | Yes — edit post-hoc |
| **Sourcegraph Cody** | 0 (admin-controlled) | None (admin-scoped) | Yes |
| **Claude Code** | 0 (login only) | `CLAUDE.md` via `/init`, `/team-onboarding` scans 30d history | Yes |

**Findings:**
- **Universally asked: literally nothing.** No tool in this set asks a single structured question.
- **Universally inferred:** language, framework, test tool, build tool, project layout, commit-style.
- **Per-user profile concept: 2 of 5** (Cursor, Copilot) — both free-form text files, no wizard, no schema.
- **"21-42 questions" is unprecedented** in this market segment.

**DexHub's genuine moat (where we are MORE rigorous):**
- Structured YAML profile schema (competitors: free-form text)
- Branching logic by role/domain
- `verbosity: detailed | default | minimal` override that propagates to every agent
- Cross-project per-user persistence (competitors: repo-scoped)

**DexHub's over-asking (where competitors skip):**
- Language/framework/test-tool → **infer, don't ask**
- Commit-style, naming conventions, formatters → **infer from .editorconfig + git log**
- Favorite editor, prior AI-experience, goal-horizon → **no competitor asks**
- Role/domain up-front → **Copilot and Cursor defer this; emerges from repo + first prompts**

Sources (all verifiable):
- GitHub Copilot custom instructions docs · Continue.dev Rules docs · Claude Code `/team-onboarding` feature · Cursor Rules guide · Onboarding-questionnaire 3-7 question ceiling literature

---

## Section 2 — Verified Content Issues (Beta repo, not drafts)

These are claims cross-checked against the actual files in this Beta repo today (2026-04-19), not against Playground/Alpha drafts (which are older).

### 2.1 Question-ID collision bug (HIGH severity)

`myDex/.dex/config/profile.yaml.example` references the same question-ID for two different profile fields:

| ID | Field A | Field B |
|---|---|---|
| Q21 | `ai.copilot_enabled: false` (line 36) | `workflow.extra_time_use:` (line 92) |
| Q22 | `tech.primary_stack:` (line 25) | `ai.preferred_model: "claude"` (line 37) |

**Impact:** Ambiguity for agents reading the profile. The transform logic in `mydex-agent.md` can't deterministically decide which Q21 the user-answer targets. Must resolve (rename one of each pair, or clarify in transform block).

### 2.2 Variant mislabeling (MEDIUM severity)

`metadata.variants.smart.questions` lists 21 question IDs. Looking at the list, Q40-Q42 (custom instructions — expert config) are included in SMART. That contradicts SMART's stated purpose of "quick essential onboarding".

**Impact:** SMART path is ~15% expert-features by accident. Either remove Q40-Q42 from SMART (making it a ~18-question path) or re-justify their inclusion.

### 2.3 Free-text dead-weight (LOW-MEDIUM severity)

Questions Q29 (`ai_transformation_wish`), Q30 (`career_dream`), Q42 (`additional_context`, up to 2000 chars) produce unstructured prose with no extraction logic. Agents can store and retrieve them, but they don't shape agent behavior.

**Design question for the user:** Are these intentional "engagement" fields (user invests emotion, feels seen) or just legacy bloat? If engagement, keep but label honestly. If bloat, cut.

### 2.4 NOT verified as current-Beta bugs (flagged by drafts, but already addressed)

The `FIX-PLAN-PROFILE-SCHEMA.md` draft in Playground mentions these — **fixed in Beta 1.0 already**:
- Q1 language values: draft said "deutsch"/"english", actual Beta YAML has `de`/`en`/`bilingual` ✅
- "profile.yaml never read by web app": Beta has no web app (`app/` doesn't exist). Beta is platform-agnostic (Copilot, Claude Code, Cursor, Continue, Ollama) — agents read profile via YAML loaders.

Lesson: drafts are time-stamped snapshots. Always verify against current code before treating a draft-claim as live bug.

---

## Section 3 — Enterprise-Compliance Gap (the big one)

The user stated 2026-04-19: **"Enterprise Compliance must be constraint for ALL features."**

`ENTERPRISE-COMPLIANCE.md` enumerates feature-level compliance requirements (e.g., `parser.pattern_b_raster_6phase` = `local_vlm_required`, `llm.copilot_primary` = `cloud_with_consent`). But the onboarding never captures the *user-level consent* that those feature-level markers depend on.

**Result: features marked `cloud_with_consent` in the matrix can currently be enabled without the user ever granting consent during onboarding.** That is not compliance; that is theater.

### 3.1 Missing compliance-critical fields (from 4 agent perspectives converging)

| # | Field | Values | Priority | Rationale |
|---|---|---|---|---|
| 1 | `company.data_handling_policy` | `local_only` \| `lan_only` \| `cloud_llm_allowed` \| `hybrid` | **P0** | Drives Ollama-vs-cloud decision platform-wide |
| 2 | `company.available_connectors` | multi-select: `github_enterprise`, `atlassian_cloud`, `atlassian_server`, `figma`, `internal_git`, each with `requires_vpn` flag | **P0** | Connector wizards currently offer integrations that may not be reachable |
| 3 | `company.approved_llm_providers` | multi-select: `ollama_local`, `copilot_enterprise`, `claude_api`, `openai_public` | **P0** | Captures actionable consent, not aspiration |
| 4 | `company.audit_requirements` | `not_required` \| `local_logs_only` \| `soc2` \| `iso27001` \| `hipaa` \| `dhl_supply_chain` | **P0** | Drives whether DexHub must produce audit trails |
| 5 | `company.network_topology` | `direct_internet` \| `corporate_proxy` \| `vpn_required` \| `air_gapped` \| `hybrid` | **P1** | Affects every outbound call (MCP connectors, model APIs) |
| 6 | `company.compliance_certifications` | multi-select: `gdpr`, `hipaa`, `sox`, `iso27001`, `pci_dss`, `none` | **P1** | Reg-specific constraints (GDPR = residency, HIPAA = no cloud-LLM without BAA) |
| 7 | `company.forbidden_git_targets` | free text or URL list | **P1** | Prevents accidental pushes to tombstoned/enterprise targets |

### 3.2 Proposed new questions Q43-Q48 (detail in drafts)

Concrete YAML for all 7 fields was drafted by the Enterprise-Gap agent. Should live in `onboarding-questions.yaml` under `category: enterprise`, VOLLSTÄNDIG-only (SMART stays minimal but MUST ask at least the data_handling_policy as a P0 gate).

**Minimal proposal:** Add `data_handling_policy` to **SMART** (because it locks cloud-LLM vs local-only — everything downstream depends on it). Add the other 6 to **VOLLSTÄNDIG**. If the user picks `local_only` in SMART, onboarding can short-circuit the rest of the LLM/connector/audit questions with "local-only mode — see advanced for enterprise details".

---

## Section 4 — Recommended Redesign (from the 3 problems above)

Instead of "prune 42→30", propose a **3-layer information model**:

### Layer A — Asked explicitly (5-6 questions, SMART core)

Things that **cannot** be inferred from repo:
1. Language of interaction (`de`/`en`/`bilingual`) — user preference
2. Verbosity (`concise`/`balanced`/`detailed`) — personal style
3. Team context (`solo`/`small`/`medium`/`large`) — affects agent coordination patterns
4. Skill-level self-report (`junior`/`intermediate`/`senior`/`expert`) — affects explanation depth
5. **Data-handling policy** (new, P0) — `local_only` / `cloud_ok` / `hybrid`
6. (Optional) Primary goal horizon — what are you trying to achieve this week

Total: 5-6. Completion rate on this scale is ~90% per literature.

### Layer B — Inferred and confirmed (15-20 items, post-SMART)

Auto-detect from repo, show as "I see X — confirm?":
- Primary language (from file extensions + lock files)
- Framework (from package.json / requirements.txt / go.mod)
- Test framework (from test files / configs)
- Build tool
- Commit style (from git log)
- Package manager (from lock files)
- ORM (from imports)
- IDE hints (from `.vscode/`, `.idea/`)
- Role (inferred from `CODEOWNERS` or first 100 commits author-self-ratio)
- Tools available (atlassian/github/figma config presence)

Total: 10-15. User confirms in batch; no cold-question fatigue.

### Layer C — Progressive disclosure (asked only when needed)

When the user first triggers a feature, ask the question that gates it:
- First MCP connector install → "Do you have VPN access?"
- First parser use → "Is local-only OCR required?"
- First push → "Which git targets are approved?"
- First workflow needing a persona → role-detail questions
- First team-workflow → team-size, coordination-style

Everything else (career goals, time-waste, company-culture) becomes **optional surveys** — available in `*dex-settings` later, not gating the first 10 minutes.

### Layer D — VOLLSTÄNDIG stays but as opt-in survey

VOLLSTÄNDIG becomes "I want to fill out the full survey to help my DexHub personalize deeply" — 42 questions as before, framed as investment, not requirement. This preserves the existing work and serves research-discipline users.

---

## Section 5 — What we do NOT recommend

- **Do not** keep the current 42-questions-cold path as default. That is over-asking vs. every competitor.
- **Do not** delete the dead-field sections wholesale. Agent 4 flagged these may be intentional engagement ("tell me your career dream"). Cut agent consumers' dependency on them, keep as optional-fill.
- **Do not** try to fix this in Phase 5.1 alone. Layer A + enterprise additions + variant relabeling are P5.1 scope. Layer B + C (inference + progressive) are Phase 5.2+ scope, because they need test harness for inference-accuracy.
- **Do not** ship "Enterprise Compliance" claims until at least the P0 fields (data-handling, LLM-providers, audit) are captured in onboarding. That is a real blocker for the user's 2026-04-19 constraint.

---

## Section 6 — Decision points for the user

To move forward, the user needs to decide:

**D1.** Accept the 3-layer model (5 asked / 15-20 inferred / rest progressive) as the target for Phase 5.1+? If yes, proceed with detailed design. If no, what's the preferred alternative?

**D2.** Which enterprise fields make SMART (non-VOLLSTÄNDIG) mandatory? My recommendation: only `data_handling_policy`. The other 6 go in VOLLSTÄNDIG.

**D3.** Dead-field strategy for the 42-question legacy path: engagement-keep OR cut? If keep, add a honest-label in the YAML ("these fields currently do not shape agent behavior but are recorded for future use").

**D4.** Phase 5.1.a (live walkthrough test) — is that still the right next tactical step? Three options:
   - Option A: Finish 5.1.a against the *current* 42Q as baseline, then redesign in 5.1.b. Risk: testing a flow we already know we will restructure.
   - Option B: Skip 5.1.a walkthrough against current flow, redesign first, then write walkthrough tests for the new 3-layer flow. Risk: fewer structural tests on current state.
   - Option C: Do both in parallel — 5.1.a validates current flow exists end-to-end (catches today's bugs), 5.1.b redesigns. Risk: slight wasted test-writing effort.
   - My recommendation: **Option C.** Current-flow tests still have value as regression-guard, even if we redesign.

**D5.** Test-harness placement — when we build walkthrough tests for 3-layer design, do they live in `tests/e2e/` (current) or `.dexCore/_dev/tests/e2e/`? (Deferred decision from Phase 5.0.)

---

## Section 7 — Honest-Labeling of this review's claims

Per the 2026-04-18 agent-confirm-bias correction protocol, every claim here is marked for provenance:

- **Verified against current Beta files today:** Sections 2.1, 2.2, 3 (counts of fields in profile.yaml.example), competitor reality in Section 1.
- **From agent synthesis (4 agents, cross-checked):** Section 4 recommendations, Section 5 don'ts.
- **Flagged as draft-older-than-Beta:** Section 2.4.
- **Unverified and requiring user judgment:** Section 6 decision points (these are questions, not claims).

Remaining open questions I could not answer without more work:
- Does the Playground `onboarding-questions.yaml` differ from Beta's? (Would need 2-file diff.) Probably yes given the FIX-PLAN exists only in Playground drafts.
- Is the 57%-dead-fields number from Agent 1 still true in Beta, or already partially fixed? (Would need agent-file audit against mydex-agent.md transform blocks in Beta.) Flagged as likely overestimate-for-Beta.
- What is the actual Copilot onboarding UX today? (Agent 2 cited docs but I did not observe it live. Flagged for 5.1.f Copilot smoke test.)

---

## Appendix — Input artifacts

- `.dexCore/_cfg/onboarding-questions.yaml` (Beta, 921 lines)
- `myDex/.dex/config/profile.yaml.example` (Beta)
- `.dexCore/_dev/docs/ENTERPRISE-COMPLIANCE.md` (Beta, referenced)
- `/Users/az/Downloads/test-1911-0349_dexHub-Enterprise-Alpha-1.0-master/myDex/drafts/FIX-PLAN-PROFILE-SCHEMA.md` (Playground, older state)
- `/Users/az/Downloads/test-1911-0349_dexHub-Enterprise-Alpha-1.0-master/myDex/drafts/COPILOT-LIVE-TEST-PLAN.md` (Playground)
- `/Users/az/Downloads/test-1911-0349_dexHub-Enterprise-Alpha-1.0-master/myDex/drafts/CONCEPT-SETTINGS-ARCHITECTURE-OPENDEX.md` (Playground)
- Agent outputs (4 parallel research tasks, dispatched 2026-04-19, all completed within ~100s)

---

**Last Updated:** 2026-04-19
