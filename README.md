# Dotfiles

This repository is the source of truth for personal workstation, server, and development-environment configuration. Configuration changes belong here first; GNU Stow links the selected package into its live destination.

The repository lives under `~/Projects/dotfiles`, not directly in the home directory. Always pass an explicit Stow target.

## Non-negotiable workflow

1. Inspect the package, its README, current target files, and the device's existing symlinks before editing.
2. Make changes in this repository, in a dedicated Grove worktree and branch based on the latest `main`. Do not edit live home-directory files as the source of truth.
3. Put each file under the package path that mirrors its intended destination. Keep unrelated machine state and generated runtime data out of packages.
4. If a target file already exists, compare it with the repository version. Merge unique local changes into the package, keep a backup, and only then replace the target with a Stow link. Never use `stow --adopt` blindly.
5. Preview every Stow operation. Apply only the packages intended for that device; never run a blanket `stow */`.
6. Keep secrets local, ignored by Git and Syncthing, and permission-restricted. Commit safe example templates, never real credentials.
7. Validate the resulting links and runtime behavior. Unit files existing in the repository does not mean a service is enabled or healthy.

Use the `git-and-gh-workflow` skill for branches, Grove worktrees, signed commits, PRs, and merges.

## GNU Stow

Each applicable top-level package is stowed independently. The default Stow target is not the home directory when invoked from this repository, so use `--target="$HOME"`.

Preview and apply a home package:

```sh
stow --simulate --verbose --no-folding --target="$HOME" <package>
stow --no-folding --target="$HOME" <package>
```

Restow after changing package files, or remove a package's links:

```sh
stow --restow --no-folding --target="$HOME" <package>
stow --delete --no-folding --target="$HOME" <package>
```

Use explicit package names. Alternative Bash profiles are mutually exclusive; do not stow all `bash-*` packages together.

### Systemd package

The `systemd` package contains both user units and root-level units. Stow each tree to its correct target:

```sh
# User units and user configuration
stow --no-folding --target="$HOME" --ignore='^etc$' systemd

# Root-level units
sudo stow --no-folding --target=/ --ignore='^[.]config$' systemd
```

After changes, reload the relevant manager:

```sh
systemctl --user daemon-reload
sudo systemctl daemon-reload
```

Select the device's non-secret systemd profile with:

```sh
./systemd/bin/select-device-config arch
./systemd/bin/select-device-config vps
./systemd/bin/select-device-config omarchy
```

Use only the matching profile. The selector and optional `systemd.secrets.env` are local files; the tracked `systemd.env.common` and `systemd.env.<device>` files contain non-secret configuration.

### Stow ignore rules are separate from Git ignores

Git's `.gitignore` and Syncthing's `.stignore` do not stop GNU Stow from linking a file. If a package contains local-only files or generated state, add a package-local `.stow-local-ignore` and verify it with a Stow dry run. The repository-root `.stow-local-ignore` does not replace package-local rules.

## Device profiles

| Environment | Bash profile | Systemd profile | Notes |
|---|---|---|---|
| Arch Linux (`archlinux`) | `bash-archlinux` | `arch` | Current Arch desktop configuration |
| Ubuntu VPS (`ubuntu-s-1vcpu-1gb-sfo3-01`) | `bash-droplet` | `vps` | VPS configuration; `bash-ubuntu` is the generic Ubuntu profile |
| Omarchy (`omarchy`) | Omarchy-native shell configuration | `omarchy` | Its current Bash/Zsh startup files are not Stow-managed; do not replace them with an Arch profile without reviewing the host setup |
| GitHub Codespaces | `bash-codespaces` | — | Copy the `devcontainer` package into the target project as its README describes; do not Stow it as a home package |
| Windows Git Bash | `bash-git-bash` | — | Use the Windows-specific package only on Windows |
| Other Ubuntu hosts | `bash-ubuntu` | — | Generic Ubuntu profile; do not substitute it for the VPS profile without checking the host |

Only one Bash profile should own `~/.bashrc` on a host. Other shell and application packages can be selected independently.

## Package map

### Normal home packages

These are home-directory packages when the host uses them:

- Shell and terminal: `bash-*`, `zsh`, `ble`, `starship`, `alacritty`, `wezterm`, `tmux`, `tmuxp`, `htop`.
- Shared tools: `bin`, `git`, `ssh`, `nvim`, `stowrc`.
- GitHub CLI: `gh` plus only the relevant `gh-<account>` profile packages. Account-specific `hosts.yml` files are local authentication state, not portable configuration.
- Desktop integrations: `input-leap`, `input-leap-gui`, and `pulse` only on hosts that actually use those services. Omarchy's `hyprland` package contains only `~/.config/hypr/hyprland.lua`; it loads Omarchy's own defaults and the other personal modules remain Omarchy-managed local files. Pulse runs its daemon on the VPS; the Arch GNOME extension reaches that same socket through `pulse-socket-forward.service`.
- MCP integrations: `mcp`, `mcp-shell-privileged`, `workspace-mcp`, and `metamcp-ops` only on the hosts where their applications run. `metamcp-ops` is VPS-only; its local ignored environment file is mode 600 and its systemd unit is tracked in the `systemd` package. `mcp-relay` is paused and VPS-only: its default port conflicts with MetaMCP Ops, its environment is absent, and its watcher still needs authentication and end-to-end failover validation.
- `cloudflared`: per-device configuration templates and local tunnel settings. Before editing, inspect the live unit and its drop-ins; a service may use an app-owned config path instead of the tracked template.

