# ADR-005: Build a portfolio system instead of fixing individual branches

**Date:** 2026-04-15
**Status:** accepted
**Deciders:** Arash Zamani, ecosystem-reckoning-session
**Context:** 2026-04-15 Ecosystem Reckoning Milestone

## Context

On 2026-04-14 the user discovered that `feature/ollama-settings-wysiwyg` — the branch on which Phase 0, Phase 1, and Phase 2 of the Beta Migration had been executed — was a kitchen-sink: **100 commits across 13 themes**, only 7 of which were actual Ollama Settings UI work. The migration work had been appended to a branch named for an entirely different feature because no session had validated the branch name against the session task.

The initial proposed fix (Option A+, 2026-04-15 morning) was a branch rename + migration-branch-split. A 4-agent research pass (ecosystem map, voice/voxtral, DexHub agents, industry patterns) returned findings that reframed the problem:
- **35 projects/workstreams** exist in the ecosystem. None are indexed anywhere.
- **6 cold clones** sit in `~/Downloads/`, uncataloged. Block 2 later revealed 1 with unique commits.
- **6 azamani1 colleague branches** exist with multiple external contributors whose work underpins DexHub core rules.
- **MEMORY.md (688 lines) was being truncated** on session load — the "central index" was unreliable.

The user's framing: *"Ich habe langsam den Überblick verloren. Also ich weiß nicht mal, was, wo, wie, wann und so weiter."*

The retrospective question: **"In 6 months, what would I wish we had done today?"** The answer was clearly *not* "we renamed a branch". The answer was "we built the infrastructure that makes the next 6 months tractable".

## Decision

**The Ecosystem Reckoning will not treat the kitchen-sink branch as the problem. It will treat the absence of a portfolio layer as the problem.**

Branch-level work is sequenced AFTER portfolio-level work:
- **Layer 0** (2026-04-15, complete) — stop the bleeding: milestone anchor, workstreams.csv v1, voice-engine tag, global learnings, cross-session commit discipline.
- **Layer 1** (this session) — portfolio system buildout: MEMORY.md trim, cold clones inventory, workstreams.csv v2, ADRs (this document), mem0 spike.
- **Layer 2** (later) — branch discipline enforcement via lefthook.
- **Layer 3** (later) — worktree adoption with Claude Code `-w`.
- **Layer 4** (later) — branch reorganization: rename kitchen-sink to `legacy/kitchen-sink-2026-04`, create clean `feature/beta-migration-eb-1.0`.
- **Layer 5** (ongoing) — hygiene: VALIDATION BLOCK at every session start, 4-step commit discipline, workstreams.csv updates.

Phase 3 of the Beta Migration (Beta clone + port) is **blocked** until Layer 4 completes.

## Consequences

**Positive:**
- The next kitchen-sink is prevented structurally, not culturally. Lefthook + branch discipline = machine-enforced.
- Future sessions can re-orient in 5 minutes by reading workstreams.csv instead of grep-ing 141 memory files.
- The Beta community-branch vision becomes executable because external contributions are now tracked in the portfolio.
- Honest framing: the user lost overview. The fix is tooling, not willpower.

**Negative / accepted:**
- Phase 3 Beta Migration is delayed by the duration of Layers 1–4 (estimated 5–10h total across multiple sessions).
- The kitchen-sink branch continues to accumulate pointer-commits during Layer 1 (workstreams.csv v2, MEMORY.md trim, ADR set, Layer 1 close) — but these are meta-work on portfolio infrastructure, not new feature work, and they are documented as such in commit messages.
- Some readers will see this as "planning over doing", the exact anti-pattern the April Intervention was meant to combat. Response: the portfolio layer IS the doing. It is infrastructure whose absence has been costing weeks of overview-rebuilding at every session transition.

## Alternatives considered

1. **Rename branch + migrate + move on** (Option A+ from morning) — rejected. Would fix cosmetics; within weeks another branch would become the next kitchen-sink.
2. **Start Phase 3 immediately and fix portfolio later** — rejected. Starting Phase 3 on an unknown foundation would compound existing debt.
3. **Do nothing, live with the overview loss** — rejected. User explicitly stated this is the problem being solved.
4. **Adopt a heavier tool (Linear, Notion, mem0)** — deferred for evaluation in Layer 1 Block 5 (mem0 spike). CSV + ADR chosen for Block 3 because it is immediate, local, version-controllable, and requires no external service.

## References

- `MILESTONE_2026_04_15_ECOSYSTEM_RECKONING.md` — the anchor document
- `project_april_intervention_2026_04_15_EXTENDED.md` — the extended intervention narrative
- `BRANCH_FORENSIC_COMMIT_MANIFEST_2026_04_15.md` — 100 commits × 13 themes analysis
- `PROJECT_ECOSYSTEM_MAP_2026_04_15.md` — 35 projects mapped
- `NEXT_SESSION_PROMPT_REVIEW_AND_LAYER_1_2026_04_15.md` — execution prompt
- `SELF_REVIEW_LAYER_0_2026_04_15.md` — honest self-critique of Layer 0
- workstreams.csv row `layer-1-portfolio-buildout`
