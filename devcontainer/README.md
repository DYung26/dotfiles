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

## What this devcontainer.json actually does

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
  the relevant `start-*-background.sh` manually if something goes down. A
  proper supervisor is a follow-up, not blocking the gh-06 pilot.
- Not yet tested end-to-end (fresh codespace creation, not just the pieces
  individually) — gh-06 already has everything set up manually from
  earlier work, so this devcontainer.json is for the *next* fresh
  codespace or a gh-06 rebuild, whichever comes first.
