#!/bin/bash
# Atlassian MCP Auto-Authentication for DexHub
# Version: 2.0 (FEATURE-003)
# Automatische Browser-basierte Authentifizierung
#
# Kann direkt vom Agent aufgerufen werden:
#   .dexCore/core/integrations/atlassian-mcp/auto-auth.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
MCP_CONFIG="$HOME/.vscode/mcp-servers.json"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Function to open browser cross-platform
open_browser() {
    local url="$1"
    case "$(uname -s)" in
        Darwin)  open "$url" ;;
        Linux)   xdg-open "$url" 2>/dev/null || sensible-browser "$url" 2>/dev/null || echo "Open: $url" ;;
        MINGW*|MSYS*|CYGWIN*)  start "$url" ;;
        *)       echo "Open: $url" ;;
    esac
}

echo -e "${BLUE}🚀 Atlassian MCP Auto-Setup${NC}"
echo "=============================="
echo ""

# Step 0: Instance Selection
echo -e "${BLUE}🏢 Welche Atlassian-Instanz?${NC}"
echo ""
echo "  Gib die URL deiner Instanz ein (z.B. dhl.atlassian.net,"
echo "  confluence1.lcm.deutschepost.de, jira.dhl.com, etc.)"
echo ""
echo "  Anhand der Domain erkennen wir automatisch:"
echo "    - Cloud (*.atlassian.net) → API Token via Browser"
echo "    - Server (*.deutschepost.de, *.dhl.com) → PAT aus Profil"
echo ""
read -p "Instanz-URL: " ATLASSIAN_INSTANCE

if [ -z "$ATLASSIAN_INSTANCE" ]; then
    echo -e "${RED}❌ Keine Instanz angegeben${NC}"
    exit 1
fi

# Strip protocol if provided
ATLASSIAN_INSTANCE="${ATLASSIAN_INSTANCE#https://}"
ATLASSIAN_INSTANCE="${ATLASSIAN_INSTANCE#http://}"
ATLASSIAN_INSTANCE="${ATLASSIAN_INSTANCE%%/*}"

# Detect instance type
if [[ "$ATLASSIAN_INSTANCE" == *"atlassian.net"* ]]; then
    INSTANCE_TYPE="cloud"
    TOKEN_URL="https://id.atlassian.com/manage-profile/security/api-tokens"
    echo -e "${GREEN}☁️  Cloud-Instanz erkannt${NC}"
else
    INSTANCE_TYPE="server"
    TOKEN_URL="https://$ATLASSIAN_INSTANCE/plugins/servlet/de.resolution.apitokenauth/admin"
    echo -e "${GREEN}🏢 Server-Instanz erkannt${NC}"
fi

echo ""

# Step 1: VPN Check (silent, quick)
echo -e "${YELLOW}📡 VPN-Check...${NC}"
if ping -c 1 -W 2 "$ATLASSIAN_INSTANCE" &> /dev/null; then
    echo -e "${GREEN}✅ Verbindung zu $ATLASSIAN_INSTANCE OK${NC}"
else
    echo -e "${RED}❌ $ATLASSIAN_INSTANCE nicht erreichbar!${NC}"
    echo ""
    echo "Bitte:"
    echo "  1. VPN verbinden (falls Server-Instanz)"
    echo "  2. URL pruefen"
    echo "  3. Dieses Script erneut starten"
    exit 1
fi

echo ""

# Step 2: Check for existing config
if [ -f "$MCP_CONFIG" ] && grep -q "atlassian" "$MCP_CONFIG" 2>/dev/null; then
    echo -e "${YELLOW}⚠️  Atlassian bereits konfiguriert${NC}"
    echo ""
    read -p "Neu konfigurieren? [j/n] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[JjYy]$ ]]; then
        echo "Abgebrochen."
        exit 0
    fi
fi

echo ""

# Step 3: Get Email
echo -e "${BLUE}📧 Atlassian E-Mail${NC}"
read -p "Deine DHL E-Mail: " ATLASSIAN_EMAIL

