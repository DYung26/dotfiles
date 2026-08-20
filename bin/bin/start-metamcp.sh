#!/usr/bin/env bash
set -euo pipefail

# Brings up the MetaMCP docker compose stack on codespace start. Idempotent
# — `docker compose up -d` is a no-op if containers are already running and
# healthy, so this is safe to call on every postStartCommand run, not just
# the first.

METAMCP_DIR="/workspaces/metamcp"

if [ ! -d "${METAMCP_DIR}" ]; then
  echo "start-metamcp.sh: ${METAMCP_DIR} not found, skipping" >&2
  exit 0
fi

if [ ! -f "${METAMCP_DIR}/.env" ]; then
  echo "start-metamcp.sh: ${METAMCP_DIR}/.env not found, skipping MetaMCP start" >&2
  exit 0
fi

if [ ! -f "${METAMCP_DIR}/docker-compose.override.yml" ]; then
  echo "start-metamcp.sh: ${METAMCP_DIR}/docker-compose.override.yml not found, skipping MetaMCP start" >&2
  exit 0
fi

cd "${METAMCP_DIR}"
docker compose up -d
