# ADR-008: Colleague-Contributor Recognition

**Date:** 2026-04-15 (original) / 2026-04-25 (superseded)
**Status:** **superseded** by 2026-04-25 release-policy decision
**Deciders:** Arash Zamani

## Status note (2026-04-25)

The original ADR-008 (2026-04-15) decided to document and credit colleague contributors via:
1. Explicit `workstreams.csv` rows naming each contributor
2. A `CONTRIBUTORS.md` discoverability file
3. Forward-looking attribution in README + CHANGELOG + OpenDex announcement

This decision was **reversed on 2026-04-25** as part of the Beta 1.0 release-policy review. The reversal applies to the public-facing repo content; **canonical authorship is preserved in git commit history** (`git log`, `git shortlog`, `git blame`).

Reasoning for the reversal:
- **Equity:** A partial named list creates a bright-line that excludes unlisted alpha-phase collaborators.
- **Maintenance:** Hand-curated discoverability documents drift; git history does not.
- **Privacy:** Surnames + commit metadata in a public repo invite discoverability concerns that a partial list does not solve.

User direktive verbatim 2026-04-24: *"Reine + Martin mit Namen ... lass es raus. Weil da sind noch ein paar andere Leute, die würde ich auch noch mit reinnehmen, die bei der Alpha-Phase mit dabei waren. Das macht keinen Sinn, das ist Kindergarten. Lass es raus, bitte."*

## What changed

- `.dexCore/_dev/docs/CONTRIBUTORS.md` retired to a surnameless stub pointing at git history (commit 5/7 of D1 atomic-commit batch).
- `workstreams.csv` row IDs containing surnames renamed to surnameless slugs (commit 7/7).
- ADR-005 (portfolio system) updated to drop named references (commit 6/7).
- This ADR-README updated to drop named references (commit 6/7).
- Persona-names `Kalpana` + `Yamuna` PRESERVED in agents (per D1b release-policy decision: persona-names are persona-names, not attributions).

## What did not change

- `git log` author metadata for every commit (preserved indefinitely).
- License + copyright (Apache 2.0; per-author copyright on contributions remains as captured in git author info).
- The fact that DexHub had multiple contributors (this is preserved in git history; what changed is the discoverability layer in user-facing docs).

## Archive

Original ADR-008 (90 lines, 2026-04-15) preserved in `.dexCore/_archive/2026-04-25_d1a-real-name-removal/ADR-008-colleague-contributor-recognition.md.original` with SHA-256 + MANIFEST per ground rule #2.

## References

- `.dexCore/_dev/docs/CONTRIBUTORS.md` (current stub)
- ADR-005 (portfolio system) — parent decision, edited 2026-04-25 to drop named references
- `.dexCore/_archive/2026-04-25_d1a-real-name-removal/` (originals + MANIFEST)
- SESSION_END_2026_04_25_PART2_DECISIONS_RESOLVED_EXECUTION_GO.md (D1a/D1b/D1c decisions)
