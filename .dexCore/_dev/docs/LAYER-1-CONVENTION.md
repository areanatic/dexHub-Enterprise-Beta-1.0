# Layer 1 Convention — DexHub 3-Layer Knowledge Architecture

**Status:** Phase 1 MVP foundation (v4.2 SCHLACHTPLAN, Story E1.1)
**Created:** 2026-04-13
**Supersedes:** nothing — first formal definition

---

## What are the 3 Layers?

DexHub organizes knowledge into **three layers** with strict priority ordering:

| Layer | Role | Examples | Authority |
|-------|------|----------|-----------|
| **Layer 1** | **Truth / Rules** (always-loaded, invariant) | SHARED.md, platform tails, truth-manifest, agent definitions, G1-G8 | **HIGHEST** |
| **Layer 2** | **Searchable Context** (on-demand, semantic) | myDex/inbox/, myDex/drafts/, project docs (via RAG) | MEDIUM |
| **Layer 3** | **Session State** (per-session, mutable) | CONTEXT.md, chronicle/YYYY-MM-DD.md, decisions/ | LOW |

**Conflict Resolution Rule (G9):**
> When Layer 2 or Layer 3 content contradicts Layer 1, **Layer 1 wins**.
> The agent must flag the contradiction to the user and propose updating the lower layer.

---

## What qualifies as Layer 1?

Layer 1 content must satisfy ALL of:

1. **Project-invariant:** applies across all sessions, all projects in this DexHub instance
2. **Authoritative:** not a proposal, not a draft, not a "for-now" snapshot
3. **Load-on-start:** read at session launch, not on-demand
4. **Platform-agnostic OR explicitly platform-tailed** (via SHARED.md + {claude,copilot}-specific.md)
5. **Listed in `truth-manifest.md`**

**Not Layer 1:** Drafts, inbox content, ad-hoc session notes, personal preferences, project-specific analysis, CONTEXT.md, chronicle.

**Edge cases:**
- **Agent definitions** (`.dexCore/core/agents/*.md`): Layer 1 — they define behavior, are invariant, load-on-use
- **Guardrails (G1-G8) in SHARED.md:** Layer 1 — core rules
- **profile.yaml (user prefs):** NOT Layer 1 — user-mutable, session-scoped
- **project truth-files (e.g., RZP-ARCHITECTURE-REFERENCE.md):** **Project-Layer-1** (promoted to Layer 1 inside that project's scope only)

---

## The Truth-Manifest

`.dexCore/core/instructions/truth-manifest.md` is the **authoritative list** of Layer 1 files. It is itself Layer 1 (meta-truth).

Format: plain markdown with YAML-like keyed sections. No external tool required to parse.

The manifest lists:
- **Global Layer 1** files (all projects, all sessions)
- **Project-scoped Layer 1** files (per-project promotion)
- **Expected SHA-256 hashes** for drift detection (updated by `build-instructions.sh`)

**Rules:**
- A file NOT in truth-manifest is NOT Layer 1 (even if it looks important)
- Any edit to a Layer 1 file should be acknowledged by updating truth-manifest if the file's role changes
- On conflict: what the truth-manifest says wins

---

## G9 Guardrail (NEW — Layer 1 Wins)

Added to the Guardrails set (G1-G8 in SHARED.md; G9 is introduced here):

### G9: Layer 1 Wins

When answering any question or executing any task:
1. **First:** check Layer 1 (SHARED.md, truth-manifest, agent definitions)
2. **Then:** Layer 2 (RAG search over inbox/drafts/project docs) — **only if Layer 1 is silent**
3. **Then:** Layer 3 (session state, CONTEXT.md, chronicle) — **only to resume state, not to override rules**

**On Contradiction:**
- Lower layer says X, Layer 1 says NOT-X → follow Layer 1
- Flag to user: "⚠️ {layer_2_source} says X, but Layer 1 (SHARED.md:LINE) says NOT-X. Following Layer 1. Should I update {layer_2_source}?"
- NEVER silently prefer Layer 2 or 3

**Why:** Session state and RAG results decay and drift; Layer 1 is the invariant anchor.

This rule will be embedded in SHARED.md in a follow-up commit (Phase 2 cleanup) so it's loaded at session start.

---

## How this interacts with the Compile Step

The Compile Step (`build-instructions.sh`, see E2.3) takes Layer 1 sources (`SHARED.md` + platform tails) and emits platform-native outputs:
- `.github/copilot-instructions.md` — concatenation
- `.claude/CLAUDE.md` — concatenation (fallback) OR `@import` (after A/B test passes)

**Conventions:**
- Sources in `.dexCore/core/instructions/` are the SSOT
- Outputs in `.claude/` and `.github/` are **generated artifacts** — do not edit by hand
- Drift check (`build-instructions.sh check`) runs pre-commit to enforce

---

## Layer 2 preview (for context, not Phase 1 scope)

Layer 2 will be implemented in Phase 4b:
- Indexer runs over `myDex/inbox/`, `myDex/drafts/`, `myDex/projects/*/.dex/`
- sqlite-vec + Ollama nomic-embed-text for semantic search (PoC required first — Schwachstelle 2)
- API endpoint `/api/rag/query` + `/api/rag/index` in server.js
- **NEVER** overrides Layer 1 (per G9)

## Layer 3 preview

Layer 3 is already partially implemented via:
- `myDex/.dex/CONTEXT.md` — system-level state
- `myDex/projects/{name}/.dex/CONTEXT.md` — per-project state
- `.dex/chronicle/YYYY-MM-DD.md` — daily session logs
- `.dex/decisions/NNN-*.md` — captured decisions

Full wire-up (E1.3+E1.4) is Phase 4b scope. Phase 1 only establishes the convention.

---

## Migration note

Existing files in `.claude/CLAUDE.md` and `.github/copilot-instructions.md` are still hand-maintained as of Commit `acdb2fb` (Phase 1 Block 3). They will be cutover to generated-from-SSOT in Block 4 or Phase 2 once:
1. A/B test for `@import` passes (or we accept concat-only for Claude too)
2. Pre-commit drift-check hook is wired in

Until then, a **known, documented drift** exists. `build-instructions.sh check` will report it — that's expected.
