# Canonical Locations — DexHub Data Map

**This file is the authoritative answer to "where does X live?".** It is referenced from `SHARED.md` and gets compiled into `.claude/CLAUDE.md` and `.github/copilot-instructions.md` on every `build-instructions.sh build`, so every new Claude session loads it automatically.

If you are an AI agent in a new session: read this file first when you need to write, read, archive, or back up anything. If two other docs disagree about where something lives, this file wins.

**Last reviewed:** 2026-04-19
**Mirror on AstronOne:** `/Volumes/AstronOne/shared-memory/dexhub/ARCHITECTURE.md` (longer, includes recovery procedures)

---

## 0. ⚠️ WORKTREE IDENTITY CHECK (read BEFORE any write)

At any given time, the user may have **multiple parallel Claude Code sessions** active, each anchored in a different worktree. Cross-session commits into the wrong repo HAVE HAPPENED (2026-04-19 incident — RZP session committed DexHub Phase 5.1 work into Beta repo during a "next phase" ambiguity).

**Protocol before any file write:**
1. Read `.dexcore-session-anchor` at the repo root. It declares `expected_origin`, `expected_worktree_path_contains`, `expected_branches`.
2. Verify: `git config --get remote.origin.url` matches `expected_origin`.
3. Verify: `pwd` contains `expected_worktree_path_contains`.
4. Verify: `git rev-parse --abbrev-ref HEAD` is in `expected_branches`.
5. If any mismatch OR the user's request is ambiguous across worktrees: **STOP, ASK, DON'T GUESS.**

`validate.sh §24` checks the anchor consistency automatically. If §24 fails, something is structurally wrong with the repo — investigate before acting.

**Known parallel worktrees (not this repo):**
- RZP POC work → `~/Downloads/rzp-alba-flowable-konform/` (Flowable-konform branch)
- RZP worktree (exp-cleanup) → `~/Downloads/rzp-alba-prototyp-worktree-exp-cleanup/`
- DexHub Alpha (tombstoned, read-only) → `~/Downloads/test-1911-0349_dexHub-Enterprise-Alpha-1.0-master/`

**This repo (Beta) is at:** `~/Documents/A+/AVX/AI_Workspace/dexHub-Enterprise-Beta-1.0/`

See: `SESSION_ERROR_2026_04_19_RZP_CROSSED_INTO_BETA_PHASE5.md` in memory for the incident writeup + MEMORY.md Ground Rule #9 ("Worktree-anchor beats phase-name").

---

## 1. The 3 storage layers

| Layer | Path | Role | Speed | Availability |
|---|---|---|---|---|
| **L1 Local working repo** | `~/Downloads/test-1911-0349_dexHub-Enterprise-Alpha-1.0-master/` | Source of truth for code, in-flight work | Fast (SSD) | Always, while Mac is on |
| **L2 Local Claude memory** | `~/.claude/projects/-Users-az-Downloads-test-1911-0349-dexHub-Enterprise-Alpha-1-0-master/memory/` | Primary memory store for this project | Fast (SSD) | Always |
| **L3 AstronOne mirror + archives** | `/Volumes/AstronOne/shared-memory/dexhub/` | Redundant mirror + long-term archives + phase backups | Slow (SMB, ~150× slower for small files) | Only when SMB mount is active |

**Origin remote** `areanatic/dexHub-Enterprise-Alpha-1.0` (private GitHub) is the offsite-ish backup for git history. It is the primary disaster recovery anchor for code.

**Azamani1 remote** is **tombstoned** (push URL `no_push://`). Never push there. Archive-only read access.

---

## 2. Where each kind of data lives

### 2a. Code, docs, tools, tracked files

