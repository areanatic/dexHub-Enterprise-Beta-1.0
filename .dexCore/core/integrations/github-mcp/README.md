# GitHub MCP Integration (DHL Enterprise)

> Git Operations in VS Code via GitHub Copilot - Push, Commit, PRs direkt aus dem Chat

---

## Quick Start

```bash
cd /path/to/dexhub
bash .dexCore/core/integrations/github-mcp/install.sh
```

**Requirements:**
- DHL VPN connected (für your-github-enterprise.example.com)
- VS Code installed
- GitHub Copilot Chat Extension
- `gh` CLI installed

**Time:** 2-3 minutes

---

## What Gets Configured

### Files Created/Modified:

1. **`~/.dexhub/bin/github-mcp-server`**
   - Pre-built Binary (~14 MB)
   - Keine weitere Installation nötig

2. **`~/.vscode/mcp-servers.json`**
   - VS Code MCP configuration
   - Pre-configured for `your-github-enterprise.example.com`

3. **`.dexCore/_cfg/config.yaml`**
   - DexHub tracking flag

---

## Post-Setup

### Test Connection

```
Copilot Chat: "List my repositories on your-github-enterprise.example.com"
```

Expected: Liste deiner Repos

### Example Usage

**Push Changes:**
```
"Push my changes to feature/my-branch"
```

**Create PR:**
```
"Create a pull request for feature/my-branch"
```

**Check Status:**
```
"Show open PRs in this repo"
```

### Available Tools

See: `tools.yaml` (40+ tools documented)

**Quick Reference:**
- `create_or_update_file` - Datei erstellen/aktualisieren
- `push_files` - Mehrere Dateien pushen
- `create_pull_request` - PR erstellen
- `list_pull_requests` - PRs auflisten
- `search_issues` - Issues suchen
- `create_issue` - Issue erstellen

---

## Troubleshooting

### "Connection failed"

**Check:**
1. VPN connected? `ping your-github-enterprise.example.com`
2. VS Code restarted after setup?
3. Token valid? `gh auth status --hostname your-github-enterprise.example.com`

### "Permission denied"

**Solution:**
```bash
gh auth login --hostname your-github-enterprise.example.com
```

### "Binary not found"

**Fix:**
```bash
# Re-run install script
bash .dexCore/core/integrations/github-mcp/install.sh
```

### "Token expired"

**Refresh:**
```bash
gh auth refresh --hostname your-github-enterprise.example.com
export GH_DHL_TOKEN=$(gh auth token --hostname your-github-enterprise.example.com)
```

---

## Manual Setup (If Script Fails)

1. Download Binary:
   ```bash
   mkdir -p ~/.dexhub/bin
   curl -sL "https://github.com/github/github-mcp-server/releases/latest/download/github-mcp-server_$(uname -s)_$(uname -m).tar.gz" | tar -xz -C ~/.dexhub/bin/
   ```

2. Authenticate:
   ```bash
   gh auth login --hostname your-github-enterprise.example.com
   ```

3. Create `~/.vscode/mcp-servers.json`:
   ```json
   {
     "mcpServers": {
       "github-dhl": {
         "command": "~/.dexhub/bin/github-mcp-server",
         "args": ["stdio", "--gh-host", "https://your-github-enterprise.example.com"],
         "env": {
           "GITHUB_PERSONAL_ACCESS_TOKEN": "<your-token>"
         }
       }
     }
   }
   ```

4. Get token:
   ```bash
   gh auth token --hostname your-github-enterprise.example.com
   ```

5. Restart VS Code

---

## Uninstall

```bash
# Remove binary
rm -rf ~/.dexhub/bin/github-mcp-server

# Remove from MCP config
# Edit ~/.vscode/mcp-servers.json and remove "github-dhl" entry

# Reset DexHub flag
# Edit .dexCore/_cfg/config.yaml → set github_mcp_enabled: false
```

---

## Architecture

**Pattern:** Local MCP Server with Pre-built Binary

```
User installs DexHub
    ↓
install.sh downloads binary (~5MB)
    ↓
gh auth login (Browser OAuth)
    ↓
Config written to ~/.vscode/mcp-servers.json
    ↓
VS Code starts MCP server on demand
    ↓
Copilot can push, commit, create PRs!
```

**Why Local (not Remote)?**
- Remote MCP doesn't support Enterprise Server (your-github-enterprise.example.com)
- Local binary works with any GitHub instance
- No Docker required

---

## Support

- **Binary Source:** https://github.com/github/github-mcp-server/releases
- **MCP Docs:** https://code.visualstudio.com/docs/copilot/chat/mcp-servers
- **Tools Docs:** `tools.yaml`

---

**Version:** 1.0
**Status:** Production Ready
**Last Updated:** 2025-12-01
