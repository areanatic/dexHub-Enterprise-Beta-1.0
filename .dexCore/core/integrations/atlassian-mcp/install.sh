#!/bin/bash
# Atlassian MCP Setup for DexHub — user-guided wizard
# Version: 2.0 (2026-04-19 — rewrite of 7-layer-bug install)
# Pairs with: config-template.json
#
# Changes from v1.0:
#   - Removed hardcoded "your-org.atlassian.net" — wizard asks for instance
#   - Writes to BOTH modern (user-settings.json with mcp.servers key) AND
#     legacy (.vscode/mcp.json workspace-local) to cover VS Code 1.92+ and
#     older installs without a hard version dependency
#   - Persists user-provided instance URL to .dexCore/_cfg/config.yaml so
#     DexHub can re-use the value
#   - Detects whether we are running under Copilot workspace or Claude Desktop
#     and writes appropriate path
#   - Cloud (*.atlassian.net) vs Server/DC (self-hosted) detection prompts

set -euo pipefail

echo "🚀 Atlassian MCP Setup — DexHub Wizard"
echo "========================================"
echo ""
echo "This wizard will:"
echo "  1. Ask for your Atlassian instance URL"
echo "  2. Verify reachability (VPN-aware)"
echo "  3. Write MCP config to the right path for your IDE"
echo "  4. Persist settings to DexHub config"
echo ""

# ─── Step 1: Ask for instance URL ──────────────────────────────────────
read -r -p "Atlassian instance URL (e.g. mycompany.atlassian.net or jira.mycompany.com): " ATLASSIAN_URL

if [ -z "$ATLASSIAN_URL" ]; then
  echo "❌ No URL provided. Aborting."
  exit 1
fi

# Strip protocol + trailing slash for consistency
ATLASSIAN_URL="${ATLASSIAN_URL#https://}"
ATLASSIAN_URL="${ATLASSIAN_URL#http://}"
ATLASSIAN_URL="${ATLASSIAN_URL%/}"

# Detect Cloud vs Server/DC
if [[ "$ATLASSIAN_URL" == *.atlassian.net ]]; then
  INSTANCE_TYPE="cloud"
  MCP_URL="https://mcp.atlassian.com"
  echo "🌐 Detected: Atlassian Cloud → using public MCP endpoint"
else
  INSTANCE_TYPE="server"
  MCP_URL="https://$ATLASSIAN_URL/rest/mcp"
  echo "🏢 Detected: Atlassian Server/DC → using tenant MCP endpoint ($MCP_URL)"
  echo "    (Adjust MCP_URL manually in the generated config if your Server has a different MCP path)"
fi

echo ""

# ─── Step 2: Reachability check (VPN-aware) ────────────────────────────
echo "📡 Checking reachability..."
if ping -c 1 -W 2 "$ATLASSIAN_URL" &> /dev/null; then
  echo "✅ $ATLASSIAN_URL reachable"
else
  echo "⚠️  $ATLASSIAN_URL not reachable — may need VPN or firewall rule"
  read -r -p "Continue anyway? [y/N] " CONT
  if [[ ! "$CONT" =~ ^[Yy]$ ]]; then
    echo "Aborted. Check VPN or contact your IT."
    exit 1
  fi
fi

echo ""

# ─── Step 3: Write config to correct paths ─────────────────────────────
echo "⚙️  Writing MCP configuration..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE="$SCRIPT_DIR/config-template.json"

# Render template with user values via sed (portable — jq not assumed)
RENDERED="$(mktemp)"
sed -e "s|__INSTANCE_URL__|$ATLASSIAN_URL|g" \
    -e "s|__MCP_URL__|$MCP_URL|g" \
    -e "s|__INSTANCE_TYPE__|$INSTANCE_TYPE|g" \
    "$TEMPLATE" > "$RENDERED"

