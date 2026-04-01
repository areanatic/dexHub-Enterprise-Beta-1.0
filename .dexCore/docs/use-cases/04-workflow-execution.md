# Use Case 04: Workflow Execution

**Scenario**: Run brainstorming, planning, and solutioning workflows

**Duration**: 10-15 minutes

**Prerequisites**:
- DexHub initialized in project (`dex init`)
- Understanding of agent roles

---

## Step-by-Step Instructions

### 1. List Available Workflows

```bash
dex workflow list
```

**Expected Output**:
```
📋 DexHub Alpha v1 - Available Workflows

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📦 CORE WORKFLOWS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  🔄 orchestration
     Workflow coordination and management

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔍 ANALYSIS PHASE (8 workflows)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  💭 brainstorming
     Ideation and creative thinking session

  🔬 research
     Comprehensive research and analysis

  📄 product-brief
     Product brief creation

  🎮 game-brief
     Game brief creation

  📊 market-analysis
     Market and competitive analysis

  👥 user-research
     User research and persona development

  💡 innovation-session
     Innovation and strategy workshop

  🎯 problem-definition
     Problem space exploration

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 PLANNING PHASE (7 workflows)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  📝 prd
     Product Requirements Document

  📐 tech-spec
     Technical Specification

  🎲 gdd
     Game Design Document

  🎨 ux-spec
     UX Specification

  📖 narrative-design
     Narrative and storytelling design

  🧪 test-strategy
     Test strategy and planning

  🏗️ architecture-review
     Architecture review and validation

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎯 SOLUTIONING PHASE (5 workflows)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  🏛️ solution-architecture
     Solution architecture design

  🔧 technical-specification
     Detailed technical specs

  📚 tech-stack
     Technology stack selection

  🔄 refactoring-plan
     Refactoring strategy

  🚀 mvp-planning
     MVP scope and planning

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚙️ IMPLEMENTATION PHASE (10 workflows)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  📋 story-creation
     User story creation

  📝 story-context
     Story context and details

  💻 dev-story
     Development story breakdown

  👁️ review-story
     Code review story

  🔍 retrospective
     Sprint retrospective

  🎯 correct-course
     Course correction planning

  📦 release-planning
     Release planning and management

  🐛 bug-triage
     Bug triage and prioritization

  🔧 technical-debt
     Technical debt management

  📊 metrics-review
     Metrics and KPI review

Total: 30+ workflows across 5 phases
```

### 2. Run Brainstorming Workflow

```bash
dex workflow brainstorming
```

**Expected Output**:
```
💭 Running Workflow: brainstorming

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 WORKFLOW OVERVIEW
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Workflow: Brainstorming Session
Phase: Analysis
Primary Agent: brainstorming-coach
Supporting Agents: innovation-strategist, creative-problem-solver

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎯 OBJECTIVE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Facilitate creative ideation session to generate innovative solutions
for a given problem or opportunity.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📝 INSTRUCTIONS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

STEP 1: Define Problem Space
────────────────────────────
- Clearly articulate the challenge or opportunity
- Identify stakeholders and their needs
- Define success criteria

STEP 2: Divergent Thinking
────────────────────────────
- Generate as many ideas as possible (quantity over quality)
- Encourage wild and unconventional ideas
- Build on others' ideas
- No critidism or evaluation at this stage

STEP 3: Idea Clustering
────────────────────────────
- Group similar ideas into themes
- Identify patterns and connections
- Label clusters with descriptive names

STEP 4: Convergent Thinking
────────────────────────────
- Evaluate ideas against success criteria
- Prioritize based on impact and feasibility
- Select top 3-5 ideas for further exploration

STEP 5: Concept Development
────────────────────────────
- Develop selected ideas into concrete concepts
- Create rough prototypes or sketches
- Identify next steps for each concept

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🛠️ TOOLS & TECHNIQUES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

- Mind mapping
- SCAMPER technique
- Six Thinking Hats
- Reverse brainstorming
- Analogical thinking

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 DELIVERABLES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Problem definition document
2. List of generated ideas (50-100+)
3. Idea clusters and themes
4. Top 3-5 prioritized concepts
5. Next steps and action items

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⏱️ ESTIMATED DURATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

45-90 minutes

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔗 NEXT WORKFLOWS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

After brainstorming, consider:
  → research (Validate ideas with research)
  → product-brief (Document product vision)
  → prd (Create detailed requirements)

✅ Workflow loaded successfully!

💡 Tip: Run 'dex agent brainstorming-coach' to learn more about the primary agent.
```

