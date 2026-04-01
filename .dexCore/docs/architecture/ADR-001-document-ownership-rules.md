> **REBRANDED:** 2025-10-26 - DexHub Omega → DexHub Alpha V1 (FINAL AUTHORITATIVE VERSION)

# ADR-001: Document Ownership Rules

**Status:** Draft - Requires Holistic Challenge
**Date:** 2025-10-24
**Dedision Makers:** Ash, Claude
**Context:** DexHub Alpha V1 Architecture Design

---

## Context

During the development of DexHub Alpha V1, a fundamental question arose:

> "Where should project-related documents be stored in a multi-project workspace?"

**Concrete Problem:**
- Brainstorming and feedback documents were created in `/sandbox-dex-v6_0/docs/`
- But they belong to `/projects/dexhub-alpha-v1/` conceptually
- **Question:** How does DexHub handle document ownership and location?

This dedision is **critical** because:
1. DexHub itself will be a **document-heavy framework**
2. Users will work on **multiple projects** simultaneously
3. The **`.dex/` meta-layer** needs clear rules
4. **Export** functionality depends on document location
5. **Community sharing** requires predictable structure

---

## Dedision

**Approach: Hybrid (Option A + D)**

### Core Principle
> "Documents belong to their project context, with agent-assisted placement and explicit exceptions for cross-project content"

---

## Rules

### Rule 1: Default Project Ownership
**Principle:** Documents belong to the nearest project context

```
/dexhub/                          # DexHub Repository
  /docs/                          # Only DexHub-framework docs
    setup.md
    contributing.md

  /dexspace/                      # User projects
    /my-app/
      /.dex/                      # Meta-layer
      /docs/                      # Project-specific docs ✅
        /architecture/
        /research/
          brainstorming-*.md
        /dedisions/
        /learnings/
      /src/
```

**Rationale:**
- ✅ Clear ownership
- ✅ Export-ready (project + docs together)
- ✅ Scalable (works with 1 or 1000 projects)
- ✅ GitHub-standard pattern

---

### Rule 2: Cross-Project Documents
**Principle:** Explicitly mark and place in shared location

**Location:** `/knowledge/` (global) or `/docs/` (workspace)

**Requirements:**
- Must have frontmatter with `scope: cross-project`
- Must reference affected projects
- Should be rare (most docs belong to a project)

**Example:**
```markdown
---
scope: cross-project
projects: [dexhub-alpha-v1, my-app, another-app]
tags: [architecture, standards]
---

# Global Architecture Dedisions

This document affects all projects...
```

**Rationale:**
- ⚠️ Exception, not the rule
- 📋 Explicit metadata prevents confusion
- 🔍 Searchable/filterable

---

### Rule 3: Agent-Assisted Placement (`.dex/` Integration)
**Principle:** DexMaster asks or infers document location

**Scenarios:**

#### A) Obvious Context (Agent infers)
```
User: "Start brainstorming for DexHub features"
Context: Working in /dexspace/dexhub-alpha-v1/
Agent: [Creates brainstorming-*.md in ./docs/research/] ✅
```

#### B) Ambiguous Context (Agent asks)
```
User: "Document our API architecture"
Context: Multiple projects open
Agent: "Which project is this for?"
  → DexHub Alpha V1
  → My App
  → All Projects (cross-project)
```

#### C) `.dex/context.md` Tracks Ownership
```yaml
# .dex/context.md
project:
  name: DexHub Alpha V1
  type: framework
  docs_policy: strict  # All docs must be in ./docs/

documents:
  - path: docs/research/brainstorming-2025-10-23.md
    created: 2025-10-23
    type: research
  - path: docs/dedisions/ADR-001-*.md
    created: 2025-10-24
    type: adr
```

**Rationale:**
- 🤖 Automation reduces user burden
- 🎯 Context-aware (smart defaults)
- 📝 `.dex/` tracks everything (completeness)

---

### Rule 4: Special Cases

