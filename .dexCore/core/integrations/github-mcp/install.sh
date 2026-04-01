#!/bin/bash
# GitHub MCP Setup for DexHub (DHL Enterprise)
# Version: 1.0
# Auto-configures MCP for your-github-enterprise.example.com

set -e

echo "🚀 GitHub MCP Setup (DHL Enterprise)"
echo "====================================="
echo ""

# Configuration
GITHUB_HOST="your-github-enterprise.example.com"
BINARY_DIR="$HOME/.dexhub/bin"
MCP_CONFIG="$HOME/.vscode/mcp-servers.json"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Step 1: Check prerequisites
echo "🔍 Checking prerequisites..."

# Check gh CLI
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) not found"
    echo ""
    echo "Please install gh CLI first:"
    echo "  macOS:   brew install gh"
    echo "  Linux:   https://github.com/cli/cli/blob/trunk/docs/install_linux.md"
    echo "  Windows: https://github.com/cli/cli/releases"
    exit 1
fi
echo "✅ GitHub CLI found"

# Check VS Code
if ! command -v code &> /dev/null; then
    echo "⚠️  VS Code CLI not found (optional)"
    echo "   VS Code may still work, but 'code' command is not in PATH"
fi

echo ""

# Step 2: VPN Check
echo "📡 Checking VPN connection..."
if ping -c 1 -W 2 "$GITHUB_HOST" &> /dev/null; then
    echo "✅ VPN connected - $GITHUB_HOST reachable"
else
    echo "❌ VPN not connected or $GITHUB_HOST unreachable"
    echo ""
    echo "Please:"
    echo "  1. Connect to DHL VPN"
    echo "  2. Run this script again"
    exit 1
fi

echo ""

# Step 3: Download Binary
echo "📦 Downloading GitHub MCP Server..."

mkdir -p "$BINARY_DIR"

# Detect platform
OS=$(uname -s)
ARCH=$(uname -m)

case "$OS" in
    Darwin)
        case "$ARCH" in
            arm64) BINARY="github-mcp-server_Darwin_arm64.tar.gz" ;;
            x86_64) BINARY="github-mcp-server_Darwin_x86_64.tar.gz" ;;
            *) echo "❌ Unsupported architecture: $ARCH"; exit 1 ;;
        esac
        ;;
    Linux)
        case "$ARCH" in
            x86_64) BINARY="github-mcp-server_Linux_x86_64.tar.gz" ;;
            aarch64) BINARY="github-mcp-server_Linux_arm64.tar.gz" ;;
            *) echo "❌ Unsupported architecture: $ARCH"; exit 1 ;;
        esac
        ;;
    *)
        echo "❌ Unsupported OS: $OS"
        exit 1
        ;;
esac

DOWNLOAD_URL="https://github.com/github/github-mcp-server/releases/latest/download/$BINARY"

echo "   Platform: $OS $ARCH"
echo "   Downloading: $BINARY"

if curl -sL "$DOWNLOAD_URL" | tar -xz -C "$BINARY_DIR"; then
    chmod +x "$BINARY_DIR/github-mcp-server"
    echo "✅ Binary installed: $BINARY_DIR/github-mcp-server"
else
    echo "❌ Download failed"
    exit 1
fi

echo ""

# Step 4: Authenticate with GitHub Enterprise
echo "🔐 Checking GitHub authentication..."

if gh auth status --hostname "$GITHUB_HOST" &> /dev/null; then
    echo "✅ Already authenticated with $GITHUB_HOST"
else
    echo "⚠️  Not authenticated with $GITHUB_HOST"
    echo ""
    echo "Starting browser authentication..."
    echo "(If browser doesn't open, copy the URL manually)"
    echo ""

    if gh auth login --hostname "$GITHUB_HOST" --web; then
        echo "✅ Authentication successful"
    else
        echo "❌ Authentication failed"
        echo ""
        echo "Manual authentication:"
        echo "  gh auth login --hostname $GITHUB_HOST"
        exit 1
    fi
fi

# Get token
GH_TOKEN=$(gh auth token --hostname "$GITHUB_HOST" 2>/dev/null || echo "")

if [ -z "$GH_TOKEN" ]; then
    echo "❌ Could not retrieve token"
    exit 1
fi

echo ""

# Step 5: Generate MCP Config
echo "⚙️  Generating MCP configuration..."

mkdir -p "$(dirname "$MCP_CONFIG")"

# Check if config exists and has other servers
if [ -f "$MCP_CONFIG" ]; then
    echo "⚠️  MCP config already exists: $MCP_CONFIG"

    # Check if github-dhl already configured
    if grep -q "github-dhl" "$MCP_CONFIG"; then
        echo "   github-dhl already configured"
        read -p "   Overwrite? [y/n] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Setup cancelled."
            exit 0
        fi
    fi

    # Backup existing config
    cp "$MCP_CONFIG" "$MCP_CONFIG.backup.$(date +%Y%m%d_%H%M%S)"
    echo "✅ Backup created"
fi

# Write config
cat > "$MCP_CONFIG" << EOF
{
  "mcpServers": {
    "github-dhl": {
      "command": "$BINARY_DIR/github-mcp-server",
      "args": ["stdio", "--gh-host", "https://$GITHUB_HOST", "--toolsets", "default,pull_requests,actions"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "$GH_TOKEN"
      }
    }
  }
}
EOF

echo "✅ Config created: $MCP_CONFIG"

echo ""

# Step 6: Update DexHub Config (optional)
CONFIG_FILE=".dexCore/_cfg/config.yaml"

if [ -f "$CONFIG_FILE" ]; then
    if ! grep -q "github_mcp:" "$CONFIG_FILE" 2>/dev/null; then
        cat >> "$CONFIG_FILE" << EOF

# GitHub MCP Integration (EA-1.1)
mcp_integrations:
  github:
    enabled: true
    auto_configured: true
    instance: "$GITHUB_HOST"
EOF
        echo "✅ DexHub config updated"
    else
        echo "ℹ️  GitHub MCP already in DexHub config"
    fi
fi

echo ""

# Step 7: Done!
echo "✅ Setup Complete!"
echo ""
echo "Next Steps:"
echo "  1. Restart VS Code"
echo "  2. Open Copilot Chat"
echo "  3. Test: 'List my repositories on $GITHUB_HOST'"
echo ""
echo "Example Commands:"
echo "  • 'Push my changes to feature/xyz'"
echo "  • 'Create a pull request'"
echo "  • 'Show open issues'"
echo ""
echo "Troubleshooting:"
echo "  • VPN disconnected? Reconnect and retry"
echo "  • Token expired? Run: gh auth refresh --hostname $GITHUB_HOST"
echo "  • Need help? See: .dexCore/core/integrations/github-mcp/README.md"
echo ""
