<p align="center">
  <a href="https://www.apache.org/licenses/LICENSE-2.0"><img src="https://img.shields.io/badge/License-Apache%202.0-blue.svg" alt="License"></a>
  <img src="https://img.shields.io/badge/version-EB--0.1.0-orange" alt="Version">
  <img src="https://img.shields.io/badge/agents-43-blueviolet" alt="Agents">
  <img src="https://img.shields.io/badge/workflows-45-blueviolet" alt="Workflows">
  <img src="https://img.shields.io/badge/skills-12-blueviolet" alt="Skills">
  <img src="https://img.shields.io/badge/100%25-local-green" alt="Local">
</p>

# DexHub

**A structured AI development platform.** 43 specialized agents, 45 guided workflows, 12 knowledge packs — running locally in your IDE. No cloud, no API keys.

---

## Install

```bash
git clone https://github.com/areanatic/dexhub-ea-beta.git
cd dexhub-ea-beta
```

Open in VS Code with GitHub Copilot. Type `@dex-master hi`. Done.

Works with any AI-capable IDE (Copilot, Cursor, Windsurf, etc.).

---

## What It Is

DexHub is a **knowledge meta-layer** that sits on top of your repository. It carries structured agents, proven workflows, and institutional knowledge — so your AI doesn't just chat, it follows your methodology.

| What | How |
|------|-----|
| **43 Agents** | Each with a defined role, persona, and expertise |
| **45 Workflows** | Step-by-step processes with templates and checklists |
| **12 Knowledge Packs** | Lazy-loaded domain knowledge (skills) |
| **3 MCP Integrations** | Jira, GitHub Enterprise, Figma |
| **Private Workspace** | myDex/ — your data stays local, never synced |
| **7 Guardrails** | Enforced output quality and file organization |

---

## Features

### Agents

| Category | Agents | Examples |
|----------|--------|----------|
| **Development** | 14 | Business Analyst, Architect, Developer, UX, PM, Scrum Master, Product Owner |
| **Testing** | 2 | Test Engineer Architect (TEA), TestArch Pro |
| **Innovation** | 5 | Brainstorming Coach, Design Thinking, Innovation Strategist, Storyteller, Problem Solver |
| **Builder** | 1 | Dex Builder — create your own agents and workflows |
| **Integration** | 3 | Atlassian Onboarding, GitHub Onboarding, Figma Onboarding |
| **Meta-Analysis** | 18 | Codebase Analyzer, Pattern Detector, Tech Debt Auditor, API Documenter, ... |

Every agent has a `.agent.md` file for Copilot integration (46 total) and a full definition in `.dexCore/`.

### Workflows

Guided step-by-step processes across the development lifecycle:

| Phase | Workflows | What you get |
|-------|-----------|-------------|
| **Analysis** | Brainstorming, Market Research, Product Brief, User Research | Structured ideation and discovery outputs |
| **Planning** | PRD, Technical Spec, UX Spec, Game Design Doc | Templated planning documents |
| **Solutioning** | Architecture Design, Technology Selection | Decision records and solution specs |
| **Implementation** | Story Creation, Dev Story, Code Review, Retrospective | Traceable implementation artifacts |
| **Testing** | Framework Generation, Coverage Analysis, Quality Gates | Automated test strategy |

### Integrations

Setup wizards that guide you through connecting your tools:

```
@atlassian-onboarding   → Jira + Confluence via MCP
@github-onboarding      → GitHub Enterprise via MCP
@figma-onboarding       → Figma design files via MCP + REST
```

No hardcoded URLs — the wizard asks for your instance and configures everything.

### Knowledge Packs (Skills)

Agents load domain knowledge on demand:

| Skill | Content |
|-------|---------|
| Core | Agent activation protocol, menu system |
| Architecture | Platform structure, module system |
| Guardrails | Safety rules, file routing policies |
| Platform Awareness | IDE differences and capabilities |
| Integrations | Setup guides and troubleshooting |
| Chronicle | Session documentation system |
| + 6 domain-specific | Design systems, accessibility, components, patterns |

---

## Architecture

```
.dexCore/                    The framework (versioned, portable)
  core/                      DexMaster + integrations (Jira, GitHub, Figma)
  dxm/                       Development methodology (14 agents, 30+ workflows)
  dis/                       Innovation suite (5 agents, 4 workflows)
  dxb/                       Builder (create agents, workflows, skills)
  _cfg/                      Manifests, config, agent registry
  _dev/                      Dev-Mode (validator, dashboard, templates)

.github/
  agents/                    46 Copilot agent files (.agent.md)
  skills/                    12 knowledge packs
  copilot-instructions.md    IDE behavior configuration

myDex/                       Your workspace (local, gitignored)
  projects/                  Structured per-project workspaces
  inbox/ → drafts/ → export/ File pipeline
```

**Design principles:**
- **Plain markdown** — portable to any LLM, no vendor lock-in
- **Modular** — add or remove modules (DXM, DIS, DXB) independently
- **Extensible** — build custom agents with `@dex-builder`, add knowledge packs, create workflows
- **Zero cloud** — everything runs in your IDE, your data stays on your machine

---

## Use Cases

**Brownfield Analysis** — Point DexHub at an existing codebase. The 18 meta-agents analyze architecture, patterns, tech debt, APIs, dependencies, and test coverage. Get structured reports instead of ad-hoc AI guesses.

**Structured Product Development** — Start with `@analyst` for a product brief, hand off to `@architect` for system design, then `@dev` implements story by story with `@tea` validating quality gates. Each step produces templated, traceable artifacts.

**Knowledge Preservation** — DexHub's chronicle system captures decisions, session logs, and project context. When someone new joins, the institutional knowledge is already structured in the repository — not lost in chat history.

**Enterprise Tool Integration** — Connect Jira, Confluence, GitHub Enterprise, and Figma through guided setup wizards. Agents can search issues, read design files, and create documentation without leaving your IDE.

**Custom Agent Development** — Use `@dex-builder` to create agents for your domain. Define a persona, connect workflows, add knowledge packs. Your custom agents follow the same guardrails and quality standards as built-in ones.

---

## Community & Extensibility

DexHub is designed for contribution and exchange:

- **Fork and extend** — add agents, workflows, skills for your domain
- **Branch and version** — each feature branch carries its own agent/workflow changes
- **Share via Git** — your extensions are markdown files in a Git repo, shareable like any code
- **Dev-Mode** — type `Start Dev-Mode` to access the development meta-layer (validator, dashboard, templates)
- **validate.sh** — 168 automated checks verify structural integrity

The architecture follows a **registry pattern**: manifests track all agents, workflows, and files. New components register themselves. Removing a module means removing a folder.

---

## Quality

```bash
bash .dexCore/_dev/tools/validate.sh    # 168 automated checks
python tests/validate_profile_schema.py  # Profile schema validation
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
