# Use Case 05: Configuration Management

**Scenario**: Customize DexHub settings and configuration

**Duration**: 5 minutes

**Prerequisites**:
- DexHub initialized in project

---

## Step-by-Step Instructions

### 1. View Current Configuration

```bash
dex config show
```

**Expected Output**:
```
📋 DexHub Configuration

Project: my-project
Version: 0.1.0-alpha
Initialized: 2025-10-27T03:01:06.456Z

Features:
  ✅ DexMaster
  ✅ KnowledgeHub
  ✅ Workflows
```

### 2. View Configuration File

```bash
cat .dex/config.yaml
```

**Expected Output**:
```yaml
# DexHub Project Configuration
version: 0.1.0-alpha
project:
  name: my-project
  initialized: 2025-10-27T03:01:06.456Z
features:
  dexMaster: true
  knowledgeHub: true
  workflows: true
```

### 3. Customize Configuration

Edit `.dex/config.yaml`:

```yaml
# DexHub Project Configuration
version: 0.1.0-alpha

project:
  name: my-awesome-project
  description: "My amazing project with DexHub"
  initialized: 2025-10-27T03:01:06.456Z
  team:
    - name: "John Doe"
      role: "Developer"
    - name: "Jane Smith"
      role: "Product Owner"

features:
  dexMaster: true
  knowledgeHub: true
  workflows: true
  customAgents: false

preferences:
  defaultWorkflowPhase: "analysis"
  verboseOutput: true
  autoSaveOutputs: true

integrations:
  git: true
  slack: false
  jira: false
```

### 4. Verify Updated Configuration

```bash
dex config show
```

**Expected**: Updated values reflected

---

## Configuration Options

### Project Settings

```yaml
project:
  name: "project-name"           # Project identifier
  description: "Description"     # Project description
  initialized: "2025-10-27..."   # Initialization timestamp
  team: []                        # Team members (optional)
```

### Features

```yaml
features:
  dexMaster: true      # Core orchestration agent
  knowledgeHub: true   # Knowledge management
  workflows: true      # Workflow execution
  customAgents: false  # Custom agent support (future)
```

### Preferences

```yaml
preferences:
  defaultWorkflowPhase: "analysis"  # Default workflow phase
  verboseOutput: false              # Detailed output
  autoSaveOutputs: true             # Auto-save to knowledgeHub
  coloredOutput: true               # Terminal colors
```

### Integrations (Future Features)

```yaml
integrations:
  git: true            # Git integration
  slack: false         # Slack notifications
  jira: false          # Jira integration
  github: false        # GitHub integration
```

---

## Success Criteria

- [ ] Successfully viewed current configuration
- [ ] Edited `.dex/config.yaml` file
- [ ] Verified changes with `dex config show`
- [ ] Configuration is valid YAML

---

## Troubleshooting

### Error: "Invalid YAML syntax"

**Solution**: Validate YAML syntax
```bash
# Use online YAML validator or
python3 -c "import yaml; yaml.safe_load(open('.dex/config.yaml'))"
```

### Configuration changes not reflected

**Solution**: Check file saved correctly
```bash
cat .dex/config.yaml
```

---

## Next Steps

- Explore other configuration files in `.dex/`
- Set up team collaboration settings
- Configure integrations (when available)

---

## Related Documentation

- [Configuration Reference](../configuration-reference.md)
