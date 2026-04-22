<p align="center">
  <a href="https://www.apache.org/licenses/LICENSE-2.0"><img src="https://img.shields.io/badge/License-Apache%202.0-blue.svg" alt="License"></a>
  <img src="https://img.shields.io/badge/version-EB--1.0-orange" alt="Version">
  <img src="https://img.shields.io/badge/agents-46-blueviolet" alt="Agents">
  <img src="https://img.shields.io/badge/workflows-46-blueviolet" alt="Workflows">
  <img src="https://img.shields.io/badge/skills-12-blueviolet" alt="Skills">
  <img src="https://img.shields.io/badge/data-local-green" alt="Data Local">
</p>

# DexHub Enterprise Beta 1.0

An AI development framework built on three ideas:

**Structure over chat.** Instead of prompting from scratch, you work with 20+ AI agents that carry domain expertise and follow proven workflows. They have names — Jana for analysis, Alex for architecture, Steffi for code, Mona for UX, Martin for product — because they act as team members, not tools.

**Knowledge that stays.** DexHub includes a knowledge meta-layer that captures decisions, session logs, and project context directly in your repository. When a colleague joins or you revisit a project months later, the reasoning is there — not buried in someone's chat history.

**Extensions through Git.** Agents, workflows, and skills are plain files in your repo. Fork DexHub, add your own, share via branches and PRs. Teams can exchange proven processes the way open-source projects exchange code — versioned, reviewable, composable. Development knowledge becomes a shared, evolving asset across organizations.

### What "local" means here (honest)

- **Your data is local.** Profiles, decisions, chronicles, project files never leave your machine unless you explicitly configure a connector.
- **Your LLM is your choice.** Run against GitHub Copilot (cloud), Anthropic's CLI (cloud), or Ollama (fully local). DexHub compiles identical instructions for all three.
- **Connectors are optional.** Jira, GitHub, Figma integrations talk to their respective APIs when configured — always with your explicit setup step, never auto-enabled.

Enterprise deployments: see [Enterprise Compliance Matrix](.dexCore/_dev/docs/ENTERPRISE-COMPLIANCE.md) for a per-feature compliance stance.

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

## Feature Matrix

DexHub tracks every capability as an individually toggleable feature in [`.dexCore/_cfg/features.yaml`](.dexCore/_cfg/features.yaml) — 84 features today, classified by status:

| Status | Count | What it means |
|---|---|---|
| `always_on` | 8 | Core infrastructure (DexMaster, SSOT compile, validate.sh, D1 state model, consent tracking, L3 chronicle) |
| `enabled` | 57 | Shipped and tested — covered by this README |
| `deferred` | 19 | Planned for 1.1 or later (Parser Pattern B Phases 2-6 — Phase 1 enabled today, native Workflow-Runner backend, systemd/launchd daemon for inbox watcher — foreground watcher enabled today) |
| `experimental` | 0 | No features currently in experimental status |
| `broken` | 0 | No known-broken shipping features. 3 P0/P1 "bugs" inherited from Playground tracking were reclassified 2026-04-19: 2 were Playground-only (app/server.js never ported to Beta), 1 was fixed (Atlassian MCP install.sh v2.0 interactive wizard). |

**Honest label for Beta 1.0 scope:** DexHub core framework (SSOT compile, agent boundary state model, onboarding variants, guardrails, 46 agent definitions, 46 workflow YAMLs, 12 skills, GitHub/Figma connector wizards, validate.sh 27-section quality gate) **plus the L2 Knowledge Tank** (SQLite-backed, hybrid keyword+semantic search via optional Ollama, enterprise-compliance gate) **and the Document Parser arc** (router + kreuzberg/ollama-vlm/pattern-a-vector-text/pattern-b-phase1-overview backends + capabilities probe + inbox auto-parse + inbox watcher for continuous processing + Desktop-shortcut setup — end-to-end usable for text/PDF/Office/image via `*inbox`). **Still deferred to 1.1+:** Parser Pattern B Phases 2-6 (cluster-detect, hi-res crops, per-cluster VLM, synthesis, verify — Phase 1 overview shipped 2026-04-21), native Workflow-Runner execution backend, watcher daemon mode (systemd/launchd — foreground watcher enabled today). See `.dexCore/_dev/planning/` and [bugs.md](.dexCore/_dev/todos/bugs.md) for the remaining plan.

