# Use Case 06: Status & Health Check

**Scenario**: Verify DexHub installation and health status

**Duration**: 1-2 minutes

**Prerequisites**:
- DexHub installed globally

---

## Step-by-Step Instructions

### 1. Check DexHub Version

```bash
dex --version
```

**Expected Output**:
```
0.1.0-alpha
```

### 2. Run Status Check

```bash
dex status
```

**Expected Output (Healthy)**:
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

**Expected Output (Unhealthy)**:
```
🔍 DexHub Status Check

❌ .dex/ folder: Not found
❌ DexMaster Agent: Not found
❌ Config file: Not found
❌ Agents directory: Not found
❌ Workflows directory: Not found
❌ Knowledge Hub: Not found

⚠️  DexHub has missing components

💡 Run `dex init` to initialize DexHub in this project
```

### 3. Check Installation Location

```bash
which dex
```

**Expected Output**:
```
/usr/local/bin/dex
```

Or if using nvm/pnpm:
```
~/.nvm/versions/node/v20.x.x/bin/dex
```

### 4. Verify Node.js Version

```bash
node --version
```

**Expected**: v18.0.0 or higher

---

## Health Check Criteria

### Component Checks

| Component | Location | Purpose |
|-----------|----------|---------|
| `.dex/` folder | Project root | Main DexHub directory |
| `dexMaster/` | `.dex/dexMaster/` | Core orchestration |
| `config.yaml` | `.dex/config.yaml` | Project configuration |
| `agents/` | `.dex/agents/` | Agent directory |
| `workflows/` | `.dex/workflows/` | Workflow directory |
| `knowledgeHub/` | `.dex/knowledgeHub/` | Knowledge storage |

### Resource Counts

- **Agents**: Should show 20+ agents across modules
- **Workflows**: Should show 22+ workflows across phases

---

## Success Criteria

- [ ] `dex --version` shows correct version
- [ ] `dex status` shows all green checkmarks
- [ ] Agent count: 20+
- [ ] Workflow count: 22+
- [ ] No error messages

---

## Troubleshooting

### Error: "dex: command not found"

**Cause**: DexHub not installed or not in PATH

**Solutions**:

1. **Install globally**:
   ```bash
   npm install -g dexhub-alpha-v1
   ```

2. **Check installation**:
   ```bash
   npm list -g dexhub-alpha-v1
   ```

3. **Verify PATH**:
   ```bash
   echo $PATH
   ```

### Warning: ".dex/ folder not found"

**Cause**: DexHub not initialized in current directory

**Solution**:
```bash
dex init
```

### Error: "Permission denied"

**Cause**: Insufficient permissions

**Solutions**:

1. **Fix npm permissions**:
   ```bash
   sudo chown -R $USER:$USER ~/.npm
   ```

2. **Reinstall without sudo**:
   ```bash
   npm install -g dexhub-alpha-v1
   ```

### Low agent/workflow count

**Cause**: Incomplete installation

**Solution**: Reinstall DexHub
```bash
npm uninstall -g dexhub-alpha-v1
npm install -g dexhub-alpha-v1
```

### Node version too old

**Error**: "DexHub requires Node.js ≥18.0.0"

**Solution**: Update Node.js
```bash
# Using nvm
nvm install 20
nvm use 20

# Verify
node --version
```

---

## Advanced Health Checks

### 1. Verify Repository Connection

```bash
cd $(npm list -g dexhub-alpha-v1 | grep dexhub | awk '{print $NF}')
ls -la dex/
```

**Expected**: See all module directories (core/, dxm/, dxb/, dis/)

### 2. Check Configuration Validity

```bash
cat .dex/config.yaml
```

**Expected**: Valid YAML with no syntax errors

### 3. Test Agent Loading

```bash
dex agent list
```

**Expected**: All agents load without errors

### 4. Test Workflow Loading

```bash
dex workflow list
```

**Expected**: All workflows load without errors

---

## Health Status Meanings

### ✅ Healthy
- All components present
- All checks passing
- Ready to use

### ⚠️ Warning
- Some optional components missing
- Functionality may be limited
- Consider running `dex init`

### ❌ Unhealthy
- Critical components missing
- DexHub cannot function
- Must run `dex init` or reinstall

---

## Regular Maintenance

### Weekly Checks

```bash
# 1. Check for updates
npm outdated -g dexhub-alpha-v1

# 2. Verify health
dex status

# 3. Clean cache (if issues)
npm cache clean --force
```

### Monthly Checks

```bash
# 1. Update DexHub
npm update -g dexhub-alpha-v1

# 2. Verify installation
dex --version
dex status

# 3. Test core functionality
dex agent list
dex workflow list
```

---

## Next Steps

After healthy status confirmed:

1. ✅ **Explore Features**: Run workflows and agents
2. ✅ **Customize Config**: Adjust settings for your needs
3. ✅ **Monitor Health**: Run `dex status` regularly

---

## Related Documentation

- [Installation Guide](../installation.md)
- [Troubleshooting Guide](../troubleshooting.md)
- [CLI Reference](../cli-reference.md)
