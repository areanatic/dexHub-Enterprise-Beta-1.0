# Atlassian MCP Integration (DHL)

> Quick Setup for Jira & Confluence in VS Code via GitHub Copilot

---

## Quick Start

```bash
cd /path/to/dexhub
bash .dexCore/core/integrations/atlassian-mcp/install.sh
```

**Requirements:**
- DHL VPN connected
- VS Code installed
- GitHub Copilot Chat Extension

**Time:** 5 minutes

---

## What Gets Configured

### Files Created/Modified:

1. **`~/.vscode/mcp-servers.json`**
   - VS Code MCP configuration
   - Pre-configured for `dhl.atlassian.net`

2. **`.dexCore/_cfg/config.yaml`**
   - DexHub tracking flag
   - MCP status

---

## Post-Setup

### Test Connection

```
Copilot Chat: "Get Jira ticket PS-12345"
```

Expected: Ticket details displayed

### Available Tools

See: `tools.yaml` (27 tools documented)

**Quick Reference:**
- `jira_get_issue` - Get ticket details
- `jira_search_issues` - JQL search
- `confluence_search` - Search docs
- `confluence_get_page` - Get page content

---

## Troubleshooting

### "Connection failed"

**Check:**
1. VPN connected? `ping dhl.atlassian.net`
2. VS Code restarted after setup?
3. OAuth completed in browser?

### "Permission denied"

**Solution:**
- Verify Atlassian account access
- Contact IT if needed

### "Tool not found"

**Fix:**
- Reconnect MCP in VS Code settings
- Check `~/.vscode/mcp-servers.json` exists

---

## Manual Setup (If Script Fails)

1. Create `~/.vscode/mcp-servers.json`:
   ```json
   {
     "mcpServers": {
       "atlassian-mcp-dhl": {
         "type": "http",
         "url": "https://mcp.atlassian.com",
         "name": "Atlassian (DHL)",
         "enabled": true
       }
     }
   }
   ```

2. Restart VS Code

3. OAuth prompt appears → Select `dhl.atlassian.net`

4. Done!

---

## Uninstall

```bash
# Remove config
rm ~/.vscode/mcp-servers.json

# Reset DexHub flag
# Edit .dexCore/_cfg/config.yaml → set mcp_enabled: false
```

---

## Support

- **Planning Docs:** `myDex/projects/atlassian-mcp-workflow/`
- **Setup Guide:** `.dex/2-planning/01-SETUP-GUIDE.md`
- **Tools Docs:** `tools.yaml`

---

**Version:** 1.0  
**Status:** Production Ready  
**Last Updated:** 2025-12-01