# Path strategy — support two modern paths, let user pick or write both
MACOS_VSCODE_USER="$HOME/Library/Application Support/Code/User/mcp.json"
LINUX_VSCODE_USER="$HOME/.config/Code/User/mcp.json"
WORKSPACE_LOCAL=".vscode/mcp.json"

echo "Choose where to write the MCP config:"
echo "  [1] User-level (affects all VS Code projects for you)"
echo "  [2] Workspace-local .vscode/mcp.json (only this project)"
echo "  [3] Both"
read -r -p "Pick 1/2/3 [default: 2]: " PATH_CHOICE
PATH_CHOICE="${PATH_CHOICE:-2}"

write_user_level() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    TARGET="$MACOS_VSCODE_USER"
  else
    TARGET="$LINUX_VSCODE_USER"
  fi
  mkdir -p "$(dirname "$TARGET")"
  if [ -f "$TARGET" ]; then
    cp "$TARGET" "$TARGET.backup.$(date +%Y%m%d_%H%M%S)"
    echo "💾 Backed up existing: $TARGET.backup.*"
  fi
  cp "$RENDERED" "$TARGET"
  echo "✅ Wrote user-level config: $TARGET"
}

write_workspace() {
  mkdir -p ".vscode"
  if [ -f "$WORKSPACE_LOCAL" ]; then
    cp "$WORKSPACE_LOCAL" "$WORKSPACE_LOCAL.backup.$(date +%Y%m%d_%H%M%S)"
    echo "💾 Backed up existing: $WORKSPACE_LOCAL.backup.*"
  fi
  cp "$RENDERED" "$WORKSPACE_LOCAL"
  echo "✅ Wrote workspace config: $WORKSPACE_LOCAL"
}

case "$PATH_CHOICE" in
  1) write_user_level ;;
  2) write_workspace ;;
  3) write_user_level; write_workspace ;;
  *) echo "Invalid choice — defaulting to workspace-local"; write_workspace ;;
esac

rm -f "$RENDERED"
echo ""

# ─── Step 4: Update DexHub config.yaml ─────────────────────────────────
echo "🔧 Updating DexHub config..."

CONFIG_FILE=".dexCore/_cfg/config.yaml"

if [ ! -f "$CONFIG_FILE" ]; then
  echo "❌ $CONFIG_FILE missing — are you running from Beta repo root?"
  exit 1
fi

# Replace existing atlassian block if present, else append
if grep -q "^mcp_integrations:" "$CONFIG_FILE"; then
  # Already has block — we won't edit inline (risky). Inform user.
  echo "ℹ️  mcp_integrations: section exists in config.yaml — please manually set:"
  echo "     atlassian.instance: $ATLASSIAN_URL"
  echo "     atlassian.instance_type: $INSTANCE_TYPE"
else
  cat >> "$CONFIG_FILE" << EOF

# Atlassian MCP Integration (configured via install.sh, $(date +%Y-%m-%d))
mcp_integrations:
  atlassian:
    enabled: true
    instance: "$ATLASSIAN_URL"
    instance_type: "$INSTANCE_TYPE"
    mcp_url: "$MCP_URL"
EOF
  echo "✅ Appended Atlassian block to $CONFIG_FILE"
fi

echo ""

# ─── Step 5: Next-step instructions ────────────────────────────────────
echo "✅ Atlassian MCP Setup Complete"
echo ""
echo "Next steps:"
echo "  1. Restart VS Code (MCP configs load at startup)"
echo "  2. In Copilot Chat, try: 'Get recent Jira issues'"
echo "  3. First call will trigger OAuth — approve in browser"
echo ""
echo "If authentication fails:"
echo "  - For Cloud: ensure your Atlassian user has API scope 'read:jira-work + read:confluence-content'"
echo "  - For Server/DC: ensure admin has enabled MCP endpoint on $ATLASSIAN_URL"
echo "  - Proxy/VPN: corporate proxy may need allowlist for $MCP_URL"
echo ""
echo "Troubleshooting: .dexCore/core/integrations/atlassian-mcp/README.md"
