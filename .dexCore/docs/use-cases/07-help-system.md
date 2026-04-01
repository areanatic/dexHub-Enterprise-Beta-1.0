# Use Case 07: Help & Documentation System

**Scenario**: Access built-in help and guidance for DexHub commands

**Duration**: 5 minutes

**Prerequisites**:
- DexHub installed globally

---

## Step-by-Step Instructions

### 1. Main Help Command

```bash
dex --help
```

**Expected Output**:
```
Usage: dex [options] [command]

DexHub Alpha v1 - AI-Powered Development Platform

Options:
  -V, --version              output the version number
  -h, --help                 display help for command

Commands:
  init                       Initialize DexHub in current project
  agent [options] [name]     List or view AI agents
  workflow [options] [name]  Run a workflow or list workflows
  config [options]           Show or update configuration
  status                     Check DexHub installation health
  help [command]             display help for command
```

### 2. Command-Specific Help

```bash
# Agent command help
dex agent --help
```

**Expected Output**:
```
Usage: dex agent [options] [name]

List or view AI agents

Arguments:
  name                Agent name (optional)

Options:
  -l, --list         List all available agents
  -m, --module <name> Filter by module (core, dxm, dxb, dis)
  -h, --help         display help for command

Examples:
  dex agent --list
  dex agent analyst
  dex agent --module dxm
```

```bash
# Workflow command help
dex workflow --help
```

**Expected Output**:
```
Usage: dex workflow [options] [name]

Run a workflow or list workflows

Arguments:
  name                 Workflow name (optional)

Options:
  -l, --list          List all available workflows
  -p, --phase <phase> Filter by phase (analysis, plan, solutioning, implementation)
  -h, --help          display help for command

Examples:
  dex workflow --list
  dex workflow brainstorming
  dex workflow --phase analysis
```

```bash
# Config command help
dex config --help
```

**Expected Output**:
```
Usage: dex config [options]

Show or update configuration

Options:
  -s, --show                Show current configuration
  --set <key> <value>       Set configuration value
  -h, --help                display help for command

Examples:
  dex config --show
  dex config --set project.name "My Project"
```

### 3. Get Help for Specific Command

```bash
dex help init
```

**Expected Output**:
```
Usage: dex init [options]

Initialize DexHub in current project

Creates .dex/ folder structure with:
  - dexMaster/ (core orchestration agent)
  - agents/ (linked to DexHub agents)
  - workflows/ (linked to DexHub workflows)
  - knowledgeHub/ (project knowledge storage)
  - config.yaml (project configuration)

Options:
  -h, --help  display help for command
```

---

## Help System Features

### 1. Global Options

Available for all commands:

| Option | Short | Description |
|--------|-------|-------------|
| `--help` | `-h` | Show command help |
| `--version` | `-V` | Show DexHub version |

### 2. Command Categories

#### Initialization
- `dex init` - Initialize DexHub in project

#### Discovery
- `dex agent` - Explore AI agents
- `dex workflow` - Explore workflows

#### Execution
- `dex workflow <name>` - Run workflow

#### Management
- `dex config` - Manage configuration
- `dex status` - Check health

#### Help
- `dex --help` - Main help
- `dex <command> --help` - Command help
- `dex help <command>` - Detailed help

---

## Success Criteria

- [ ] `dex --help` shows main help menu
- [ ] All command helps accessible
- [ ] Examples are clear and actionable
- [ ] Help text matches actual functionality

---

## Help System Examples

### Example 1: Learning About Agents

```bash
# 1. See how to use agent command
dex agent --help

# 2. List all agents
dex agent --list

# 3. View specific agent
dex agent analyst

# 4. Filter by module
dex agent --module dis
```

### Example 2: Understanding Workflows

```bash
# 1. See workflow command options
dex workflow --help

# 2. List all workflows
dex workflow --list

# 3. Filter by phase
dex workflow --phase analysis

# 4. Run specific workflow
dex workflow brainstorming
```

### Example 3: Configuration Help

```bash
# 1. Learn about config command
dex config --help

# 2. View current config
dex config --show

# 3. Update config (future feature)
dex config --set project.name "New Name"
```

---

## Documentation Hierarchy

```
1. Command Line Help (--help)
   ├── Quick reference
   ├── Options and flags
   └── Usage examples

2. Use Case Documentation (this file)
   ├── Step-by-step tutorials
   ├── Best practices
   └── Troubleshooting

3. Architecture Documentation
   ├── Design dedisions
   ├── Technical details
   └── System architecture

4. API Documentation
   ├── Programmatic usage
   ├── Integration guides
   └── Developer reference
```

---

## Troubleshooting

### Help not showing

**Solution**: Verify installation
```bash
dex --version
which dex
```

### Outdated help text

**Solution**: Reinstall DexHub
```bash
npm install -g dexhub-alpha-v1@latest
```

### Missing command in help

**Solution**: Check if using correct version
```bash
dex --version
# Should be 0.1.0-alpha or higher
```

---

## Quick Reference Card

### Essential Commands

```bash
# Getting Started
dex init                    # Initialize DexHub
dex status                  # Check health
dex --help                  # Show help

# Discovery
dex agent --list            # List agents
dex workflow --list         # List workflows

# Execution
dex agent <name>            # View agent details
dex workflow <name>         # Run workflow

# Configuration
dex config --show           # Show config
```

### Common Patterns

```bash
# Fresh project setup
dex init && dex status

# Explore available resources
dex agent --list && dex workflow --list

# Run analysis workflow
dex workflow brainstorming

# Check everything is working
dex status
```

---

## Built-in Documentation

### Where to Find Help

1. **Command Line**:
   ```bash
   dex --help
   dex <command> --help
   ```

2. **Local Files** (after `npm install -g`):
   ```bash
   # Find installation directory
   npm list -g dexhub-alpha-v1

   # View README
   cat $(npm root -g)/dexhub-alpha-v1/README.md
   ```

3. **Online Resources**:
   - GitHub: https://github.com/areanatic/dexhub-alpha-v1
   - Documentation: https://github.com/areanatic/dexhub-alpha-v1/tree/main/docs
   - Issues: https://github.com/areanatic/dexhub-alpha-v1/issues

---

## Help Best Practices

### 1. Always Start with Help

Before using unfamiliar command:
```bash
dex <command> --help
```

### 2. Check Examples

Every help text includes examples - use them as templates

### 3. Combine Help with Status

```bash
dex --help && dex status
```

### 4. Keep Help Output

Save help output for offline reference:
```bash
dex --help > dexhub-help.txt
dex agent --help >> dexhub-help.txt
dex workflow --help >> dexhub-help.txt
```

---

## Interactive Help (Future Feature)

Future versions may include:

- Interactive tutorials
- Context-sensitive help
- Auto-completion in terminal
- In-workflow guidance
- Video tutorials

---

## Next Steps

After exploring help system:

1. ✅ **Practice Commands**: Try examples from help text
2. ✅ **Read Use Cases**: Complete all 7 use case tutorials
3. ✅ **Explore Docs**: Read architecture and API documentation

---

## Related Documentation

- [CLI Reference](../cli-reference.md)
- [FAQ](../faq.md)
- [Troubleshooting Guide](../troubleshooting.md)
- [Getting Started Guide](01-fresh-start.md)
