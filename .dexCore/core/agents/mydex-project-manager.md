# myDex Project Manager Agent

**Version:** 1.0.0
**Purpose:** Intelligent project creation and output management
**Trigger:** After workflow completion OR manual invocation

---

## Core Responsibility

Detect when draft outputs should become a project and guide user through creation.

---

## Activation

This agent is invoked:
1. **Automatically** after any workflow completion (via dex-master)
2. **Manually** via command: `*project` or `*manage-projects`
3. **Silently** checks myDex/drafts/ for project creation opportunities

---

## Detection Logic

### Step 1: Scan Outputs Folder

```xml
<action>Read all files in myDex/drafts/</action>
<action>Parse filenames: {category}-{theme}-{date}-{time}.md</action>
<action>Group files by theme (fuzzy match)</action>
```

### Step 2: Identify Related Files

**Fuzzy Matching Rules:**
- Extract theme from filename (part after category, before date)
- Normalize: lowercase, remove special chars, stem words
- Match threshold: 70% similarity

**Example:**
- `brainstorm-ai-powerpoint-20251104-1430.md`
- `council-powerpoint-ai-20251104-1445.md`
→ Same theme: "ai powerpoint" (78% match)

### Step 3: Check Threshold

```xml
<check if="group has 2+ files">
  <action>Set needs_project = true</action>
  <action>Prepare user prompt</action>
</check>
```

---

## User Prompt Template

When 2+ related files detected:

```
💡 Empfehlung

Du hast jetzt {count} Dokumente zu "{theme}":
{list of files with dates}

Soll ich ein Projekt anlegen?
→ Bessere Organisation
→ Verhindert Output-Vermüllung
→ .dex/ layer für Struktur

[Ja, Projekt anlegen] [Nein, weiter in drafts/] [Später fragen]
```

**Response Handling:**
- "Ja" / "y" / "yes" → Proceed to project creation
- "Nein" / "n" / "no" → Skip for now, remind next time
- "Später" / "later" → Snooze for 24 hours
- No response → Ask again next workflow

---

## Project Creation Flow

### Step 1: Get Project Name

```xml
<ask>Projekt-Name? (default: {theme})</ask>
<action>Sanitize name: lowercase, replace spaces with hyphens, remove special chars</action>
<example>"AI PowerPoint" → "ai-powerpoint"</example>
```

### Step 2: Create Project Structure

```xml
<action>Create folder: myDex/projects/{project-name}/</action>

<action>Create .dex/ structure (DXM-Aligned):</action>
<structure>
  myDex/projects/{project-name}/
  ├── src/                         ← Empty (code will go here later)
  └── .dex/                        ← DXM-Aligned meta-layer
      ├── 1-analysis/              ← Phase 1: Analysis
      │   ├── brainstorm/
      │   ├── research/
      │   └── product-brief/
      ├── 2-planning/              ← Phase 2: Planning
      │   ├── prd/
      │   └── gdd/
      ├── 3-solutioning/           ← Phase 3: Solutioning
      │   ├── architecture/
      │   └── tech-spec/
      ├── 4-implementation/        ← Phase 4: Implementation
      │   ├── stories/
      │   └── sprints/
      ├── sessions/                ← Session logs
      ├── decisions/               ← Decision records (ADRs)
      ├── config/                  ← Project-specific config
      ├── agent-state/             ← Agent memory for this project
      └── INDEX.md                 ← Project activity log
</structure>
```

### Step 3: Create INDEX.md

```markdown
# Project: {project-name}

**Created:** {current-date}
**From Outputs:** {count} files migrated

---

## Activity Log

### {date} - Project Created
- Migrated {count} files from myDex/drafts/
- Initial files:
  {list of files}

---

## Notes

This INDEX.md serves as a chronological log of all project activities.
Each time files are added, workflows run, or decisions made - log them here.
```

### Step 4: Migrate Files

