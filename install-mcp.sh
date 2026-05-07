#!/bin/bash
# Installs all MCP servers from mcp.json into Claude Code at user scope.
# Run after cloning: ./install-mcp.sh

echo "Installing Claude Code MCP servers..."

add_mcp() {
  claude mcp remove -s user "$1" 2>/dev/null || true
  claude mcp add "$@" 2>/dev/null
  echo "  + $1"
}

# stdio servers
add_mcp igniteui-cli -s user -- npx -y igniteui-cli mcp
add_mcp igniteui-theming -s user -- npx -y igniteui-theming igniteui-theming-mcp

# http servers
add_mcp dhtmlx-mcp --transport http -s user https://docs.dhtmlx.com/mcp

echo ""
echo "Done. Restart Claude Code to activate."
