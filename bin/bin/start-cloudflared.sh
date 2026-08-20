#!/usr/bin/env bash
set -euo pipefail

: "${CLOUDFLARED_CREDENTIALS_FILE:?CLOUDFLARED_CREDENTIALS_FILE must be set}"

CONFIG_TEMPLATE="${HOME}/.cloudflared/config.yml"
CONFIG_RENDERED="${HOME}/.cloudflared/config.yml.rendered"

envsubst < "${CONFIG_TEMPLATE}" > "${CONFIG_RENDERED}"
exec cloudflared tunnel --config "${CONFIG_RENDERED}" run
