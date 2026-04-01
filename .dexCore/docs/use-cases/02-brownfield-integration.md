# Use Case 02: Brownfield Integration

**Scenario**: Add DexHub to an existing legacy codebase without breaking anything

**Duration**: 3-5 minutes

**Prerequisites**:
- Existing project with codebase (e.g., React app, Node.js backend, etc.)
- DexHub Alpha v1 installed globally

---

## Step-by-Step Instructions

### 1. Navigate to Existing Project

```bash
cd ~/projects/my-legacy-app
```

**Current State**: Existing project with:
- Source code in `src/`
- Dependencies in `node_modules/`
- Configuration files (package.json, tsconfig.json, etc.)
- Possibly Git repository

### 2. Verify Current Project State

```bash
# Check Git status (if Git repo)
git status

# Check file count
ls -la
```

**Expected**: Your existing project files unchanged

### 3. Initialize DexHub Meta-Layer

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
   Project: my-legacy-app
   Version: 0.1.0-alpha
   Features: DexMaster, KnowledgeHub, Workflows
```

### 4. Verify No Existing Files Were Changed

```bash
# Check Git status again
git status
```

**Expected Output**:
```
On branch main
Untracked files:
  (use "git add <file>..." to include in what will be committed)
        .dex/

nothing added to commit but untracked files present
```

**Key Point**: ONLY `.dex/` is new - all existing files untouched

### 5. Add .dex/ to .gitignore (Optional but Recommended)

```bash
echo ".dex/" >> .gitignore
```

**Why**: Keep DexHub meta-layer separate from project version control

### 6. Verify DexHub Health

```bash
dex status
```

**Expected**: All green checkmarks, healthy status

### 7. Test Existing Project Still Works

```bash
# Run your existing build/test commands
npm run build
npm test
npm start
```

**Expected**: Everything works exactly as before - DexHub is non-invasive

---

## Example: React Application

### Before DexHub:
```
my-react-app/
├── src/
│   ├── components/
│   ├── App.tsx
│   └── index.tsx
├── public/
├── package.json
├── tsconfig.json
└── .gitignore
```

### After DexHub:
```
my-react-app/
├── src/                 ← Unchanged
│   ├── components/      ← Unchanged
│   ├── App.tsx          ← Unchanged
│   └── index.tsx        ← Unchanged
├── public/              ← Unchanged
├── package.json         ← Unchanged
├── tsconfig.json        ← Unchanged
├── .gitignore           ← Updated (added .dex/)
└── .dex/                ← NEW (DexHub meta-layer)
    ├── config.yaml
    ├── dexMaster/
    ├── agents/
    ├── workflows/
    └── knowledgeHub/
```

**Impact**: ZERO changes to existing code, ZERO breaking changes

---

## Success Criteria

- [ ] `.dex/` folder created successfully
- [ ] Git status shows ONLY `.dex/` as untracked (if Git repo)
- [ ] Existing build/test commands still work
- [ ] No changes to any existing source files
- [ ] `dex status` shows healthy installation
- [ ] `.dex/` added to `.gitignore`

---

## Troubleshooting

### Warning: "This will overwrite existing .dex folder"

**Cause**: `.dex/` already exists from previous initialization

**Solutions**:
1. **Backup and reinitialize**:
   ```bash
   mv .dex .dex.backup
   dex init
   ```

2. **Keep existing** (skip initialization):
   ```bash
   # Just use existing .dex folder
   dex status
   ```

### Error: "Permission denied when creating .dex/"

**Cause**: Insufficient write permissions

**Solution**: Check directory permissions
```bash
ls -la
# Ensure you own the directory
sudo chown -R $USER:$USER .
```

### Concern: "Will this change my package.json?"

**Answer**: NO - DexHub NEVER modifies existing project files without explicit approval

---

## DexHub Brownfield Principles

1. ✅ **Non-Invasive**: Only adds `.dex/` folder, touches nothing else
2. ✅ **Reversible**: Delete `.dex/` folder to completely remove DexHub
3. ✅ **Git-Friendly**: `.dex/` can be gitignored or committed (your choice)
4. ✅ **Build-Compatible**: Works alongside any build system (Webpack, Vite, etc.)
5. ✅ **Zero Dependencies**: Doesn't add dependencies to your package.json

---

## Integration Patterns

### Pattern 1: Personal Use Only
```bash
# Add .dex/ to .gitignore
echo ".dex/" >> .gitignore
git add .gitignore
git commit -m "chore: Ignore DexHub meta-layer"
```

### Pattern 2: Team Collaboration
```bash
# Commit .dex/ structure (without personal data)
git add .dex/config.yaml .dex/dexMaster/
git commit -m "feat: Add DexHub for team workflows"
```

### Pattern 3: Company Standard
```bash
# Link to company-wide DexHub configuration
ln -s ~/.dexHub/company .dex/company-config
```

---

## Next Steps

After successful brownfield integration:

1. ✅ **Run Workflows**: Use DexHub workflows on existing codebase ([Use Case 04](04-workflow-execution.md))
2. ✅ **Document Codebase**: Use Knowledge Hub to capture existing architecture
3. ✅ **Modernization**: Use DexHub agents to plan refactoring/updates

---

## Related Documentation

- [Dex Meta-Layer Deep Dive](../architecture/dex-meta-layer-deep-dive.md)
- [Brownfield Strategy](../architecture/brownfield-strategy.md)
- [Git Integration Guide](../git-integration.md)
