#!/usr/bin/env bash
# postStartCommand for codespaces. Just calls the existing, already
# machine-agnostic start-mcp.sh / start-cloudflared.sh directly —
# backgrounded with a pgrep guard, since there's no systemd here to
# supervise them the way mcp.service / cloudflared-mcp.service do on
# archlinux. No new "background" variants of those scripts; this is the
# only place the backgrounding logic needs to live.

# shellcheck disable=SC1090
source ~/.config/mcp/env 2>/dev/null || true

mkdir -p /tmp/mcp

if ! pgrep -f "node dist/index.js streamableHttp" > /dev/null; then
  nohup /workspaces/dotfiles/bin/bin/start-mcp.sh > /tmp/mcp/start-mcp.log 2>&1 &
fi

if ! pgrep -f "cloudflared tunnel" > /dev/null; then
  if [ -n "${CLOUDFLARED_CREDENTIALS_FILE:-}" ] && [ -f "${CLOUDFLARED_CREDENTIALS_FILE}" ]; then
    nohup /workspaces/dotfiles/bin/bin/start-cloudflared.sh > /tmp/mcp/cloudflared.log 2>&1 &
  fi
fi

bash /workspaces/dotfiles/bin/bin/start-metamcp.sh
