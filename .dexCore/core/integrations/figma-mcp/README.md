# Figma MCP Integration

> Design Analysis, Token Extraction & Canvas Editing in VS Code via GitHub Copilot

---

## Quick Start

```bash
cd /path/to/dexhub
bash .dexCore/core/integrations/figma-mcp/install.sh
```

**Requirements:**
- VS Code installed
- GitHub Copilot Chat Extension
- Figma account (Professional or Enterprise for meaningful usage)

**Time:** 2-3 minutes

---

## What Gets Configured

### Files Created/Modified:

1. **VS Code user MCP configuration**
  - Official VS Code MCP configuration source
  - Adds or preserves `servers.figma`

2. **Browser auth flow**
  - Opens Figma auth pages to complete OAuth

### Architecture

```
Copilot Chat → VS Code MCP Client → https://mcp.figma.com/mcp → Figma API
                                          (OAuth)
```

**Why Remote (not Local)?**
- Official Figma MCP server, hosted by Figma Inc.
- No binary download needed
- OAuth handled by VS Code automatically
- Always up-to-date (no version management)

---

## Authentication

### Option 1: OAuth (Recommended)

1. Run `install.sh`
2. In VS Code, start the Figma MCP server if prompted and trust it
3. Open Copilot Chat in Agent mode
4. Use `#get_design_context` to verify the tools are present
5. Run a Figma prompt with your design link

### Option 2: Personal Access Token

```bash
bash .dexCore/core/integrations/figma-mcp/auto-auth.sh --token
```

1. Browser opens Figma token page
2. Create token with Read scopes
3. Paste token in terminal
4. Script verifies + saves token
5. Restart VS Code

---

## Post-Setup

### Test Connection

```
Copilot Chat: "Analyze this Figma design: https://www.figma.com/design/<your-file-id>"
```

Expected: Structured code representation of the design

Recommended first verification:

```
#get_design_context
```

If no Figma tools are listed, restart VS Code and run `MCP: List Servers`.

### Example Usage

**Analyze Design:**
```
"Show me the layout structure of this Figma screen: <link>"
```

**Extract Tokens:**
```
"What design tokens and colors does this Figma file use?"
```

**Search Components:**
```
"Find the Button component in the design system"
```

**Create Design:**
```
"Add a login screen to this Figma file"
```

### Available Tools

See: `tools.yaml` (7 tools documented)

**Quick Reference:**
- `get_design_context` — Design as structured code (React + Tailwind)
- `get_variable_defs` — Design tokens and styles
- `search_design_system` — Find reusable components
- `get_code_connect_map` — Map design to code components
- `use_figma` — Create/modify frames on canvas
- `generate_figma_design` — Capture webpage to Figma
- `generate_diagram` — Create FigJam diagrams

---

## Troubleshooting

### "Needs authentication"

**Solution:**
1. Run `MCP: List Servers`
2. Select `figma` → Start/Authenticate or Show Output
3. Trust the server if VS Code asks
4. Open chat in Agent mode and try `#get_design_context`
5. If OAuth fails: `bash auto-auth.sh --token`

### "Rate limit exceeded"

**Check your plan:**
- Free/Starter: 6 calls/month (not usable)
- Professional: Per-minute limits
- Enterprise: Per-minute limits, high ceiling

### "File not found"

**Check:**
- Figma URL is correct (must be `/design/` not `/file/`)
- You have access to the file in Figma
- File is not in a draft (drafts may not be accessible via API)

### "Tool not found"

**Fix:**
1. Check the official VS Code user MCP configuration has `servers.figma`
2. Run `MCP: List Servers` and confirm `figma` is enabled
3. Restart VS Code
4. Re-run `install.sh` if needed

---

## Manual Setup (If Script Fails)

1. Add to the official VS Code user `mcp.json`:
   ```json
   {
     "servers": {
       "figma": {
         "type": "http",
         "url": "https://mcp.figma.com/mcp"
       }
     }
   }
   ```

2. Run `MCP: List Servers` → `figma` → Start/Authenticate

3. Trust the server if asked, then complete OAuth

4. Open chat in Agent mode and verify with `#get_design_context`

---

## Uninstall

```bash
# Remove from MCP config
# Edit ~/.vscode/mcp-servers.json and remove "figma" entry

# Reset DexHub flag
# Edit .dexCore/_cfg/config.yaml → remove figma section

# Revoke OAuth (optional)
# Figma → Settings → Connected apps → Remove "VS Code"
```

---

## Support

- **Figma MCP Docs:** https://github.com/figma/mcp-server-guide
- **MCP in VS Code:** https://code.visualstudio.com/docs/copilot/chat/mcp-servers
- **Tools Docs:** `tools.yaml`
- **DexHub Research:** `myDex/projects/figma-integration-pocs/.dex/1-analysis/`

---

**Version:** 1.0
**Status:** Functional, needs alignment with current VS Code MCP flow
**Last Updated:** 2026-03-26
