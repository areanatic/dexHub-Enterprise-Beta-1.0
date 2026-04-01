# Figma MCP Setup — Copilot Prompt

> Copy the prompt below into **VS Code Copilot Chat** to set up the Figma MCP integration.
> Copilot will configure the MCP server and trigger the OAuth flow.

---

## Prompt (copy everything between the lines)

---

```
I need you to set up the Figma MCP server in VS Code. Follow these steps exactly:

**Step 1: Check the official VS Code MCP config**
Open the VS Code user MCP config and confirm there is a `figma` server.
The current official config shape is:

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

If needed, you can still inspect legacy config with:
```bash
cat ~/.vscode/mcp-servers.json 2>/dev/null | grep -i figma || echo "Not configured"
```

**Step 2: Add Figma MCP to the official VS Code MCP config**
Open VS Code user `mcp.json` and add the following MCP server configuration.
If there is already a `servers` section, merge this into it (do NOT overwrite existing servers):

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

**Step 3: Trigger OAuth**
After adding the config, VS Code should detect the new MCP server.
VS Code may ask whether to trust/start the server first. After that, the OAuth flow should start in the browser.

If the OAuth does not trigger automatically:
1. Run the command: "MCP: List Servers" (Cmd+Shift+P)
2. Click on "figma" in the list
3. Click "Start", "Authenticate", or "Show Output"

**Step 4: Verify**
After I authorize in the browser, switch Copilot Chat to Agent mode and verify tools are visible:
- Try `#get_design_context`

Then test the connection by running this Figma MCP prompt:
- Try to get design context from any Figma file I provide

Please proceed step by step and tell me what to do at each stage.
```

---

## Alternative: Direct Terminal Setup

If Copilot Chat is not available, run this in the VS Code terminal:

```bash
bash .dexCore/core/integrations/figma-mcp/install.sh
```

Then restart VS Code. OAuth will trigger on first Figma command.

---

## After Setup

Test with:
```
Analyze this Figma design: https://www.figma.com/design/<your-file-id>
```