#### Brownfield Projects (External Repos)
```
/external-repo/                   # Not in DexHub
  /.dex/                          # Added by DexHub
    context.md
    learnings.md
  /docs/                          # Existing structure
    (existing docs)
  /src/
```

**Rule:** Respect existing structure, augment with `.dex/`

---

#### Sandbox/Experimental Workspaces
```
/sandbox-dex-v6_0/
  /docs/                          # Sandbox-level docs OK
    sandbox-setup.md
    meta-dedisions.md
  /projects/
    /dexhub-alpha-v1/
      /docs/                      # Project docs here ✅
```

**Rule:** Sandbox docs are meta-level only (setup, experiments, not project content)

---

## Consequences

### Positive
- ✅ **Clear structure** - No ambiguity about where docs go
- ✅ **Portable** - Projects can be moved/exported with docs
- ✅ **Scalable** - Works with any number of projects
- ✅ **Agent-friendly** - Clear rules for automation
- ✅ **Git-standard** - Follows common patterns

### Negative
- ⚠️ **Migration needed** - Existing docs may need moving
- ⚠️ **Cross-project docs** - Require explicit handling
- ⚠️ **Agent complexity** - Needs context detection logic

### Neutral
- 🔄 **Convention over configuration** - Opinionated, but overridable
- 📚 **Learning curve** - Users need to understand the system

---

## Open Questions (Holistic Challenge Required)

### Q1: `.dex/` vs. `/docs/` Relationship
**Question:** Should `.dex/` BE the docs folder, or separate?

**Option A: Separate (Current)**
```
/my-app/
  /.dex/           # Meta-layer (context, learnings, changelog)
  /docs/           # Human-readable docs
```

**Option B: Integrated**
```
/my-app/
  /.dex/
    /meta/         # Machine-readable (context, connections)
    /docs/         # Human-readable (architecture, dedisions)
```

**Challenge:**
- Pros/Cons of each?
- Best practices (GitHub, DEX)?
- AI/LLM considerations?

---

### Q2: Document Types & Structure
**Question:** What document categories should exist?

**Current Proposal:**
```
/docs/
  /architecture/   # System design, diagrams
  /dedisions/      # ADRs
  /learnings/      # Project-specific learnings
  /research/       # Brainstorming, exploration
  /specs/          # Requirements, PRDs
```

**Challenge:**
- Complete list?
- Naming conventions?
- Required vs. optional?
- Framework-adaptive? (React project vs. Backend project)

---

### Q3: Frontmatter Standards
**Question:** What metadata should all docs have?

**Proposal:**
```yaml
---
project: dexhub-alpha-v1        # Which project
type: research                   # Document type
scope: project                   # project | cross-project | global
created: 2025-10-24
updated: 2025-10-24
tags: [brainstorming, features]
related_docs: [ADR-002, PRD-001]
---
```

**Challenge:**
- Required fields?
- Optional fields?
- Validation/Linting?
- Agent auto-generates?

---

### Q4: Community Sharing
**Question:** When sharing a DexSpace, what gets shared?

**Scenarios:**

**A) Share Everything**
```
my-app/
  /.dex/     ✅ Shared (Blueprint)
  /docs/     ✅ Shared (Context)
  /src/      ✅ Shared (Code)
```

**B) Share Selective**
```
my-app/
  /.dex/
    context.md         ✅ Shared
    learnings.md       ✅ Shared
    team.md            ❌ Private
  /docs/               ✅ Shared
  /src/                ✅ Shared
```

**C) Share Blueprint Only**
```
my-app/
  /.dex/     ✅ Shared (Blueprint)
  /docs/     ✅ Shared (Context)
  /src/      ❌ Not shared (Code private)
```

**Challenge:**
- Default behavior?
- User control (.dex/visibility.yaml)?
- License implications?

---

### Q5: Versioning & History
**Question:** How do we version documents?

**Options:**

**A) Git Native**
- Use git history
- No special versioning

