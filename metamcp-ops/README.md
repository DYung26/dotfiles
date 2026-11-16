# MetaMCP Ops

VPS-only MCP service for MetaMCP operations.

## Configuration

The local file `~/.config/metamcp-ops/env` is intentionally ignored by Git and Syncthing. It contains the API key and deployment-specific host, port, and trusted-client settings. Keep it at mode `600`; never commit or print its values.

The tracked `env.example` is a template only. On the VPS, the service binds to the Docker bridge host address (`172.17.0.1`) so the MetaMCP container can reach it. Keep `METAMCP_OPS_TRUSTED_IPS` restricted to the intended container/client address.

## Service

The unit is tracked in `systemd/.config/systemd/user/metamcp-ops.service` and installed by Stow. It is enabled on the VPS, starts at `default.target`, and uses `Restart=on-failure`.

The launcher in `systemd/bin/run-metamcp-ops` resolves the Grove-managed project path and Node binary at runtime. On hosts without the local environment file, the unit is skipped by `ConditionPathExists`.
