# Architecture Decision Records (ADRs)

**Location:** `.dexCore/_dev/docs/adr/`
**Status:** initial set written 2026-04-15 (Layer 1 Portfolio Buildout Block 4)
**Format:** one markdown file per decision, numbered `ADR-NNN-<kebab-title>.md`

---

## What this is

Architecture Decision Records capture **why** a decision was made, what was considered, and what the consequences were. They are not documentation of current state (that's for READMEs and workstreams.csv). They are a frozen record of decision moments, so future sessions (mine, yours, a new contributor's) can reconstruct the reasoning without asking "why does DexHub do X?".

**Rule:** never edit an ADR after it is accepted. If a decision changes, write a new ADR that supersedes the old one and mark the old one `status: superseded`.

**When to write an ADR:** when a choice between alternatives is made that would be hard to re-derive later, or when a principle is declared that will shape future work.

**When NOT to write an ADR:** for routine code changes, bug fixes, cosmetic updates, or decisions that are already documented in commit messages + changelog.

---

## Initial ADR set (2026-04-15)

These 8 ADRs capture the frozen decisions from Phase 0 through Layer 1 of the DexHub Beta Migration + Ecosystem Reckoning. They were written retroactively during Layer 1 Block 4 because they had been living only in memory files and session logs — a fragile location.

| # | Title | Date | Status | One-line |
|---|---|---|---|---|
| [ADR-001](ADR-001-alpha-stopp-beta-target.md) | Alpha = STOPP, all new work targets Beta (EB-1.0) | 2026-04-12 | accepted | Alpha is frozen; Beta (EB-1.0) is the only future; Playground is a sandbox. |
| [ADR-002](ADR-002-areanatic-offsite-via-github.md) | areanatic (GitHub private) is offsite; AstronOne is local only | 2026-04-14 | accepted | `origin` is the canonical offsite backup; AstronOne is a fast local mirror, not offsite. |
| [ADR-003](ADR-003-no-rotation-no-bfg.md) | No token rotation, no BFG history rewrite | 2026-04-14 | accepted | Rotation skipped consciously (private repo, solo owner, non-destructive principle). |
| [ADR-004](ADR-004-non-destructive-only.md) | Non-destructive operations only (archive-first) | 2026-04-14 | accepted | No destructive operation without a SHA-256 + MANIFEST archive of prior state. Absolute rule, no exceptions. |
| [ADR-005](ADR-005-portfolio-system-over-branch-fixes.md) | Build a portfolio system instead of fixing individual branches | 2026-04-15 | accepted | Treat the kitchen-sink as a symptom; fix the missing portfolio layer first. |
| [ADR-006](ADR-006-ssot-compile-step-for-instructions.md) | SSOT compile step for multi-platform AI instructions | 2026-04-13 | accepted | Single source of truth + build script; no hand-sync across Claude/Copilot/Cursor. |
| [ADR-007](ADR-007-kitchen-sink-branch-as-historical-artifact.md) | `feature/ollama-settings-wysiwyg` stays as historical artifact | 2026-04-15 | accepted | Rename not delete at Layer 4; preserve forensic history forever. |
| [ADR-008](ADR-008-colleague-contributor-recognition.md) | DexHub has multiple contributors; document and credit them | 2026-04-15 | accepted | Solo-dev framing was wrong; Yamuna/Rainer/kavedagi contributions are tracked + credited. |

---

## Upcoming ADRs (not yet written)

These are placeholders — decisions that will likely need an ADR when they happen:

- **ADR-009** — lefthook branch discipline enforcement (Layer 2)
- **ADR-010** — git worktree + `claude -w` adoption (Layer 3)
- **ADR-011** — branch reorganization execution (Layer 4)
- **ADR-012** — mem0 evaluation outcome (Layer 1 Block 5 produces decision doc; if adoption is chosen, this ADR captures why; if not, a short ADR still captures the rejection)
- **ADR-013** — Phase 3 Beta clone strategy (post-Layer-4)

---

## Relationship to other docs

- **workstreams.csv** — current-state portfolio. ADRs explain *why* a row is what it is; workstreams.csv answers *what* exists now.
- **CANONICAL-LOCATIONS.md** — tells you where things live in the filesystem. ADRs tell you why they live there.
- **MEMORY.md** — session-start pointer. ADRs are referenced from memory trigger files when the reasoning behind a rule is needed.
- **SHARED.md** (the instruction SSOT) — enforces rules in live sessions. ADRs document why a rule is in SHARED.md.
- **global learnings (`~/.claude/learnings/`)** — cross-project wisdom. ADRs are DexHub-specific; global learnings may cite ADRs as examples.

---

## How to write a new ADR

1. Pick the next number (`ADR-00N`).
2. Copy the template structure: Title, Date, Status, Deciders, Context, Decision, Consequences (positive / negative), Alternatives considered, References.
3. Write it in the moment the decision is made, not weeks later. Retro-ADRs (like this initial set) are acceptable but less accurate; live-ADRs are better.
4. Add an entry to this README table.
5. Commit under the message pattern `docs(adr): ADR-00N <short title>`.
6. If this ADR supersedes an earlier one, mark the earlier one `status: superseded by ADR-00N` in-place (this is the one exception to "never edit an ADR").

---

**Initial set written in Layer 1 Block 4 (2026-04-15) during the Ecosystem Reckoning Portfolio Buildout. See ADR-005 for the "why now" answer.**
