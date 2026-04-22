---
name: dexhub-guardrails
description: DexHub Safety Guardrails G1-G6 — file creation rules, consent patterns, output format enforcement
---

# DexHub Guardrails (G1-G6)

These guardrails apply to ALL agent behavior in DexHub.

## G1: Output Format
ALWAYS create Markdown (.md) files. NEVER create .yaml, .json, or other formats UNLESS the user explicitly requests it.

## G2: Diff-First
ALWAYS show a diff BEFORE overwriting an existing file. Wait for explicit approval before writing.

## G3: Root-Forbidden
NEVER create files in the project root. Use the Smart Routing table:

| Category | Location |
|----------|----------|
| ADRs, decisions | `.dexCore/_dev/docs/` |
| Feature docs, roadmaps | `.dexCore/_dev/planning/` |
| Agent definitions | `.dexCore/_dev/agents/` |
| Analysis outputs | `myDex/projects/{name}/.dex/1-analysis/` or `myDex/drafts/` |
| Planning docs | `myDex/projects/{name}/.dex/2-planning/` or `myDex/drafts/` |
| Architecture specs | `myDex/projects/{name}/.dex/3-solutioning/` |
| Code | `myDex/projects/{name}/src/` or `src/` |

## G4: Check-Existing-First
ALWAYS inventory existing files, agents, workflows BEFORE creating new ones. Never reinvent what exists. Keep scope proportional to the request.

## G5: Consent-Pattern
Before ANY file creation, modification, or deletion:
1. Show what you plan to do
2. WAIT for explicit "Go" / "Ja" / "Yes"
3. THEN execute

## G6: No Hallucinated Paths
NEVER reference files or paths that don't exist. Verify with file system first.

## Privacy & Safety

**NEVER:**
- Auto-create projects without user consent
- Delete files without confirmation
- Modify config without telling user
- Execute workflows without explicit approval
- Share user working data with external services without explicit consent (data-local discipline: working data on disk; LLMs + connectors opt-in only)

**ALWAYS:**
- Ask before migrating files
- Confirm before deleting originals
- Show what will happen before doing it
- Allow user to cancel at any step
