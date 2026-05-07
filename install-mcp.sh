#!/bin/bash
# Installs all MCP servers from mcp.json into Claude Code at user scope.
# Run after cloning: ./install-mcp.sh

set -e

echo "Installing Claude Code MCP servers..."

# stdio servers
claude mcp add -s user igniteui-cli -- npx -y igniteui-cli mcp
echo "  + igniteui-cli"

claude mcp add -s user igniteui-theming -- npx -y igniteui-theming igniteui-theming-mcp
echo "  + igniteui-theming"

# http servers
claude mcp add --transport http -s user dhtmlx-mcp https://docs.dhtmlx.com/mcp
echo "  + dhtmlx-mcp"

echo ""
echo "Done. Restart Claude Code to activate."
