# ADR-008: DexHub has multiple contributors; document and credit them

**Date:** 2026-04-15
**Status:** accepted — partial implementation (workstreams.csv rows created, CONTRIBUTORS.md deferred)
**Deciders:** Arash Zamani, ecosystem-reckoning-session
**Context:** Azamani1 Colleague-Branches Investigation, 2026-04-15 evening (post-VPN)

## Context

The April Intervention (2026-04-12) and every DexHub planning document before 2026-04-15 framed the project as **solo-developer**. All documentation referenced "the user" singular, all self-reviews used first-person singular, all ADRs treated the contribution history as a single-lineage story.

On 2026-04-15 (evening, after VPN was re-enabled), a read-only investigation of the `azamani1` enterprise mirror found **6 colleague branches** with work from **3 external contributors** plus an older branch from the user himself:

| Branch | Contributor | Origin | Status in Playground |
|---|---|---|---|
| `feature/atlas_agent_for_feature_documentation` | **Yamuna Boopathi** (IST) | `05c2091` (2026-01-12) | ✅ integrated as `.dexCore/custom-agents/atlas-knowledge-reconstructor.md` |
| `bug/BUG-012` | **Yamuna Boopathi** (IST) | `21d7452` (2026-01-09) | Partial (workflow references, no dedicated file) |
| `feature/NOTICKET_enforce_guardian_for_project_secrets` | **Rainer Muth** (CET) | `7e33ce7` (2025-12-10) | ✅ integrated as `.dexCore/core/tasks/guardian-check.xml` |
| `feature/NOTICKET_enforce_guardian_with_dexhub` | **Rainer Muth** (CET) | `85083c4` (2025-12-19) | ✅ integrated as `.dexCore/_cfg/project-guards.yaml` |
| `feature/test_automation_agent` | **kavedagi** (IST) | `da0b4bc` (2026-03-03) | ❌ NOT integrated |
| `bugfix/BUG-011-dev-mode-ux` | Arash Zamani | `3c4b759` (2025-12-22) | In history via shared ancestor |

Further investigation into shared-ancestor commits (commits on multiple colleague branches but not on `azamani1/master`) revealed that several **"DexHub Core Rules"** treated as baseline architecture in SHARED.md and CLAUDE.md originated on colleague branches:

- **G3 Root-Forbidden rule** — commit `fee8f14` (colleague lineage)
- **DexMaster Meta-Layer** — commit `c79d6cf` (colleague lineage)
- **Feature-Anfragen UX pattern** — commit `a61cc7c`
- **PRIVACY & SAFETY policy** — commit `ac1857a`
- **Agent=Project paradigm for DexBuilder** — commit `4a90b64`
- **myDex V1.1 project structure (9 core folders + inputs routing)** — commits `6eb75f3` + `cfdad0d`
- **Automatic Browser-OAuth (FEATURE-003)** — commit `95c95a9`

These commits are not on `azamani1/master`. They reached the current Playground through an unclear mechanism (likely `git checkout <branch> -- <path>` or squash-merge-without-history, the same anti-pattern that caused the 2026-04-06 alba-master.js incident).

## Decision

**DexHub is not a solo project. Contributors are documented, credited, and their work is explicitly tracked in the portfolio.**

Three actions:

1. **workstreams.csv v2 includes explicit rows for each colleague contribution** with contributor name, origin commit, integration status, and a pointer to the Colleague-Branches Investigation file. Implemented in Block 3 (2026-04-15).

2. **A `CONTRIBUTORS.md` file will be written** at the root of the Playground (and later at the root of Beta) listing all contributors, their branches, and their contributions. **Deferred to Layer 1 close** (this session's Block 8) — not strictly Block 4 scope.

3. **Future Beta public-release documentation will credit contributors** in any README, CHANGELOG, or OpenDex announcement. The Beta-community-branch vision the user has stated ("Beta becomes a community project") is **already embryonically true**; formalizing contributor recognition is the first step.

## Consequences

**Positive:**
- Contributor attribution is correct, which matters for:
  - Legal/IP clarity when DexHub becomes public or open-source (OpenDex).
  - Team morale: people whose work landed should know it landed.
  - Historical accuracy: the project's architecture story gets told correctly.
- Rainer's security infrastructure gets explicit credit, which encourages maintaining it properly.
- The "Beta community branches" vision gets a concrete starting point.

**Negative / accepted:**
- The "solo dev" framing in prior documents (April Intervention, Phase 1/2 logs) is now incorrect in spirit. Not rewriting history per ADR-004; the Extended April Intervention 2026-04-15 explicitly acknowledges this gap.
- Reaching out to contributors (Yamuna, Rainer, kavedagi) is eventually required for:
  - Re-establishing collaboration if they want to continue.
  - Confirming license intent (if DexHub becomes public).
  - Not done in this session — explicit deferral.
- Security story is now "inherited from Rainer" rather than "built by us". Accepted.

## Alternatives considered

1. **Ignore the colleague branches** — rejected. They contain production code that is already in the Playground. Ignoring is both incorrect and ungrateful.
2. **Merge the colleague branches forward to Beta immediately** — deferred to Phase 3 (blocked). The merge requires contributor dialogue + license check + rebase onto current state.
3. **Rewrite history to attribute contributions retroactively** — rejected per ADR-004 (non-destructive).
4. **Write CONTRIBUTORS.md this session (Block 4)** — partially done: the intent is documented here; the actual file is deferred to Block 8. Reason: Block 4 is for ADRs; CONTRIBUTORS.md is a separate artifact.

## Action items (not all in this session)

- [x] Add workstreams.csv rows for each colleague contribution (Block 3, done)
- [x] Write this ADR (Block 4, done)
- [ ] Write `CONTRIBUTORS.md` at repo root with contributor names + branches + integration status (Block 8, this session)
- [ ] `git bundle` the 6 colleague branches to AstronOne as a safety net (Block 8, this session, ~30s)
- [ ] Contact contributors (Layer 3 or later session, not this one)
- [ ] Forward-merge kavedagi's test_automation agent to Beta (Phase 3 scope)
- [ ] Verify Rainer's guardian config is maintained during Beta migration (Phase 3 scope)

## References

- `AZAMANI1_COLLEAGUE_BRANCHES_INVESTIGATION_2026_04_15.md` — full investigation report
- `project_april_intervention_2026_04_15_EXTENDED.md` — updated intervention narrative
- workstreams.csv rows: `security-guardian-rainer`, `atlas-agent-yamuna`, `custom-agent-discovery-yamuna`, `test-automation-agent-kavedagi`, `dexmaster-meta-layer-origin`, `colleague-branches-azamani1`
- `.dexCore/_cfg/project-guards.yaml` (21 lines, Rainer)
- `.dexCore/custom-agents/atlas-knowledge-reconstructor.md` (Yamuna)
- ADR-005 (Portfolio System) — parent decision
