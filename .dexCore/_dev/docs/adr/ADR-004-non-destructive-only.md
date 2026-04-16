# ADR-004: Non-destructive operations only (archive-first)

**Date:** 2026-04-14 (formalized); principle in force since early Phase 0 (2026-04-12)
**Status:** accepted — **absolute rule, not subject to case-by-case override**
**Deciders:** Arash Zamani
**Supersedes:** nothing — this is a principle that existed implicitly and is now written down

## Context

Between 2026-03-25 and 2026-04-12, multiple incidents in the DexHub ecosystem traced back to destructive git operations executed without safety nets:
- **2026-03-25 secret leak** — live Atlassian PATs committed and removed in the same day, but history retained them. Recovery required no data, only policy change.
- **2026-04-06 alba-master.js downgrade** — a `git checkout <branch> -- <path>` silently replaced working files with an older version; 17 team members' work was lost until manual rollback (`d8f4342`). Three reviews confirmed "clean" before the bug was noticed.
- **Pre-2026-03 session losses** — `git stash` operations that discarded uncommitted working-tree state (documented in `feedback_git_stash_datenverlust.md`).

Each of these was a single destructive operation that could not be reversed from the repo's own state. Each required recovery from an external source (backup branch, chat history, colleague copy). The pattern: **destructive operations are cheap in the moment and expensive when they go wrong**.

The April Intervention (2026-04-12) + Ecosystem Reckoning (2026-04-15) crystallized a principle that was already implicit in the user's work style but never formally stated.

## Decision

**No destructive operation executes without an archive of prior state. Ever.**

Destructive operations include but are not limited to:
- File deletion (`rm`, `git rm`)
- File overwrite (edit, `git checkout <branch> -- <path>`)
- Branch deletion (`git branch -D`)
- History rewrite (`git rebase -i`, `git commit --amend`, `BFG`, `git filter-branch`)
- Force push (`git push --force`, `git push --force-with-lease`)
- Hard reset (`git reset --hard`)
- Stash drop without patch export
- Filesystem-level directory removal
- Database drop / truncate

The archive-first protocol:
1. **Identify** what is about to change.
2. **Copy** the prior state to an archive location (local `backup/` branch, `.dexCore/_archive/YYYY-MM-DD_reason/`, or AstronOne `archives/<topic>-<date>/`).
3. **Compute** SHA-256 checksums for every archived artifact.
4. **Write** a `MANIFEST.md` describing what was archived, why, and how to recover.
5. **Then** execute the destructive operation.
6. **Verify** the archive is readable and the recovery path is understood before closing the task.

Storage cost of archives is trivial. Data loss cost is catastrophic. The asymmetry always favors archiving.

## Consequences

**Positive:**
- Every destructive operation has a recovery path by construction.
- The three prior incidents (secret leak, alba downgrade, stash loss) would have been survivable under this rule.
- The rule is testable: "where is the archive?" If the answer is "nowhere", stop.
- Composes well with other principles: workstreams.csv can record the archive location, ADRs can reference archives, Cross-Session Commit Discipline includes a pre-destructive-action check.

**Negative / accepted:**
- Workspace accumulates archives (`.dexCore/_archive/`, `backup/`, AstronOne archives). This is explicitly acceptable per "storage is cheap".
- Each destructive action takes 30 seconds to several minutes longer. Accepted.
- Multi-step processes that used to be "clean up at the end" must now archive incrementally. Accepted.

## Alternatives considered

1. **Case-by-case judgment** — rejected. The three incidents were all "obviously safe" in the moment.
2. **Archive only for "big" operations** — rejected. Defining "big" creates a policy exception loophole.
3. **Trust git alone** — rejected. Git does not cover: uncommitted working tree state, untracked files, `.gitignored` content, non-repo artifacts, history rewrites that remove reachable commits.
4. **Accept some losses as normal** — rejected. The pattern is fixable, not inherent.

## Exceptions

**None.** This ADR is explicit: no exceptions. If an operation seems to need an exception, the correct response is to archive anyway. If archive feels burdensome, the operation is probably destructive and the burden is the point.

The only "exception-like" cases:
- **Undoing an operation immediately** (within the same command invocation) is not destructive because it returns to the prior state.
- **Writing into an already-archived destination** is not destructive because the archive still exists.

## References

- `feedback_archive_first_never_delete.md` — user-rule learning file
- `~/.claude/learnings/archive-first-never-100-percent-delete.md` — global learning
- `feedback_git_stash_datenverlust.md` — incident
- `~/.claude/CLAUDE.md "Git Cross-Branch Operations"` section — incident learning
- ADR-003 — an explicit application (no BFG despite tokens)
- Every workstreams.csv row with `RESOLVED_` status traces back to this principle
