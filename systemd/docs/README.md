# Unified systemd Stow package

All dotfiles-managed systemd units live in this package. Device differences are supplied by tracked environment profiles selected locally on each machine.

## Configuration layers

- systemd.env.common contains shared, non-sensitive defaults.
- systemd.env.arch, systemd.env.vps, and systemd.env.omarchy are version-controlled device profiles. Stow links all four tracked files into ~/.config/dotfiles/systemd.
- The local systemd.env selector is a symlink in the package configuration directory. The selector helper links it into ~/.config/dotfiles/systemd for systemd to read.
- systemd.secrets.env is a local mode-0600 file in the package configuration directory for secrets that must be read directly by systemd units. It is ignored by Git, Stow and Syncthing. The helper links it into ~/.config/dotfiles/systemd. Do not put application-owned credentials here when those applications already have dedicated secret files or secret stores.

Units load shared defaults first and the selected device profile second, so device values override shared defaults. Add the secrets file only to units that actually need its variables; do not expose every secret to every service. Existing app-specific secret files remain in their current locations. Workspace MCP OAuth credentials stay in `~/Services/workspace-mcp/.env`; its helper merges only selected device settings into that existing file, preserves credentials and unrelated keys, and enforces mode 0600.

## Stow

Install user units, helper scripts, and the tracked configuration profiles:

    stow --no-folding -t "$HOME" --ignore='^etc$' systemd

Select the device profile:

    select-device-config arch
    select-device-config vps
    select-device-config omarchy

Then reload systemd and enable only the units appropriate for that device. Stowing a unit does not enable it. The tracked env profiles are distributed through Git; the existing Syncthing *env* ignore rule remains in place.

Install system-level units only on machines that need them (currently the VPS):

    sudo stow --no-folding -t / --ignore='^[.]config$' --ignore='^bin$' --ignore='^[.]local$' --ignore='^system$' systemd

System-level units use explicit /home/dyung paths because %h in the system manager resolves in the manager's context, not to the User= account's home.

## Device activation

- Arch: enable EchoProfile under graphical-session.target; Playwright MCP, MCP services, Multica and applicable maintenance timers. MCP Relay and Pulse remain disabled until their missing configuration or socket conflict is resolved.
- Omarchy: EchoProfile, Cloudflared, MCP shell proxy and shared maintenance timer.
- VPS: EchoProfile and its VNC/WM/login stack, Playwright MCP endpoints, MT5, Agentation, Market Engine, GridWatch, Workspace MCP and applicable MCP services. MCP Relay remains disabled until its local environment is restored; the Hedging Dashboard API remains disabled until its backtest_engine import path is repaired.
- AiSP bridge: enable `aisp-bridge.service` for the user on the VPS. Its unit is tracked in this package; app-owned runtime configuration remains in `~/.config/aisp/bridge.env` (mode 0600), not in Dotfiles. The service binds to the Tailscale interface and does not require a user-managed bearer token.

The same unit files are deployed everywhere; only the selected device profile, optional local secrets, and enabled-unit links differ.

## Playwright MCP browser targets

Playwright MCP should attach to existing EchoProfile browsers through CDP wherever possible. This reuses the persistent profile and avoids per-session extension approval.

- VPS: `playwright-mcp.service` attaches to the VPS EchoProfile CDP endpoint and is exposed to MetaMCP on port 8931.
- Windows laptop: `playwright-mcp-laptop.service` uses the existing laptop CDP SSH tunnel and is exposed on port 8932.
- Arch and Omarchy Edge: `playwright-mcp-edge.service` uses the profile's configured CDP endpoint or `DevToolsActivePort`; `playwright-mcp-edge-watch` restarts the MCP process when the dynamic DevTools endpoint changes after an Edge restart.
- Omarchy: `echoprofile-omarchy-cdp-tunnel.service` forwards Omarchy's loopback CDP port 9222 to VPS loopback port 9225. `playwright-mcp-omarchy.service` attaches to that tunnel; MetaMCP connects at `http://host.docker.internal:8933/mcp`.

Enable the Omarchy target on the VPS after deploying and stowing this package:

    systemctl --user enable --now echoprofile-omarchy-cdp-tunnel.service
    systemctl --user enable --now playwright-mcp-omarchy.service

The `playwright-mcp` wrapper accepts the named `omarchy` target and reads `PLAYWRIGHT_MCP_OMARCHY_*` values from the selected VPS profile. The SSH tunnel binds only to VPS loopback; CDP is not exposed on the tailnet or public interfaces.

### Optional Microsoft Playwright Extension mode

CDP is preferred. If an extension-only browser must be used, pre-authorize it with the extension's `PLAYWRIGHT_MCP_EXTENSION_TOKEN` and load that value from a per-profile local secret file such as `~/.config/playwright-mcp/edge-default.env` (mode 0600). Do not put the token in tracked env profiles, MetaMCP configuration, logs, or chat.

The extension service refuses to start without the token, so it cannot fall back to an interactive approval flow. A missing token means the extension transport is unavailable; use CDP or the auto-paired EchoProfile Extension MCP instead.
