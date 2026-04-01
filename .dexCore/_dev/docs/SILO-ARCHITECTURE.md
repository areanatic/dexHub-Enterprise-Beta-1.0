# SILO Architecture: DXM-Aligned Meta-Layer

**Version:** 3.1 (Extended Workflow Mapping)
**Status:** ✅ Official Standard (DexHub V3.1+)
**Created:** 2025-11-05
**Last Updated:** 2025-11-05
**Author:** DexHub Core Team
**Replaces:** V2.0 Activity-Based Structure

---

> **⚠️ VERSION CONTEXT - READ THIS FIRST:**
>
> - **Product Version (User-Facing):** Enterprise Alpha 1.0 (EA-1.0)
> - **Architecture Version (Internal):** V3.1 (SILO Structure Evolution)
> - **Branch:** feature/EX-1 (Experimental Development)
>
> **Important:** "V3.1" in this document refers to the SILO architecture iteration,
> NOT the product version. External users see "Enterprise Alpha 1.0" (EA-1.0).
>
> This distinction prevents confusion between internal architecture evolution
> and public product releases.

---

## What is SILO Architecture?

SILO (Separated Input/Logic/Output) Architecture is DexHub's approach to **strict separation** between:
- **Code** (`src/`) - Executable source code
- **Meta-Data** (`.dex/`) - Documentation, planning, specifications, decisions

### Core Principle

**ALL non-code artifacts MUST live in `.dex/` layer.**

```
myDex/projects/{project-name}/
├── src/                    ← ONLY CODE
│   ├── index.js
│   ├── components/
│   └── utils/
└── .dex/                   ← ALL META-DATA
    ├── 1-analysis/
    ├── 2-planning/
    ├── 3-solutioning/
    ├── 4-implementation/
    ├── sessions/
    ├── decisions/
    ├── config/
    └── agent-state/
```

**Why?**
- Clean separation prevents docs/code mixing
- Easy to .gitignore `.dex/` for privacy
- Clear mental model: code vs. planning
- Scalable: works for tiny projects to enterprise

---

## DXM-Aligned Structure (Official)

After evaluation of multiple approaches, **DXM-Aligned** was chosen as the official standard.

### Full Structure

```
.dex/
├── 1-analysis/              # Phase 1: Discovery & Analysis
│   ├── brainstorm/          # Brainstorming sessions (all variants)
│   │   └── brainstorm-{theme}-{YYYYMMDD}-{HHMM}.md
│   ├── research/            # Market research, competitive analysis
│   │   └── research-{theme}-{YYYYMMDD}-{HHMM}.md
│   └── product-brief/       # Product briefs (including game briefs)
│       └── product-brief-{theme}-{YYYYMMDD}-{HHMM}.md
│
├── 2-planning/              # Phase 2: Requirements & Design
│   ├── prd/                 # Product Requirements Documents
│   │   ├── PRD.md
│   │   └── PRD-validation-report.md
│   ├── gdd/                 # Game Design Documents
│   │   └── GDD.md
│   ├── narrative/           # Narrative design documents
│   │   └── narrative-{theme}-{YYYYMMDD}-{HHMM}.md
│   ├── ux/                  # UX design documents
│   │   └── ux-{theme}-{YYYYMMDD}-{HHMM}.md
│   └── tech-spec/           # Technical specifications (planning phase)
│       └── tech-spec-{theme}-{YYYYMMDD}-{HHMM}.md
│
├── 3-solutioning/           # Phase 3: Technical Architecture
│   ├── architecture/        # System architecture documents
│   │   └── architecture.md
│   └── tech-spec/           # Technical specifications (architecture phase)
│       └── tech-spec-epic-{n}.md
│
├── 4-implementation/        # Phase 4: Development Artifacts
│   ├── stories/             # User stories
│   │   └── story-{epic}-{n}.md
│   ├── sprints/             # Sprint planning, retrospectives, course corrections
│   │   └── sprint-{n}-retro.md
│   └── testing/             # Test architecture artifacts
│       ├── framework/       # Test framework setup
│       ├── atdd/            # Acceptance test-driven development
│       ├── automate/        # Test automation
│       ├── test-design/     # Test scenario design
│       ├── trace/           # Requirements-to-tests tracing
│       ├── nfr-assess/      # Non-functional requirements assessment
│       ├── ci/              # CI/CD pipeline configuration
│       └── gate/            # Quality gate decisions
│
├── sessions/                # Session logs
│   └── session-{topic}-{date}.md
│
├── decisions/               # Architecture Decision Records (ADRs)
│   └── ADR-{n}-{title}.md
│
├── config/                  # Project-specific configurations
│   └── project-config.yaml
│
└── agent-state/             # Agent memory/state for this project
    └── agent-memory.json
```

