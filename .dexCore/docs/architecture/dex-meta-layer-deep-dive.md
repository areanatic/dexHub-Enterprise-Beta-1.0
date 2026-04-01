> **REBRANDED:** 2025-10-26 - DexHub Omega → DexHub Alpha V1 (FINAL AUTHORITATIVE VERSION)

# .dex/ Meta-Layer: Deep-Dive Architecture

**Date:** 2025-10-24
**Status:** Architecture Design - Holistic Challenge Phase
**Authors:** Ash, Claude

---

## 🎯 Core Vision

> ".dex/ muss als **selbstständiger Blueprint** funktionieren - mit ODER ohne DexHub-Verbindung"

---

## 📋 Alle offenen Fragen (Comprehensive List)

### 1. GitHub Copilot Integration
**Q:** Reicht `.dex/` als Instruction Prompt, oder brauchen wir auch `.github/copilot-instructions.md`?

### 2. Agent Selbst-Konfiguration
**Q:** Kann dex-meta-agent sich selbst erweitern und mit DexHub sharen?

### 3. Partial Git Push
**Q:** Können wir einzelne `.dex/` Files (Agents, Learnings) zu DexHub pushen ohne ganze Repo?

### 4. Blueprint Architecture
**Q:** Blueprints lokal oder remote? Was IST ein Blueprint?

### 5. Agent vs Module vs Extension
**Q:** Naming - Was sind Blueprints? Extensions? Wie unterscheiden?

### 6. Default Agents
**Q:** Welche Agents sollten IMMER in `.dex/` dabei sein?

### 7. Workflows vs Agents
**Q:** Wann Agent, wann Workflow? Wie kombinieren?

### 8. .dex/ als Mini-DexHub?
**Q:** Kann `.dex/` alles was DexHub kann, nur projekt-spezifisch?

### 9. Standalone Installation
**Q:** `.dex/` ohne DexHub installierbar? Wie?

### 10. Docs Location Rationale
**Q:** Warum sind Docs traditionell in `/docs/` statt `.dex/`?

---

## 🔍 FRAGE 1: GitHub Copilot Integration

### Use Cases

#### UC1.1: Copilot triggert .dex/ Agent
```
User öffnet Projekt in VS Code
→ GitHub Copilot aktiv
→ Copilot sieht .dex/
→ ??? Was passiert?
```

#### UC1.2: Zwei Instruction-Quellen
```
Option A: Nur .dex/
  /.dex/
    agents/
      dex-meta-agent.md  ← Copilot liest DAS

Option B: .dex/ + .github/
  /.dex/
    agents/
      dex-meta-agent.md
  /.github/
    copilot-instructions.md  ← Referenziert .dex/
```

### 🎯 Analyse

**GitHub Copilot Standard:**
- Liest `.github/copilot-instructions.md` automatisch
- Wird bei jedem Chat/Completion geladen
- Ist der "Entry Point" für Copilot

**Problem:**
Copilot liest `.dex/agents/*.md` **nicht automatisch**!

**Lösung: Hybrid Approach**

```
/.github/
  copilot-instructions.md   ← ENTRY POINT
    Content:
    """
    # Project Instructions

    This project uses the .dex/ meta-layer for comprehensive context.

    IMPORTANT: Before responding, ALWAYS read:
    - .dex/agents/dex-meta-agent.md (primary agent)
    - .dex/meta/context.yaml (project context)
    - .dex/docs/ (relevant documentation)

    The dex-meta-agent will guide you on how to work with this project.
    """

/.dex/
  agents/
    dex-meta-agent.md       ← ACTUAL INTELLIGENCE
```

**Warum das funktioniert:**
1. Copilot liest `.github/copilot-instructions.md` (automatisch)
2. Instruction sagt: "Lies `.dex/agents/dex-meta-agent.md`"
3. Copilot lädt dex-meta-agent
4. dex-meta-agent übernimmt!

**DexHub Installation muss also:**
```bash
dex init my-project
  1. Erstellt .dex/
  2. Erstellt .github/copilot-instructions.md (referenziert .dex/)
  3. Fertig!
```

