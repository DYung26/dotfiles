#!/usr/bin/env bash
set -euo pipefail
umask 077

: "${CLOUDFLARED_TUNNEL_TOKEN:?missing tunnel token}"
: "${CLOUDFLARED_CONFIG_TEMPLATE:?missing config template}"
: "${CLOUDFLARED_CONFIG_RENDERED:?missing rendered config path}"

STATE_DIR="${HOME}/.local/state/cloudflared"
TOKEN_FILE="${STATE_DIR}/omarchy-tunnel-token"

mkdir -p "${STATE_DIR}"
chmod 700 "${STATE_DIR}"
mkdir -p "$(dirname "${CLOUDFLARED_CONFIG_RENDERED}")"
envsubst < "${CLOUDFLARED_CONFIG_TEMPLATE}" > "${CLOUDFLARED_CONFIG_RENDERED}"

TOKEN_TEMP="$(mktemp "${TOKEN_FILE}.XXXXXX")"
trap 'rm -f "${TOKEN_TEMP}"' EXIT
printf '%s' "${CLOUDFLARED_TUNNEL_TOKEN}" > "${TOKEN_TEMP}"
chmod 600 "${TOKEN_TEMP}"
mv -f "${TOKEN_TEMP}" "${TOKEN_FILE}"
unset CLOUDFLARED_TUNNEL_TOKEN

exec cloudflared tunnel --config "${CLOUDFLARED_CONFIG_RENDERED}" run --token-file "${TOKEN_FILE}"
