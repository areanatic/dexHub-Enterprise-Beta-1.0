# ADR-007: `feature/ollama-settings-wysiwyg` stays as a historical artifact

**Date:** 2026-04-15
**Status:** accepted — executed in Layer 4 (future session)
**Deciders:** Arash Zamani, ecosystem-reckoning-session
**Context:** 2026-04-15 Ecosystem Reckoning — Kitchen-Sink Discovery

## Context

`feature/ollama-settings-wysiwyg` started as a branch for a small Ollama Settings UI feature in early April 2026. Over ~2 weeks it accreted **100 commits across 13 themes**:

| Theme | Commit count (approx) |
|---|---|
| Ollama Settings UI (nominal theme) | 7 |
| EA-2.0 cleanup | 6 |
| MCP integration merge | 9 |
| RZP Flow Board V1 | 12 |
| RZP ALBA Mega-Session | 1 (51e3454, large) |
| RZP Figma v6 refactor | ~8 |
| KONF role-aware landing | ~4 |
| Open-Dex voice engine | ~3 (via merge) |
| Phase 0 Beta-Freeze | 4 |
| Phase 1 Canary | 5 |
| Phase 2 Security + Core Fixes | 12 |
| Ecosystem Reckoning Layer 0 | varies |
| Documented incidents | 2 (secret leak, alba downgrade) |
| **Total** | **100** |

The branch name described 7 of the 100 commits. The 93 others were added because sessions inherited the branch name from handoff prompts without validating it against session tasks. See ADR-005 for the portfolio-level analysis.

## Decision

**Do not rename, delete, or rewrite `feature/ollama-settings-wysiwyg`. Keep it as a historical artifact, reachable forever, documented via tags and memory files.**

Specifically:
- Layer 4 (future session) will create a **new** branch `feature/beta-migration-eb-1.0` at the current HEAD additively, then `git branch -m` the kitchen-sink to `legacy/kitchen-sink-2026-04`.
- The rename is non-destructive — commits are untouched, only the branch pointer name changes.
- Tags will be added to mark theme boundaries and the two incidents (secret leak, alba downgrade) so future forensic work can locate them without manual log archaeology.
- The branch is not deleted, even after the rename, because:
  - 7 legitimate Ollama Settings UI commits live only here and might be reused.
  - The two incidents are documentation for future learning; deleting them erases the evidence.
  - The non-destructive rule (ADR-004) forbids deletion.

## Consequences

**Positive:**
- The full migration history is preserved for audit and forensics.
- The 7 Ollama UI commits remain extractable if that feature is ever revived.
- The two incidents stay as live examples for onboarding / learning.
- Future sessions see a clear `legacy/` prefix and know not to commit there.

**Negative / accepted:**
- The git repo carries more branch refs than strictly necessary. Accepted — branch refs are cheap.
- `git log --all` output will still include the kitchen-sink history forever. Accepted — that is the point.
- The `legacy/kitchen-sink-2026-04` branch will appear in `git branch -a` output in every future session. Accepted — the prefix makes it ignorable.

## Alternatives considered

1. **Delete the branch after migration** — rejected, violates ADR-004.
2. **Rebase the 100 commits into 13 clean theme-branches** — rejected. Two weeks of work; error-prone; destroys commit SHAs that are referenced elsewhere (workstreams.csv, memory files, prior ADRs).
3. **Rewrite history to remove the two incidents** — rejected. ADR-003 and ADR-004 both forbid history rewrites; incidents are preserved as learning artifacts.
4. **Force-push the branch to match a clean reorg** — rejected, destructive + would break references on origin.

## Execution plan (Layer 4, not this session)

When Layer 4 runs:
1. Create safety backup: `git branch backup/pre-reorg-2026-04-XX`
2. Push safety backup to origin.
3. Additively create `feature/beta-migration-eb-1.0` at current HEAD.
4. Rename kitchen-sink: `git branch -m feature/ollama-settings-wysiwyg legacy/kitchen-sink-2026-04`
5. Tag theme boundaries (7+ tags for legitimate themes) and incident markers (`incident/secret-leak-2026-03-25`, `incident/alba-downgrade-2026-04-06`).
6. Push all new refs to origin.
7. Update `NEXT_SESSION_PROMPT_PHASE_3_2026_04_14.md` and all other memory files that reference the old branch name.
8. Update workstreams.csv to reflect the new branch name for active migration rows.

Layer 4 is **not** executed in the Layer 1 session. It is documented here so the plan exists when Layer 2 (lefthook) and Layer 3 (worktrees) complete.

## References

- ADR-004 (Non-Destructive Only) — parent principle
- ADR-005 (Portfolio System Over Branch Fixes) — sibling decision
- `BRANCH_FORENSIC_COMMIT_MANIFEST_2026_04_15.md` — 100 commits × 13 themes source data
- `BRANCH_INVENTORY_ALL_BRANCHES_2026_04_15.md` — all 28 local branches
- `MILESTONE_2026_04_15_ECOSYSTEM_RECKONING.md` — the anchor
- workstreams.csv row `ollama-settings-wysiwyg` (NEEDS_USER_CONFIRM_STATUS)
