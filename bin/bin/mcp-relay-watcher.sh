#!/usr/bin/env bash
# mcp-relay watcher -- runs on ubuntu. Health-checks archlinux MetaMCP over
# a restricted SSH connection; on sustained failure, fails forward by
# rewriting CLOUDFLARED_SERVICE in ubuntu own cloudflared env file (the
# same file start-cloudflared.sh envsubst renders) to point at ubuntu own
# local MetaMCP instead, then reloads cloudflared. Never fails back
# automatically -- see the pin file below.
#
# Note: CLOUDFLARED_ENV_FILE is NOT the filesystem-MCP env -- ubuntu does
# not run that server. It is whichever env file ubuntu cloudflared-mcp.service
# sources CLOUDFLARED_SERVICE/CLOUDFLARED_HOSTNAME/etc. from; on most
# machines in this setup that is ~/.config/mcp/env, but on ubuntu it may be a
# dedicated file if the filesystem-MCP env was never set up there at all.
#
# Invoked on an interval by mcp-relay-watcher.timer (systemd). Each run is a
# single check, not a long-lived loop -- the timer supplies the interval.

set -euo pipefail

: "${CLOUDFLARED_ENV_FILE:?CLOUDFLARED_ENV_FILE must be set - the env file ubuntu cloudflared-mcp.service sources CLOUDFLARED_SERVICE from (e.g. /home/ubuntu/.config/mcp/env or a dedicated file)}"
: "${WATCHER_STATE_DIR:?WATCHER_STATE_DIR must be set (e.g. /home/ubuntu/.local/state/mcp-relay)}"
: "${ARCHLINUX_SSH_HOST:?ARCHLINUX_SSH_HOST must be set (e.g. archlinux or a Tailscale hostname/IP)}"
: "${ARCHLINUX_SSH_USER:?ARCHLINUX_SSH_USER must be set}"
: "${ARCHLINUX_SSH_KEY:?ARCHLINUX_SSH_KEY must be set (path to the dedicated, forced-command-restricted key)}"
: "${LOCAL_SERVICE_URL:?LOCAL_SERVICE_URL must be set (ubuntu own MetaMCP, e.g. http://localhost:12008)}"
: "${REMOTE_SERVICE_URL:?REMOTE_SERVICE_URL must be set (archlinux MetaMCP, reached over the private network, e.g. http://<tailscale-ip>:12008)}"
: "${FAILURE_THRESHOLD:=3}"
: "${CLOUDFLARED_UNIT:=cloudflared-mcp.service}"

FAILCOUNT_FILE="${WATCHER_STATE_DIR}/failcount"
PIN_FILE="${WATCHER_STATE_DIR}/pin"
LOG_TAG="mcp-relay-watcher"

mkdir -p "${WATCHER_STATE_DIR}"
[ -f "${FAILCOUNT_FILE}" ] || echo 0 > "${FAILCOUNT_FILE}"

log() {
  logger -t "${LOG_TAG}" -- "$*"
  echo "$*"
}

# The forced command on archlinux authorized_keys entry ignores whatever
# we pass here -- this string is a placeholder, not something that executes.
# Exit code 0 = OK reply, anything else = unreachable or unhealthy.
check_archlinux() {
  ssh -i "${ARCHLINUX_SSH_KEY}" \
      -o ConnectTimeout=5 \
      -o BatchMode=yes \
      -o StrictHostKeyChecking=accept-new \
      "${ARCHLINUX_SSH_USER}@${ARCHLINUX_SSH_HOST}" \
      "healthcheck" \
      2>/dev/null | grep -qx "OK"
}

get_current_service() {
  grep -E "^CLOUDFLARED_SERVICE=" "${CLOUDFLARED_ENV_FILE}" | tail -n1 | cut -d= -f2-
}

# Atomic, idempotent rewrite of CLOUDFLARED_SERVICE in the env file. Only
# touches that one line; leaves everything else in the file untouched.
set_service() {
  local new_url="$1"
  local tmp
  tmp="$(mktemp "${CLOUDFLARED_ENV_FILE}.XXXXXX")"
  local found=0
  while IFS= read -r line; do
    if [[ "${line}" == CLOUDFLARED_SERVICE=* ]]; then
      echo "CLOUDFLARED_SERVICE=${new_url}"
      found=1
    else
      echo "${line}"
    fi
  done < "${CLOUDFLARED_ENV_FILE}" > "${tmp}"
  if [ "${found}" -eq 0 ]; then
    echo "CLOUDFLARED_SERVICE=${new_url}" >> "${tmp}"
  fi
  mv "${tmp}" "${CLOUDFLARED_ENV_FILE}"
}

reload_cloudflared() {
  local rendered="${HOME}/.cloudflared/config.yml.rendered"
  # Render first so a validate failure is caught before we touch the live
  # tunnel process at all.
  set -a
  # shellcheck disable=SC1090
  source "${CLOUDFLARED_ENV_FILE}"
  set +a
  envsubst < "${HOME}/.cloudflared/config.yml" > "${rendered}"

  if ! cloudflared tunnel --config "${rendered}" ingress validate; then
    log "ERROR: rendered cloudflared config failed validation, aborting reload"
    return 1
  fi

  systemctl --user restart "${CLOUDFLARED_UNIT}"
}

current_service="$(get_current_service)"
is_pinned=false
[ -f "${PIN_FILE}" ] && is_pinned=true

if check_archlinux; then
  echo 0 > "${FAILCOUNT_FILE}"

  # Recovery only matters if we would have actually failed over. A manual
  # pin means: stay on remote (ubuntu) no matter what archlinux does, until
  # a human clears it -- this script never removes the pin itself.
  if [ "${current_service}" = "${LOCAL_SERVICE_URL}" ] && [ "${is_pinned}" = false ]; then
    log "archlinux is healthy but service is already local -- nothing to do"
  fi
  exit 0
fi

failcount="$(cat "${FAILCOUNT_FILE}")"
failcount=$((failcount + 1))
echo "${failcount}" > "${FAILCOUNT_FILE}"
log "archlinux health check failed (${failcount}/${FAILURE_THRESHOLD})"

if [ "${failcount}" -lt "${FAILURE_THRESHOLD}" ]; then
  exit 0
fi

if [ "${is_pinned}" = true ]; then
  log "already pinned to remote, no switch needed"
  exit 0
fi

if [ "${current_service}" = "${REMOTE_SERVICE_URL}" ]; then
  log "already on remote (ubuntu), no switch needed"
  exit 0
fi

log "failure threshold reached -- failing forward to remote (ubuntu)"
set_service "${LOCAL_SERVICE_URL}"

if reload_cloudflared; then
  log "failover complete: now serving from ${LOCAL_SERVICE_URL}"
else
  log "ERROR: failover config reload failed -- reverting env change"
  set_service "${REMOTE_SERVICE_URL}"
  exit 1
fi