**B) Explicit Versions**
```
/docs/architecture/
  system-design-v1.md
  system-design-v2.md
```

**C) Time-Travel (.dex/ History)**
```
/.dex/history/
  2025-10-23-snapshot.json
  2025-10-24-snapshot.json
```

**Challenge:**
- Which approach?
- Combination?
- User-facing UI for time-travel?

---

### Q6: Search & Discovery
**Question:** How do users find documents?

**DexMaster Commands:**
- `*find architecture` - Search all project docs?
- `*find brainstorming --project my-app` - Scoped search?
- `*recent-docs` - Show recently modified?

**Challenge:**
- Search scope (current project vs. all projects)?
- Indexing strategy?
- Performance with many projects?

---

### Q7: Agent-Generated vs. User-Created
**Question:** How do we differentiate?

**Proposal:**
```yaml
---
author: agent | user | collaborative
generator: dex-master | brainstorming-agent
---
```

**Challenge:**
- Why does it matter?
- Trust/Validation?
- Edit permissions?

---

### Q8: Brownfield Integration
**Question:** What if project already has `/docs/`?

**Scenario:**
```
/existing-repo/
  /docs/                    # Existing docs (100+ files)
  [DexHub adds .dex/]
```

**Options:**
- A) Leave docs as-is, `.dex/` references them
- B) Migrate docs to `.dex/` structure
- C) Hybrid (map existing structure in `.dex/context.md`)

**Challenge:**
- Minimal disruption?
- Backward compatibility?

---

### Q9: Multilingual Documentation
**Question:** How to handle DE/EN docs?

**Option A: Separate Folders**
```
/docs/
  /de/
    architecture/
  /en/
    architecture/
```

**Option B: Suffixed Files**
```
/docs/architecture/
  system-design.de.md
  system-design.en.md
```

**Option C: Frontmatter**
```yaml
---
language: de
translations: [en/architecture/system-design.md]
---
```

**Challenge:**
- Which approach?
- Auto-translate?
- Sync mechanism?

---

### Q10: Documentation Completeness
**Question:** How does `.dex/` track completeness?

**Proposal:**
```yaml
# .dex/completeness.yaml
documentation:
  required:
    - architecture/system-design.md: ✅ Complete
    - dedisions/ADR-001-*.md: ✅ Complete
    - specs/PRD.md: ⚠️ Missing
  optional:
    - learnings/: ✅ Has entries

  score: 75%
  blockers:
    - "PRD is missing (required for production)"
```

**Challenge:**
- Required vs. optional docs per project type?
- Scoring algorithm?
- Enforcement? (Block deployment if incomplete?)

---

## Next Steps

### Immediate (Before MVP)
1. **Holistic Challenge Session** - Deep dive into all 10 questions
2. **Document each dedision** - Separate ADRs if needed
3. **Implement rules in DexMaster** - Agent logic for placement
4. **Create `.dex/` schema** - Document tracking structure
5. **Test with DexHub Alpha V1** - Dogfood our own system

### Future Iterations
1. **User testing** - Validate approach with real users
2. **Refinement** - Adjust based on feedback
3. **Automation** - Enhance agent capabilities
4. **Documentation** - User guides, best practices

---

## References

- **Trigger Issue:** Misplaced `brainstorming-session-results-2025-10-23.md` and `scamper-feedback-analysis.md`
- **Discussion:** [Session 2025-10-24]
- **Related:** `.dex/` Meta-Layer Architecture (pending ADR)
- **Related:** Community Sharing Model (pending ADR)

---

## Dedision Status

**Current:** Draft - Awaiting Holistic Challenge
**Required:** Full team review of all 10 open questions
**Timeline:** Before DexHub MVP finalization

---

**Notes:**
- This ADR is intentionally incomplete - it documents the dedision AND the questions
- The 10 open questions are the agenda for our holistic challenge session
- Each question may spawn its own ADR if complex enough

---

_This ADR follows the MADR format with DexHub-specific extensions_
