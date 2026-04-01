# DexHub Alpha v1 - Use Cases & Test Scenarios

This directory contains comprehensive test scenarios to verify DexHub functionality and demonstrate its capabilities.

## Test Scenario Index

1. [Fresh Start](01-fresh-start.md) - Initialize DexHub in a brand new project
2. [Brownfield Integration](02-brownfield-integration.md) - Add DexHub to existing legacy codebase
3. [Agent Discovery](03-agent-discovery.md) - Explore and understand available AI agents
4. [Workflow Execution](04-workflow-execution.md) - Run brainstorming and planning workflows
5. [Configuration Management](05-config-management.md) - Customize DexHub settings
6. [Status & Health Check](06-status-check.md) - Verify DexHub installation and health
7. [Help & Documentation](07-help-system.md) - Access built-in help and guidance

## Quick Test Run

Run all test scenarios in sequence:

```bash
# 1. Fresh start in new project
mkdir /tmp/test-dex-fresh && cd /tmp/test-dex-fresh
dex init
dex status

# 2. Explore agents
dex agent list
dex agent analyst

# 3. Run workflow
dex workflow brainstorming

# 4. Check configuration
dex config show

# 5. Help system
dex --help
dex agent --help
```

## Expected Outcomes

Each test scenario includes:
- Prerequisites (what you need before starting)
- Step-by-step instructions
- Expected output/behavior
- Troubleshooting tips
- Success criteria

## Testing Checklist

- [ ] Fresh project initialization works
- [ ] Brownfield integration doesn't break existing projects
- [ ] All 20+ agents are discoverable
- [ ] Workflows load correctly
- [ ] Configuration management works
- [ ] Status check shows accurate health
- [ ] Help system is comprehensive

## Test Environment

**Recommended Setup:**
- Node.js ≥18.0.0
- npm or pnpm installed
- Terminal with color support
- Git installed (for version control)

**Clean Test Directory:**
```bash
# Create isolated test environment
mkdir -p /tmp/dexhub-tests
cd /tmp/dexhub-tests
```

## Reporting Issues

If any test scenario fails:

1. Check Node.js version: `node --version`
2. Verify installation: `which dex`
3. Check DexHub version: `dex --version`
4. Review logs in `.dex/logs/` (if available)
5. Report issue at: https://github.com/areanatic/dexhub-alpha-v1/issues

## Next Steps

After completing test scenarios:
- Review [Architecture Documentation](../architecture/ADR-002-complete-architecture.md)
- Explore [Pitch Materials](../pitch/VARIANTS-OVERVIEW.md)
- Check [CLI Reference](../cli-reference.md)
