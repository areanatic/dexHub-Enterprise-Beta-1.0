<p align="center">
  <img src=".github/dexhub-header.jpg" alt="DexHub — AI-Powered Development Workspace" width="100%">
</p>

<p align="center">
  <a href="https://www.apache.org/licenses/LICENSE-2.0"><img src="https://img.shields.io/badge/License-Apache%202.0-blue.svg" alt="License"></a>
  <img src="https://img.shields.io/badge/version-EB--0.1.0-orange" alt="Version">
  <img src="https://img.shields.io/badge/agents-43-blueviolet" alt="Agents">
  <img src="https://img.shields.io/badge/workflows-45-blueviolet" alt="Workflows">
  <img src="https://img.shields.io/badge/skills-12-blueviolet" alt="Skills">
  <img src="https://img.shields.io/badge/platform-Copilot_%7C_Claude_Code-blue" alt="Platform">
</p>

<p align="center">
  <strong>Your AI development team — structured agents, guided workflows, 100% local.</strong>
</p>

---

## What is DexHub?

DexHub gives you **43 specialized AI agents** and **45 guided workflows** that turn your IDE into a structured development workspace. Instead of generic AI chat, you get a Business Analyst who writes PRDs, an Architect who designs systems, a Developer who implements stories — each following proven methodologies.

**No cloud. No API keys. No installation. Clone and go.**

---

## Quick Start

```bash
git clone https://github.com/areanatic/dexhub-ea-beta.git
cd dexhub-ea-beta
```

**For GitHub Copilot (VS Code):**
1. Open Copilot Chat
2. Type `@dex-master hi`
3. Pick from the interactive menu

**For Claude Code (Terminal):**
1. `cd dexhub-ea-beta && claude`
2. Type `hi`
3. Pick from the interactive menu

**Requirements:** Git + (GitHub Copilot Business/Enterprise OR Claude Code)

---

## What You Get

### Agents (43)

| Role | What it does | Command |
|------|-------------|---------|
| **Business Analyst** | PRDs, requirements, product briefs | `@analyst` |
| **Solution Architect** | System design, architecture decisions | `@architect` |
| **Developer** | Story implementation, code review | `@dev` |
| **UX Expert** | User research, UX specs, prototyping | `@ux` |
| **Scrum Master** | User stories, sprint planning | `@sm` |
| **Product Manager** | Product strategy, roadmaps | `@pm` |
| **Product Owner** | Acceptance criteria, backlog | `@po` |
| **Test Engineer Architect** | Test strategy, ATDD, quality gates | `@tea` |
| **TestArch Pro** | Website test automation frameworks | `@testarch-pro` |
| **Brainstorming Coach** | Structured ideation, 300+ frameworks | `@brainstorming-coach` |
| **Design Thinking Coach** | Workshop facilitation | `@design-thinking` |
| **Innovation Strategist** | Innovation methods, trend analysis | `@innovation` |
| **Storyteller** | Narrative design, presentations | `@storyteller` |
| **Creative Problem Solver** | Root cause analysis, decision frameworks | `@creative-problem-solver` |
| **Dex Builder** | Create your own custom agents | `@dex-builder` |

Plus: 18 meta-agents for brownfield analysis (codebase, patterns, tech debt, APIs, dependencies), 3 integration onboarding agents, and domain-specific agents.

### Workflows (45)

Guided step-by-step processes across 4 phases:

| Phase | Examples |
|-------|---------|
| **1. Analysis** | Brainstorming, market research, user research, product brief |
| **2. Planning** | PRD, technical spec, UX spec, game design doc |
| **3. Solutioning** | Architecture design, technology selection, technical design |
| **4. Implementation** | User stories, code review, sprint planning, dev stories |

### Integrations

Guided setup wizards for enterprise tools:

| Integration | Setup | Agent |
|-------------|-------|-------|
| **Atlassian** (Jira + Confluence) | `@atlassian-onboarding` | Guided MCP setup |
| **GitHub Enterprise** | `@github-onboarding` | Guided MCP setup |
| **Figma** (Design files) | `@figma-onboarding` | MCP + REST client |

### Workspace (myDex)

Your private, local workspace — never synced, never shared:

```
myDex/
  projects/     Your projects (structured per-project)
  inbox/        Drop files for analysis
  drafts/       Work in progress
  export/       Finished deliverables
```

---

## Architecture

```
.dexCore/                 The framework
  core/                   Orchestrator (DexMaster) + integrations
  dxm/                    Development methodology (14 agents, 30+ workflows)
  dis/                    Innovation suite (5 creative agents)
  dxb/                    Builder (create custom agents/workflows)
  _cfg/                   Manifests + configuration
  _dev/                   Dev-Mode (dashboard, validator, docs)

.github/
  agents/                 46 Copilot agent definitions (.agent.md)
  skills/                 12 lazy-loaded knowledge packs
  copilot-instructions.md Copilot behavior configuration

myDex/                    Your private workspace (100% local)
```

---

## Version

**Enterprise Beta 0.1.0** (`EB-0.1.0`)

| File | Purpose |
|------|---------|
| `.version` | Single source of truth for current version |
| `.dexCore/_dev/CHANGELOG.md` | Development changelog |
| `.dexCore/_dev/docs/VERSIONING-SCHEME.md` | Versioning rules |

Versioning: `EB-MAJOR.MINOR.PATCH` (Semantic Versioning)

---

## Platform Support

| Platform | Support | Notes |
|----------|---------|-------|
| **GitHub Copilot** (VS Code) | Full | 46 `.agent.md` files, 12 skills, model routing |
| **Claude Code** (Terminal) | Full | Via `CLAUDE.md` + `.dexCore/` |
| **Other LLMs** | Partial | Agent definitions are plain markdown — portable |

---

## Quality

```bash
bash .dexCore/_dev/tools/validate.sh
```

---

## License

Apache 2.0 — see [LICENSE](LICENSE).

Built by [Arash Zamani](https://github.com/areanatic) as an open-source community project.
