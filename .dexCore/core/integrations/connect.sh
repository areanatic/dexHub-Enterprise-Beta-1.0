#!/bin/bash
# DexHub Integration Connector
# Version: 1.0 (FEATURE-003)
#
# Unified entry point for all MCP integrations
# Called by the DexHub agent for automatic setup
#
# Usage:
#   connect.sh atlassian    # Connect to Atlassian (Jira/Confluence)
#   connect.sh github       # Connect to GitHub Enterprise
#   connect.sh all          # Connect to all available integrations

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

show_header() {
    echo ""
    echo -e "${BLUE}╔═══════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║   ${GREEN}DexHub Integration Connector${BLUE}        ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════╝${NC}"
    echo ""
}

show_usage() {
    echo "Usage: connect.sh <integration>"
    echo ""
    echo "Available integrations:"
    echo "  atlassian    Connect to Atlassian (Jira/Confluence)"
    echo "  github       Connect to GitHub Enterprise"
    echo "  figma        Connect to Figma (Design Files & Tokens)"
    echo "  all          Connect to all integrations"
    echo ""
    echo "Example:"
    echo "  ./connect.sh figma"
    echo ""
}

connect_atlassian() {
    echo -e "${BLUE}Connecting to Atlassian...${NC}"
    echo ""
    if [ -f "$SCRIPT_DIR/atlassian-mcp/auto-auth.sh" ]; then
        "$SCRIPT_DIR/atlassian-mcp/auto-auth.sh"
    else
        echo -e "${RED}❌ Atlassian integration not found${NC}"
        exit 1
    fi
}

connect_github() {
    echo -e "${BLUE}Connecting to GitHub Enterprise...${NC}"
    echo ""
    if [ -f "$SCRIPT_DIR/github-mcp/auto-auth.sh" ]; then
        "$SCRIPT_DIR/github-mcp/auto-auth.sh"
    else
        echo -e "${RED}❌ GitHub integration not found${NC}"
        exit 1
    fi
}

connect_figma() {
    echo -e "${BLUE}Connecting to Figma...${NC}"
    echo ""
    if [ -f "$SCRIPT_DIR/figma-mcp/install.sh" ]; then
        "$SCRIPT_DIR/figma-mcp/install.sh"
    else
        echo -e "${RED}❌ Figma integration not found${NC}"
        exit 1
    fi
}

connect_all() {
    echo -e "${BLUE}Connecting to all integrations...${NC}"
    echo ""

    echo -e "${YELLOW}[1/3] Atlassian${NC}"
    connect_atlassian

    echo ""
    echo -e "${YELLOW}[2/3] GitHub${NC}"
    connect_github

    echo ""
    echo -e "${YELLOW}[3/3] Figma${NC}"
    connect_figma

    echo ""
    echo -e "${GREEN}✅ All integrations connected!${NC}"
}

# Main
show_header

if [ $# -eq 0 ]; then
    show_usage
    exit 0
fi

case "$1" in
    atlassian|jira|confluence)
        connect_atlassian
        ;;
    github|git)
        connect_github
        ;;
    figma|design)
        connect_figma
        ;;
    all)
        connect_all
        ;;
    -h|--help|help)
        show_usage
        ;;
    *)
        echo -e "${RED}❌ Unknown integration: $1${NC}"
        echo ""
        show_usage
        exit 1
        ;;
esac