---

## Why DXM-Aligned?

We evaluated two main approaches:

### Option A: Activity-Based (V2.0 - Deprecated)
```
.dex/
├── briefing/    # Mixed: brainstorm, research, product-brief
├── planning/    # Mixed: PRD, GDD
├── solutioning/ # Architecture, tech-spec
└── decisions/   # ADRs
```

**Problems:**
- Multiple workflow types mixed in same folder
- Repeated execution → file naming conflicts
- Example: `brainstorm-v1.md`, `brainstorm-v2.md`, `brainstorm-final.md` all in `briefing/`

### Option B: DXM-Aligned (V3.0 - Current) ✅
```
.dex/
├── 1-analysis/
│   ├── brainstorm/  # Separate folder per workflow type
│   ├── research/
│   └── product-brief/
```

**Advantages:**
- ✅ Each workflow type has dedicated folder
- ✅ Repeated executions: `brainstorm-ai-tool-20251105-1430.md`, `brainstorm-ai-tool-20251105-1530.md`
- ✅ Timestamp prevents overwrites
- ✅ Clear chronological history per workflow type
- ✅ Aligns with DexHub 4-phase methodology
- ✅ Scales to enterprise without reorganization

---

## Smart Filename Generation

All files use semantic timestamps:

**Pattern:** `{category}-{theme}-{YYYYMMDD}-{HHMM}.md`

**Examples:**
- `brainstorm-ai-powerpoint-20251105-1430.md`
- `research-market-analysis-20251105-1500.md`
- `prd-mobile-app-20251105-1615.md`

**Benefits:**
- Human-readable
- Chronologically sortable
- Theme-based grouping
- No overwrites (unique timestamp)

---

## Routing Logic

### Draft Mode
**When:** `current_project = null` in `config.yaml`

**Output:** `myDex/drafts/`

```yaml
# config.yaml
current_project: null          # Draft mode
output_folder: "./myDex/drafts"
```

**Result:** All workflows save to `myDex/drafts/` with smart filenames.

### Project Mode
**When:** `current_project = "project-name"` in `config.yaml`

**Output:** `myDex/projects/{project-name}/.dex/{dexhub-aligned-path}/`

```yaml
# config.yaml
current_project: "my-awesome-app"
project_base_path: "./myDex/projects"
```

**Result:** Workflows automatically route to correct `.dex/` subfolder.

---

## Workflow Integration

### workflow.xml (Core Engine)

The routing logic lives in `workflow.xml` substeps 1b.5 and 1b.6:

**Substep 1b.5: Smart Filename Generation**
- Extracts workflow category from path
- Asks user for theme/topic
- Generates timestamp
- Creates: `{category}-{theme}-{YYYYMMDD}-{HHMM}.md`

**Substep 1b.6: DXM-Aligned Routing**
- Reads `current_project` from config
- IF null → Draft mode (myDex/drafts/)
- IF set → Project mode (parse workflow path → map to .dex/ structure)

**Mapping Example:**
```
Workflow location: .dexCore/dxm/workflows/1-analysis/brainstorm/
↓
Extract: "1-analysis/brainstorm"
↓
Map to: myDex/projects/my-app/.dex/1-analysis/brainstorm/
↓
Final: myDex/projects/my-app/.dex/1-analysis/brainstorm/brainstorm-ai-tool-20251105-1430.md
```

---

## Agent Integration

All DXM agents have `<output_handling>` block that declares:

```xml
<output_handling>
  <context_awareness>
    <principle>This agent is context-aware and respects the current project state</principle>
  </context_awareness>

  <agent_responsibility>
    <do>
      - Execute workflows via workflow.xml (which handles routing)
      - Respect {output_folder} variable from config
      - Trust DXM-Aligned routing logic in workflow.xml
    </do>
    <dont>
      - DO NOT manually determine output paths
      - DO NOT bypass workflow.xml routing logic
      - DO NOT hardcode paths
    </dont>
  </agent_responsibility>
</output_handling>
```

**Key Insight:** Agents **DO NOT** determine paths. They trust `workflow.xml` routing.

---

## Project Creation Flow

### 1. Draft Phase
User starts without project:
```yaml
current_project: null
```

Workflows save to `myDex/drafts/`:
- `brainstorm-ai-tool-20251105-1430.md`
- `research-market-20251105-1445.md`

### 2. Detection
After 2+ related files detected (fuzzy theme matching):

