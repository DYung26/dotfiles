# Unified systemd Stow package

All dotfiles-managed systemd units live in this package. Device differences belong in the local, untracked systemd.env file; units read it directly from the repository. Keep credentials in their existing dedicated secret files.

## Per-device configuration

Copy systemd.env.example to systemd.env, edit values for that machine, and set mode 0600. The file is excluded by Git, Syncthing and Stow. It must exist independently on each device.

## Stow

Install user units and helper links:

    stow --no-folding -t "$HOME" --ignore='^etc$' systemd

Install system-level units only on machines that need them (currently the VPS):

    sudo stow --no-folding -t / --ignore='^[.]config$' --ignore='^bin$' --ignore='^[.]local$' systemd

Then reload systemd and enable only the units appropriate for that device. Stowing a unit does not enable it.

## Device activation

- Arch: enable echoprofile.service under graphical-session.target; Playwright MCP, Input Leap, MCP services, Multica, Pulse and shared maintenance timers use their normal targets.
- Omarchy: EchoProfile, Cloudflared, MCP shell proxy and shared maintenance timers.
- VPS: EchoProfile and its VNC/WM/login stack, Playwright MCP endpoints, MT5, Agentation, Market Engine, GridWatch, Workspace MCP and applicable MCP services.

The same unit files are deployed everywhere; only the per-device environment file and enabled-unit links differ.
