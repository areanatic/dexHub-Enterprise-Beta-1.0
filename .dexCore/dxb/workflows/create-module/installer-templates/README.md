# Module Installer Template System

**Status:** Template Infrastructure (EA-1.0)
**Active:** No - Planning/Foundation Phase
**Planned For:** EA-1.1 or later releases

---

## Overview

This directory contains the template infrastructure for DexHub's future module installation system. When fully implemented, this will enable users to:

- **Install custom modules** from the DexHub marketplace
- **Configure module-specific settings** during installation
- **Initialize module databases** and features automatically
- **Register modules** in the DexHub manifest system
- **Uninstall modules** with proper cleanup and backup

---

## Current Status (EA-1.0)

### What's Here

1. **`installer.js`** - JavaScript template for custom module installation logic
   - Contains complete function structure
   - TODOs mark implementation points
   - Supports environment validation, config setup, feature initialization
   - Handles post-install tasks and cleanup

2. **`install-module-config.yaml`** - YAML template for module installation configuration
   - Defines pre-install checks
   - Specifies installation steps
   - Configures external assets
   - Sets default module config
   - Defines post-install tasks

### What's NOT Active Yet

- **No active installer workflow** - Templates are not called by any current DexHub workflow
- **No marketplace integration** - Module discovery/download not implemented
- **No module registry** - External module hosting infrastructure pending
- **Manual installation only** - Users must copy files manually in EA-1.0

---

## How It Will Work (Future)

### Installation Flow (Planned)

```
1. User discovers module in marketplace
   └─> Browses DexHub module registry

2. User initiates installation
   └─> `dex install <module-name>`

3. Pre-install checks run
   └─> Validates DEX version, dependencies, disk space

4. installer.js executes
   └─> validateEnvironment()
   └─> setupConfigurations()
   └─> initializeFeatures()
   └─> runPostInstallTasks()

5. Module registered in manifest
   └─> .dexCore/_cfg/manifest.yaml updated

6. Post-install message shown
   └─> Quick start guide, documentation links
```

### Module Types Supported

- **Data Modules** - Database schemas, storage initialization
- **Automation Modules** - Triggers, watchers, schedulers
- **Integration Modules** - APIs, webhooks, external services
- **Custom Modules** - User-defined installation logic

---

## Template Variables

Both templates use placeholder variables that get replaced during module creation:

- `{{MODULE_NAME}}` - Full module name
- `{{MODULE_CODE}}` - Short module identifier (e.g., "dxm", "dxb")
- `{{MODULE_DESCRIPTION}}` - Module description
- `{{MODULE_CATEGORY}}` - Category (data/automation/integration)
- `{{DATE}}` - Installation timestamp
- `{{USER}}` - Installing user
- `{{PROJECT_ROOT}}` - DexHub installation path

---

## TODOs Explained

The `installer.js` file contains multiple TODOs. These are **intentional markers** for future implementation:

- **Line 54:** Environment validation (tools, permissions, connectivity)
- **Line 75:** Configuration setup (config files, env vars, external services)
- **Line 104:** Feature initialization (databases, cron jobs, caches)
- **Line 164:** Post-install tasks (sample data, notifications, registry updates)
- **Line 180:** Database initialization (schema creation, migrations)
- **Line 192:** Sample data generation (examples, documentation)
- **Line 208:** Uninstall cleanup (backups, service deregistration)

**These TODOs are NOT bugs** - they document planned extension points for EA-1.1+.

---

## For Developers

### Extending the Template System

When implementing module installation in EA-1.1+:

1. **Review `installer.js` TODOs** - Each marks an implementation point
2. **Implement functions incrementally** - Start with validateEnvironment(), then setupConfigurations()
3. **Test with simple module first** - Use minimal config before complex modules
4. **Update `install-module-config.yaml`** - Add new installation steps as needed
5. **Create installer workflow** - Build the CLI/workflow that calls these templates

### Testing Installation Templates

While the installer isn't active, you can test the structure:

```javascript
const installer = require('./installer.js');

const testConfig = {
  project_root: '/path/to/dexhub',
  module_code: 'test-module',
  version: 'ea-1.0',
  module_category: 'data'
};

installer.installModule(testConfig)
  .then(result => console.log(result));
```

---

## Roadmap

### EA-1.0 (Current)
- ✅ Template structure complete
- ✅ Function signatures defined
- ✅ Installation config schema ready

### EA-1.1 (Planned)
- [ ] Implement core installer functions
- [ ] Create CLI command (`dex install <module>`)
- [ ] Basic module validation

### EA-1.2+ (Future)
- [ ] Marketplace integration
- [ ] Module registry (CSV/JSON metadata)
- [ ] Automated module discovery
- [ ] Version management
- [ ] Dependency resolution

---

## Related Documentation

- [DXB Module Documentation](../../README.md) - Builder module overview
- [SILO Architecture](../../../_dev/docs/SILO-ARCHITECTURE.md) - Module system architecture
- [Module Manifest](../../../_cfg/manifest.yaml) - Current module registry

---

## Questions?

This is alpha-stage infrastructure. If you have questions or ideas for the module system:

1. Check the [GitHub Discussions](https://github.com/areanatic/dexhub-alpha-v1/discussions)
2. Review existing module structure (dxm, dxb, core, dis)
3. Propose improvements via GitHub Issues

---

**Version:** EA-1.0
**Last Updated:** 2025-11-13
**Status:** Template Infrastructure - Not Active
