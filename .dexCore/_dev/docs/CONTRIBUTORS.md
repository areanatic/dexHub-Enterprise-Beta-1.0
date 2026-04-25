# DexHub Contributors

**Last updated:** 2026-04-25 (real-name attribution removed per release-policy decision)

## Authorship policy

DexHub Beta 1.0 does not maintain a discoverability document of named individual contributors. **Canonical authorship is preserved in git commit history.** Use:

```bash
git log --format="%h %an %ad %s"
git shortlog -s -n
git blame <file>
```

These provide complete, machine-verifiable authorship for every line of code, configuration, and documentation in the repository.

## Why this changed

Earlier versions of this file (pre-2026-04-25) listed individual contributors by full name with branch references and integration metadata. The release-policy decision (2026-04-25) was to retire this discoverability layer:

- **Equity:** A partial list of "alpha-phase contributors" creates a bright-line that excludes unlisted collaborators. The release policy is "either everybody, or git history is the source of truth" — git history won.
- **Maintenance:** The list required active curation as new contributions landed. Authorship in git is automatic.
- **Privacy:** Surnames + commit metadata in a public-facing repo created a discoverability concern that is not solved by listing 3 of N contributors.

## How attribution still works

- **Commit messages** retain author attribution where it was authored that way (e.g., commits authored by external collaborators on inherited branches preserve their `git log` author metadata).
- **Persona-names in DexHub** (Jana, Mona, Steffi, Martin, Kalpana, Yamuna, etc.) are persona-names for AI agents, not attributions to individuals.
- **The project creator** (Arash Zamani) is identified in `dex-master.md` `*about` prompt under Attribution and in the LICENSE / NOTICE.

## What was archived

The pre-2026-04-25 version of this file (125 lines, listing 3 named contributors with branch + commit + integration-status detail) is preserved in `.dexCore/_archive/2026-04-25_d1a-real-name-removal/CONTRIBUTORS.md.original` with SHA-256 checksum + MANIFEST.

---

*This file is intentionally minimal. Update only if the release-policy on contributor naming changes.*
