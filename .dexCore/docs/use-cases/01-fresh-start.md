# Use Case 01: Fresh Start

**Scenario**: Initialize DexHub in a brand new project from scratch

**Duration**: 2-3 minutes

**Prerequisites**:
- DexHub Alpha v1 installed globally (`npm install -g dexhub-alpha-v1`)
- Empty directory or new project folder

---

## Step-by-Step Instructions

### 1. Create New Project Directory

```bash
mkdir my-new-project
cd my-new-project
```

**Expected**: Empty directory created

### 2. Initialize DexHub

```bash
dex init
```

**Expected Output**:
```
🚀 DexHub Alpha v1 - Initialization

✅ Created .dex/ folder
✅ Created dexMaster/ (core orchestration agent)
✅ Created agents/ directory
✅ Created workflows/ directory
✅ Created knowledgeHub/ directory
✅ Created config.yaml

🎉 DexHub initialized successfully!

📝 Configuration:
   Project: my-new-project
   Version: 0.1.0-alpha
   Features: DexMaster, KnowledgeHub, Workflows

💡 Next steps:
   - Run 'dex agent list' to see available agents
   - Run 'dex workflow list' to see available workflows
   - Run 'dex status' to verify installation
```

### 3. Verify Installation

```bash
dex status
```

**Expected Output**:
```
🔍 DexHub Status Check

✅ .dex/ folder: Found
✅ DexMaster Agent: Found
✅ Config file: Found
✅ Agents directory: Found
✅ Workflows directory: Found
✅ Knowledge Hub: Found

✅ DexHub is healthy!

📊 Available Resources:
   - 20 agents
   - 22+ workflows
```

### 4. Explore Directory Structure

```bash
tree .dex/
```

**Expected Structure**:
```
.dex/
├── config.yaml
├── dexMaster/
│   └── (orchestration agent files)
├── agents/
│   └── (linked to repository agents)
├── workflows/
│   └── (linked to repository workflows)
└── knowledgeHub/
    └── (project-specific knowledge)
```

### 5. View Configuration

```bash
dex config show
```

**Expected Output**:
```
📋 DexHub Configuration

Project: my-new-project
Version: 0.1.0-alpha
Initialized: 2025-10-27T...

Features:
  ✅ DexMaster
  ✅ KnowledgeHub
  ✅ Workflows
```

---

## Success Criteria

- [ ] `.dex/` folder created in project root
- [ ] All subdirectories present (dexMaster/, agents/, workflows/, knowledgeHub/)
- [ ] `config.yaml` contains correct project name
- [ ] `dex status` shows all green checkmarks
- [ ] No errors during initialization

---

## Troubleshooting

### Error: "dex: command not found"

**Solution**: Install DexHub globally
```bash
npm install -g dexhub-alpha-v1
```

### Error: ".dex folder already exists"

**Solution**: Remove existing .dex folder or use different directory
```bash
rm -rf .dex
dex init
```

### Warning: "Git repository not found"

**Info**: This is normal - DexHub works with or without Git
**Optional**: Initialize git if needed
```bash
git init
```

---

## Next Steps

After successful initialization:

1. ✅ **Explore Agents**: Run `dex agent list` ([See Use Case 03](03-agent-discovery.md))
2. ✅ **Run Workflow**: Try `dex workflow brainstorming` ([See Use Case 04](04-workflow-execution.md))
3. ✅ **Customize Config**: Modify `.dex/config.yaml` ([See Use Case 05](05-config-management.md))

---

## Related Documentation

- [Architecture Overview](../architecture/ADR-002-complete-architecture.md)
- [CLI Reference](../cli-reference.md)
- [Configuration Guide](../configuration.md)