---

## Workflows (46)

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

| Integration | What you get | Setup | Status |
|-------------|-------------|-------|--------|
| **Atlassian** (Jira + Confluence) | Search issues, read pages, create content | `@atlassian-onboarding` | ✅ Enabled (wizard v2.0 — interactive, Cloud/Server auto-detect, modern MCP config paths) |
| **GitHub Enterprise** | Repos, PRs, issues, CI/CD workflows | `@github-onboarding` | ✅ Enabled |
| **Figma** | Design files, components, tokens | `@figma-onboarding` | ✅ Enabled |

All integrations use MCP (Model Context Protocol) and work with any Atlassian/GitHub/Figma instance. All are `cloud_with_consent` per the [Enterprise Compliance Matrix](.dexCore/_dev/docs/ENTERPRISE-COMPLIANCE.md) — they call out to the respective service after you've configured the URL + credentials.

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

> **Note on counts.** The top-of-README badges show **46** agents and **46** workflows — those are the total Copilot-activation counts (`.github/agents/*.agent.md` and `workflow.yaml` files across all modules). Per-module lines above (`dxm/14 agents`, `dis/5 agents`) break the same total down by module. Authoritative agent registry: [`.dexCore/_cfg/agent-manifest.csv`](.dexCore/_cfg/agent-manifest.csv) (43 source personas; 3 onboarding wizards share 1 activation, producing the 46 Copilot-activation count).

**Design principles:**
- **Plain markdown** — agents and workflows are markdown files, portable to any LLM
- **Data-local** — your files stay on disk; LLM + connectors are your choice
- **Modular** — add or remove modules (DXM, DIS, DXB) independently
- **Guardrails** — 9 safety rules (G1–G9) enforce output quality and file organization
- **Extensible** — build custom agents with `@dex-builder`, add knowledge packs, create workflows
- **Feature-flagged** — every capability is declared in [`features.yaml`](.dexCore/_cfg/features.yaml) with explicit status

---

## Use Cases

### Brownfield Analysis

Point DexHub at an existing codebase. The meta-agents analyze architecture, patterns, tech debt, and dependencies.

```
You:        "Analyze this codebase — architecture, tech debt, test coverage"
DexMaster:  Delegates to Codebase Analyzer, Pattern Detector, Tech Debt Auditor
Agents:     Read your repo, produce structured reports in myDex/drafts/
Result:     3 markdown reports with findings, scores, and recommendations
```

### Structured Product Development

Full development lifecycle — from idea to implementation, each agent hands off to the next.

```
You:        "@analyst Create a product brief for a task management app"
Jana:       Asks clarifying questions, runs brainstorming workflow
            → Saves product-brief.md to myDex/drafts/

You:        "@architect Design the system based on the product brief"
Alex:       Reads the brief, proposes architecture, creates tech spec
            → Saves architecture.md + tech-spec.md

You:        "@sm Create user stories from the tech spec"
Arjun:      Breaks epics into stories with acceptance criteria
            → Saves stories to your project folder

You:        "@dev Implement story #1"
Steffi:     Reads the story, implements against acceptance criteria
            → Writes code, runs tests

You:        "@tea Review the quality gates"
Murat:      Validates test coverage, checks NFRs, writes gate decision
            → Saves quality-gate-report.md
```

### Knowledge Preservation

Capture decisions and context so nothing is lost between sessions or team members.

```
You:        "We decided to use PostgreSQL instead of MongoDB"
DexMaster:  Detects decision signal, announces "📌 Notiert" and writes
            myDex/.dex/decisions/001-database-choice.md
            (agent-driven, never silent — you always see it happen)

You:        "*save"
DexMaster:  Writes session chronicle to myDex/.dex/chronicle/2026-04-01.md

New colleague joins, opens the project:
Agent:      Reads CONTEXT.md + decisions/ + chronicle/
            → Has full context of what was built and why
```

*Note: DexMemory is an agent-driven convention, not a background service — captures happen when the agent detects a strong signal and announces the write. See `dexhub-chronicle` skill for details.*

### Enterprise Tool Integration