### Conditional or non-home packages

- `windows`: Windows-only configuration; never apply it to a Linux home directory.
- `barrier`: legacy/optional. Do not install unless Barrier is still deliberately in use.
- `containers`: repository-managed container definitions and local runtime data; not a normal home Stow package.
- `devcontainer`: copy into a target development repository as documented; do not Stow it into the home directory.
- `networkmanager-wifi-reconnect`: archived; its README documents the historical setup. Do not install it as an active package.
- `systemd`: special dual-target package described above.

A directory at the repository root is not automatically a package to install on every machine. Read its README and inspect its target paths first.

## Multi-device configuration and secrets

- Prefer one shared default plus a small device-specific override when the application supports it. Do not copy an entire configuration to every machine just to change a few paths or ports.
- Keep device-specific files named explicitly (for example, `config.arch.yml`, `config.vps.yml`, and `config.omarchy.yml`).
- Track non-secret settings and safe `.example` templates. Keep tokens, passwords, OAuth client secrets, tunnel credentials, API keys, and private keys in local files that are excluded from Git and Syncthing.
- Preserve application-owned secret stores. Do not move every application's credentials into one global secrets file.
- Keep local secret files at mode `600` where appropriate. Never print their values in tool output, logs, PRs, or commit messages.
- A path to a local secret file is configuration, not the secret itself; verify the target exists and has restrictive permissions.
- The Syncthing `*env*` ignore is intentional. Tracked environment profiles are distributed through Git, not Syncthing. Do not weaken this rule to make a profile appear on another device; pull the repository instead.
- Cloudflare credential JSON and `cert.pem` files are local secrets. Do not commit or sync them. Check the effective systemd `ExecStart` and drop-ins before assuming a tracked config template is active.

## Systemd service policy

- Long-running daemons should have an appropriate `Restart=on-failure` or `Restart=always`, a sensible `RestartSec`, and an `[Install]` target that matches the host/session.
- `Type=oneshot` jobs should not be given daemon restart policies. Use a timer or an explicit dependency when a one-shot job must run again.
- Do not enable every unit on every device. Enable only the units intended for that device and preserve deliberate disabled states.
- For each affected host, inspect `systemctl list-unit-files`, `is-enabled`, `status`, and relevant journals. Verify both boot enablement and runtime health.
- Use `systemd-analyze verify` after editing units. Reload the correct manager after Stow.

### Pulse cross-device socket

- The Pulse daemon runs on the VPS as `pulse.service`, using `%h/.local/lib/pulse/pulse-daemon` and `%h/.local/run/pulse.sock`.
- The MetaMCP container on the VPS runs `pulse-mcp` from `%h/.local/lib/pulse/pulse-mcp`; its `PULSE_SOCKET_PATH` must match the daemon socket.
- Arch runs `pulse-socket-forward.service`, which forwards the VPS Unix socket over Tailscale SSH to the same local path. The GNOME extension and local MCP clients use `/home/dyung/.local/run/pulse.sock`.
- Install `pulse-daemon` and `pulse-mcp` under `~/.local/lib/pulse` on the VPS. Do not point runtime services at a Grove-managed Cargo `target` symlink. The daemon creates a group-writable socket for the container's supplementary GID 1000; the Arch forward socket is owner-only.
- The MetaMCP container already bind-mounts `/home/dyung`; do not add a separate `/tmp/pulse` volume.

## Verification checklist

Before publishing a change:

- `git status --short --ignored`: confirm no local secrets, generated state, or unrelated work is included.
- `git diff --check`: confirm clean whitespace and patch formatting.
- `stow --simulate --verbose --no-folding --target="$HOME" <selected-packages>`: confirm there are no unexplained conflicts.
- Inspect each resulting link with `readlink -f`; do not assume a regular file is already Stow-managed.
- Run the package's tests or the relevant application/systemd validation.
- On each affected device, verify the actual service state and the intended target path.

Do not delete backups, local secret files, Grove worktrees, or unrelated working-tree changes as part of a dotfiles change.


## References

- [GNU Stow manual](https://www.gnu.org/software/stow/manual/stow.html)
- [Syncthing ignore patterns](https://docs.syncthing.net/users/ignoring)
