<p align="center">
  <a href="https://www.apache.org/licenses/LICENSE-2.0"><img src="https://img.shields.io/badge/License-Apache%202.0-blue.svg" alt="License"></a>
  <img src="https://img.shields.io/badge/version-EB--0.1.0-orange" alt="Version">
  <img src="https://img.shields.io/badge/agents-43-blueviolet" alt="Agents">
  <img src="https://img.shields.io/badge/workflows-45-blueviolet" alt="Workflows">
  <img src="https://img.shields.io/badge/skills-12-blueviolet" alt="Skills">
  <img src="https://img.shields.io/badge/100%25-local-green" alt="Local">
</p>

# DexHub

An AI development framework built on three ideas:

**Structure over chat.** Instead of prompting from scratch, you work with 20+ AI agents that carry domain expertise and follow proven workflows. They have names — Jana for analysis, Alex for architecture, Steffi for code, Mona for UX, Martin for product — because they act as team members, not tools.

**Knowledge that stays.** DexHub includes a knowledge meta-layer that captures decisions, session logs, and project context directly in your repository. When a colleague joins or you revisit a project months later, the reasoning is there — not buried in someone's chat history.

**Extensions through Git.** Agents, workflows, and skills are plain files in your repo. Fork DexHub, add your own, share via branches and PRs. Teams can exchange proven processes the way open-source projects exchange code — versioned, reviewable, composable. Development knowledge becomes a shared, evolving asset across organizations.

Everything runs locally. No cloud dependency, no accounts, no data leaving your machine.

---

## Install

```bash
git clone https://github.com/areanatic/dexhub-ea-beta.git
cd dexhub-ea-beta
```

Open in VS Code with GitHub Copilot. Type `@dex-master hi`. Done.

Works with any AI-capable IDE (Copilot, Cursor, Windsurf, etc.).

---

## Agents

Each agent has a name, a role, and domain expertise. They follow defined methodologies — not ad-hoc prompts.

### Development Team

| Agent | Name | Role | Command |
|-------|------|------|---------|
| **Business Analyst** | Jana | Requirements, PRDs, market analysis | `@analyst` |
| **Architect** | Alex | System design, tech selection, C4 models | `@architect` |
| **Developer** | Steffi | Story implementation, code reviews | `@dev` |
| **UX Expert** | Mona | User research, interaction design, prototypes | `@ux` |
| **Product Manager** | Martin | Product strategy, roadmaps, prioritization | `@pm` |
| **Scrum Master** | Arjun | User stories, sprint planning, ceremonies | `@sm` |
| **Product Owner** | Lisa | Acceptance criteria, backlog management | `@po` |
| **Test Architect** | Murat | Test strategy, automation, quality gates | `@tea` |
| **TestArch Pro** | — | Website test automation frameworks | `@testarch-pro` |

### Innovation Team

| Agent | Name | Role | Command |
|-------|------|------|---------|
| **Brainstorming Coach** | Carson | Innovation sessions, 300+ creative techniques | `@brainstorming-coach` |
| **Design Thinking** | Maya | Human-centered design, empathy mapping | `@design-thinking` |
| **Problem Solver** | Dr. Quinn | Root cause analysis, TRIZ, systems thinking | `@creative-problem-solver` |
| **Innovation Strategist** | Victor | Disruption analysis, business model innovation | `@innovation` |
| **Storyteller** | Sophia | Narrative strategy, compelling communication | `@storyteller` |

### Specialist & Integration Agents

| Agent | Name | Role | Command |
|-------|------|------|---------|
| **Figma Analyst** | Fiona | Design file analysis, component audits | `@figma-analyst` |
| **Game Architect** | Marek | Game systems, multiplayer, engine design | `@game-architect` |
| **Game Designer** | Luna | Mechanics, player psychology, balancing | `@game-designer` |
| **Game Developer** | Nico | Gameplay programming, performance | `@game-dev` |
| **Atlas** | — | Knowledge reconstruction across Jira/GitHub/Confluence | `@atlas` |

### System & Onboarding Agents

| Agent | Role | Command |
|-------|------|---------|
| **Dex Master** | Navigation, orchestration, agent directory | `@dex-master` |
| **myDex** | Profile, workspace, project management | `@mydex` |
| **Dex Builder** | Create custom agents, workflows, skills | `@dex-builder` |
| **Atlassian Onboarding** | Guided Jira + Confluence MCP setup | `@atlassian-onboarding` |
| **GitHub Onboarding** | Guided GitHub Enterprise MCP setup | `@github-onboarding` |
| **Figma Onboarding** | Guided Figma MCP setup | `@figma-onboarding` |
| **myDex Project Manager** | Project lifecycle, file routing | `@mydex-project-manager` |

### Meta-Agents (18)

Brownfield analysis capabilities for existing codebases:

Codebase Analyzer, Pattern Detector, API Documenter, Data Analyst, Requirements Analyst, User Journey Mapper, Epic Optimizer, Dependency Mapper, Technical Decisions Curator, Trend Spotter, User Researcher, Market Researcher, Competitor Analyzer, Tech Debt Auditor, Test Coverage Analyzer, Technical Evaluator, Document Reviewer, Project Context Master.

---

## Workflows (45)

Guided step-by-step processes with templates and checklists:

