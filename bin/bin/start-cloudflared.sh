#!/usr/bin/env bash
set -euo pipefail

if [ -n "${CLOUDFLARED_TUNNEL_TOKEN:-}" ]; then
  exec cloudflared tunnel run --token "${CLOUDFLARED_TUNNEL_TOKEN}"
fi

: "${CLOUDFLARED_CREDENTIALS_FILE:?CLOUDFLARED_CREDENTIALS_FILE must be set}"
: "${CLOUDFLARED_SERVICE:?CLOUDFLARED_SERVICE must be set}"

CONFIG_TEMPLATE="${HOME}/.cloudflared/config.yml"
CONFIG_RENDERED="${HOME}/.cloudflared/config.yml.rendered"

envsubst < "${CONFIG_TEMPLATE}" > "${CONFIG_RENDERED}"
exec cloudflared tunnel --config "${CONFIG_RENDERED}" --loglevel debug run