### ✅ Antwort
**JA, wir brauchen `.github/copilot-instructions.md`** als Entry Point, der auf `.dex/` referenziert.

---

## 🔍 FRAGE 2: Agent Self-Extension & Community Sharing

### Szenario
```
1. dex-meta-agent arbeitet an Projekt
2. Merkt: "Ich brauche einen GraphQL-Analyzer"
3. Findet KEINEN in .dex/blueprints/
4. ??? Was jetzt?

Option A: Fragt DexHub
  Agent: "Checking DexHub for graphql-analyzer..."
  DexHub: "Found! Install?"
  User: Yes
  → Download & Install

Option B: Baut selbst einen
  Agent: "I can create a basic GraphQL analyzer. Continue?"
  User: Yes
  Agent: Erstellt .dex/agents/graphql-analyzer.md
  → Funktioniert!

Option C: Hybrid
  Agent: "No GraphQL analyzer found. Options:"
    1. Download from DexHub (recommended)
    2. Create basic one myself
    3. Skip for now
```

### Community Sharing Flow

```
User hat custom Agent gebaut:
/.dex/agents/my-custom-analyzer.md

dex-meta-agent:
  "I notice you created 'my-custom-analyzer.md'.
   This could be useful for the community!

   Would you like to share it to DexHub?"

User: Yes

Agent:
  "Great! I'll prepare it for sharing.

   Please review:
   - Name: Custom Analyzer
   - Description: [auto-generated]
   - License: MIT (default)
   - Tags: [auto-detected]

   Ready to push?"

User: Yes

Agent:
  → Git push ONLY .dex/agents/my-custom-analyzer.md
  → To: github.com/dexhub-community/agents/
  → Creates PR automatically
```

### Partial Git Push - Ist das möglich?

**Problem:**
Git pushed normalerweise ganze Repo, nicht einzelne Files.

**Lösungen:**

#### Option A: Separate Community Repo
```
User-Projekt:
  /my-app/.dex/agents/custom.md

DexHub Community:
  github.com/dexhub-community/agents/
    custom-analyzer.md  ← Kopie

Mechanismus:
  1. Agent kopiert File
  2. Git clone community-repo
  3. Adds File
  4. Commits & pushes
  5. Creates PR
```

#### Option B: Git Subtree/Sparse Checkout
```
Komplexer, aber möglich:
  git subtree push --prefix=.dex/agents/ origin agents-only
```

#### Option C: API-Based Upload
```
GitHub API:
  POST /repos/dexhub-community/agents/contents/custom-analyzer.md
  Body: {content: <base64>, message: "Add custom analyzer"}
```

### ✅ Antwort
**JA, Agent kann sich erweitern UND Community-sharen!**
- Erweiterung: Option C (Hybrid - DexHub oder self-build)
- Sharing: Option C (GitHub API - einfacher als Git-Subtree)

---

## 🔍 FRAGE 3: Blueprint Architecture - Lokal oder Remote?

### Was IST ein Blueprint?

**Definition:**
> Ein Blueprint ist eine **YAML-Anleitung**, die einem Agent sagt, WIE er ein Projekt analysieren/erweitern soll.

**Beispiel:**
```yaml
# .dex/blueprints/extensions/react.yaml
name: React Project Analyzer
version: 1.0.0
type: extension
category: framework

triggers:
  - file_exists: package.json
  - dependency_contains: react

analysis_steps:
  - name: Detect Components
    scan: src/**/*.{jsx,tsx}
    extract: component_names

  - name: Detect State Management
    patterns:
      redux: "import.*from.*'redux'"
      zustand: "import.*from.*'zustand'"
      context: "React.createContext"

  - name: Detect Routing
    files: [src/App.jsx, src/Router.jsx]
    patterns:
      react-router: "import.*from.*'react-router'"

outputs:
  meta/tech-stack.yaml:
    framework: React
    version: ${package.json.dependencies.react}
    state_management: ${detected_state}
    routing: ${detected_routing}
```

**Größe:** ~10KB
**Ausführung:** dex-meta-agent liest YAML, führt Steps aus

### Unterschied: Blueprint vs Agent vs Module

