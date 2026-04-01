# Use Case 03: Agent Discovery

**Scenario**: Explore and understand all available AI agents in DexHub

**Duration**: 5-10 minutes

**Prerequisites**:
- DexHub installed globally
- Basic understanding of AI agents concept

---

## Step-by-Step Instructions

### 1. List All Available Agents

```bash
dex agent list
```

**Expected Output**:
```
🤖 DexHub Alpha v1 - Available Agents

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📦 CORE MODULE (1 agent)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  🎯 dex-master
     Core orchestration and workflow management

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔧 DXM MODULE - Dex Methodology (11 agents)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  📊 analyst
     Requirements analysis and research

  🏗️ architect
     Solution architecture and technical design

  💻 developer
     Implementation and coding

  📋 pm (Project Manager)
     Project planning and coordination

  🏃 sm (Scrum Master)
     Agile ceremonies and team facilitation

  🎯 po (Product Owner)
     Product vision and backlog management

  🎨 ux-expert
     User experience and interface design

  🧪 tea (Test Engineering Architect)
     Test strategy and quality assurance

  🎮 game-designer
     Game mechanics and systems design

  🕹️ game-developer
     Game implementation and programming

  🏛️ game-architect
     Game architecture and technical foundation

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🛠️ DXB MODULE - Dex Builder (1 agent)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  🔨 dex-builder
     Create custom agents and workflows

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
💡 DIS MODULE - Dex Intelligence Suite (5 agents)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  🚀 innovation-strategist
     Innovation planning and strategic thinking

  💭 brainstorming-coach
     Ideation and creative thinking facilitation

  🎯 design-thinking-coach
     Design thinking process guidance

  📖 storyteller
     Narrative design and content creation

  🧩 creative-problem-solver
     Creative problem-solving techniques

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Total: 18 agents across 4 modules
```

### 2. View Specific Agent Details

```bash
dex agent analyst
```

**Expected Output**:
```
🤖 Agent: analyst

Module: DXM (Dex Methodology)
Version: 0.1.0-alpha

Description:
Requirements analysis and research specialist. Helps with:
- User story analysis
- Requirements gathering
- Research and documentation
- Stakeholder interviews
- Data analysis

Capabilities:
  ✅ Requirement elicitation
  ✅ User research
  ✅ Competitive analysis
  ✅ Documentation
  ✅ Stakeholder management

Related Workflows:
  - brainstorming
  - research
  - product-brief
  - market-analysis
  - user-research

Example Usage:
  "Help me analyze user requirements for a mobile app"
  "Research competitors in the e-commerce space"
  "Create user personas based on interview data"
```

### 3. Explore Different Agent Modules

#### DXM Module (Software Development)

```bash
dex agent architect
dex agent developer
dex agent pm
```

**Focus**: Traditional software development lifecycle

#### DXB Module (Meta-Development)

```bash
dex agent dex-builder
```

**Focus**: Creating custom agents and workflows

#### DIS Module (Creative Intelligence)

```bash
dex agent brainstorming-coach
dex agent innovation-strategist
dex agent storyteller
```

**Focus**: Creative thinking and innovation

### 4. Compare Similar Agents

```bash
# Compare project management roles
dex agent pm
dex agent sm
dex agent po
```

**Key Differences**:
- **PM**: Overall project coordination, timelines, resources
- **SM**: Agile ceremonies, team dynamics, process improvement
- **PO**: Product vision, backlog prioritization, stakeholder value

---

## Agent Categories

### 1. Core Orchestration
- **dex-master**: Central coordination agent

### 2. Software Development (DXM)
- **Analyst**: Requirements & research
- **Architect**: Solution design
- **Developer**: Implementation
- **TEA**: Test strategy

### 3. Project Management (DXM)
- **PM**: Project coordination
- **SM**: Agile facilitation
- **PO**: Product ownership

### 4. Specialized Roles (DXM)
- **UX Expert**: User experience
- **Game Designer**: Game mechanics
- **Game Developer**: Game implementation
- **Game Architect**: Game architecture

### 5. Meta-Development (DXB)
- **Dex Builder**: Custom agent creation

### 6. Creative Intelligence (DIS)
- **Innovation Strategist**: Strategic innovation
- **Brainstorming Coach**: Ideation facilitation
- **Design Thinking Coach**: Design process guidance
- **Storyteller**: Narrative design
- **Creative Problem Solver**: Creative solutions

---

## Success Criteria

- [ ] Successfully listed all 18+ agents
- [ ] Viewed details for at least 3 different agents
- [ ] Understood the difference between modules (DXM, DXB, DIS)
- [ ] Identified which agents are relevant for your use case
- [ ] Noted related workflows for each agent

---

## Agent Selection Guide

### Use Case: Building New Web Application

**Recommended Agents**:
1. **analyst** - Gather requirements
2. **architect** - Design solution
3. **ux-expert** - Design user interface
4. **developer** - Implement features
5. **tea** - Plan testing strategy

### Use Case: Game Development

**Recommended Agents**:
1. **game-designer** - Design mechanics
2. **game-architect** - Technical foundation
3. **storyteller** - Narrative design
4. **game-developer** - Implementation
5. **tea** - Quality assurance

### Use Case: Innovation Workshop

**Recommended Agents**:
1. **brainstorming-coach** - Facilitate ideation
2. **design-thinking-coach** - Guide design process
3. **innovation-strategist** - Strategic planning
4. **creative-problem-solver** - Solution generation

### Use Case: Create Custom Agent

**Recommended Agent**:
1. **dex-builder** - Build custom agents/workflows

---

## Troubleshooting

### No agents showing up

**Solution**: Verify DexHub installation
```bash
dex --version
dex status
```

### Agent details not displaying

**Solution**: Check if agent name is correct
```bash
# List all agents first
dex agent list

# Use exact name from list
dex agent analyst
```

### "Module not found" error

**Solution**: Reinstall DexHub
```bash
npm install -g dexhub-alpha-v1
```

---

## Agent Interaction Patterns

### Pattern 1: Sequential Workflow
```
analyst → architect → developer → tea
(Requirements → Design → Implementation → Testing)
```

### Pattern 2: Parallel Collaboration
```
        ux-expert
       /          \
architect -------- developer
       \          /
         tea
(Design and development in parallel with UX and testing oversight)
```

### Pattern 3: Iterative Refinement
```
brainstorming-coach → analyst → architect
         ↑                               ↓
         └───────────────────────────────┘
(Ideation → Analysis → Design → Back to ideation)
```

---

## Next Steps

After exploring agents:

1. ✅ **Run Workflows**: Try workflows associated with agents ([Use Case 04](04-workflow-execution.md))
2. ✅ **Create Custom Agent**: Use dex-builder to create specialized agents
3. ✅ **Build Agent Chain**: Combine multiple agents for complex tasks

---

## Related Documentation

- [Agent Architecture](../architecture/agent-architecture.md)
- [Module Overview](../architecture/modules-overview.md)
- [Workflow Integration](../workflows/integration-guide.md)
