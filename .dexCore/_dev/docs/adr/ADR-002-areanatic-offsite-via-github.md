# ADR-002: areanatic (GitHub private) is the offsite backup; AstronOne is local only

**Date:** 2026-04-14
**Status:** accepted
**Deciders:** Arash Zamani, phase-2-session
**Context:** Phase 2 Block 4 hygiene review

## Context

During Phase 2 of the Beta Migration (Block 4, offsite backup review), three storage layers were identified:
- **L1 — local working repo** on laptop SSD (`~/Downloads/test-1911-0349_...`)
- **L2 — `~/.claude/projects/.../memory/`** for session memory files
- **L3 — `/Volumes/AstronOne/shared-memory/`** on the Mac Mini via SMB mount

The question was: "What is our offsite backup story?"

AstronOne (Mac Mini M4 Pro) lives in the same physical location as the laptop. SMB mount is ~150× slower than local SSD for small files. Most importantly: **AstronOne is not offsite**. A single-location disaster (fire, theft, flood) would lose both L1 and L3 simultaneously.

## Decision

**`origin` (the areanatic GitHub private repo) is the canonical offsite backup. AstronOne is a fast local mirror only.**

- Every commit that matters must be pushed to `origin` within the 2h-commit rule.
- AstronOne remains useful for: archive snapshots (SHA-256 + MANIFEST), session-memory mirror, phase-backup tarballs, cold storage of work-in-progress that isn't yet committable.
- AstronOne is **not** trusted as the only copy of anything. If the AstronOne mirror is the only copy, the data is at risk.
- No paid cloud backup service is adopted for DexHub at this time. GitHub private repositories satisfy the offsite requirement for code + memory that can be committed.

## Consequences

**Positive:**
- Clear storage-layer semantics. No confusion about "where is the truth?"
- The 2h-commit rule gets a second justification (not just discipline, also backup).
- Memory files that can be committed (workstreams.csv, ADRs, CANONICAL-LOCATIONS) are backed up automatically.

**Negative / accepted:**
- Session-memory under `~/.claude/projects/.../memory/` is **not** committed and thus not offsite-backed. This is a known gap — if the laptop and AstronOne fail simultaneously, recent session memory is lost. Accepted risk: the user can reconstruct from chat history + global learnings.
- The archive snapshots on AstronOne (Phase 0 backup tarball, secrets-archive, etc.) are single-location. If AstronOne fails, they are gone. Accepted risk pending a future "external drive rotation" decision.

## Alternatives considered

1. **Adopt a paid cloud backup (Backblaze/Borg/Arq)** — deferred. No budget allocated; risk tolerated.
2. **Treat AstronOne as offsite** — rejected, same physical location.
3. **Push session-memory to a private git repo** — deferred as a possible Layer 5 hygiene item. Not blocking.

## References

- `SESSION_END_2026_04_14_PHASE_2_COMPLETE.md` — Phase 2 closeout discussion
- `feedback_archive_first_never_delete.md` — related principle
- `CANONICAL-LOCATIONS.md` — canonical storage layer map
- `ARCHITECTURE.md` on AstronOne — recovery procedures for 3 failure scenarios
