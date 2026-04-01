---
name: dexhub-architecture
description: "DexHub file structure, module layout, silo architecture, and development structure. Use when exploring the codebase, understanding where files go, or planning new modules."
---

# DexHub Architecture

## Directory Structure

```
.dexCore/                     ← Framework (DO NOT modify without understanding)
├── _cfg/                     ← Configuration (manifests, config.yaml)
│   ├── agent-manifest.csv    ← Source of truth: all agents
│   ├── workflow-manifest.csv ← Source of truth: all workflows
│   └── config.yaml           ← Global config (language, modules, guardian)
├── core/                     ← Core module (DexMaster, myDex, workflow engine)
│   ├── agents/               ← Core agent definitions
│   ├── integrations/         ← MCP integrations (Atlassian, GitHub)
│   ├── tasks/                ← Execution engines (workflow.xml, guardian-check.xml)
│   └── workflows/            ← Core workflows (brainstorming, council-mode, init)
├── dxm/                      ← Development Methodology module
│   ├── agents/               ← 13 DXM agents (analyst, architect, dev, pm, etc.)
│   ├── workflows/            ← Phase workflows (1-analysis → 4-implementation)
│   └── templates/            ← Project templates, chronicle templates
├── dis/                      ← Creative Intelligence module
│   ├── agents/               ← 5 DIS agents (brainstorm, design-thinking, etc.)
│   └── workflows/            ← Creative workflows
├── dxb/                      ← Builder module
│   ├── agents/               ← DexBuilder agent
│   └── workflows/            ← Create agent/workflow/module/skill
├── meta-agents/              ← 18 brownfield analysis agents
├── custom-agents/            ← User/community contributed agents (Atlas)
└── _dev/                     ← Development tracking (NOT user-facing)
    ├── todos/                ← bugs.md, features.md, roadmap.md
    ├── tools/                ← validate.sh, dashboard, scripts
    ├── docs/                 ← Architecture docs, feature specs
    └── archive/              ← Historical planning docs

.github/                      ← GitHub Copilot Integration
├── agents/                   ← 18 .agent.md files (Copilot auto-discovers)
└── skills/                   ← 10+ Skills (lazy-loaded knowledge)

├── IDE-instructions.md                 ← IDE instructions
├── skills/                   ← IDE skills (testing)
└── settings.json             ← Hooks (post-write-check)

myDex/                        ← User Workspace (gitignored sensitive data)
├── .dex/                     ← System-wide config, chronicle, decisions
│   ├── config/               ← profile.yaml, onboarding-questions.yaml
│   ├── chronicle/            ← Daily session logs
│   └── decisions/            ← Captured decisions
├── inbox/                    ← Drop external files here
├── drafts/                   ← Temporary outputs (before project creation)
├── export/                   ← Finished products for external use
└── projects/{name}/          ← Project workspaces
    ├── src/                  ← Code ONLY
    └── .dex/                 ← All meta-data (analysis, planning, docs)
```

## Module System

Each module has: `agents/` + `workflows/` + optional `config.yaml`

| Module | ID | Scope |
|--------|----|-------|
| Core | `core` | Orchestration, workspace, integrations |
| DXM | `dxm` | Full development lifecycle |
| DIS | `dis` | Creative intelligence, innovation |
| DXB | `dxb` | Platform building (agents, workflows, skills) |
| META | `meta-agents` | Codebase analysis (read-only) |

## Manifests (Source of Truth)

- `agent-manifest.csv`: name, displayName, module, path, visibility (user/meta/system)
- `workflow-manifest.csv`: name, description, module, path
- Changes to agents/workflows MUST be reflected in manifests
