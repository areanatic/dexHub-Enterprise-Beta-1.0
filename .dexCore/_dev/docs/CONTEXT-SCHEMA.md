# CONTEXT.md Schema — DexMemory + Session State

**File:** `myDex/.dex/CONTEXT.md`
**Status:** Gitignored (user-private local state)
**Owner:** DexMaster (agent-driven convention, never background service)
**Introduced:** Phase 2 honest labeling (2026-04-14)
**Session state block added:** Phase 5 Tier 1a — D1 Layer-2 (2026-04-18)

---

## Purpose

Single file that a new DexMaster session reads at startup to answer:

1. **What am I?** — Session state (IDLE / AGENT:{name} / CODE-MODE). Added in Phase 5 as D1 Option 3 structural fix.
2. **Where was I?** — Last active project, branch, date.
3. **What happened recently?** — Last 10 decisions/actions (rolling).
4. **What's pending?** — Open tasks.
5. **What was decided this session?** — Decisions that haven't made it to `decisions/NNN-*.md` yet.

DexMaster is the sole writer. Other agents do not touch CONTEXT.md — state transitions are mediated by DexMaster at agent activation / exit boundaries.

---

## Canonical Schema (markdown with YAML-ish sections)

```markdown
<!-- DexMemory — Agent-written by DexMaster. Do not edit manually during a session. -->

## Session
state: IDLE | AGENT:{name} | CODE-MODE
active_agent: null | "analyst" | "architect" | ...        # when state = AGENT:{name}
activated_at: null | "2026-04-18T14:30:00Z"                # ISO-8601
previous_agent: null | "{name}"                            # last agent before current
last_transition: "2026-04-18T14:30:00Z"                    # any state change

## Status
active_project: "{project-name}" | "none"
last_date: "YYYY-MM-DD"
last_agent: "{agent-name} (via {platform})"
branch: "{git-branch}"

## Recent (rolling, max 10)
- YYYY-MM-DD: {concise one-line summary}
- ...

## Pending
- {open task 1}
- {open task 2}

## Decisions (this session)
- {decision that hasn't yet moved to .dex/decisions/NNN-*.md}
```

---

## DexMaster State Transitions (D1 Layer-2)

### On agent activation (IDLE → AGENT:{name})

DexMaster is the IDLE-state responder. When user requests agent activation:

1. Load the target agent's persona file.
2. **Before handing off,** update CONTEXT.md `## Session`:
   - `state: AGENT:{name}`
   - `active_agent: "{name}"`
   - `activated_at: "{current ISO-8601}"`
   - `previous_agent:` (copy from `active_agent` before this change, or keep null)
   - `last_transition: "{current ISO-8601}"`
3. Announce the transition once (e.g., "📋 {Name} übernimmt.")
4. Adopt the agent's persona and respond as that agent for all subsequent turns.

### On agent exit (AGENT:{name} → IDLE)

The active agent receives `*exit`:
1. Agent performs its exit protocol (if any — some agents offer a save-chronicle prompt).
2. Agent calls DexMaster-return semantically (narrative handoff).
3. DexMaster updates CONTEXT.md `## Session`:
   - `state: IDLE`
   - `previous_agent: "{name that just exited}"`
   - `active_agent: null`
   - `activated_at: null`
   - `last_transition: "{current ISO-8601}"`
4. DexMaster shows IDLE greeting menu.

### On agent switch (AGENT:{A} → AGENT:{B})

When Agent A is active and the user requests Agent B:
1. Agent A narratively hands control back to DexMaster ("übergebe an {B}").
2. DexMaster writes a **single combined transition** to CONTEXT.md:
   - `state: AGENT:{B}`
   - `active_agent: "{B}"`
   - `previous_agent: "{A}"`
   - `activated_at: "{now}"`
   - `last_transition: "{now}"`
3. DexMaster loads Agent B's persona file and hands off.

The intermediate IDLE state is a **semantic beat, not a persisted state** — it represents the moment DexMaster is mediating the switch, but CONTEXT.md skips directly from AGENT:{A} to AGENT:{B}. This keeps the file consistent with "whoever is actually responding."

**Implication:** Only DexMaster writes CONTEXT.md. Agents themselves never touch it.

### On code-mode (AGENT:{name} → CODE-MODE)

1. Agent pauses.
2. DexMaster updates CONTEXT.md:
   - `state: CODE-MODE`
   - `previous_agent: "{the agent that was active}"`
   - `active_agent: null`
3. Raw LLM mode resumes.

### On session start

When DexMaster loads at session start (step 3.5 of `dex-master.md` activation):
1. Read CONTEXT.md `## Session` block.
2. If `state: AGENT:{X}` and `activated_at` is recent (< 48h):
   - Inform user: "Letzte Session: Agent {X} war aktiv seit {activated_at}. Fortsetzen (`*resume`) oder neu starten (`*help`)?"
   - On `*resume`: load agent file, restore AGENT:{X} state.
   - On `*help` / new agent request: clear session state, proceed normally.
3. If `state: IDLE` or no session block: proceed with standard IDLE greeting.
4. If `state: CODE-MODE`: inform user "Code-Modus war aktiv. Sage 'DexHub' oder 'hi' um DexMaster zu aktivieren."

### On crash / unclean exit

If session dies mid-agent without `*exit`, CONTEXT.md retains the last-known state. Next session's startup routine handles the resume offer.

---

## Honest Limitations (as of 2026-04-18)

1. **Still agent-discipline-based.** DexMaster must faithfully write to CONTEXT.md at every transition. If the LLM skips the write (long-conversation context loss, distraction, compaction), state can become stale.

2. **No automatic enforcement.** There is no hook that fires on agent activation to guarantee the write. `post-write-check.sh` runs on Edit/Write tools but cannot detect agent-activation intent reliably.

3. **File can desync from actual state.** Single source of truth is the conversation itself; CONTEXT.md is a best-effort mirror. If a review or inspection reveals mismatch, treat the conversation as authoritative and fix CONTEXT.md.

4. **No multi-session concurrency.** Two concurrent sessions in two editor windows both write to the same CONTEXT.md. Last write wins. Acceptable for current single-user scale.

5. **Resume offer is heuristic (< 48h).** Long gaps (> 48h) default to fresh IDLE; user can manually reload the agent if needed.

---

## Validation

`validate.sh §22` (added 2026-04-18, Phase 5 Tier 1a):
- If CONTEXT.md exists, verify it contains `## Session` section
- If `state: AGENT:{name}`, verify the agent name exists in `agent-manifest.csv`
- If `activated_at` set, verify ISO-8601 format

Does NOT fail if CONTEXT.md absent (it is gitignored; a fresh user won't have one yet).

---

## References

- ADR-009 — Agent Boundary State Model (paradigm foundation)
- `.dexCore/core/instructions/SHARED.md` — Orchestration Protocol, Agent Loading Protocol
- `.dexCore/core/agents/dex-master.md` — Reads this schema on IDLE startup
- `FIX-PLAN-AGENT-BOUNDARY.md` (Playground) — Option 3 specification
- Phase 5 Tier 1a commit (this)