```
💡 Empfehlung

Du hast jetzt 2 Dokumente zu "ai-tool":
- brainstorm-ai-tool-20251105-1430.md
- research-market-20251105-1445.md

Soll ich ein Projekt anlegen?
→ Bessere Organisation
→ Verhindert Output-Vermüllung
→ .dex/ layer für Struktur

[Ja, Projekt anlegen] [Nein, weiter in outputs/] [Später fragen]
```

### 3. Project Creation
User confirms → `mydex-project-manager` agent:

1. **Creates structure:**
```
myDex/projects/ai-tool/
├── src/           ← Empty (for future code)
└── .dex/          ← DexHub structure
    ├── 1-analysis/
    │   ├── brainstorm/
    │   └── research/
    └── INDEX.md   ← Activity log
```

2. **Migrates files:**
- `brainstorm-ai-tool-20251105-1430.md` → `.dex/1-analysis/brainstorm/`
- `research-market-20251105-1445.md` → `.dex/1-analysis/research/`

3. **Updates config:**
```yaml
current_project: "ai-tool"
```

4. **Creates INDEX.md:**
```markdown
# Project: ai-tool

**Created:** 2025-11-05

## Activity Log

### 2025-11-05 - Project Created
- Migrated 2 files from myDex/drafts/
- Initial files:
  - brainstorm-ai-tool-20251105-1430.md
  - research-market-20251105-1445.md
```

### 4. Project Mode
Now all subsequent workflows automatically save to:
`myDex/projects/ai-tool/.dex/{correct-subfolder}/`

---

## Edge Cases

### Repeated Workflow Execution
**Scenario:** User runs brainstorm 3 times in same project.

**Result:**
```
.dex/1-analysis/brainstorm/
├── brainstorm-ai-tool-20251105-1430.md  # First run
├── brainstorm-ai-tool-20251105-1530.md  # Second run
└── brainstorm-ai-tool-20251105-1645.md  # Third run
```

**Benefit:** Each execution preserved, chronologically sorted, no overwrites.

### Cross-Phase Iteration
**Scenario:** User works on PRD, then goes back to research, then returns to PRD.

**Result:**
```
.dex/
├── 1-analysis/research/
│   └── research-competitor-20251105-1500.md  # New research
└── 2-planning/prd/
    ├── PRD.md  # Original (can be updated)
    └── PRD-v2-20251105-1530.md  # Revised version
```

**Benefit:** Natural iteration, no forced linearity.

### Unknown Workflow Type
**Scenario:** Workflow path doesn't match known categories.

**Fallback:**
```
Default to: .dex/1-analysis/brainstorm/
```

**Rationale:** Safe default for exploration.

---

## Migration from V2.0 (Activity-Based)

If upgrading from V2.0 with activity-based structure:

### Old (V2.0 - Activity-Based)
```
myDex/projects/my-app/.dex/
├── briefing/      # Mixed: brainstorm, research, product-brief
├── decisions/
├── sessions/
└── workflows/
```

### New (V3.0 - DXM-Aligned)
```
myDex/projects/my-app/.dex/
├── 1-analysis/
│   ├── brainstorm/
│   ├── research/
│   └── product-brief/
├── 2-planning/
├── 3-solutioning/
├── 4-implementation/
├── sessions/
└── decisions/
```

**Migration Strategy:**
1. Create DXM-Aligned structure
2. Map old folders to new:
   - `briefing/brainstorm-*.md` → `.dex/1-analysis/brainstorm/`
   - `briefing/research-*.md` → `.dex/1-analysis/research/`
   - `briefing/product-brief-*.md` → `.dex/1-analysis/product-brief/`
   - `workflows/prd-*.md` → `.dex/2-planning/prd/`
3. Move files
4. Update config
5. Test workflow execution

---

## Privacy & Security

### Gitignore Strategy

**For private projects:**
```gitignore
# .gitignore
.dex/          # Entire meta-layer (private planning)
src/           # Code is public
```

**For open-source projects:**
```gitignore
# .gitignore
.dex/agent-state/   # Agent memory (private)
.dex/sessions/      # Session logs (private)
.dex/config/        # Local config (private)

# Keep public:
# .dex/1-analysis/
# .dex/2-planning/
# .dex/3-solutioning/
# .dex/4-implementation/
```

**Benefit:** Fine-grained control over what's shared vs. private.

---

## Testing & Validation

### Manual Test Checklist

**Draft Mode:**
- [ ] Set `current_project: null` in config
- [ ] Run brainstorm workflow
- [ ] Verify file created in `myDex/drafts/`
- [ ] Verify smart filename: `{category}-{theme}-{YYYYMMDD}-{HHMM}.md`

