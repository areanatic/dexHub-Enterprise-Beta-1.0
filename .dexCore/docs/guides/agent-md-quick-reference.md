# agent.md Quick Reference Guide

## TL;DR - What You Need to Know

### 1. The File
- **Name:** `agent.md` (industry standard from GitHub Copilot)
- **Location:** Root of repository (+ subfolders for mono-repos)
- **Format:** Free-text Markdown (NOT YAML/JSON)
- **Purpose:** Tell AI how to work with your code

### 2. Core Principle
> "Otherwise you will get average. And I don't want average." - Tomas Kubica, Microsoft

**Quality of instructions = Quality of AI output**

### 3. Three-Level System
1. **Personal** - Your global preferences
2. **Organizational** - Company-wide standards
3. **Repository (agent.md)** - ⭐ Most important, team-shared

---

## What Goes in agent.md?

### Must-Have Sections

```markdown
## Coding Philosophy
- Abstraction preferences
- When to split files
- Composition vs inheritance

## Documentation Standards
- Docstring requirements
- When to use inline comments
- What NOT to comment

## Technology Stack
- Language + version
- Frameworks
- Package manager
- Type system preferences

## Naming Conventions
- snake_case, PascalCase, etc.
- File naming
- Variable naming

## Project Structure
- Where code lives
- Common directories
- File organization
```

### Should-Have Sections

```markdown
## Testing Standards
- Coverage expectations
- Naming patterns
- When to mock

## Security Guidelines
- Secret management
- Input validation
- Common vulnerabilities

## Common Patterns
- Error handling approach
- Database queries
- API responses

## Common Files Explained
- What pyproject.toml is for
- What .env.example is for
- Migration directories
```

---

## Key Rules

### ✅ DO

1. **Use natural language** - "Start simple and readable" not `{"style": "simple"}`
2. **Give examples** - Show, don't just tell
3. **Explain WHY** - Context helps AI make dedisions
4. **Be specific** - "Use snake_case" not "be consistent"
5. **Use code blocks** - Demonstrate patterns directly
6. **Keep it focused** - Each section has clear purpose

### ❌ DON'T

1. **Don't use rigid schemas** - Free text > structured data
2. **Don't be vague** - "Write good code" tells AI nothing
3. **Don't conflict yourself** - Check for contradictions
4. **Don't exceed context limits** - Huge files get compressed (quality loss)
5. **Don't comment the obvious** - AI knows what a for loop is
6. **Don't forget subfolders** - Mono-repos need subfolder agent.md files

---

## Hierarchical Structure (Mono-repos)

```
my-monorepo/
├── agent.md                 # General project rules
├── backend/
│   ├── agent.md            # Backend-specific overrides
│   └── src/
├── frontend/
│   ├── agent.md            # Frontend-specific overrides
│   └── src/
└── ml/
    ├── agent.md            # ML-specific overrides
    └── notebooks/
```

**Inheritance:** Subfolder agent.md inherits from root + adds specifics

---

## Context Window Management

### The Problem
- AI has limited "memory" (context window)
- ~100K-200K tokens depending on model
- If exceeded → compression → **quality loss**

### Solutions
1. **Don't dump huge files** - Reference selectively with @file
2. **Structure matters** - Many small files > one giant file
3. **Use LMCXT files** - Context metadata helps AI prioritize
4. **Watch token usage** - Some tools show this

**Critical Quote:**
> "If the window is reaching its limits, it will compress it, and by compression we mean that it will ask LLM to summarize it, so you are losing quality in that context."

---

## Copilot Spaces (Multi-Repo Knowledge)

### What It Is
- Knowledge graph across multiple repositories
- No IDE needed (web, mobile accessible)
- Perfect for architecture discussions

### When to Use
- Microservices architecture (repo per service)
- Shared integration patterns
- Coding standards across projects
- Architecture dedision records (ADRs)

### Structure Example
```
Space: "MyCompany Engineering"
├── integration-patterns-repo
│   └── rest-api.md, grpc.md, kafka.md
├── coding-standards-repo
│   └── python.md, typescript.md, go.md
└── architecture-dedisions-repo
    └── adr/*.md
```

---

## Slash Commands (Prompt Macros)

### What They Are
Predefined prompts that juniors can use easily

### Location
```
.github/copilot/prompts/
├── update-docs.md
├── generate-tests.md
├── refactor-module.md
└── security-scan.md
```

### Usage
Developer types: `/update-docs`
AI executes pre-written, tested prompt

### Why Use Them
- Consistency across team
- Junior developer enablement
- Senior knowledge capture
- Time saver for common tasks

---

## File Formats for AI

### Best → Worst

