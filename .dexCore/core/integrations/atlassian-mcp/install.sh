#!/bin/bash
# Atlassian MCP Setup for DexHub (DHL)
# Version: 1.0
# Auto-configures MCP for your-org.atlassian.net

set -e

echo "🚀 Atlassian MCP Setup (DHL)"
echo "=============================="
echo ""

# Step 1: VPN Check
echo "📡 Checking VPN connection..."
if ping -c 1 -W 2 your-org.atlassian.net &> /dev/null; then
    echo "✅ VPN connected - your-org.atlassian.net reachable"
else
    echo "❌ VPN not connected or your-org.atlassian.net unreachable"
    echo ""
    echo "Please:"
    echo "  1. Connect to DHL VPN"
    echo "  2. Run this script again"
    exit 1
fi

echo ""

# Step 2: Check VS Code
echo "🔍 Checking VS Code installation..."
if command -v code &> /dev/null; then
    echo "✅ VS Code found"
else
    echo "❌ VS Code not found"
    echo "Please install VS Code first: https://code.visualstudio.com"
    exit 1
fi

echo ""

# Step 3: Generate Config
echo "⚙️  Generating MCP configuration..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE="$SCRIPT_DIR/config-template.json"
VSCODE_DIR="$HOME/.vscode"
MCP_CONFIG="$VSCODE_DIR/mcp-servers.json"

# Create .vscode directory
mkdir -p "$VSCODE_DIR"

# Check if config already exists
if [ -f "$MCP_CONFIG" ]; then
    echo "⚠️  MCP config already exists: $MCP_CONFIG"
    echo ""
    read -p "Overwrite? [y/n] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Setup cancelled. MCP config unchanged."
        exit 0
    fi
    # Backup
    cp "$MCP_CONFIG" "$MCP_CONFIG.backup.$(date +%Y%m%d_%H%M%S)"
    echo "✅ Backup created"
fi

# Copy template
cp "$TEMPLATE" "$MCP_CONFIG"
echo "✅ Config created: $MCP_CONFIG"

echo ""

# Step 4: Update DexHub Config
echo "🔧 Updating DexHub config..."

CONFIG_FILE=".dexCore/_cfg/config.yaml"

if ! grep -q "mcp_integrations:" "$CONFIG_FILE" 2>/dev/null; then
    cat >> "$CONFIG_FILE" << EOF

# Atlassian MCP Integration (EA-1.1)
mcp_integrations:
  atlassian:
    enabled: true
    auto_configured: true
    instance: "your-org.atlassian.net"
EOF
    echo "✅ DexHub config updated"
else
    echo "ℹ️  MCP already configured in DexHub config"
fi

echo ""

# Step 5: Instructions
echo "✅ Setup Complete!"
echo ""
echo "Next Steps:"
echo "  1. Restart VS Code (to load MCP config)"
echo "  2. Browser will open for OAuth login"
echo "  3. Select instance: your-org.atlassian.net"
echo "  4. Approve permissions"
echo "  5. Test: 'Get Jira ticket PS-12345' in Copilot Chat"
echo ""
echo "Troubleshooting:"
echo "  - VPN disconnected? Reconnect VPN"
echo "  - Permission denied? Check Atlassian access"
echo "  - Need help? See: .dexCore/core/integrations/atlassian-mcp/README.md"
echo ""