```
┌─────────────────────────────────────────────┐
│                                             │
│  BLUEPRINT (YAML)                           │
│  - Anleitung/Rezept                         │
│  - Deklarativ                               │
│  - Klein (~10KB)                            │
│  - Agent führt aus                          │
│  - Beispiel: react.yaml                     │
│                                             │
└─────────────────────────────────────────────┘
                    ↓ wird ausgeführt von
┌─────────────────────────────────────────────┐
│                                             │
│  AGENT (.md)                                │
│  - Ausführbare Intelligenz                  │
│  - Prompt für LLM                           │
│  - Größe: 5-50KB                            │
│  - Kann Blueprints lesen                    │
│  - Beispiel: dex-meta-agent.md              │
│                                             │
└─────────────────────────────────────────────┘
                    ↓ kann nutzen
┌─────────────────────────────────────────────┐
│                                             │
│  MODULE (Folder mit Code)                   │
│  - Komplexe Logik                           │
│  - Externe Tools                            │
│  - Größe: 100KB - 10MB                      │
│  - Nur bei Bedarf                           │
│  - Beispiel: graphql-schema-validator/      │
│                                             │
└─────────────────────────────────────────────┘
```

### Lokal vs Remote: Dedision Matrix

| Was? | Immer lokal? | Von DexHub? | Warum? |
|------|--------------|-------------|--------|
| **Core Blueprints** | ✅ JA | Optional update | Offline-fähig |
| **Extension Blueprints** | ✅ JA (alle!) | Optional update | Klein genug (~500KB total) |
| **dex-meta-agent.md** | ✅ JA | Optional update | MUSS offline funktionieren |
| **Project-specific Agents** | Optional | ❌ Nein | User erstellt |
| **Modules** | ❌ Nein | ✅ JA | Groß, on-demand |

### ✅ Antwort
**Blueprints sind IMMER lokal** (alle Extensions, ~500KB total)
**Modules sind on-demand** von DexHub

---

## 🔍 FRAGE 4: Naming Convention

### Vorschlag: Einheitliche Begriffe

```
┌─ .dex/ (DEX META-LAYER)
│
├─ /blueprints/          ← "Blueprints" = Anleitungen
│  ├─ core.yaml
│  └─ /extensions/       ← "Extensions" = Optionale Blueprints
│     ├─ react.yaml
│     └─ python.yaml
│
├─ /agents/              ← "Agents" = Ausführbare Intelligenz
│  ├─ dex-meta-agent.md
│  └─ custom-agent.md
│
├─ /modules/             ← "Modules" = Externe Tools/Code
│  └─ graphql-tools/
│
└─ /workflows/           ← "Workflows" = Multi-Step Prozesse
   └─ onboarding.yaml
```

**Alternative Namen:**

| Current | Alternative 1 | Alternative 2 | Empfehlung |
|---------|--------------|---------------|------------|
| blueprints | templates | recipes | **blueprints** ✅ (klar) |
| extensions | plugins | add-ons | **extensions** ✅ (standard) |
| agents | assistants | bots | **agents** ✅ (AI-Begriff) |
| modules | packages | plugins | **modules** ✅ (vs npm) |

### ✅ Antwort
**Begriffe beibehalten:**
- Blueprints = Anleitungen (YAML)
- Extensions = Optionale Blueprints
- Agents = Intelligenz (.md)
- Modules = Code/Tools (Folder)

---

## 🔍 FRAGE 5: Default Agents

### Welche Agents sollten IMMER dabei sein?

```
/.dex/agents/

  ✅ dex-meta-agent.md          (PFLICHT)
     - Haupt-Orchestrator
     - Liest Blueprints
     - Analysiert Projekt
     - Erweitert sich bei Bedarf

  ✅ dex-initializer-agent.md   (PFLICHT)
     - Wird bei "dex init" genutzt
     - Fragt User Fragen
     - Setzt .dex/ auf

  ❓ project-analyzer-agent.md   (OPTIONAL?)
     - Spezialisiert auf Code-Analyse
     - Oder kann dex-meta-agent das?

  ❓ dex-sync-agent.md          (OPTIONAL?)
     - DexHub Synchronisation
     - Oder macht dex-meta-agent das?
```