1. **Markdown** ⭐ - Natural language, code blocks, readable
2. **Text files** - Simple, works well
3. **Code** - Depends on language (Python > minified JS)
4. **YAML/JSON** - Okay for data, not for instructions
5. **Binary** ❌ - PDFs, Visio, etc. (AI can't read easily)

**Key Quote:**
> "Text-based formats... not Visio or those kind of binary format... text-based format, it is working incredibly."

---

## MCP - Model Context Protocol (Tools)

### What It Is
Standardized way for AI to call external systems

### Examples
- **Kubernetes:** Query pods, deployments
- **Databases:** Run SQL queries
- **GitHub:** Check issues, PRs
- **Custom:** Anything you build

### Limit
~128 tools max

### Why It Matters
AI can DO things, not just suggest code:
- Check if deployment succeeded
- Query database state
- Verify API health
- Generate random strings (AI is bad at randomness!)

---

## Modes of Operation

### Agent Mode (Recommended)
- AI makes changes, iterates, fixes mistakes
- You supervise and guide
- Like pair programming

### Ask Mode
- AI answers but doesn't modify
- Good for brainstorming
- Safe exploration

### Custom Modes
- Define your own (e.g., "Teacher Mode")
- Specific instructions for specific tasks

---

## Models

### Free (Unlimited)
- GPT-4o
- Claude 3.5 Sonnet
- o1-mini
- o1-preview

### Premium
- Advanced models
- Counted against quota

**Tip:** Start with free, upgrade if needed

---

## IDE vs Cloud Agents

### IDE-Based (VS Code, JetBrains)
- Watch agent work in real-time
- Interactive
- Open source (can see prompts!)
- Good for learning

### Cloud-Based
- Agent works autonomously
- Creates PR when done
- No IDE needed
- Good for larger tasks

**GitHub supports both!**

---

## Productivity Impact

### Senior Developers
> "I'm able to do four or five out of 10 ideas instead of one because I can spend much less time developing that idea."

**Translation:** Do more, not just faster

### Junior Developers
> "For junior developers, this is absolutely a key. It's really educational... This teacher is very patient and can explain whatever five times in a row."

**Translation:** Always-available mentor

---

## Common Mistakes

### 1. "I'll just tell AI what to do each time"
**Problem:** Inconsistent results, wasted time
**Solution:** Document once in agent.md, consistent forever

### 2. "More detail = better"
**Problem:** Exceeds context window, gets compressed
**Solution:** Be condise, structure well, use examples

### 3. "YAML is more structured"
**Problem:** AI prefers natural language
**Solution:** Use markdown with free-text explanations

### 4. "I can fix conflicting instructions"
**Problem:** AI gets confused, unpredictable results
**Solution:** Review agent.md for contradictions regularly

### 5. "agent.md is just for code style"
**Problem:** Missing huge value
**Solution:** Include architecture, patterns, philosophy, project context

---

## Starting Template (Minimal)

```markdown
# [Project Name]

## What This Project Does
[2-3 sentence description]

## Coding Philosophy
- Start simple
- Avoid premature abstraction
- Readable > clever

## Documentation
- Docstrings for all public functions
- Comments only for WHY, not WHAT
- Explain workarounds (link to issue)

## Tech Stack
- Language: [e.g., Python 3.11]
- Framework: [e.g., FastAPI]
- Package Manager: [e.g., UV]

## Naming
- Functions/vars: snake_case
- Classes: PascalCase
- Constants: SCREAMING_SNAKE_CASE

## Testing
- Minimum 80% coverage
- Name tests: test_[function]_[scenario]_[expected]
- Mock external dependencies

## Common Patterns

### Error Handling
[Show example code]

### API Responses
[Show example structure]

## Questions?
[Link to team chat/docs]
```

**Time to create:** 15-20 minutes
**Value:** Immediate, compounding

---

## Advanced: agent.md + .dex/

### The Vision
```
project/
├── agent.md                    # GitHub Copilot standard
├── .dex/
│   ├── context.md             # Additional context
│   ├── architecture.md        # System design
│   └── tools/                 # MCP tools
└── src/
```

### Integration
- agent.md = primary instructions
- .dex/ = enhanced metadata, tools, automation
- Together = powerful meta-layer

---

## Resources

### Official
- GitHub Copilot Docs
- MCP Protocol Specification
- VS Code Copilot Extension

### Community
- GitHub Universe (annual conference)
- Microsoft Ignite (November)
- Copilot GitHub Discussions

---

## Final Wisdom

> "The developer job is not really about coding. Most research states that the developer codes like 30% or less of its time."

**Implication:** AI helping with code is just the start. The real value is AI helping with:
- Planning
- Architecture
- Testing
- Deployment
- Operations
- Knowledge transfer

**agent.md is your team's knowledge, codified.**

Make it excellent.

---

**Questions to Ask Yourself:**

1. If a new developer joined tomorrow, would agent.md get them up to speed?
2. If AI read my agent.md, would it understand our philosophy?
3. Have I documented WHY we make dedisions, not just WHAT they are?
4. Are there patterns we repeat that should be in agent.md?
5. Would my team's seniors approve AI code following this agent.md?

**If "no" to any → improve your agent.md**

---

*Quick Reference Guide - GitHub Copilot Training Analysis*
*Last Updated: 2025-10-24*
