# Truth-Manifest — DexHub Layer 1 Authoritative Files

**Status:** Layer 1 (meta-truth)
**Version:** 1.0 (Phase 1 MVP, Story E1.1)
**Convention:** See `.dexCore/_dev/docs/LAYER-1-CONVENTION.md`
**Updated by:** Manual commits. Hash enforcement deferred to Phase 4b (Layer 2 indexer).

---

## Rules

1. A file NOT listed here is NOT Layer 1. Period.
2. Entries are categorized: `global` (all projects) or `project-scoped` (one project only)
3. This file itself is Layer 1 (meta-truth)
4. Hash tracking is deferred to Phase 4b (Layer 2 indexer will enforce; until then no hashes here)

---

## Global Layer 1 — Instructions (SSOT + Tails)

```yaml
global_instructions:
  - path: .dexCore/core/instructions/SHARED.md
    role: "Single Source of Truth — platform-agnostic DexHub rules, guardrails, conventions"
    critical: true

  - path: .dexCore/core/instructions/claude-specific.md
    role: "Claude Code specific tail (appended to SHARED when building .claude/CLAUDE.md)"
    critical: true

  - path: .dexCore/core/instructions/copilot-specific.md
    role: "GitHub Copilot specific tail (appended to SHARED when building .github/copilot-instructions.md)"
    critical: true

  - path: .dexCore/core/instructions/truth-manifest.md
    role: "This file — authoritative Layer 1 index"
    critical: true
```

## Global Layer 1 — Agents

```yaml
global_agents:
  - path: .dexCore/core/agents/dex-master.md
    role: "DexMaster — permanent orchestrator (loaded via intent detection protocol)"
    critical: true
    always_load_on: [greeting, agent-request-ambiguous]

  - path: .dexCore/core/agents/mydex-agent.md
    role: "myDex Project Manager — project context, chronicle, DexMemory handlers"
    critical: true
    always_load_on: [project-active]
```

## Global Layer 1 — Config

```yaml
global_config:
  - path: .dexCore/_cfg/manifest.yaml
    role: "Installation manifest — version, modules, IDE list"
    critical: true
    owned_by: build + version.sh

  - path: .dexCore/_cfg/config.yaml
    role: "Project configuration — language, user name, paths, guards"
    critical: true
    user_editable: true
    note: "version field is SSOT-mirrored, not primary"

  - path: .dexCore/_cfg/agent-manifest.csv
    role: "Source of truth for agent name resolution (G4 agent resolution rule)"
    critical: true
```

## Global Layer 1 — Guardrails (embedded in SHARED.md)

Not separate files — rules G1-G9 live inside `SHARED.md` under `## Guardrails (G1-G9)`. G9 was embedded 2026-04-13 (Phase 1 follow-up).

```yaml
guardrails_live_in: .dexCore/core/instructions/SHARED.md
rules:
  - G1: "Output Format — MD only"
  - G2: "Diff-First — show diff before overwrite"
  - G3: "Root-Forbidden — use Smart Routing"
  - G4: "Check-Existing-First — inventory before create"
  - G5: "Consent-Pattern — wait for Go/Ja/Yes"
  - G6: "No Hallucinated Paths — verify with file system"
  - G7: "Verify-Before-Done — manual sweep after agent work"
  - G8: "No Personal Data in Commits — scan before push to enterprise"
  - G9: "Layer 1 Wins — over Layer 2 and Layer 3 (introduced 2026-04-13, embedded in SHARED.md)"
```

---

## Project-Scoped Layer 1

Each project may promote specific files to project-local Layer 1 status by listing them here under its `project` key. Project-scoped Layer 1 applies only when working inside that project's scope.

```yaml
project_scoped:
  RZP-Rentenzahlplattform:
    - path: myDex/projects/RZP-Rentenzahlplattform/.dex/docs/RZP-ARCHITECTURE-REFERENCE.md
      role: "SSoT for RZP program architecture (ALBA / AURA / KONF / module hierarchy)"
      critical: true
      added: 2026-04-09
      reason: "Confluence-validated truth; overrides all prior memory about RZP naming"

    - path: myDex/projects/RZP-Rentenzahlplattform/.dex/docs/RZP-PROGRAMM-WORKFLOW.md
      role: "Master concept, 26 sections — program workflow, zones, push matrix"
      critical: true
      added: 2026-04-09

  rzp-alba-prototyp:
    note: "Nested git repo with its own lifecycle. Layer 1 managed inside that repo separately."

  # Future projects add their truth files here
```

---

## Anti-Patterns (what NOT to promote to Layer 1)

- Session chronicles (`chronicle/YYYY-MM-DD.md`) — these are Layer 3 (session state)
- Drafts in `myDex/drafts/` — unvalidated, Layer 2 material
- Analysis reports — one-off, usually Layer 2
- Memory files in `~/.claude/projects/.../memory/` — per-user, per-project, Layer 3
- Agent session state (`myDex/.dex/agents/*.working-state.md`) — Layer 3

---

## How to add a file to Layer 1

1. Verify it satisfies ALL 5 Layer 1 criteria (see `LAYER-1-CONVENTION.md`)
2. Add an entry to this manifest in the right category
3. Commit with message `chore(truth-manifest): promote <file> to Layer 1 — <reason>`
4. (Hash enforcement arrives in Phase 4b via Layer 2 indexer — until then no hashes tracked here)

## How to remove a file from Layer 1

Rare. Only if the file becomes obsolete or is archived. Procedure:
1. Remove entry from this manifest
2. If the file still exists, move it to its new home (Layer 2 or archive)
3. Commit with message `chore(truth-manifest): demote <file> from Layer 1 — <reason>`

---

## Drift & Hash Policy

Hash tracking is **informational** in Phase 1. In Phase 4b (Layer 2 RAG full implementation), hashes become **enforced** via the Layer 2 indexer: if a Layer 1 file's content hash differs from the manifest, the indexer refuses to serve search results until the manifest is updated (ensures Layer 1 drift is always intentional).

Until then, `build-instructions.sh check` will report drift between sources and generated outputs, but does NOT block work.

---

**This manifest is authoritative. When in doubt, it beats memory, agent assumption, or old docs.**
