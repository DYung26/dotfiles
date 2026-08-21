# devcontainer files — committed directly to codespaces, not symlinked

`devcontainer.json`, `post-create.sh`, and `post-start.sh` live here in
`dotfiles` as the source of truth you edit, but they must be **copied and
committed directly into the `codespaces` repo's own `.devcontainer/`**, not
stow-symlinked there. Two reasons this can't be a symlink, found the hard
way:

1. Git refuses to track a path through a symlinked directory (`git add
   .devcontainer/devcontainer.json` errors with "beyond a symbolic link")
   when `.devcontainer` itself is a symlink into another repo — there'd be
   nothing for `codespaces` to actually commit.
2. GitHub Codespaces reads `.devcontainer/devcontainer.json` from the
   repo's committed content to decide how to build the container in the
   first place — `dotfiles` isn't guaranteed to be cloned yet at that
   point, so even a working symlink wouldn't reliably resolve on a fresh
   codespace creation.

**Critical: `postCreateCommand`/`postStartCommand` in `devcontainer.json`
must reference `/workspaces/codespaces/.devcontainer/...`, not
`/workspaces/dotfiles/devcontainer/.devcontainer/...`.** Got this backwards
for several iterations — `codespaces` is what gets `git pull`ed and is
guaranteed current; `/workspaces/dotfiles` only updates via Syncthing,
which isn't the same event as pushing a fix to `codespaces`. Every fix
pushed to `codespaces` silently kept executing the old, stale version
sitting in `dotfiles` until this was caught.

## Workflow for changing any of these three files

```bash
# 1. Edit the source of truth in dotfiles
# 2. Copy into your local clone of the codespaces repo
cp devcontainer/.devcontainer/devcontainer.json /path/to/codespaces-clone/.devcontainer/
cp devcontainer/.devcontainer/post-create.sh /path/to/codespaces-clone/.devcontainer/
cp devcontainer/.devcontainer/post-start.sh /path/to/codespaces-clone/.devcontainer/
chmod +x /path/to/codespaces-clone/.devcontainer/post-create.sh /path/to/codespaces-clone/.devcontainer/post-start.sh
# 3. Commit and push from the codespaces clone
cd /path/to/codespaces-clone
git add .devcontainer
git commit -m "..."
git push
# 4. On the actual codespace: git pull, then rebuild
```

The `bin/bin/*.sh` scripts (`start-mcp.sh`, `start-cloudflared.sh`,
`start-metamcp.sh`) that `post-start.sh` calls are NOT part of this — those
genuinely belong in `dotfiles` and stay Syncthing'd, since they're shared
across archlinux and every codespace. Only the top-level orchestration
(`devcontainer.json`, `post-create.sh`, `post-start.sh` themselves) needs
to be duplicated into `codespaces`.

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
