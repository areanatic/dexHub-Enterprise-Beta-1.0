# ADR-001: Alpha = STOPP, all new work targets Beta (EB-1.0)

**Date:** 2026-04-12
**Status:** accepted
**Deciders:** Arash Zamani (user), beta-migration-session
**Supersedes:** the implicit "work on whatever branch is open" approach

## Context

By 2026-04-12 the DexHub platform had three parallel version lineages in different states of completion:
- **EA-1.5 (Alpha)** — historically the "stable" release. Archived on `azamani1/dexHub-Enterprise-Alpha-1.0` at commit `0130288` on 2026-04-07.
- **EA-2.0-beta** — a mid-flight refactor that never fully landed. Referenced inconsistently across README (EA-1.5), manifest (ea-1.0), and config (ea-2.0-beta) — a three-way version inconsistency.
- **EB-1.0 (Enterprise Beta)** — the successor target. Exists on `azamani1/dexHub-Enterprise-Beta-1.0` at HEAD `5f2058a`.

The April Intervention (2026-04-12) diagnosed this as a driver of the Planning-Execution-Gap: work was being done on "whichever branch is open right now" because no version was canonical. The Playground repo was accumulating commits across all three lineages on the same kitchen-sink branch.

## Decision

**Alpha is frozen. EB-1.0 is the only future.**

- No new work on EA-1.5 or EA-2.0 lineages.
- The Playground repo stays as a *development sandbox only*. Features built here must be ported to EB-1.0 via a controlled migration (Phase 3).
- The azamani1 remote push URL for Alpha is tombstoned (`no_push://tombstoned-alpha-archive-never-push`) to make the "never push" rule physical, not policy.
- All push operations from the Playground go to `origin` (areanatic GitHub private repo).

## Consequences

**Positive:**
- Version-chaos eliminated at source: there is only one "where should this go?" answer (Beta).
- The azamani1 Alpha repo is effectively read-only for forensic/audit purposes.
- Future migrations have a clear target.

**Negative / accepted:**
- Any in-flight Alpha work not yet ported is stranded until Phase 3 migration runs.
- The Playground still carries 100+ commits of mixed-lineage history (kitchen-sink), which Layer 4 branch reorganization will isolate later.
- Developers must remember: "commit in Playground ≠ released in Beta" — an extra cognitive step.

## Alternatives considered

1. **Port everything immediately** — rejected as infeasible given the 100-commit kitchen-sink; would require weeks of unbroken focus before any new feature work.
2. **Keep both lineages active** — rejected because it reproduces the version-chaos that triggered the April Intervention.
3. **Force-push Alpha to match Beta** — rejected per the non-destructive rule (see ADR-004).

## References

- `project_april_intervention_2026_04_12.md` — original intervention doc
- `project_april_intervention_2026_04_15_EXTENDED.md` — extended version
- `feedback_alpha_ist_stopp_nur_beta.md` — user rule capture
- `SCHLACHTPLAN_v4.2_PORTABILITY_LAYER_2026_04_12.md` — execution plan
- workstreams.csv row `dexhub-alpha-archive` (status ARCHIVED_TOMBSTONED)
