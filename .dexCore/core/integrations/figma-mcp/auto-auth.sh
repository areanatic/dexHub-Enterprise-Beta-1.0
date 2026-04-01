#!/bin/bash
# Figma MCP Auto-Authentication for DexHub
# Version: 1.0
#
# Two auth modes:
#   1. OAuth (default) — Browser opens, user clicks "Allow", done.
#   2. Personal Access Token (fallback) — User pastes token manually.
#
# The official Figma MCP server (https://mcp.figma.com/mcp) uses OAuth.
# VS Code handles the OAuth redirect automatically on restart.
# This script is for manual setup or when OAuth redirect fails.
#
# Usage:
#   bash .dexCore/core/integrations/figma-mcp/auto-auth.sh
#   bash .dexCore/core/integrations/figma-mcp/auto-auth.sh --token

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
FIGMA_API_URL="https://api.figma.com"
TOKEN_URL="https://www.figma.com/developers/api#personal-tokens"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USER_MCP_CONFIG="$HOME/Library/Application Support/Code/User/mcp.json"
LEGACY_MCP_CONFIG="$HOME/.vscode/mcp-servers.json"

# Function to open browser cross-platform
open_browser() {
    local url="$1"
    case "$(uname -s)" in
        Darwin)  open "$url" ;;
        Linux)   xdg-open "$url" 2>/dev/null || sensible-browser "$url" 2>/dev/null || echo -e "${YELLOW}Open manually: $url${NC}" ;;
        MINGW*|MSYS*|CYGWIN*)  start "$url" ;;
        *)       echo -e "${YELLOW}Open manually: $url${NC}" ;;
    esac
}

show_header() {
    echo ""
    echo -e "${BLUE}╔═══════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║   ${GREEN}Figma MCP Authentication${BLUE}            ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════╝${NC}"
    echo ""
}

# ─────────────────────────────────────────────
# MODE 1: OAuth (Default)
# ─────────────────────────────────────────────
auth_oauth() {
    echo -e "${BLUE}🔐 OAuth Authentication${NC}"
    echo ""
    echo "The official Figma MCP server uses OAuth."
    echo "VS Code handles this automatically on restart."
    echo ""
    echo -e "${YELLOW}Steps:${NC}"
    echo "  1. Ensure Figma MCP is in your VS Code config"
    echo "  2. Restart VS Code"
    echo "  3. Open Copilot Chat and try a Figma command"
    echo "  4. Browser opens → Log in to Figma → Click 'Allow'"
    echo "  5. Done! OAuth token is stored by VS Code."
    echo ""

    # Check if config exists
    if { [ -f "$USER_MCP_CONFIG" ] && grep -q '"figma"' "$USER_MCP_CONFIG" 2>/dev/null; } || \
       { [ -f "$LEGACY_MCP_CONFIG" ] && grep -q '"figma"' "$LEGACY_MCP_CONFIG" 2>/dev/null; }; then
        echo -e "${GREEN}✅ Figma MCP config found${NC}"
    else
        echo -e "${YELLOW}⚠️  Figma MCP not in config — running install first...${NC}"
        echo ""
        bash "$SCRIPT_DIR/install.sh"
    fi

    echo ""
    echo ""
    echo -e "${GREEN}✅ Open VS Code Chat in Agent mode and test:${NC}"
    echo '   "#get_design_context"'
    echo '   "Analyze this Figma design: https://www.figma.com/design/..."'
    echo ""
}