- **Primary:** L1 working repo
- **Backup:** origin remote (every push) + `phase0-backups-2026-04-12/git-bundle/` on L3 (snapshot)
- **Never on:** L3 directly (we don't rsync the working tree)

### 2b. Session memory files

- **Primary:** L2 `~/.claude/.../memory/*.md`
- **Mirror:** L3 `/Volumes/AstronOne/shared-memory/dexhub/*.md` (flat layout, same filenames)
- **Mirror trigger:** Claude copies a memory file to L3 when it is important enough that losing it would hurt (session ends, important finding, new learning). Not every memory write.
- **MEMORY.md index:** Lives in L2 as `MEMORY.md`, mirrored to L3 as `MEMORY.md`. Always kept ≤200 lines of index entries. Details live in separate per-topic files.

### 2c. Archives and snapshots (one-off immutable copies)

- **Primary:** L3 only — `/Volumes/AstronOne/shared-memory/dexhub/archives/<topic>-<YYYY-MM-DD>/`
- **Content of an archive entry:**
  - The archived files (e.g. `release.tar.gz`, `env.live.env`)
  - `SHA256SUMS.txt` for integrity
  - `MANIFEST.md` explaining what, why, retention, cross-references
- **Examples in use:**
  - `archives/rzp-alba-release-snapshot-2026-04-13/` — tar of the playground-only DHL release
  - `archives/secrets-archive-2026-04-13/` — pre-rotation Atlassian + Figma PATs
- **Never write archives to L1 or L2** — they belong only on L3.

### 2d. Phase backups (full safety-net snapshots)

- **Primary:** L3 — `/Volumes/AstronOne/shared-memory/dexhub/phase0-backups-<date>/`
- **Structure:** git-bundle, stashes, worktree-tar, mydex-projects-tar, release-artifacts, findings, README, MANIFEST
- **When created:** Before each major migration phase (Phase 0 was the only one so far)
- **Next expected:** Before Phase 3 Beta clone (full state capture)

### 2e. Working-tree ignored bulk (myDex/projects/, inbox/, drafts/)

- **Primary:** L1 — in the working repo but gitignored, not on origin remote
- **Backup:** Captured in Phase 0 tar as `phase0-backups-2026-04-12/mydex-projects-tar/`. Newer state is **not mirrored** unless a new phase backup runs.
- **Risk:** If L1 dies between phase backups, gitignored content not captured since last phase backup is **lost**. User is aware (open question: offsite cloud backup of `myDex/projects/`).

### 2f. Secrets and tokens

- **Primary live state:** Scrubbed files on L1 with `PENDING_ROTATION_2026_04_13` placeholders (`.env.mcp-atlassian`, `myDex/projects/figma-integration-pocs/.env`). These files are gitignored.
- **Archive of pre-rotation values:** L3 `archives/secrets-archive-2026-04-13/` with SHA-256 + MANIFEST
- **Rotation status:** Pending user action. See `TODO_ROTATION_PENDING_2026_04_13.md` in L2.
- **Never commit:** any file containing real tokens. The `.gitignore` allowlist under `.claude/` and the `*env`/`*.key`/`credentials.json` patterns enforce this.

### 2g. Hooks and per-clone local state

- **Primary:** `.git/hooks/pre-push` on L1 (installed by `install-hooks.sh`)
- **Not tracked by git.** If L1 is cloned fresh, the installer must run again.
- **Source of the hook body:** `.dexCore/_dev/tools/install-hooks.sh` (in-repo, tracked)
- **Scan script it delegates to:** `.dexCore/_dev/tools/pre-push-scan.sh` (in-repo, tracked)

### 2h. Configuration and manifests

- **Primary:** In-repo under `.dexCore/_cfg/` (`manifest.yaml`, `config.yaml`, `agent-manifest.csv`)
- **Version SSOT:** `manifest.yaml` → mirrored to `config.yaml` → mirrored to `README.md` badge. Drift detected by `.dexCore/_dev/tools/version.sh`.

---

## 3. Quick lookup: "I want to ..."

| Task | Go here |
|---|---|
| Read what we decided last session | L2 `MEMORY.md` top entries, then the specific `session_*` or `SESSION_END_*` file |
| Check the current migration phase status | `.dexCore/_dev/docs/PHASE-CONTRACTS.md` |
| Check the master plan | L2 `SCHLACHTPLAN_v4.2_PORTABILITY_LAYER_2026_04_12.md` (frozen) + `SCHLACHTPLAN_v4.2_BACKLOG_UPDATES_2026_04_13.md` (live delta) |
| Understand where something on AstronOne came from | Read its sibling `MANIFEST.md` in the same archive subfolder |
| Find what's on AstronOne | L3 `ARCHITECTURE.md` (entry point doc) |
| Rotate secrets | L2 `TODO_ROTATION_PENDING_2026_04_13.md` has the step-by-step |
| Restore from disaster | L3 `ARCHITECTURE.md` § Recovery procedures |
| Add a new archive | L3 `archives/<topic>-<YYYY-MM-DD>/` with `SHA256SUMS.txt` + `MANIFEST.md`. Never skip the manifest. |
| Add a new memory file | L2 `*.md` first (primary), then mirror to L3 when important |
| Know whether a file should be committed to git | If it's under `.claude/*` check the allowlist in `.gitignore`. If unclear, don't commit — ask. |
| Know whether a file should be pushed to azamani1 | **No. Azamani1 is tombstoned.** All DexHub work pushes to `origin` (areanatic). |

---

## 4. Integrity rules

1. **Archive-first** before any destructive action. Never 100% delete anything. See `feedback_archive_first_never_delete.md` in L2.
2. **Source-of-truth is local**, mirror is on AstronOne. If L1 and L3 disagree about a file's content, L1 wins (unless L3 is an older timestamped archive, in which case L3 is historical truth and L1 is current).
3. **Every archive needs a MANIFEST.md.** Undocumented files are poison.
4. **Every commit that changes the storage architecture** must also update this file AND the AstronOne `ARCHITECTURE.md`.
5. **Retention = forever** for memory and archives. No auto-delete. Capacity is not currently a concern (3% of AstronOne used).

---

## 5. Open questions (as of 2026-04-13)

1. **Is AstronOne itself backed up offsite?** If no, both Mac Minis are in the same building and represent a single point of failure. User to evaluate a cloud backup of `shared-memory/dexhub/` (Backblaze, S3, iCloud for small stuff).
2. **Is `~/.claude/projects/` backed up by Time Machine or iCloud?** If no, local memory can only be recovered from L3 mirror (which is only as fresh as the last mirror operation).
3. **When do we next run a phase backup?** Plan: before Phase 3 Beta clone (`phase3-backups-<date>/`). Until then, running is at the user's discretion.

---

## 6. Cross-reference

This file:
- Is compiled into `.claude/CLAUDE.md` and `.github/copilot-instructions.md` via `build-instructions.sh`, so every session loads it
- Is listed in `PHASE-CONTRACTS.md` Phase 2 Block 1 as a delivery
- Is referenced from `MEMORY.md` top entry for fast lookup
- Mirrors (longer form, with recovery procedures): L3 `/Volumes/AstronOne/shared-memory/dexhub/ARCHITECTURE.md`

**Contradictions between this file and another doc:** This file wins on location questions. More recent memory files win on topic-specific current state. When in doubt, grep both and ask.
