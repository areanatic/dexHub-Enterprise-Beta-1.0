# ADR-009: Agent Boundary State Model (D1 prompt-layer fix)

**Date:** 2026-04-17
**Status:** accepted — prompt layer implemented in Phase 4 Block 3 (commit `d248f0d`), persistence layer (Option 3) deferred
**Deciders:** Arash Zamani, phase-4-opus-4.6-session, phase-4-opus-4.7-review
**Context:** Phase 4 Block 3 + Phase 4 Reality Sync (2026-04-18)

## Context

DexHub ships 24 user-facing agents plus 22 meta-agents. Each agent has both a persona `.md` file and a Copilot `.agent.md` wrapper. When a user activates a specific agent (e.g., "Load architect Alex"), the user expects that agent — not DexMaster — to respond from that point forward.

Before 2026-04-17, DexMaster's identity was embedded in the always-loaded SHARED.md SSOT:
- "DexMaster is ALWAYS active. Not just on greetings — on EVERY message, throughout ALL processes."
- "User Input → DexMaster (FIRST RESPONDER)"
- "Evaluate intent on EVERY message (DexMaster first)"

Because SHARED.md compiles into `.claude/CLAUDE.md` and `.github/copilot-instructions.md`, these phrases appeared at the top of every LLM context window. This produced **agent identity bleed**: an activated agent would drift back to DexMaster behavior — showing menus, evaluating intent hierarchies, intercepting greetings.

Documented instances:
- Loaded Architect would show the DexMaster menu when the user typed "hi".
- Loaded Analyst would announce itself as DexMaster after a long conversation.
- `.agent.md` identity (Copilot) and CLAUDE.md DexMaster instructions competed in the same prompt context — the permanent/ALWAYS framing won every time.

A detailed fix plan (`myDex/drafts/FIX-PLAN-AGENT-BOUNDARY.md` in the Playground) evaluated five options ranging from documentation-only to full server-side orchestration. Options 2 (prompt refactor) and 3 (state persistence) were identified as the realistic path.

## Decision

**Replace the permanent DexMaster meta-layer with an explicit session state model.** DexMaster becomes one agent among many, loaded on demand when no other agent is active.

### State model (now in SHARED.md)

```
IDLE ............. No agent active → DexMaster loaded on demand from dex-master.md
AGENT:{name} ..... An agent is active → exclusively handles messages in-role
CODE-MODE ........ Raw LLM mode → no DexHub persona, direct LLM access
```

### Transitions

- `IDLE → AGENT:{name}` on agent request or task-direct intent
- `AGENT:{name} → IDLE` on `*exit`
- `AGENT:{name} → AGENT:{new}` on new agent request
- `AGENT:{name} → CODE-MODE` on code-mode request
- `* → IDLE` on greeting when no agent active (loads DexMaster)
- `AGENT:{name} + greeting` → agent responds in-role (does NOT switch to DexMaster)

### The five critical rules

1. ONE identity at a time. When an agent is active, you ARE that agent.
2. Greetings inside an active agent do NOT trigger DexMaster.
3. DexMaster is loaded on demand, not permanently active.
4. State persists until explicit change (*exit, switch, code-mode).
5. Active agent identity takes priority over any other instruction.

### Implementation layers

**Layer 1 — Prompt engineering (implemented 2026-04-17):**
- SHARED.md orchestration protocol replaces DexMaster meta-layer
- `dex-master.md` gets the intent-detection block with "IDLE state only" note
- 24 agent persona files get `<identity-anchor critical="MANDATORY">` blocks
- 45 `.agent.md` Copilot wrappers get a `**CRITICAL:** You are NOT DexMaster` line
- `dex-master.agent.md` wording changes from "permanent first responder" to "on-demand orchestrator"

**Layer 2 — State persistence (deferred, Option 3 from fix plan):**
- Write active agent name to `myDex/.dex/CONTEXT.md` on agent activation
- Read CONTEXT.md at session start to resume state
- Clear on `*exit`
- Not implemented in Phase 4 — planned as separate follow-on work

## Consequences

**Positive:**
- Agents keep identity across turns when the LLM follows the state model
- New paradigm is teachable: "you are in IDLE, AGENT, or CODE-MODE at any time"
- `.agent.md` negative anchors give Copilot a second defensive line
- `dex-master.md` intent-detection block centralizes DexMaster-specific behavior

**Negative / accepted:**
- **State is narrative, not structural.** Without Layer 2 persistence (Option 3), the LLM must "remember" which state it's in across turns. On very long conversations or after context compaction, state can drift.
- **D1 is partially resolved.** The prompt-layer fix is a meaningful improvement but not a complete solution. Full solution requires Option 3.
- **Maintenance burden:** every new agent needs an identity-anchor block. The build-instructions.sh does not enforce this — it is a manual convention.
- **76 files changed at once.** Rollback requires touching all of them.

## Validation

After Phase 4 Block 3, the following were verified:
- SHARED.md has no "DexMaster ALWAYS active" / "EVERY message" / "FIRST RESPONDER" language.
- 24 persona files have identity anchors (24/24 verified).
- 45 `.agent.md` files have negative anchors (dex-master excluded) (45/45 verified).
- `dex-master.md` has intent-detection block with IDLE-only note.
- validate.sh cross-platform consistency checks pass 257/0/0.

The Phase 4 Opus 4.7 Reality Sync (ADR-009 written here, 2026-04-18) caught and fixed:
- `copilot-specific.md` still contained "DexMaster is active in Copilot too / Level 1/2/3" — contradicted the new state model. Rewritten to be consistent.
- No ADR existed for this decision — this document.
- validate.sh §21 added to detect future contradictions between SHARED.md and the platform-specific tails.

## Alternatives considered

See `FIX-PLAN-AGENT-BOUNDARY.md` sections D and E for the full matrix. Ranked summary:

1. **Option 1 — Document as limitation (15 min)** — rejected, does not fix the problem.
2. **Option 2 — Prompt refactor (this ADR)** — accepted.
3. **Option 3 — DexMemory state tracking (4-8h)** — deferred but recommended as follow-on.
4. **Option 4 — Native `.agent.md` isolation (Copilot)** — already in place; Option 2 unblocks its effectiveness.
5. **Option 5 — Server-side orchestration (OpenDex Web)** — long-term, part of separate platform initiative.

## References

- `.dexCore/core/instructions/SHARED.md` — orchestration protocol lines 6-88
- `.dexCore/core/agents/dex-master.md` — intent-detection block
- `SESSION_END_2026_04_17_PHASE_4_BLOCKS_1_2_3.md` — implementation session
- `REALITY_CHECK_2026_04_18.md` — Opus 4.7 forensic review that caught the tail drift
- Phase 4 Block 3 commit: `d248f0d feat(agents): D1 Agent Boundary refactor`
- Phase 4 Reality Sync commit: (this ADR's commit)
- Fix plan: `myDex/drafts/FIX-PLAN-AGENT-BOUNDARY.md` (Playground)