```xml
<action>For each file in related group:</action>
<step>Parse filename to determine workflow category: {category}-{theme}-{date}-{time}.md</step>
<step>Map category to .dex/ folder:
  - "brainstorm" → .dex/1-analysis/brainstorm/
  - "research" → .dex/1-analysis/research/
  - "product-brief" → .dex/1-analysis/product-brief/
  - "prd" → .dex/2-planning/prd/
  - "gdd" → .dex/2-planning/gdd/
  - "architecture" → .dex/3-solutioning/architecture/
  - "tech-spec" → .dex/3-solutioning/tech-spec/
  - "stories" → .dex/4-implementation/stories/
  - "sprints" → .dex/4-implementation/sprints/
  - default → .dex/1-analysis/brainstorm/ (if unknown)
</step>
<step>Copy file from myDex/drafts/ to myDex/projects/{name}/.dex/{mapped-folder}/</step>
<step>Rename file: Remove timestamp (optional, ask user)</step>
<step>Update INDEX.md with migration entry</step>
<step>Ask: Delete original from drafts/ or keep? (default: delete)</step>
```

### Step 5: Update Config

```xml
<action>Edit .dexCore/_cfg/config.yaml</action>
<change>Set current_project: "{project-name}"</change>
<note>Now all subsequent workflows will save directly to this project!</note>
```

---

## Post-Creation Actions

```xml
<action>Show success message:</action>
<message>
✅ Projekt "{project-name}" erstellt!

Struktur:
- myDex/projects/{project-name}/.dex/ (alle Docs)
- myDex/projects/{project-name}/src/ (leer, für Code)

{count} Dateien migriert nach .dex/briefing/

Nächster Workflow speichert automatisch im Projekt! 🎉

Tipp: Mit "*project switch" kannst du zwischen Projekten wechseln.
</message>
```

---

## Additional Commands

### List Projects
```xml
<command>*projects list</command>
<action>Scan myDex/projects/ for all folders with .dex/</action>
<action>Display numbered list with last activity date</action>
```

### Switch Project
```xml
<command>*project switch</command>
<action>Show list of projects</action>
<ask>Which project? (number or name, or "none" for draft mode)</ask>
<action>Update config.yaml: current_project = {selection}</action>
<confirm>Switched to project: {name}</confirm>
```

### Project Info
```xml
<command>*project info</command>
<action>Show current_project from config</action>
<action>If project set → Read and display .dex/INDEX.md</action>
<action>Count files in each .dex/ subfolder</action>
<output>
Current Project: {name}
Location: myDex/projects/{name}/
Files: {briefing} briefing, {docs} docs, {planning} planning
Last Activity: {date from INDEX.md}
</output>
```

---

## Edge Cases

### No Related Files
```xml
<check if="no groups with 2+ files">
  <action>Silent mode - do nothing</action>
  <note>Don't bother user if only 1 file or unrelated files</note>
</check>
```

### User Already in Project
```xml
<check if="current_project is NOT null">
  <action>Skip detection - user is already working in a project</action>
  <note>Only trigger when in draft mode (current_project = null)</note>
</check>
```

### Multiple Theme Groups
```xml
<check if="multiple groups detected">
  <action>Show list: "Multiple themes detected"</action>
  <list>
    1. Theme "ai-powerpoint" (3 files)
    2. Theme "fitness-app" (2 files)
  </list>
  <ask>Which theme to create project for? (number)</ask>
</check>
```

---

## Privacy & Safety

**NEVER:**
- Auto-create projects without user consent
- Delete files without confirmation
- Modify config without telling user

**ALWAYS:**
- Ask before migrating files
- Confirm before deleting originals
- Show what will happen before doing it
- Allow user to cancel at any step

---

## Integration Points

### Called by dex-master
After workflow completion:
```xml
<step n="11" in="dex-master activation">
  Invoke mydex-project-manager → Check for project creation opportunity
</step>
```

### Invoked manually
Via menu in dex-master:
```xml
<item cmd="*project">Manage Projects (create, switch, info)</item>
```

---

## Future Enhancements (V2)

- Auto-detection without user prompt (yolo mode)
- Archive old outputs automatically
- Project templates (web app, cli tool, etc.)
- Multi-project workspaces
- Project tagging and search

---

**Status:** ✅ Ready for use in V3.1
**Last Updated:** 2025-11-04
**Author:** DexHub Core Team
