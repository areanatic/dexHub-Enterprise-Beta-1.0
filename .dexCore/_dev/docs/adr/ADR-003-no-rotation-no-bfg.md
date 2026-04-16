# ADR-003: No token rotation, no BFG history rewrite (consciously accepted)

**Date:** 2026-04-14
**Status:** accepted
**Deciders:** Arash Zamani, phase-2-session
**Context:** Phase 2 Block 1 security foundation

## Context

Phase 2 Block 1 discovered three live Personal Access Tokens in the Playground repo's git history:
- Confluence PAT (Atlassian MCP setup)
- Jira PAT (Atlassian MCP setup)
- Figma PAT (Figma MCP setup)

Standard security response would be a full rotation sequence:
1. Rotate each token immediately (invalidate old, issue new).
2. Update all local configs.
3. BFG Repo-Cleaner the git history to remove the old tokens.
4. Force-push to all remotes.
5. Notify anyone who cloned the repo.

The pre-push-scan.sh enforcement tool was installed and blocking pushes to `azamani1` when these tokens were detected — tooling behaving correctly.

## Decision

**Rotation is consciously skipped. BFG history rewrite is consciously skipped. The tokens are archived, scrubbed from working state, and the tool is adjusted to not block on historical occurrences on origin.**

Rationale from user (2026-04-14):
- The repository is **private** (areanatic GitHub, Arash-only access).
- The repository has **one owner** (solo). No clones exist beyond the author.
- The tokens are **live on origin** but no one except the owner can pull them.
- The enforcement tool is blocking push to **azamani1** (the tombstoned enterprise mirror) — which will never be pushed to anyway.
- BFG + force-push is a **destructive operation** that rewrites history. Per ADR-004 (Non-Destructive Only), this violates the policy for a situation that is not actually exploitable.
- Tokens are archived to AstronOne under `secrets-archive-2026-04-13/` with SHA-256 + MANIFEST for audit trail.

## Consequences

**Positive:**
- Avoids multi-hour rotation sequence + potential cascade (breaking local automation that still uses the tokens).
- Avoids destructive history rewrite.
- Preserves full forensic history for future audit.
- Matches the non-destructive-only principle.

**Negative / accepted:**
- Live tokens exist in the git history of `origin`. If the repo ever becomes public, or a second collaborator is added, those tokens become exposure vectors.
- Any future decision to make the repo public or add collaborators **requires** revisiting this ADR and executing the rotation + BFG sequence before the decision is carried out.
- The `secret-incident-2026-03-25` row in workstreams.csv stays in state `RESOLVED_NOT_CLEANED` until that decision is made.

## Alternatives considered

1. **Full rotation + BFG + force-push** — rejected as disproportionate to the risk (private repo, solo owner).
2. **Rotation without BFG** — rejected because the tokens in history would still be exploitable; partial measure offers no real security.
3. **Ignore entirely, no archive** — rejected as violating the archive-first rule. Archive was still created.

## Trigger conditions to revisit this decision

This ADR must be revisited and the rotation sequence executed **before any of the following**:
- The repo is made public.
- A second collaborator is added.
- The Beta target (EB-1.0) pulls from this repo rather than being a clean port.
- A security incident or exposure is discovered.

## References

- `TODO_ROTATION_PENDING_2026_04_13.md` — original pending-action record
- `feedback_tool_correctness_vs_strategic_relevance.md` — related learning
- `feedback_archive_first_never_delete.md` — related principle
- ADR-004 (Non-Destructive Only) — parent principle
- workstreams.csv row `secret-incident-2026-03-25`
- `/Volumes/AstronOne/shared-memory/dexhub/archives/secrets-archive-2026-04-13/`
