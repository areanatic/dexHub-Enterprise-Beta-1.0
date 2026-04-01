# Development Meta-Layer

**Purpose:** Transparent development tracking for the DexHub project.

---

## What is this?

This directory (`.dexCore/_dev/`) contains the development meta-layer - a transparent system for tracking features, bugs, and documentation related to DexHub's development.

---

## Structure

```
.dexCore/_dev/
├── analysis/          # Meta-Agent analyses (codebase, architecture, tech-debt)
├── dev-mode-conception/ # Dev-Mode design and research
├── docs/              # Development documentation
│   ├── CRITICAL-AGENT-MODE-BOUNDARY-VIOLATION.md  # CRITICAL: Agent execution model issue
│   ├── SILO-ARCHITECTURE.md                       # Output structure documentation
│   ├── OUTPUT-HANDLING-TEMPLATE.md                # Agent template for output handling
│   ├── MYDEX-PROFILE-INTEGRATION-ANALYSIS.md      # Profile integration analysis
│   └── [other docs]
├── planning/          # Planning artifacts (roadmaps, migration matrices)
├── sessions/          # Dev-Mode session documentation
├── todos/             # Task tracking
│   ├── roadmap.md          # Feature roadmap
│   ├── features.md         # Feature status
│   ├── bugs.md             # Bug tracking
│   └── technical-debt.md   # Tech debt catalog
└── README.md          # This file
```

---

## Critical Findings

**AGENT MODE BOUNDARY VIOLATION** - A fundamental architectural issue was discovered regarding agent execution boundaries and system authority. See:
- **docs/CRITICAL-AGENT-MODE-BOUNDARY-VIOLATION.md** - Complete analysis and research roadmap
- **Status:** Requires dedicated research before Enterprise release
- **Impact:** Potentially Enterprise-blocking

---

## For Alpha Testers

This directory is part of DexHub's **transparent development approach**:

- **todos/roadmap.md** - Feature roadmap and release planning
- **todos/features.md** - See what features are shipped, in progress, or planned
- **todos/bugs.md** - Report bugs or see known issues
- **todos/technical-debt.md** - Known tech debt catalog
- **docs/** - Technical documentation and critical findings
- **analysis/** - Meta-Agent analyses of DexHub codebase
- **sessions/** - Development session documentation

---

## Contributing

Want to help improve DexHub?

1. Check **todos/features.md** for planned features
2. Check **todos/bugs.md** for known issues
3. Report new bugs by creating GitHub issues
4. Suggest features via GitHub discussions

---

**DexHub Alpha** - Built transparently, evolved collaboratively.