### Minimalismus vs Spezialisierung

**Option A: Ein Agent kann alles (LEAN)**
```
/.dex/agents/
  dex-meta-agent.md  (500 lines)
    - Initialisierung
    - Analyse
    - Erweiterung
    - Sync
    - Alles!
```

**Option B: Spezialisierte Agents (MODULAR)**
```
/.dex/agents/
  dex-meta-agent.md        (200 lines) - Orchestrator
  dex-init-agent.md        (100 lines) - Initialization
  dex-analyzer-agent.md    (150 lines) - Analysis
  dex-sync-agent.md        (100 lines) - DexHub sync
```

**Option C: Hybrid (PRAGMATISCH)**
```
/.dex/agents/
  dex-meta-agent.md        (300 lines)
    - Core: Orchestration, Blueprint execution
    - Can delegate to specialized agents if present

  # Optional (downloaded on-demand):
  dex-advanced-analyzer.md
  dex-security-scanner.md
```

### ✅ Empfehlung
**Option C: Hybrid**
- `dex-meta-agent.md` (IMMER) - Kann 80% alleine
- Spezialisierte Agents on-demand von DexHub

---

## 🔍 FRAGE 6: Workflows vs Agents

### Unterschied

```
AGENT (.md):
  - Intelligenz
  - Trifft Entscheidungen
  - Kann improvisieren
  - Beispiel: "Analysiere dieses Projekt"

WORKFLOW (.yaml):
  - Prozess
  - Feste Schritte
  - Deterministisch
  - Beispiel: "1. Frage Name, 2. Erstelle Ordner, 3. Init Git"
```

### Wann was?

| Use Case | Agent oder Workflow? | Warum? |
|----------|---------------------|--------|
| Projekt analysieren | Agent | Braucht Intelligenz |
| Onboarding-Fragen | Workflow | Feste Schritte |
| Brownfield-Init | Workflow (+ Agent) | Workflow ruft Agent |
| Bug finden | Agent | Braucht Reasoning |
| Deploy-Pipeline | Workflow | Deterministisch |

### Kombination

```yaml
# .dex/workflows/brownfield-init.yaml
name: Brownfield Project Initialization
trigger: manual

steps:
  - name: Ask User
    type: questions
    questions:
      - project_name
      - project_type

  - name: Analyze Codebase
    type: agent_call
    agent: dex-meta-agent.md
    task: "Analyze this ${project_type} project"

  - name: Generate Context
    type: template
    input: ${agent_output}
    output: .dex/meta/context.yaml

  - name: Detect Completeness
    type: agent_call
    agent: dex-meta-agent.md
    task: "What's missing in this project?"
```

### ✅ Antwort
**Beide nutzen!**
- Workflows = Strukturierte Prozesse
- Agents = Intelligente Entscheidungen
- Workflows RUFEN Agents bei Bedarf

---

## 🔍 FRAGE 7: .dex/ als Mini-DexHub?

### Deine Vision
> "Kann .dex/ alles was DexHub kann, nur projekt-spezifisch?"

### DexHub Capabilities

```
DexHub kann:
  ✅ Neue Projekte erstellen
  ✅ Brainstorming / Sparring
  ✅ Agents orchestrieren
  ✅ Knowledge Hub navigieren
  ✅ Module installieren
  ✅ Community sharen
  ✅ Multi-Project Management
```

### .dex/ Capabilities (Vorschlag)

```
.dex/ kann:
  ✅ Projekt analysieren
  ✅ Projekt erweitern (Agents, Modules)
  ✅ Mit DexHub kommunizieren
  ✅ Learnings erfassen
  ✅ Docs verwalten
  ✅ Completeness tracken

  ❌ NICHT: Neue Projekte erstellen
    (das macht DexHub)
  ❌ NICHT: Multi-Project Management
    (das macht DexHub)
  ✅ ABER: Kann DexHub aufrufen!
    Agent: "This requires DexHub. Connect?"
```

### Architektur

