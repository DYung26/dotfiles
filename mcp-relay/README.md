# MCP Relay — paused

MCP Relay is a legacy, VPS-only Codespaces registry/control and Cloudflare failover project. It is not an Arch or Omarchy service.

Do not enable `mcp-relay.service` or `mcp-relay-watcher.timer` until the remaining deployment work is complete:

- The local `~/.config/mcp-relay/env` file is absent.
- Its example defaults to port `12010`, which is currently occupied by the active MetaMCP Ops service.
- The watcher environment still requires deployment-specific remote URL and SSH identity values.
- The project checklist still defers its authentication layer and end-to-end failover validation.

The server unit now checks for its local environment file and uses restart-on-failure if configured. The watcher remains a true `Type=oneshot` job and checks for its separate watcher environment; its timer intentionally remains disabled.
