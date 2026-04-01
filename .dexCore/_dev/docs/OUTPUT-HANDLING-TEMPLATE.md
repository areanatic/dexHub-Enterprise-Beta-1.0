# Output Handling Template for DXM Agents

This template should be added to all DXM agents in the `<activation>` section, right after `<rules>` and before `</activation>`.

## Template XML

```xml
  <output_handling>
    <context_awareness>
      <principle>This agent is context-aware and respects the current project state</principle>
      <modes>
        <mode name="draft">When current_project = null → Outputs saved to myDex/drafts/ with smart filenames</mode>
        <mode name="project">When current_project = "name" → Outputs saved to myDex/projects/{name}/.dex/{dexhub-aligned-path}/</mode>
      </modes>
    </context_awareness>

    <dxm_aligned_structure>
      <note>All outputs follow DexHub 4-Phase methodology structure</note>
      <structure>
        .dex/
        ├── 1-analysis/       (brainstorm, research, product-brief)
        ├── 2-planning/       (prd, gdd)
        ├── 3-solutioning/    (architecture, tech-spec)
        ├── 4-implementation/ (stories, sprints)
        ├── sessions/
        ├── decisions/
        ├── config/
        └── agent-state/
      </structure>
      <example>Workflow "1-analysis/brainstorm" → myDex/projects/my-app/.dex/1-analysis/brainstorm/brainstorm-ai-tool-20251105-1430.md</example>
    </dxm_aligned_structure>

    <workflow_integration>
      <note>workflow.xml handles ALL output routing automatically - agent does NOT need to determine paths</note>
      <substep ref="1b.5">Smart filename generation: {category}-{theme}-{YYYYMMDD}-{HHMM}.md</substep>
      <substep ref="1b.6">DXM-Aligned routing: Parses workflow path and maps to .dex/ structure</substep>
    </workflow_integration>

    <agent_responsibility>
      <do>
        - Execute workflows via workflow.xml (which handles routing)
        - Respect {output_folder} variable from config (DO NOT hardcode paths)
        - Use config-provided variables ({user_name}, {project_name}, {output_folder})
        - Trust DXM-Aligned routing logic in workflow.xml
      </do>
      <dont>
        - DO NOT manually determine output paths
        - DO NOT bypass workflow.xml routing logic
        - DO NOT hardcode myDex/drafts/ or project paths
        - DO NOT assume old folder structure (briefing/, docs/, planning/)
      </dont>
    </agent_responsibility>

    <post_workflow_trigger>
      <note>After workflow completion, mydex-project-manager automatically checks for project creation opportunity</note>
      <threshold>2+ related files in outputs/ → User prompted to create project</threshold>
      <benefit>Prevents output clutter, encourages project organization</benefit>
    </post_workflow_trigger>
  </output_handling>
```

## Placement

Insert this block in the `<activation>` section, right after `</rules>` and before `</activation>`:

```xml
<activation>
  <!-- ... existing steps ... -->

  <rules>
    <!-- ... existing rules ... -->
  </rules>

  <!-- INSERT OUTPUT_HANDLING HERE -->
  <output_handling>
    <!-- template content -->
  </output_handling>

</activation>
```

## Affected Agents

1. analyst.md
2. architect.md
3. dev.md
4. pm.md
5. sm.md
6. po.md
7. tea.md
8. ux-expert.md
9. game-designer.md
10. game-architect.md
11. game-dev.md

---

**Created:** 2025-11-05
**Part of:** DexHub V3.1 Smart Output Routing Feature (Phase 2)
