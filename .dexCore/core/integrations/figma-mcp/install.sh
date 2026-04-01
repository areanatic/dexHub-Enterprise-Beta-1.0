#!/bin/bash
# Figma MCP Setup for DexHub
# Version: 1.2

set -e

echo "🚀 Figma MCP Setup (DexHub)"
echo "============================"
echo ""

if ! command -v python3 >/dev/null 2>&1; then
    echo "❌ python3 is required for safe JSON merge"
    exit 1
fi

USER_MCP_JSON="$HOME/Library/Application Support/Code/User/mcp.json"
mkdir -p "$(dirname "$USER_MCP_JSON")"

echo "⚙️  Ensuring Figma MCP is present in the official VS Code user MCP config..."

python3 - <<'PY'
import json
from pathlib import Path

user_mcp = Path.home() / "Library" / "Application Support" / "Code" / "User" / "mcp.json"

if user_mcp.exists():
    try:
        data = json.loads(user_mcp.read_text(encoding="utf-8"))
    except Exception:
        data = {}
else:
    data = {}

servers = data.setdefault("servers", {})
existing = servers.get("figma")

if existing:
    print(f"✅ Existing figma server preserved: {existing.get('url', '<unknown>')}")
else:
    servers["figma"] = {
        "type": "http",
        "url": "https://mcp.figma.com/mcp"
    }
    user_mcp.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
    print(f"✅ Updated {user_mcp}")
PY

echo ""
echo "🌐 Opening authentication pages..."
open "https://mcp.figma.com/mcp" || true
open "https://www.figma.com/login" || true

echo ""
echo "✅ Setup Complete"
echo ""
echo "Next steps (official flow):"
echo "  1. In VS Code: Cmd+Shift+P → MCP: List Servers"
echo "  2. Select 'figma' → Start/Authenticate or Show Output"
echo "  3. Trust the server if VS Code asks"
echo "  4. Open Chat in Agent mode and type: #get_design_context"
echo "  5. Test: Analyze this Figma design: https://www.figma.com/design/<file-id>"
echo ""