```
┌─────────────────────────────────────────────┐
│  DexHub (Framework-Ebene)                   │
│  - Multi-Project                            │
│  - Brainstorming                            │
│  - Knowledge Hub                            │
│  - Community                                │
└─────────────────┬───────────────────────────┘
                  │
                  │ creates/manages
                  ↓
┌─────────────────────────────────────────────┐
│  .dex/ (Project-Ebene)                      │
│  - Single Project                           │
│  - Analysis                                 │
│  - Extension                                │
│  - Bridge zu DexHub                         │
└─────────────────────────────────────────────┘
```

### ✅ Antwort
**JA, aber Scope unterschiedlich:**
- **DexHub** = Framework (Multi-Project, Creation, Community)
- **.dex/** = Project Agent (Analysis, Extension, DexHub-Bridge)

---

## 🔍 FRAGE 8: Standalone Installation

### Use Case
> "User hat NICHTS mit DexHub zu tun, lädt nur `.dex/` runter und nutzt es"

### Installation Scenarios

#### Szenario A: Via DexHub (Empfohlen)
```bash
# User hat DexHub installiert
cd ~/my-existing-project
dex init

# DexHub:
#   1. Kopiert .dex/ Template
#   2. Erstellt .github/copilot-instructions.md
#   3. Fragt Onboarding-Fragen
#   4. Startet dex-meta-agent
```

#### Szenario B: Standalone (Ohne DexHub)
```bash
# User hat kein DexHub
cd ~/my-existing-project

# Download .dex/ template
curl -L https://github.com/dexhub/dex-template/archive/main.zip -o dex.zip
unzip dex.zip -d .dex
rm dex.zip

# Manual setup .github/
mkdir -p .github
cat > .github/copilot-instructions.md << 'EOF'
This project uses .dex/ meta-layer.
Read .dex/agents/dex-meta-agent.md for instructions.
EOF

# Open in VS Code with Copilot
code .

# Copilot reads .github/copilot-instructions.md
# Copilot loads dex-meta-agent.md
# Agent: "Hi! I'm your .dex/ agent. Let's initialize!"
```

#### Szenario C: Git Clone (Template)
```bash
# DexHub provides template repo
git clone https://github.com/dexhub/dex-template.git my-project
cd my-project
rm -rf .git

# .dex/ ist schon da!
# VS Code + Copilot → dex-meta-agent starts
```

### Was muss in standalone .dex/ sein?

```
/.dex/
  ✅ agents/dex-meta-agent.md     (MUSS)
  ✅ blueprints/                  (MUSS - alle Extensions)
  ✅ meta/ (templates)            (MUSS - leer, aber Struktur)
  ✅ docs/ (templates)            (MUSS - leer, aber Struktur)
  ✅ README.md                    (MUSS - Erklärt was .dex/ ist)
  ✅ config.yaml                  (MUSS - Default settings)
  ❌ modules/                     (NICHT - on-demand)
  ❌ sync.yaml                    (NICHT - DexHub-spezifisch)
```

### ✅ Antwort
**JA, Standalone möglich!**
- Download als ZIP oder Git Clone
- Minimal: ~2MB (Agents + Blueprints + Templates)
- Funktioniert ohne DexHub-Verbindung

---

## 🔍 FRAGE 9: Warum `/docs/` traditionell außerhalb?

### Historische Gründe

#### 1. GitHub Konvention
```
GitHub erwartete:
  /README.md          → Projekt-Overview
  /docs/              → Dokumentation
  /CONTRIBUTING.md    → Wie beitragen
  /LICENSE            → Lizenz
```

**Warum?**
- GitHub rendert `/docs/` automatisch als GitHub Pages
- `example.com/project/docs/` funktioniert out-of-box

#### 2. Sichtbarkeit
```
Repo-Browse zeigt:
  ✅ /docs/ (sichtbar, klickbar)
  ❌ /.dex/docs/ (hidden, nicht offensichtlich)
```

#### 3. Tooling
```
Viele Tools erwarten:
  - MkDocs: /docs/
  - Docusaurus: /docs/
  - Sphinx: /docs/
```

### Warum ist das bei .dex/ ANDERS?

**Weil .dex/ ein META-SYSTEM ist:**

```
Traditionelles Repo:
  /docs/              ← Für Menschen (GitHub Pages)
  /src/               ← Source Code
  /tests/             ← Tests

.dex/-basiertes Repo:
  /.dex/              ← Meta-Layer (Blueprint + Docs + Context)
    /docs/            ← Dokumentation (Teil des Blueprints)
    /meta/            ← Maschinenlesbar
    /agents/          ← Intelligenz
  /src/               ← Source Code (wie immer)
  /tests/             ← Tests (wie immer)
```

**Unterschied:**
- Traditionell: Docs sind "für Website"
- .dex/: Docs sind "Teil des Blueprints" (Export, Rebuild)

### Aber: GitHub Pages Problem

```
Problem:
  GitHub Pages kann .dex/docs/ NICHT automatisch rendern
  (hidden folder)

Lösung:
  gh-pages branch mit Symlink oder Copy
```

### ✅ Antwort
**Bei .dex/ macht `/docs/` außerhalb KEINEN Sinn mehr:**
- .dex/ ist Blueprint (muss selbstständig sein)
- Docs gehören zum Blueprint
- GitHub Pages: Separate Branch wenn nötig

---

## 🎯 FINALE ARCHITEKTUR: Option B++

```
/my-project/

  # ════════════════════════════════════════════
  # COPILOT ENTRY POINT
  # ════════════════════════════════════════════
  /.github/
    copilot-instructions.md    ← Referenziert .dex/

  # ════════════════════════════════════════════
  # DEX META-LAYER (SELF-CONTAINED BLUEPRINT)
  # ════════════════════════════════════════════
  /.dex/

    # ────────────────────────────────────────
    # ENTRY POINT
    # ────────────────────────────────────────
    README.md                  # "What is .dex/?"
    config.yaml                # User settings

    # ────────────────────────────────────────
    # META-DATA (Machine-readable)
    # ────────────────────────────────────────
    /meta/
      context.yaml             # Project context
      connections.yaml         # External links (Jira, etc.)
      tech-stack.yaml          # Detected technologies
      completeness.yaml        # Completeness tracking

    # ────────────────────────────────────────
    # DOCUMENTATION (Human-readable)
    # ────────────────────────────────────────
    /docs/
      /architecture/
        system-design.md
        data-model.md
      /dedisions/
        ADR-001-*.md
      /research/
        brainstorming-*.md
      /specs/
        PRD.md
      /learnings/
        project-learnings.md

    # ────────────────────────────────────────
    # AGENTS (Executable Intelligence)
    # ────────────────────────────────────────
    /agents/
      dex-meta-agent.md        # CORE (always present)
      README.md                # Agent docs
      # Project-specific agents (optional):
      custom-agent.md

    # ────────────────────────────────────────
    # BLUEPRINTS (Extension Templates)
    # ────────────────────────────────────────
    /blueprints/
      core.yaml                # Core blueprint
      /extensions/             # ALL possible extensions (~500KB)
        react.yaml
        vue.yaml
        angular.yaml
        svelte.yaml
        node.yaml
        express.yaml
        nestjs.yaml
        python.yaml
        django.yaml
        flask.yaml
        fastapi.yaml
        java.yaml
        spring.yaml
        go.yaml
        rust.yaml
        graphql.yaml
        rest-api.yaml
        postgres.yaml
        mongodb.yaml
        redis.yaml
        docker.yaml
        kubernetes.yaml
        aws.yaml
        azure.yaml
        ... (~50 total)

    # ────────────────────────────────────────
    # WORKFLOWS (Multi-Step Processes)
    # ────────────────────────────────────────
    /workflows/
      brownfield-init.yaml     # Brownfield setup
      greenfield-init.yaml     # Greenfield setup
      analyze-project.yaml     # Full analysis
      sync-dexhub.yaml         # Sync with DexHub

    # ────────────────────────────────────────
    # MODULES (External Code - on-demand)
    # ────────────────────────────────────────
    /modules/
      README.md                # "Modules are downloaded on-demand"
      # Empty by default
      # Example: graphql-tools/

    # ────────────────────────────────────────
    # REGISTRY (Tracking)
    # ────────────────────────────────────────
    registry.yaml              # Installed modules, active extensions

    # ────────────────────────────────────────
    # SYNC (DexHub Connection - optional)
    # ────────────────────────────────────────
    sync.yaml                  # Last sync, remote URL, version

  # ════════════════════════════════════════════
  # PROJECT CODE (Standard)
  # ════════════════════════════════════════════
  /src/
  /tests/
  package.json
  README.md
```

---

## 🚀 Installation Modes

### Mode 1: Via DexHub (Recommended)
```bash
cd my-project
dex init

# DexHub installs:
#   ✅ .dex/ (full template)
#   ✅ .github/copilot-instructions.md
#   ✅ Runs dex-initializer-agent
#   ✅ Connects to DexHub (optional)
```

### Mode 2: Standalone
```bash
cd my-project
curl -L https://dexhub.io/install.sh | bash

# Script installs:
#   ✅ .dex/ (full template)
#   ✅ .github/copilot-instructions.md
#   ✅ No DexHub connection
```

### Mode 3: Git Clone
```bash
git clone https://github.com/dexhub/dex-template.git my-project
cd my-project
rm -rf .git
git init

# .dex/ already present
# Open in VS Code → Copilot activates dex-meta-agent
```

---

## 🔗 DexHub Connection

### Connection Modes

#### Fully Offline
```yaml
# .dex/sync.yaml
mode: offline
dexhub_url: null
last_sync: never
```

**Can do:**
- ✅ Project analysis (via blueprints)
- ✅ Agent execution
- ✅ Docs management
- ❌ Module downloads
- ❌ Community sharing
- ❌ Blueprint updates

---

#### Connected (Recommended)
```yaml
# .dex/sync.yaml
mode: connected
dexhub_url: https://api.dexhub.io
last_sync: 2025-10-24T10:30:00Z
version: 1.0.0
```

**Can do:**
- ✅ Everything from offline
- ✅ Module downloads
- ✅ Community sharing
- ✅ Blueprint updates
- ✅ Knowledge Hub access

---

## 📦 What's Included by Default?

| Component | Size | Included? | Why? |
|-----------|------|-----------|------|
| dex-meta-agent.md | 50KB | ✅ Always | Core intelligence |
| blueprints/extensions/ | 500KB | ✅ Always | Offline-capable |
| blueprints/core.yaml | 20KB | ✅ Always | Core logic |
| workflows/ | 50KB | ✅ Always | Standard processes |
| meta/ templates | 10KB | ✅ Always | Structure |
| docs/ templates | 10KB | ✅ Always | Structure |
| modules/ | 0KB | ❌ Empty | On-demand |
| sync.yaml | 1KB | Optional | If DexHub-connected |

**Total:** ~640KB (tiny!)

---

## 🎯 Key Dedisions

### ✅ FINALIZED

1. **Option B** - Docs IN .dex/
2. **Self-contained** - Works offline
3. **All blueprints included** - ~500KB is acceptable
4. **dex-meta-agent.md** - Single core agent (can delegate)
5. **GitHub Copilot Entry** - Via .github/copilot-instructions.md
6. **Modules on-demand** - From DexHub when needed
7. **Community sharing** - Via GitHub API (partial push)
8. **Standalone installable** - Git clone or curl install

### ❓ OPEN (Need Copilot Transcript Analysis)

1. **Agent prompt structure** - Best practices from Copilot
2. **Blueprint YAML schema** - Validate against Copilot knowledge
3. **Multi-agent coordination** - How Copilot handles multiple agents
4. **Token limits** - How much context can .dex/ safely be?

---

## 📝 Next Steps

1. **Analyze Copilot transcript** - Extract best practices
2. **Write dex-meta-agent.md** - Proof of concept
3. **Define blueprint schema** - YAML specification
4. **Create .dex/ template repo** - For standalone install
5. **Test with real project** - Dogfood DexHub Alpha V1 itself

---

**Document Status:** Architecture Design - Awaiting Copilot Transcript Analysis
**Next:** Extract insights from 8000-line transcript