# ─────────────────────────────────────────────
# MODE 2: Personal Access Token (Fallback)
# ─────────────────────────────────────────────
auth_token() {
    echo -e "${BLUE}🔑 Personal Access Token Authentication${NC}"
    echo ""
    echo "Use this if OAuth redirect doesn't work in your environment."
    echo ""

    # Check existing
    if [ -f "$USER_MCP_CONFIG" ] && grep -q "FIGMA_API_TOKEN" "$USER_MCP_CONFIG" 2>/dev/null; then
        echo -e "${YELLOW}⚠️  Figma token already configured${NC}"
        read -p "Reconfigure? [y/n] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[YyJj]$ ]]; then
            echo "Cancelled."
            exit 0
        fi
    fi

    echo ""
    echo -e "${BLUE}Opening Figma token page...${NC}"
    echo ""
    echo -e "${YELLOW}In the browser:${NC}"
    echo "  1. Log in to Figma (if needed)"
    echo "  2. Scroll to 'Personal access tokens'"
    echo "  3. Click 'Generate new token'"
    echo "  4. Name: 'DexHub MCP'"
    echo "  5. Scopes: File Content (Read) — or select all Read scopes"
    echo "  6. Copy the token (starts with figd_)"
    echo ""

    open_browser "$TOKEN_URL"

    echo ""
    echo -e "${YELLOW}Paste your token:${NC}"
    read -sp "Figma API Token: " FIGMA_TOKEN
    echo ""

    if [ -z "$FIGMA_TOKEN" ]; then
        echo -e "${RED}❌ No token entered${NC}"
        exit 1
    fi

    echo ""

    # Verify token
    echo -e "${YELLOW}🔍 Verifying token...${NC}"

    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "X-FIGMA-TOKEN: $FIGMA_TOKEN" \
        "$FIGMA_API_URL/v1/me" 2>/dev/null || echo "000")

    if [ "$HTTP_CODE" = "200" ]; then
        # Get user name for confirmation
        USER_NAME=$(curl -s -H "X-FIGMA-TOKEN: $FIGMA_TOKEN" "$FIGMA_API_URL/v1/me" 2>/dev/null | \
            python3 -c "import sys,json; print(json.load(sys.stdin).get('email','unknown'))" 2>/dev/null || echo "verified")
        echo -e "${GREEN}✅ Token valid! ($USER_NAME)${NC}"
    elif [ "$HTTP_CODE" = "403" ]; then
        echo -e "${RED}❌ Token invalid (403 Forbidden)${NC}"
        echo "Please check the token and try again."
        exit 1
    else
        echo -e "${YELLOW}⚠️  Could not verify token (HTTP $HTTP_CODE)${NC}"
        echo "Continuing anyway..."
    fi

    echo ""

    # Write config with token (stdio mode via mcp-remote proxy)
    echo -e "${BLUE}⚙️  Writing MCP configuration...${NC}"

    mkdir -p "$(dirname "$USER_MCP_CONFIG")"

    if [ -f "$USER_MCP_CONFIG" ]; then
        cp "$USER_MCP_CONFIG" "$USER_MCP_CONFIG.backup.$(date +%Y%m%d_%H%M%S)"
    fi

    # Merge figma into existing config
    if [ -f "$USER_MCP_CONFIG" ] && command -v python3 &> /dev/null; then
        python3 -c "
import json
with open('$USER_MCP_CONFIG') as f:
    config = json.load(f)
config.setdefault('servers', {})['figma'] = {
    'type': 'http',
    'url': 'https://mcp.figma.com/mcp',
    'name': 'Figma',
    'description': 'Figma Design Files & Components via MCP',
    'enabled': True,
    'headers': {
        'Authorization': 'Bearer $FIGMA_TOKEN'
    }
}
with open('$USER_MCP_CONFIG', 'w') as f:
    json.dump(config, f, indent=2)
"
                echo -e "${GREEN}✅ Config updated: $USER_MCP_CONFIG${NC}"
    else
                cat > "$USER_MCP_CONFIG" << EOF
{
    "servers": {
    "figma": {
      "type": "http",
      "url": "https://mcp.figma.com/mcp",
      "name": "Figma",
      "description": "Figma Design Files & Components via MCP",
      "enabled": true,
      "headers": {
        "Authorization": "Bearer $FIGMA_TOKEN"
      }
    }
  }
}
EOF
    echo -e "${GREEN}✅ Config created: $USER_MCP_CONFIG${NC}"
    fi

    echo ""
    echo -e "${GREEN}✅ Setup complete!${NC}"
    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    echo "  1. Restart VS Code"
    echo "  2. Open Copilot Chat"
    echo "  3. Test: 'Analyze this Figma design: <paste-link>'"
    echo ""
}

# ─────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────
show_header

if [ "$1" = "--token" ] || [ "$1" = "-t" ]; then
    auth_token
else
    echo "Choose authentication method:"
    echo ""
    echo -e "  ${GREEN}1)${NC} OAuth (recommended) — Browser login, automatic"
    echo -e "  ${BLUE}2)${NC} Personal Access Token — Manual, always works"
    echo ""
    read -p "Choice [1/2]: " -n 1 -r
    echo
    echo ""

    case "$REPLY" in
        2)
            auth_token
            ;;
        *)
            auth_oauth
            ;;
    esac
fi