| Phase | Workflows | What you get |
|-------|-----------|-------------|
| **Analysis** | Brainstorming, Market Research, Product Brief, User Research, Game Brief | Structured ideation and discovery outputs |
| **Planning** | PRD, Technical Spec, UX Spec, Game Design Doc, Narrative Design | Templated planning documents |
| **Solutioning** | Architecture Design, Technology Selection | Decision records and solution specs |
| **Implementation** | Story Creation, Dev Story, Code Review, Course Correction, Retrospective | Traceable implementation artifacts |
| **Testing** | Framework Generation, Coverage Analysis, Quality Gates, ATDD, CI/CD | Automated test strategy |

Each workflow consists of:
- `workflow.yaml` — Step definitions, variables, configuration
- `instructions.md` — Detailed agent instructions per step
- `template.md` — Output template with placeholders
- `checklist.md` — Validation criteria

---

## Knowledge Packs (Skills)

Agents load domain knowledge on demand — 12 knowledge packs:

| Skill | Content |
|-------|---------|
| **DexHub Core** | Agent activation protocol, menu system |
| **Architecture** | Platform structure, module system |
| **Guardrails** | Safety rules, file routing policies |
| **Platform Awareness** | IDE differences and capabilities |
| **Integrations** | Setup guides for Jira, GitHub, Figma |
| **Chronicle** | Session documentation system |
| + 6 domain-specific | Design system, accessibility, components, layout patterns, brand foundations, Dev-Mode |

---

## Integrations

Setup wizards that guide you through connecting your tools. No hardcoded URLs — the wizard asks for your instance and configures everything.

| Integration | What you get | Setup |
|-------------|-------------|-------|
| **Atlassian** (Jira + Confluence) | Search issues, read pages, create content | `@atlassian-onboarding` |
| **GitHub Enterprise** | Repos, PRs, issues, CI/CD workflows | `@github-onboarding` |
| **Figma** | Design files, components, tokens | `@figma-onboarding` |

All integrations use MCP (Model Context Protocol) and work with any Atlassian/GitHub/Figma instance.

---

## Architecture

```
.dexCore/                    The framework (versioned, portable)
  core/                      DexMaster orchestrator + MCP integrations
  dxm/                       Development methodology (14 agents, 30+ workflows)
  dis/                       Innovation suite (5 agents, 4 workflows)
  dxb/                       Builder (create agents, workflows, skills)
  _cfg/                      Manifests, config, agent registry
  _dev/                      Dev-Mode (validator, dashboard, templates, tools)

.github/
  agents/                    46 Copilot agent definitions (.agent.md)
  skills/                    12 knowledge packs
  copilot-instructions.md    IDE behavior configuration

myDex/                       Your workspace (local, gitignored)
  projects/                  Structured per-project workspaces
  inbox/ → drafts/ → export/ File pipeline
```

**Design principles:**
- **Plain markdown** — agents and workflows are markdown files, portable to any LLM
- **Zero cloud** — everything runs in your IDE, your data stays on your machine
- **Modular** — add or remove modules (DXM, DIS, DXB) independently
- **Guardrails** — 7 safety rules enforce output quality and file organization
- **Extensible** — build custom agents with `@dex-builder`, add knowledge packs, create workflows

---

## Use Cases

**Brownfield Analysis** — Point DexHub at an existing codebase. The 18 meta-agents analyze architecture, patterns, tech debt, APIs, dependencies, and test coverage. Get structured reports instead of ad-hoc AI guesses.

**Structured Product Development** — Start with Jana (Analyst) for a product brief, hand off to Alex (Architect) for system design, then Steffi (Developer) implements story by story with Murat (Test Architect) validating quality gates. Each step produces templated, traceable artifacts.

**Knowledge Preservation** — DexHub's chronicle system captures decisions, session logs, and project context. When someone new joins, the institutional knowledge is already structured in the repository — not lost in chat history.

**Enterprise Tool Integration** — Connect Jira, Confluence, GitHub Enterprise, and Figma through guided setup wizards. Agents can search issues, read design files, and create documentation without leaving your IDE.

**Custom Agent Development** — Use `@dex-builder` to create agents for your domain. Define a persona, connect workflows, add knowledge packs. Your custom agents follow the same guardrails and quality standards as built-in ones.

---

## Community & Extensibility

DexHub is designed for contribution and exchange:

- **Fork and extend** — add agents, workflows, skills for your domain
- **Branch and version** — each feature branch carries its own agent/workflow changes
- **Share via Git** — your extensions are markdown files, shareable like any code
- **Registry pattern** — manifests track all components, new ones register automatically
- **Dev-Mode** — type `Start Dev-Mode` to access the development meta-layer

The framework follows a distributed model: teams build their own agents and workflows, share them through branches and PRs, and compose them into their own DexHub instance. Development knowledge flows between organizations through standard Git mechanics.

---

## Quality & Validation

```bash
# 168 automated structural checks
bash .dexCore/_dev/tools/validate.sh

# Profile schema validation
python .dexCore/_dev/tools/validate_profile_schema.py myDex/.dex/config/profile.yaml
```

---

## Version

**Enterprise Beta 0.1.0** — `.version` file is the single source of truth.

Versioning: `EB-MAJOR.MINOR.PATCH` (Semantic Versioning)

---

## License

Apache 2.0 — see [LICENSE](LICENSE).

Copyright 2025-2026 Arash Zamani. "DexHub" is a trademark — see [NOTICE](NOTICE).

Contributions welcome — see [CONTRIBUTING.md](CONTRIBUTING.md).