**Project Mode:**
- [ ] Create project via `mydex-project-manager`
- [ ] Verify `.dex/` structure created with DXM-Aligned folders
- [ ] Verify `current_project` updated in config
- [ ] Run workflow
- [ ] Verify file routed to correct `.dex/` subfolder

**Project Creation:**
- [ ] Create 2 files in `myDex/drafts/` with similar theme
- [ ] Verify agent prompts for project creation
- [ ] Accept prompt
- [ ] Verify files migrated to `.dex/1-analysis/` subfolders
- [ ] Verify `INDEX.md` created
- [ ] Verify originals deleted from `outputs/`

---

## Architecture Decisions

### ADR-001: DXM-Aligned Over Activity-Based
**Status:** Accepted
**Date:** 2025-11-05
**Context:** Need to choose folder structure for `.dex/` layer.
**Decision:** DXM-Aligned (phase-based with workflow-type subfolders)
**Rationale:** Better handling of repeated workflows, clearer separation, aligns with methodology.
**Consequences:** More folders, but clearer organization and no naming conflicts.

### ADR-002: Smart Filenames with Timestamps
**Status:** Accepted
**Date:** 2025-11-05
**Context:** Need unique filenames for repeated workflow execution.
**Decision:** `{category}-{theme}-{YYYYMMDD}-{HHMM}.md` pattern
**Rationale:** Human-readable, sortable, prevents overwrites, theme-based grouping.
**Consequences:** Longer filenames, but better UX and no file loss.

### ADR-003: Centralized Routing in workflow.xml
**Status:** Accepted
**Date:** 2025-11-05
**Context:** Where should output path logic live?
**Decision:** Central routing in `workflow.xml` substeps 1b.5 and 1b.6
**Rationale:** Single source of truth, agents don't need path knowledge, easier to maintain.
**Consequences:** `workflow.xml` complexity increases, but system-wide consistency improves.

---

## Future Enhancements

### Planned Features (V3.1+)
- [ ] Automatic archiving of old files after 90 days
- [ ] Project templates (web app, mobile app, game, CLI tool)
- [ ] Multi-project workspaces
- [ ] Project tagging and search
- [ ] Visual file browser for `.dex/` structure
- [ ] Export project as ZIP (with/without `.dex/`)

### Under Consideration
- [ ] Support for monorepo projects
- [ ] Integration with external docs (Notion, Confluence)
- [ ] Workflow dependency graphs
- [ ] Automated PRD validation against `.dex/1-analysis/` docs

---

## Summary

**SILO Architecture = Strict separation between code (`src/`) and meta-data (`.dex/`)**

**DXM-Aligned Structure = Official standard for `.dex/` organization**

**Key Benefits:**
- ✅ Clear mental model (4 phases, workflow-type subfolders)
- ✅ Handles repeated workflows gracefully
- ✅ Smart filenames prevent overwrites
- ✅ Automatic routing via `workflow.xml`
- ✅ Context-aware (draft mode vs. project mode)
- ✅ Scales from POC to enterprise
- ✅ Privacy-friendly (.gitignore `.dex/` or parts of it)

**Integration Points:**
- `workflow.xml` (substeps 1b.5, 1b.6) - Core routing engine
- `config.yaml` (current_project, output_folder) - State management
- `mydex-project-manager.md` - Project creation/migration
- All DXM agents - `<output_handling>` block awareness

**Status:** ✅ Production-ready (DexHub V3.1+)

---

**Related Documents:**
- [OUTPUT-HANDLING-TEMPLATE.md](./_dev/docs/OUTPUT-HANDLING-TEMPLATE.md) - Template for agents
- [mydex-project-manager.md](./core/agents/mydex-project-manager.md) - Project creation agent
- [workflow.xml](./core/tasks/workflow.xml) - Core workflow engine
- [config.yaml](./_cfg/config.yaml) - Global configuration

**Version History:**
- **3.1** (2025-11-05): Extended workflow mapping - Added support for game workflows (brainstorm-game, game-brief), narrative, UX, and complete testarch/* integration with dedicated testing/ subfolder
- **3.0** (2025-11-05): DXM-Aligned structure as official standard (replaces V2.0 Activity-Based)
- **2.0** (2025-11-04): Activity-Based structure (deprecated)
- **1.0** (earlier): Initial SILO concept

---

*This architecture is the foundation of DexHub's intelligent output management. It enables seamless transitions from exploration (draft mode) to structured development (project mode) while maintaining clean separation between code and planning artifacts.*
