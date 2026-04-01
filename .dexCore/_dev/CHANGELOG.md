# DexHub Changelog

> Development changelog for DexHub Enterprise Beta

## [EB-1.0] — 2026-04-01

### Initial Enterprise Beta Release

**Agents:**
- 43 agents (26 user-facing + 18 meta-agents)
- 46 .agent.md files for GitHub Copilot integration
- 3 integration onboarding agents (Atlassian, GitHub, Figma)
- All agent names aligned with manifest

**Workflows:**
- 45 guided workflows across 4 phases
- All workflow paths verified (0 broken references)
- Brainstorming checklist.md created

**Skills:**
- 12 lazy-loaded knowledge packs
- Platform Awareness skill (IDE vs Copilot)

**Integrations:**
- Atlassian MCP (Jira + Confluence)
- GitHub Enterprise MCP
- Figma MCP + REST client
- Generic setup wizards (no hardcoded URLs)

**Infrastructure:**
- validate.sh (168+ automated checks)
- files-manifest.csv fully migrated to .dexCore paths
- All legacy naming cleaned (bmb→dxb, bmm→dxm, cis→dis)
- Guardrails G1-G7 + Safety Rules + Archive Protocol

**Knowledge Base (recovered from prior versions):**
- 8 analysis documents (platform compatibility, methodology comparison, etc.)
- 5 architecture documents (ADR-002, meta-layer deep dive, etc.)
- 8 use case documents
- MASTERPLAN-EA-1.5 strategic document

### Migration from EA-1.5
- ~190 path corrections (dex/→.dexCore/, cis/→dis/, outputs/→drafts/)
- Profile schema aligned (Q1 language: de/en, Q2 path fixed)
- GitHub MCP genericized (no DHL-specific URLs)
- 150KB strategic knowledge recovered from older instances
