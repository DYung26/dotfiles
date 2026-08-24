#!/usr/bin/env bash
set -euo pipefail

: "${MCP_RELAY_DIR:?MCP_RELAY_DIR must be set (e.g. /home/dyung/Projects/mcp-relay)}"
: "${MCP_RELAY_PORT:=12010}"
: "${MCP_RELAY_REGISTRY_PATH:=${MCP_RELAY_DIR}/registry.json}"
: "${NODE_BIN:=node}"

cd "${MCP_RELAY_DIR}"
exec env PORT="${MCP_RELAY_PORT}" REGISTRY_PATH="${MCP_RELAY_REGISTRY_PATH}" "${NODE_BIN}" dist/index.js
