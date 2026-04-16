# ADR-006: SSOT compile step for multi-platform AI instructions

**Date:** 2026-04-13
**Status:** accepted — implemented in Phase 1 (commit `acdb2fb`)
**Deciders:** Arash Zamani, phase-1-session
**Context:** Phase 1 Canary — Block 3

## Context

DexHub runs as a "Portability Layer across LLM Providers": the same AI behavior is expected on GitHub Copilot, Claude Code, Cursor, Continue.dev, Ollama, and direct API callers. Each platform has its own native instruction format:

- **Claude Code** — `~/.claude/CLAUDE.md` + project `CLAUDE.md`
- **GitHub Copilot** — `.github/copilot-instructions.md`
- **Cursor** — `.cursor/rules/*.md`
- **Continue.dev** — `.continuerules`
- **Direct API** — system prompt strings embedded in code

Before Phase 1, instruction content was maintained in parallel across several of these files by hand. Observed drift examples:
- G3 Root-Forbidden rule lived in `CLAUDE.md` but not in `copilot-instructions.md`.
- The DexMaster Meta-Layer section was updated in Claude Code config but not in Copilot config for ~2 weeks.
- A Copilot-only "Always-On DexHub activation" feature was maintained in Copilot config only but referenced as "active" in Claude Code sessions.

Each drift caused a bug or a user-experience inconsistency. The pattern was clear: **N parallel copies of the same content cannot be hand-synced reliably**.

## Decision

**Establish a single source of truth (SSOT) for platform-agnostic instruction content and compile it into each platform's native format via a build script.**

Structure:
```
.dexCore/core/instructions/
├── SHARED.md                 ← single source of truth (486 lines)
├── claude-specific.md        ← Claude-only tail (22 lines)
├── copilot-specific.md       ← Copilot-only tail (227 lines)
└── truth-manifest.md         ← lists which files ARE the canonical SSOT

.dexCore/_dev/tools/
└── build-instructions.sh     ← compiler: SSOT → native outputs
```

Build script modes:
- **build** — compile SHARED.md + {platform}-specific.md → platform-native target file (`CLAUDE.md` / `copilot-instructions.md` / etc.).
- **check** — compile in-memory and diff against target file; exit non-zero on drift. For CI enforcement.
- **dry-run** — show what would be written without touching files.

## Consequences

**Positive:**
- Content drift across platforms is mechanically impossible if the check mode runs in CI.
- Platform-specific adaptations have a documented home (the `*-specific.md` tails) without polluting the shared content.
- Adding a new platform (Cursor, Continue.dev) requires only adding a new `*-specific.md` tail and a build target, not copy-pasting 500+ lines.
- The compile step is a natural documentation point: "to change the behavior, edit SHARED.md".

**Negative / accepted:**
- Direct edits to auto-generated files (`CLAUDE.md`, `copilot-instructions.md`) are forbidden — users must edit the SSOT instead. This is counter-intuitive on first encounter and must be documented in the target file's header.
- The build script is now a dependency of the instruction system. A bug in the build script can produce broken target files. Mitigated by `check` mode running before commits and by the build script being simple bash.
- E1.2b (live-file cutover for Claude Code's canonical sink file) was deferred at end of Phase 1 pending an A/B-test — the cutover happened in Phase 2 Block 1 (`5611506`).

## Alternatives considered

1. **Keep hand-sync** — rejected, causes drift (see Context).
2. **Symlinks** — rejected, platforms do not reliably follow symlinks (especially on Windows / Copilot).
3. **Generate at runtime** — rejected, some platforms (Copilot) read the file at cold start and don't re-read dynamically.
4. **One mega-file per platform with `#include`** — rejected, no platform supports includes natively.
5. **A heavier build tool (Make, Task, Just)** — deferred. Bash is sufficient for 3 files and fits the "local-first" principle.

## Sequence inversion note (Phase 1)

E2.3 (build script) was written *before* E1.2 (live-file cutover). This inversion was deliberate: the build script was needed to *produce* the cutover output, so writing the consumer first would have been impossible. The inversion saved ~4 hours of double-work that would have been needed in Phase 4 otherwise.

## References

- `PHASE_1_COMPLETION_LOG_2026_04_13.md` — Phase 1 closeout
- `.dexCore/core/instructions/SHARED.md` — the SSOT
- `.dexCore/core/instructions/truth-manifest.md` — canonical file list
- `.dexCore/_dev/tools/build-instructions.sh` — the compiler
- `~/.claude/learnings/ssot-compile-step-and-canonical-locations.md` — global learning
- Phase 1 Block 3 commit: `acdb2fb feat(instructions): SSOT Compile Step — SHARED.md + build-instructions.sh`
