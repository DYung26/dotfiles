#!/usr/bin/env bash
set -euo pipefail

: "${MCP_HOME:?MCP_HOME must be set (e.g. /home/dyung or /workspaces)}"
: "${MCP_SERVERS_DIR:?MCP_SERVERS_DIR must be set (e.g. ${MCP_HOME}/Projects/mcp-servers/src/filesystem-remote on archlinux, ${MCP_HOME}/mcp-servers/src/filesystem-remote on codespaces)}"
: "${MCP_PORT:=3333}"
: "${NODE_BIN:=node}"

cd "${MCP_SERVERS_DIR}"
exec env PORT="${MCP_PORT}" "${NODE_BIN}" dist/index.js streamableHttp "${MCP_HOME}"
