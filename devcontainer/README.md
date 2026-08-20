# devcontainer stow package — different target than everything else

Every other stow package in this repo targets `$HOME` (the default). This
one is the exception: it needs to land in the `codespaces` repo, not
`$HOME`, because that's where GitHub Codespaces actually looks for
`devcontainer.json` (repo root's `.devcontainer/devcontainer.json`).
Confirmed: none of the `gh-*` codespaces have ever had a devcontainer.json,
so this is new, not a merge.

## The command (remember this one — it's different)

Run from inside a codespace, once `codespaces` is cloned to
`/workspaces/codespaces`:

```bash
cd ~/Projects/dotfiles
stow -t /workspaces/codespaces devcontainer
```

Every other invocation you run is just `stow <package>` (implicitly
targeting `$HOME`). This one needs the explicit `-t` flag, or it will try
to symlink `.devcontainer/devcontainer.json` into `$HOME` instead, which is
wrong.

## Why the package structure looks like this

Stow mirrors the package's internal directory structure onto the target
root. Since the target root here is `/workspaces/codespaces`, not `$HOME`,
the package contains a full `.devcontainer/devcontainer.json` path inside
it — same principle as `systemd/.config/systemd/user/mcp.service` mirroring
onto `~/.config/systemd/user/mcp.service` for the normal `$HOME` target,
just with a different root.

```
dotfiles/devcontainer/.devcontainer/devcontainer.json
  → symlinked to →
/workspaces/codespaces/.devcontainer/devcontainer.json
```

## Base image

Uses `mcr.microsoft.com/devcontainers/javascript-node:20-bookworm`, not the
default `universal` image GitHub Codespaces falls back to when no `image`
is set. `universal` bundles full toolchains for every language (Rust,
.NET, Ruby, PHP, LLVM/clang, etc.) whether you use them or not — on a 32GB
codespace volume this left ~260MB free before any real work even started,
and every container rebuild wiped any manual cleanup back to full.
`javascript-node` ships just Node/npm/git; `docker-outside-of-docker` is
added as a Feature for MetaMCP's `docker compose` needs, rather than baked
into a universal image. Pinned to `-bookworm` specifically, not the bare
`:20` tag — the bare tag currently resolves to Debian trixie, and
`docker-outside-of-docker` doesn't support trixie yet (fails with "moby-cli
and related system packages are not available in that distribution"),
which silently drops you into GitHub's Alpine recovery container instead
of a real build failure being obvious.

The tradeoff: `universal`'s bundled tmux/zsh/neovim are gone, and Syncthing
(needed on any image — it's never in Ubuntu's default apt repos, universal
or minimal) needs its repo added explicitly. These get installed once via
`postCreateCommand` (`post-create.sh`) — neovim as a prebuilt binary
release (GitHub's `latest` URL alias, so it never goes stale), not
compiled from source, to avoid pulling gcc/cmake back in and undoing the
whole point of switching images.

## What this devcontainer.json actually does

- `postCreateCommand` (runs once, at container creation): installs
  tmux, zsh, neovim, syncthing — see "Base image" above.
- `postStartCommand` (runs on every start/resume): runs
  `.devcontainer/post-start.sh`, which calls the existing
  `start-mcp.sh` / `start-cloudflared.sh` directly (same scripts
  `mcp.service` / `cloudflared-mcp.service` already supervise on
  archlinux — nothing new, no duplicate "background" variants), backgrounds
  them with a `pgrep` guard since there's no systemd here to do that
  supervision itself, then runs `start-metamcp.sh` (`docker compose up -d`,
  idempotent). Cloudflared only starts once its credentials file actually
  exists; MetaMCP only starts once its `.env`/override exist.
- `postAttachCommand` (runs when you attach a session, e.g. opening a
  terminal/VS Code window): starts Syncthing in the background if not
  already running. This used to live in `bash-codespaces/.bashrc` and ran
  on every interactive shell open (wasteful — every new terminal tab
  re-checked it); moved here so it only runs once per attach.

`mcp-servers` and `metamcp` are NOT cloned or built by this file — both are
already Syncthing'd and `/workspaces` persists across restarts, so cloning
and building are one-time manual steps you do yourself per codespace, not
something this devcontainer.json automates.

## Logs

Backgrounded process logs go to `/tmp/mcp/`, not anywhere under `~/.config`
— codespaces have limited persistent storage, and `/tmp` clears on
restart, so logs don't accumulate across sessions.

## Known gaps, not yet solved

- No automatic respawn if a backgrounded process dies mid-session —
  `postStartCommand` only runs on start/resume, not continuously. Re-run
  the relevant script from `bin/bin/` manually (backgrounded with `&`) if
  something goes down. A proper supervisor is a follow-up, not blocking
  the gh-06 pilot.
- Switching the base image means MetaMCP's Postgres container needs actual
  free disk to `initdb` on first run — a fresh minimal image plus a fresh
  postgres volume both competing for space on a nearly-full codespace can
  still fail. Run the disk cleanup (`~/scripts/cleanup-codespace-disk.sh`)
  before the first `docker compose up -d` on a new codespace, not after.
- Being tested end-to-end on gh-06 via a real image-switch rebuild; not
  yet confirmed clean on a genuinely fresh codespace creation.
