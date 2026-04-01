<p align="center">
  <a href="https://www.apache.org/licenses/LICENSE-2.0"><img src="https://img.shields.io/badge/License-Apache%202.0-blue.svg" alt="License"></a>
  <img src="https://img.shields.io/badge/version-EB--0.1.0-orange" alt="Version">
  <img src="https://img.shields.io/badge/agents-43-blueviolet" alt="Agents">
  <img src="https://img.shields.io/badge/workflows-45-blueviolet" alt="Workflows">
  <img src="https://img.shields.io/badge/skills-12-blueviolet" alt="Skills">
  <img src="https://img.shields.io/badge/100%25-local-green" alt="Local">
</p>

<p align="center">
  <strong>An AI development team that follows your methodology.<br>Not a chatbot. A structured system.</strong>
</p>

---

## Quick Start

```bash
git clone https://github.com/areanatic/dexhub-ea-beta.git
cd dexhub-ea-beta
```

Open in VS Code with GitHub Copilot, type **`@dex-master hi`** — done.

---

## Why DexHub?

| | Generic AI Chat | DexHub |
|--|----------------|--------|
| **Approach** | One AI, all tasks | 43 specialized agents, each with a role |
| **Process** | "Write me a PRD" | Guided 45-step workflows with templates |
| **Knowledge** | Forgets every session | Preserves decisions, chronicles, context |
| **Structure** | Free-form output anywhere | Organized workspace with file routing |
| **Consistency** | Different output every time | Guardrails enforce format and quality |
| **Extensibility** | Prompt engineering | Build your own agents, workflows, skills |

---

## What You Get

### 43 AI Agents

Each agent has a defined role, persona, and methodology:

| Role | What it does |
|------|-------------|
| **Business Analyst** | Product briefs, requirements gathering, market research |
| **Solution Architect** | System design, architecture decisions, technology selection |
| **Developer** | Story implementation, code review, technical execution |
| **UX Expert** | User research, UX specs, wireframe guidance |
| **Test Architect** | Test strategy, ATDD, CI/CD quality gates |
| **Product Manager** | Product strategy, roadmaps, stakeholder alignment |
| **Scrum Master** | Sprint planning, user stories, retrospectives |
| **Product Owner** | Acceptance criteria, backlog management |
| **Brainstorming Coach** | Structured ideation with 300+ creative frameworks |
| **Innovation Strategist** | Trend analysis, business model innovation |
| **Dex Builder** | Create your own custom agents and workflows |

Plus: Design Thinking Coach, Storyteller, Creative Problem Solver, 3 Game Development agents, 3 Integration Onboarding agents, and 18 meta-agents for brownfield analysis (codebase, patterns, tech debt, APIs, dependencies).

### 45 Guided Workflows

Step-by-step processes across the full development lifecycle:

| Phase | What happens |
|-------|-------------|
| **Analysis** | Brainstorming, market research, product briefs, user research |
| **Planning** | PRDs, technical specs, UX specs, game design docs |
| **Solutioning** | Architecture design, technology selection, solution specs |
| **Implementation** | Story creation, code execution, code review, retrospectives |
| **Testing** | Framework generation, coverage analysis, quality gates |

### 12 Knowledge Packs (Skills)

Lazy-loaded knowledge that agents access on demand:

| Skill | What it provides |
|-------|-----------------|
| **DexHub Core** | Agent activation protocol, menu system |
| **Architecture** | Platform directory structure, module system |
| **Guardrails** | Safety rules, file routing, output policies |
| **Chronicle** | Session documentation system |
| **Platform Awareness** | IDE differences, capabilities, limitations |
| **Integrations** | Setup guides for Jira, GitHub, Figma |
| + 6 more | Design system patterns, accessibility, components |

### Enterprise Integrations

Guided setup wizards — no hardcoded URLs, works with any organization:

| Integration | What you get |
|-------------|-------------|
| **Atlassian** (Jira + Confluence) | Search issues, read pages, create content via MCP |
| **GitHub Enterprise** | Repos, PRs, issues, actions via MCP |
| **Figma** | Read design files, extract components, analyze layouts |

Type `@atlassian-onboarding`, `@github-onboarding`, or `@figma-onboarding` to set up.

---

## How It Works

```
You → IDE (Copilot/Cursor/etc.) → DexHub (.dexCore/)
                                      |
                            +---------+---------+
                            |         |         |
                         Agents   Workflows   Skills
                         (43)      (45)       (12)
                            |         |         |
                            +----+----+----+----+
                                 |              |
                              myDex/        Integrations
                           (your private     (Jira, GitHub,
                            workspace)        Figma)
```

**Architecture:**

```
.dexCore/              The framework (read-only, versioned)
  core/                DexMaster orchestrator + integrations
  dxm/                 14 agents + 30 workflows (development methodology)
  dis/                 5 agents + 4 workflows (innovation suite)
  dxb/                 Builder tools (create agents/workflows/skills)
  _cfg/                Manifests, config, agent registry
  _dev/                Dev-Mode: validator, dashboard, templates

.github/
  agents/              46 Copilot agent definitions (.agent.md)
  skills/              12 knowledge packs (lazy-loaded)
  copilot-instructions.md

myDex/                 Your private workspace (100% local, gitignored)
  projects/            Structured per-project workspaces
  inbox/               Drop files for analysis
  drafts/              Work in progress
  export/              Finished deliverables
```

**Key design decisions:**
- **Plain markdown** — agents and workflows are markdown files, portable to any LLM
- **Zero cloud** — everything runs locally in your IDE, no API keys needed
- **Modular** — add/remove modules (DXM, DIS, DXB) independently
- **Guardrails** — 7 safety rules enforce output quality and file organization
- **Extensible** — build custom agents with `@dex-builder`, add skills, create workflows

---

## Quality

```bash
# Run 168 automated checks
bash .dexCore/_dev/tools/validate.sh
```

---

## Version

**Enterprise Beta 0.1.0** — `.version` file is the single source of truth.

---

## License

Apache 2.0 — see [LICENSE](LICENSE).

Created by [Arash Zamani](https://github.com/areanatic).