if [[ ! "$ATLASSIAN_EMAIL" =~ @.*\. ]]; then
    echo -e "${RED}❌ Ungültige E-Mail${NC}"
    exit 1
fi

echo ""

# Step 4: Open Browser for Token Creation
echo -e "${BLUE}🔐 API Token erstellen${NC}"
echo ""
echo "Browser oeffnet sich jetzt automatisch..."
echo ""
if [ "$INSTANCE_TYPE" = "cloud" ]; then
    echo -e "${YELLOW}Bitte im Browser:${NC}"
    echo "  1. Bei Atlassian einloggen (falls noetig)"
    echo "  2. 'Create API token' klicken"
    echo "  3. Name: 'DexHub MCP' eingeben"
    echo "  4. Token kopieren"
else
    echo -e "${YELLOW}Bitte im Browser (Server-Instanz):${NC}"
    echo "  1. Einloggen bei $ATLASSIAN_INSTANCE"
    echo "  2. Profil > Personal Access Tokens"
    echo "  3. 'Create token' > Name: 'DexHub MCP'"
    echo "  4. Token kopieren"
fi
echo ""

# Open browser automatically
open_browser "$TOKEN_URL"

echo ""
echo -e "${YELLOW}Token hier einfügen:${NC}"
read -sp "API Token: " ATLASSIAN_TOKEN
echo ""

if [ -z "$ATLASSIAN_TOKEN" ]; then
    echo -e "${RED}❌ Kein Token eingegeben${NC}"
    exit 1
fi

echo ""

# Step 5: Verify Token
echo -e "${YELLOW}🔍 Token verifizieren...${NC}"

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
    -u "$ATLASSIAN_EMAIL:$ATLASSIAN_TOKEN" \
    "https://$ATLASSIAN_INSTANCE/wiki/rest/api/space?limit=1" 2>/dev/null || echo "000")

if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✅ Token gültig!${NC}"
elif [ "$HTTP_CODE" = "401" ]; then
    echo -e "${RED}❌ Token ungültig (401 Unauthorized)${NC}"
    echo "Bitte Token prüfen und erneut versuchen."
    exit 1
else
    echo -e "${YELLOW}⚠️  Konnte Token nicht verifizieren (HTTP $HTTP_CODE)${NC}"
    echo "Fahre trotzdem fort..."
fi

echo ""

# Step 6: Write MCP Config
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
    "atlassian-dhl": {
      "command": "npx",
      "args": ["-y", "@anthropic/mcp-remote@latest", "https://mcp.atlassian.com/v1/sse"],
      "env": {
        "ATLASSIAN_SITE": "https://$ATLASSIAN_INSTANCE",
        "ATLASSIAN_USER_EMAIL": "$ATLASSIAN_EMAIL",
        "ATLASSIAN_API_TOKEN": "$ATLASSIAN_TOKEN"
      }
    }
  }
}
EOF

echo -e "${GREEN}✅ Config erstellt: $MCP_CONFIG${NC}"

echo ""

# Step 7: Update DexHub Config
CONFIG_FILE="$SCRIPT_DIR/../../../_cfg/config.yaml"

if [ -f "$CONFIG_FILE" ]; then
    if ! grep -q "atlassian:" "$CONFIG_FILE" 2>/dev/null; then
        cat >> "$CONFIG_FILE" << EOF

# Atlassian MCP Integration (EA-1.1)
mcp_integrations:
  atlassian:
    enabled: true
    auto_configured: true
    instance: "$ATLASSIAN_INSTANCE"
    user_email: "$ATLASSIAN_EMAIL"
EOF
        echo -e "${GREEN}✅ DexHub Config aktualisiert${NC}"
    fi
fi

echo ""

# Step 8: Done!
echo -e "${GREEN}✅ Setup komplett!${NC}"
echo ""
echo -e "${BLUE}Nächste Schritte:${NC}"
echo "  1. VS Code neustarten"
echo "  2. Copilot Chat öffnen"
echo "  3. Testen: 'Get Jira ticket PS-12345'"
echo ""
echo -e "${GREEN}🎉 Fertig! Atlassian ist jetzt verbunden.${NC}"
echo ""