### 3. Run Planning Workflow

```bash
dex workflow prd
```

**Expected**: Complete PRD workflow instructions with:
- Agent roles (analyst, architect, pm, po)
- Step-by-step PRD creation process
- Templates and deliverables
- Estimated duration (2-4 hours)

### 4. Run Solutioning Workflow

```bash
dex workflow solution-architecture
```

**Expected**: Architecture design workflow with:
- Agent roles (architect, developer, tea)
- Architecture patterns and dedisions
- Diagrams and documentation
- Technical specifications

### 5. Explore Workflow Phases

```bash
# Analysis phase workflows
dex workflow research
dex workflow market-analysis

# Planning phase workflows
dex workflow tech-spec
dex workflow ux-spec

# Implementation phase workflows
dex workflow story-creation
dex workflow dev-story
```

---

## Workflow Lifecycle Example

### Complete Product Development Flow

```bash
# Phase 1: Analysis
dex workflow brainstorming
dex workflow research
dex workflow product-brief

# Phase 2: Planning
dex workflow prd
dex workflow tech-spec
dex workflow ux-spec

# Phase 3: Solutioning
dex workflow solution-architecture
dex workflow tech-stack
dex workflow mvp-planning

# Phase 4: Implementation
dex workflow story-creation
dex workflow dev-story
dex workflow review-story

# Phase 5: Retrospective
dex workflow retrospective
dex workflow metrics-review
```

---

## Success Criteria

- [ ] Listed all 30+ available workflows
- [ ] Successfully ran brainstorming workflow
- [ ] Understood workflow phases (Analysis → Planning → Solutioning → Implementation)
- [ ] Identified which workflows are relevant for your project
- [ ] Noted agent relationships within workflows

---

## Workflow Deep Dive: Brainstorming

### When to Use
- Starting new product/feature
- Solving complex problems
- Innovation workshops
- Strategic planning sessions

### Key Participants
- **Primary**: brainstorming-coach (facilitates session)
- **Supporting**: innovation-strategist (strategic direction)
- **Supporting**: creative-problem-solver (alternative approaches)

### Expected Outputs
1. Problem definition (clear, condise)
2. 50-100+ raw ideas
3. 5-10 idea clusters/themes
4. Top 3-5 prioritized concepts
5. Action plan for next steps

### Tips for Success
- Set time limits for each phase
- Encourage quantity over quality initially
- No idea critidism during divergent phase
- Use visual aids (whiteboards, sticky notes)
- Include diverse perspectives

---

## Troubleshooting

### Workflow not found

**Solution**: Check exact workflow name
```bash
dex workflow list
# Use exact name from list
dex workflow brainstorming
```

### Workflow loads but shows "Not implemented"

**Expected**: This is MVP prototype - AI integration coming in next phase
**Current**: Workflows show instructions and templates for manual execution

### "No agents found for workflow"

**Solution**: Ensure DexHub initialized
```bash
dex status
dex agent list
```

---

## Workflow Customization

### Create Custom Workflow (Future Feature)

```bash
# Using dex-builder agent
dex agent dex-builder

# Follow prompts to create custom workflow
# - Define phases
# - Assign agents
# - Set deliverables
# - Configure automation
```

---

## Best Practices

### 1. Sequential Execution
- Complete analysis before planning
- Finish planning before solutioning
- Validate each phase outputs

### 2. Iterative Refinement
- Revisit workflows as needed
- Update deliverables based on new information
- Don't treat workflows as one-time tasks

### 3. Team Collaboration
- Share workflow outputs with team
- Assign agent roles to team members
- Use workflows as meeting agendas

### 4. Documentation
- Save workflow outputs in `.dex/knowledgeHub/`
- Version control important documents
- Reference previous workflows in new ones

---

## Next Steps

After running workflows:

1. ✅ **Document Results**: Save outputs to Knowledge Hub
2. ✅ **Execute Deliverables**: Implement workflow recommendations
3. ✅ **Iterate**: Return to workflows as project evolves

---

## Related Documentation

- [Workflow Architecture](../architecture/workflow-architecture.md)
- [Agent-Workflow Integration](../workflows/agent-integration.md)
- [Custom Workflow Creation](../workflows/custom-workflows.md)