Connect your existing tools through guided setup — no config file editing.

```
You:        "@atlassian-onboarding"
Agent:      "What is your Atlassian instance URL?"
You:        "mycompany.atlassian.net"
Agent:      Runs install.sh, configures MCP, tests connection
            → "Connected. Try: Search for recent Jira issues"

You:        "@figma-onboarding"
Agent:      "Do you have a Figma Personal Access Token?"
            Guides through token creation, installs MCP
            → "Connected. Try: @figma-analyst analyze my design file"
```

### Custom Agent & Workflow Development

Build your own agents, workflows, and skills — guided by the Dex Builder.

```
You:        "@dex-builder Create a new agent for security reviews"
Builder:    "What should this agent be called?"
You:        "SecGuard"
Builder:    "What's SecGuard's expertise?"
You:        "OWASP Top 10, dependency scanning, code security patterns"
Builder:    Creates agent definition, registers in manifest,
            generates .agent.md for Copilot integration
            → New agent ready: "@secguard Review this PR for vulnerabilities"

You:        "@dex-builder Create a workflow for incident response"
Builder:    Guides through step definition, templates, checklists
            → New workflow registered and ready to use

You:        "@dex-builder Create a skill for our internal API docs"
Builder:    "Paste your API documentation or point me to the file"
            Creates SKILL.md with lazy-loaded knowledge
            → Agents can now reference your API docs on demand
```

You can also **modify existing agents** — every agent is a markdown file:
- Change a persona's communication style
- Add domain-specific knowledge to an agent's activation steps
- Create a team-specific workflow variant (fork a workflow, adjust the template)
- Add your company's coding standards as a skill

---

## Community & Extensibility

DexHub is designed for contribution and exchange:

- **Fork and extend** — add agents, workflows, skills for your domain
- **Branch and version** — each feature branch carries its own agent/workflow changes
- **Share via Git** — your extensions are markdown files, shareable like any code
- **Registry pattern** — manifests track all components, new ones register automatically
- **Dev-Mode** — type `Start Dev-Mode` to access the development meta-layer

The framework follows a distributed model: teams build their own agents and workflows, share them through branches and PRs, and compose them into their own DexHub instance. Development knowledge flows between organizations through standard Git mechanics.

**Customize anything:**

| What | How | Where |
|------|-----|-------|
| Add an agent | `@dex-builder` or create `.dexCore/dxm/agents/your-agent.md` | + `.github/agents/your-agent.agent.md` |
| Add a workflow | `@dex-builder` or create folder in `.dexCore/dxm/workflows/` | workflow.yaml + instructions.md + template.md |
| Add a skill | Create `.github/skills/your-skill/SKILL.md` | Agents load it on demand |
| Modify an agent | Edit the markdown file, change persona/style/knowledge | Changes take effect immediately |
| Add integrations | Create folder in `.dexCore/core/integrations/` | install.sh + tools.yaml + README |

---

## Quality & Validation

DexHub runs two complementary quality gates — one structural, one behavioural:

```bash
# Structural: 260 invariant checks across 22 sections (file existence, hash integrity,
# SSOT drift detection, cross-platform source alignment, manifest consistency)
bash .dexCore/_dev/tools/validate.sh

# Profile schema validation
python .dexCore/_dev/tools/validate_profile_schema.py myDex/.dex/config/profile.yaml

# Behavioural: E2E test harness (structural 51/51 default, +4 live assertions with --live)
bash tests/e2e/run-all.sh          # fast, no API cost
bash tests/e2e/run-all.sh --live   # invokes headless LLM CLI, costs API tokens
```

**Gate discipline:** every user-facing feature must have an E2E test entry. "Exists ≠ works" — structural green is not behavioural green. See [tests/e2e/README.md](tests/e2e/README.md).

---

## Version

**Enterprise Beta 1.0** — `.version` file is the single source of truth.

Versioning: `EB-MAJOR.MINOR.PATCH` (Semantic Versioning)

---

## License

Apache 2.0 — see [LICENSE](LICENSE).

Copyright 2025-2026 Arash Zamani. "DexHub" is a trademark — see [NOTICE](NOTICE).

Contributions welcome — see [CONTRIBUTING.md](CONTRIBUTING.md).
