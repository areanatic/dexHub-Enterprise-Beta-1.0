# Archive: 2026-04-25 D1a Real-Name Removal

**Reason:** Per user direktive 2026-04-24 ("Lass es raus, Kindergarten") + 2026-04-25 D1a-Decision (komplett scope: public + internal). Real-name attribution removed from public-facing repo content. Personas Kalpana / Yamuna (D1b Option 1) preserved as persona-names; only attribution sentences (real surname + commit SHA + branch + dates + "in honor of" prose) removed.

**Original files preserved here:**

| File | Original lines | Replacement |
|---|---|---|
| CONTRIBUTORS.md.original | 125 | Replaced by surnameless stub at same path pointing to git history for canonical authorship |
| ADR-008-colleague-contributor-recognition.md.original | 90 | Replaced by superseded stub at same path. ADR-008 ID kept (cross-references preserved). Status: superseded by 2026-04-25 D1a session. |

**Provenance:** Both files were authored 2026-04-15 (Layer 1 / Ecosystem Reckoning session). Original commit author info preserved in git history (`git log .dexCore/_dev/docs/CONTRIBUTORS.md` + `git log .dexCore/_dev/docs/adr/ADR-008-colleague-contributor-recognition.md`).

**Hash verification:** see SHA256SUMS.txt in this folder.

**Recovery:** restore from this folder via `cp <name>.original <target-path>`. Or restore via git history before 2026-04-25 D1a commits.

**Companion: AstronOne mirror.** Per ground-rule #2 / CANONICAL-LOCATIONS, mirror to `/Volumes/AstronOne/shared-memory/dexhub/archives/d1a-real-name-removal-2026-04-25/` if mount reachable (manual step, not automated).
