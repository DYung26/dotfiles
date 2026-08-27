#!/usr/bin/env bash
# postStartCommand for codespaces. Just calls the existing, already
# machine-agnostic start-mcp.sh / start-cloudflared.sh directly —
# backgrounded with a pgrep guard, since there's no systemd here to
# supervise them the way mcp.service / cloudflared-mcp.service do on
# archlinux. No new "background" variants of those scripts; this is the
# only place the backgrounding logic needs to live.

# shellcheck disable=SC1090
set -a
source ~/.config/mcp/env 2>/dev/null || true
set +a

mkdir -p /tmp/mcp

{
  echo "post-start.sh: $(date -u +%FT%TZ)"
  if [ -f "${HOME}/.config/mcp/env" ]; then
    echo "post-start.sh: found ${HOME}/.config/mcp/env"
  else
    echo "post-start.sh: MISSING ${HOME}/.config/mcp/env — env vars below are unset/default"
  fi
  echo "post-start.sh: MCP_HOME=${MCP_HOME:-<unset>}"
  echo "post-start.sh: MCP_SERVERS_DIR=${MCP_SERVERS_DIR:-<unset>}"
  echo "post-start.sh: MCP_PORT=${MCP_PORT:-<unset>}"
  echo "post-start.sh: NODE_BIN=${NODE_BIN:-<unset>}"
  echo "post-start.sh: CLOUDFLARED_CREDENTIALS_FILE=${CLOUDFLARED_CREDENTIALS_FILE:-<unset>}"
  echo "post-start.sh: CLOUDFLARED_TUNNEL_NAME=${CLOUDFLARED_TUNNEL_NAME:-<unset>}"
  echo "post-start.sh: CLOUDFLARED_HOSTNAME=${CLOUDFLARED_HOSTNAME:-<unset>}"
  echo "post-start.sh: CLOUDFLARED_SERVICE=${CLOUDFLARED_SERVICE:-<unset>}"
} > /tmp/mcp/post-start-env.log 2>&1

if ! pgrep -f "node dist/index.js streamableHttp" > /dev/null; then
  setsid nohup /workspaces/dotfiles/bin/bin/start-mcp.sh > /tmp/mcp/start-mcp.log 2>&1 < /dev/null &
fi

if ! pgrep -f "cloudflared tunnel" > /dev/null; then
  if [ -n "${CLOUDFLARED_TUNNEL_TOKEN:-}" ] || { [ -n "${CLOUDFLARED_CREDENTIALS_FILE:-}" ] && [ -f "${CLOUDFLARED_CREDENTIALS_FILE}" ]; }; then
    setsid nohup /workspaces/dotfiles/bin/bin/start-cloudflared.sh > /tmp/mcp/cloudflared.log 2>&1 < /dev/null &
  fi
fi

bash /workspaces/dotfiles/bin/bin/start-metamcp.sh

# Syncthing: duplicated here (not moved) from postAttachCommand in
# devcontainer.json, which only fires in VS Code clients — it's a
# client-side hook, not something the remote container runs, so it never
# fires for non-VS Code clients (e.g. gh cs ssh) and never appears in
# creation.log even when it does run. postStartCommand always runs
# remotely regardless of client, so this guarantees syncthing comes up
# either way; the pgrep guard makes running it from both hooks a no-op
# when it's already up.
mkdir -p /tmp/mcp
if ! pgrep -x syncthing > /dev/null; then
  setsid nohup syncthing --no-browser > /tmp/mcp/syncthing.log 2>&1 < /dev/null &
fi
