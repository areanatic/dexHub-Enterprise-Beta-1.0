# DexHub Contributors

**Last updated:** 2026-04-16 (corrected — attribution was in commit messages since March 2026)
*Ported from Playground to Beta on 2026-04-17. References to "Playground" describe the integration state at investigation time (2026-04-15/16).*

---

## Why this file exists

DexHub has multiple contributors. Their work was integrated during the **Clean Variant Sprint** (2026-03-14 and 2026-03-24) via explicit local commits that name each contributor in the commit message. This file aggregates those commit-message attributions into a single discoverability document for Beta public-release preparation.

**Note (2026-04-16 correction):** An earlier version of this file stated that contributions were "silently integrated without git attribution". That was wrong — `git log` shows commits `466155d` (Rainer Muth), `b42ff66` (Yamuna Boopathi), `1f656b3` (Kalpana Vedagiri), and `8e94ad4` (BUG-025 fix), all with explicit author names in their messages.

See **[ADR-008](.dexCore/_dev/docs/adr/ADR-008-colleague-contributor-recognition.md)** for the original decision rationale.

---

## Primary maintainer

**Arash Zamani** — project creator and primary maintainer. DHL IT Services, based in Berlin. DexHub is part of the AI Gilden initiative ("DexHub = Knowledge Meta-Layer that sits on top of repos").

---

## Contributors (alphabetical)

### kavedagi

**Contribution:** Test Automation Agent
**Branch:** `azamani1/feature/test_automation_agent` (HEAD `da0b4bc`, 2026-03-03 IST)
**Nature:** Test automation agent documentation
**Integration status in current Playground:** **NOT INTEGRATED** as of 2026-04-15 Layer 1 verification (no matching file found under `.dexCore/`). Candidate for forward-merge to Beta in Phase 3 scope.
**Workstream:** `test-automation-agent-kavedagi` (see `workstreams.csv`)
**Timezone:** IST (India Standard Time) based on commit timestamps
**Contact:** pending (not contacted as of 2026-04-15; reaching out deferred to a later session)

---

### Rainer Muth

**Contribution:** DexHub Security Guardian Infrastructure

**Branches (two, both `NOTICKET_` prefixed for direct work without a Jira ticket):**
- `azamani1/feature/NOTICKET_enforce_guardian_for_project_secrets` (HEAD `7e33ce7`, 2025-12-10) — Sample guardian enforcement prototype blocking LLMs from reading secure project files.
- `azamani1/feature/NOTICKET_enforce_guardian_with_dexhub` (HEAD `85083c4`, 2025-12-19) — Productionized: global file blacklist config for DexHub security.

**Nature:** Security-critical. Prevents DexHub agents from reading files matching sensitive patterns (`.env`, `.key`, `.pem`, `secret*`, `password*`) in any project. This is the "Guardian" concept referenced throughout SHARED.md as a baseline DexHub security primitive.

**Integration status in current Playground:** **INTEGRATED AND VERIFIED** as of 2026-04-15 Layer 1 Block 3. Confirmed by direct filesystem check:
- `.dexCore/_cfg/project-guards.yaml` — 21 lines, 6 default deny patterns, `enforced: true`
- `.dexCore/core/tasks/guardian-check.xml` — enforcement task

**Workstream:** `security-guardian-rainer` (see `workstreams.csv`, status `INTEGRATED_VERIFIED`)
**Timezone:** CET (Europe)
**Contact:** pending (not contacted as of 2026-04-15)

**Debt owed:** Rainer's guardian infrastructure must be explicitly preserved and tested during the Beta Migration (Phase 3). It cannot be left as a legacy inheritance; Beta should make the guardian a first-class feature with explicit test coverage.

---

### Yamuna Boopathi

**Contribution:** Atlas Agent + Custom Agent Discovery

**Branches (two):**
- `azamani1/feature/atlas_agent_for_feature_documentation` (HEAD `05c2091`, 2026-01-12 IST) — Atlas agent for feature documentation. Key commits: `71df743`, `58b0c5a`, `05c2091`.
- `azamani1/bug/BUG-012` (HEAD `21d7452`, 2026-01-09 IST) — Custom agent auto-discovery mechanism. BUG-012 was titled "Custom agents are not auto-discoverable".

**Nature:** The **Atlas agent** is part of the DexHub custom-agent ecosystem, performing knowledge reconstruction from repository state. The **custom agent auto-discovery** feature allows the agent manifest to find and load new agents without manual registration.

**Integration status in current Playground:**
- **Atlas agent:** **INTEGRATED AND VERIFIED** as of 2026-04-15 Layer 1 Block 3. Confirmed at `.dexCore/custom-agents/atlas-knowledge-reconstructor.md`.
- **Custom agent discovery:** **PARTIALLY INTEGRATED**. Workflow files reference discovery but no dedicated mechanism file has been located. Needs deeper investigation in a future session.

**Workstreams:** `atlas-agent-yamuna`, `custom-agent-discovery-yamuna` (see `workstreams.csv`)
**Timezone:** IST (India Standard Time) based on commit timestamps
**Contact:** pending (not contacted as of 2026-04-15)

---

## Foundational contributions (shared-ancestor commits)

Several **foundational DexHub architecture patterns** originated on shared-ancestor commits on the colleague-branch lineage (not on `azamani1/master`). These commits underpin rules and features that DexHub treats as baseline architecture in SHARED.md and CLAUDE.md, but their origin is the colleague-branch work, not the user's solo sessions.

Contributor attribution for these commits is partial — `git log` shows author metadata but the contributors are blended across the shared base. See the Azamani1 Colleague-Branches Investigation file for the full commit list.

| Commit | Feature | Current DexHub status |
|---|---|---|
| `c79d6cf` | **DexMaster Meta-Layer** — foundational first-responder pattern | Live in SHARED.md / CLAUDE.md as baseline rule |
| `fee8f14` | **G3 Root-Forbidden rule** — prevents files in repo root | Live in SHARED.md as G3 guardrail |
| `a61cc7c` | **Feature-Anfragen UX** — Always-On DexHub activation pattern | Live in CLAUDE.md |
| `ac1857a` | **PRIVACY & SAFETY policy** | Live in SHARED.md |
| `4a90b64` | **Agent=Project paradigm for DexBuilder** | Live in `.dexCore/` |
| `6eb75f3` + `cfdad0d` | **myDex V1.1 project structure** — 9 core folders + inputs routing | Live in `myDex/` template |
| `95c95a9` | **FEATURE-003 Automatic Browser-OAuth** | Integrated |

**These contributions are credited collectively to the colleague-branch contributors (Yamuna, Rainer, kavedagi, plus early collaborators) even when individual `git blame` attribution is blurred by shared-base commits.**

---

## How to become a contributor

(Placeholder for future. DexHub Beta will have public contribution guidelines. For now, contributions happen through the DHL enterprise mirror `azamani1` and require DHL employment / VPN access. OpenDex, the open-source sibling, will be the public contribution surface once released — see `project_opendex_architecture.md`.)

---

## License and attribution

DexHub's licensing is still being finalized (see `project_opendex_architecture.md` and `SCHLACHTPLAN_v4.2_PORTABILITY_LAYER_2026_04_12.md`). Planned: Apache 2.0 + Trademark + CLA for OpenDex public releases. Until the license is formalized, contributors retain copyright on their contributions as captured in the `azamani1` git history.

**If you are one of the named contributors and see this file:** please reach out to Arash Zamani. Your work is valued and your continued collaboration is welcome.

---

*This file is a living document. It will be updated when new contributions are integrated, when contributors provide updated contact info, or when Beta Community branches are formalized in Phase 3+.*
