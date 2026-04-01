#!/bin/bash
# GitHub MCP Auto-Authentication for DexHub
# Version: 2.0 (FEATURE-003)
# Automatische Browser-basierte Authentifizierung
#
# Kann direkt vom Agent aufgerufen werden:
#   .dexCore/core/integrations/github-mcp/auto-auth.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
GITHUB_HOST="your-github-enterprise.example.com"
BINARY_DIR="$HOME/.dexhub/bin"
MCP_CONFIG="$HOME/.vscode/mcp-servers.json"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}🚀 GitHub MCP Auto-Setup${NC}"
echo "=========================="
echo ""

# Step 1: VPN Check
echo -e "${YELLOW}📡 VPN-Check...${NC}"
if ping -c 1 -W 2 "$GITHUB_HOST" &> /dev/null; then
    echo -e "${GREEN}✅ VPN verbunden${NC}"
else
    echo -e "${RED}❌ VPN nicht verbunden!${NC}"
    echo ""
    echo "Bitte:"
    echo "  1. Mit DHL VPN verbinden"
    echo "  2. Dieses Script erneut starten"
    exit 1
fi

echo ""

# Step 2: Check gh CLI
echo -e "${YELLOW}🔍 GitHub CLI prüfen...${NC}"
if ! command -v gh &> /dev/null; then
    echo -e "${RED}❌ GitHub CLI (gh) nicht gefunden${NC}"
    echo ""
    echo "Installieren mit:"
    echo "  macOS:   brew install gh"
    echo "  Linux:   https://github.com/cli/cli/blob/trunk/docs/install_linux.md"
    exit 1
fi
echo -e "${GREEN}✅ GitHub CLI gefunden${NC}"

echo ""

# Step 3: Download Binary (if needed)
echo -e "${YELLOW}📦 GitHub MCP Server prüfen...${NC}"

if [ ! -f "$BINARY_DIR/github-mcp-server" ]; then
    mkdir -p "$BINARY_DIR"

    OS=$(uname -s)
    ARCH=$(uname -m)

    case "$OS" in
        Darwin)
            case "$ARCH" in
                arm64) BINARY="github-mcp-server_Darwin_arm64.tar.gz" ;;
                x86_64) BINARY="github-mcp-server_Darwin_x86_64.tar.gz" ;;
            esac
            ;;
        Linux)
            case "$ARCH" in
                x86_64) BINARY="github-mcp-server_Linux_x86_64.tar.gz" ;;
                aarch64) BINARY="github-mcp-server_Linux_arm64.tar.gz" ;;
            esac
            ;;
    esac

    echo "   Downloading $BINARY..."
    DOWNLOAD_URL="https://github.com/github/github-mcp-server/releases/latest/download/$BINARY"

    if curl -sL "$DOWNLOAD_URL" | tar -xz -C "$BINARY_DIR"; then
        chmod +x "$BINARY_DIR/github-mcp-server"
        echo -e "${GREEN}✅ Binary installiert${NC}"
    else
        echo -e "${RED}❌ Download fehlgeschlagen${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✅ Binary bereits vorhanden${NC}"
fi

echo ""

# Step 4: Browser Authentication
echo -e "${BLUE}🔐 GitHub Authentifizierung${NC}"
echo ""

if gh auth status --hostname "$GITHUB_HOST" &> /dev/null; then
    echo -e "${GREEN}✅ Bereits authentifiziert mit $GITHUB_HOST${NC}"
else
    echo "Browser öffnet sich automatisch..."
    echo ""

    if gh auth login --hostname "$GITHUB_HOST" --web; then
        echo -e "${GREEN}✅ Authentifizierung erfolgreich${NC}"
    else
        echo -e "${RED}❌ Authentifizierung fehlgeschlagen${NC}"
        exit 1
    fi
fi

# Get token
GH_TOKEN=$(gh auth token --hostname "$GITHUB_HOST" 2>/dev/null || echo "")

if [ -z "$GH_TOKEN" ]; then
    echo -e "${RED}❌ Token konnte nicht abgerufen werden${NC}"
    exit 1
fi

echo ""

# Step 5: Write MCP Config
echo -e "${BLUE}⚙️  MCP Konfiguration schreiben...${NC}"

mkdir -p "$(dirname "$MCP_CONFIG")"

# Backup if exists
if [ -f "$MCP_CONFIG" ]; then
    cp "$MCP_CONFIG" "$MCP_CONFIG.backup.$(date +%Y%m%d_%H%M%S)"
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

echo -e "${GREEN}✅ Config erstellt: $MCP_CONFIG${NC}"

echo ""

# Step 6: Done!
echo -e "${GREEN}✅ Setup komplett!${NC}"
echo ""
echo -e "${BLUE}Nächste Schritte:${NC}"
echo "  1. VS Code neustarten"
echo "  2. Copilot Chat öffnen"
echo "  3. Testen: 'List my repositories on $GITHUB_HOST'"
echo ""
echo -e "${GREEN}🎉 Fertig! GitHub ist jetzt verbunden.${NC}"
echo ""
