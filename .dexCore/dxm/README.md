# DXM - Dex Method Module

The DXM (Dex Method Module) is the core orchestration system for the Dex Method v6a, providing comprehensive software development lifecycle management through specialized agents, workflows, teams, and tasks.

## 📚 Essential Reading

**Before using DXM, you MUST read the [DXM v6 Workflows Guide](./workflows/README.md).** This document explains the revolutionary v6a workflow system and how all components work together.

## Module Structure

### 🤖 `/agents`

Specialized AI agents for different development roles:

- **PM** (Product Manager) - Product planning and requirements
- **Analyst** - Business analysis and research
- **Architect** - Technical architecture and design
- **SM** (Scrum Master) - Sprint and story management
- **DEV** (Developer) - Code implementation
- **SR** (Senior Reviewer) - Code review and quality
- **UX** - User experience design
- And more specialized roles

### 📋 `/workflows`

The heart of DXM - structured workflows for the four development phases:

1. **Analysis Phase** (Optional)
   - `brainstorm-project` - Project ideation
   - `research` - Market/technical research
   - `product-brief` - Product strategy

2. **Planning Phase** (Required)
   - `plan-project` - Scale-adaptive project planning
   - Routes to appropriate documentation based on project complexity

3. **Solutioning Phase** (Level 3-4 projects)
   - `3-solutioning` - Architecture design
   - `tech-spec` - Epic-specific technical specifications

4. **Implementation Phase** (Iterative)
   - `create-story` - Story generation
   - `story-context` - Expertise injection
   - `dev-story` - Implementation
   - `review-story` - Quality validation
   - `correct-course` - Issue resolution
   - `retrospective` - Continuous improvement

### 👥 `/teams`

Pre-configured agent teams for different project types and phases. Teams coordinate multiple agents working together on complex tasks.

### 📝 `/tasks`

Reusable task definitions that agents execute within workflows. These are the atomic units of work that compose into larger workflows.

### 🔧 `/sub-modules`

Extension modules that add specialized capabilities to DXM.

### 🏗️ `/testarch`

Test architecture and quality assurance components.

## Quick Start

```bash
# Run a planning workflow
dex pm plan-project

# Create a new story
dex sm create-story

# Run development workflow
dex dev develop

# Review implementation
dex sr review-story
```

## Key Concepts

### Scale Levels

DXM automatically adapts to project complexity:

- **Level 0**: Single atomic change
- **Level 1**: 1-10 stories, minimal documentation
- **Level 2**: 5-15 stories, focused PRD
- **Level 3**: 12-40 stories, full architecture
- **Level 4**: 40+ stories, enterprise scale

### Just-In-Time Design

Technical specifications are created one epic at a time during implementation, not all upfront, allowing for learning and adaptation.

### Context Injection

Story-specific technical guidance is generated dynamically, providing developers with exactly the expertise needed for each task.

## Integration with Dex Core

DXM integrates seamlessly with the Dex Core framework, leveraging:

- The agent execution engine
- Workflow orchestration
- Task management
- Team coordination

## Related Documentation

- [DXM Workflows Guide](./workflows/README.md) - **Start here!**
- [Agent Documentation](./agents/README.md) - Individual agent capabilities
- [Team Configurations](./teams/README.md) - Pre-built team setups
- [Task Library](./tasks/README.md) - Reusable task components

## Best Practices

1. **Always start with the workflows** - Let workflows guide your process
2. **Respect the scale** - Don't over-document small projects
3. **Embrace iteration** - Use retrospectives to continuously improve
4. **Trust the process** - The v6a methodology has been carefully designed

---

For detailed information about the complete Dex Method v6a workflow system, see the [DXM Workflows README](./workflows/README.md).
