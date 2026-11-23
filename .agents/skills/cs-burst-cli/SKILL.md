---
name: cs-burst-cli
description: Reference for the dotfiles-installed cs-burst compatibility command and its legacy Codespaces compute interface. Use when a human or agent needs to understand the wrapper and its options.
---

# cs-burst CLI Reference

## At a glance

- The dotfiles cs-burst executable is a compatibility shim, not a separate implementation.
- It executes ~/Projects/burst/bin/burst compute and forwards every argument unchanged.
- It creates disposable GitHub Codespaces compute workers, transfers a sanitized local worktree snapshot, runs a command, and collects results.
- It does not clone the application repository from GitHub; the selected launcher repository is used to create the Codespace.
- Sensitive snapshot paths require an explicit --allow-sensitive-snapshot flag and are transferred to the remote worker.
- The central codespaces-burst skill retains workflow guidance; the BURST repository owns the provider implementation.

## Activation contract

Before acting under this skill, read this entire SKILL.md from the first line to the last. The summary above is orientation only; it does not replace the complete instructions below. If the wrapper target, GitHub account, quota, or permissions are unavailable, stop and report the blocker.

## Wrapper identity

The tracked file is dotfiles/bin/bin/cs-burst. The installed command is ~/.local/bin/cs-burst and is Stow-linked to that file. Its entire behavior is:

~~~sh
exec "$HOME/Projects/burst/bin/burst" compute "$@"
~~~

Therefore cs-burst arguments are handled by the Codespaces adapter in the BURST repository. Use burst-cli for the provider-neutral burst deploy/apps interface. This skill documents the legacy compute command exposed by the shim.

## Commands

~~~bash
cs-burst run --repo OWNER/REPO [--account gh-26|gh-06|gh-df|gh-odo|gh-do] [--workdir PATH] [--machine NAME] -- COMMAND [ARG...]
cs-burst exec --codespace NAME [--output FILE] [--account ALIAS] -- COMMAND [ARG...]
cs-burst cp --codespace NAME [--account ALIAS] [--recursive] SOURCE DESTINATION
cs-burst stop --codespace NAME [--account ALIAS]
cs-burst delete --codespace NAME [--account ALIAS]
cs-burst clean --run RUN_ID [--workdir PATH] [--dry-run]
cs-burst status [--account ALIAS]
cs-burst tunnel connect|expose|status|disconnect [OPTIONS]
cs-burst accounts
~~~

### run options

- --repo OWNER/REPO is required. It identifies the project workspace directory name on the worker; it does not fetch that repository from GitHub.
- The selected --account must have access to --launcher, the minimal repository used to create the Codespace.
- --workdir PATH selects the local snapshot root; default is the current directory.
- --machine NAME selects the Codespaces machine.
- --idle-timeout DURATION and --retention DURATION set Codespaces idle timeout and stopped retention.
- --include PATH can be repeated to add exact paths from the workdir that default snapshot rules would exclude.
- --allow-sensitive-snapshot is required when including environment, credential, key, or other sensitive paths. Their contents are uploaded and visible to the remote command; do not include them without explicit authorization.
- --keep stops but retains the Codespace for debugging.
- --keep-running leaves the Codespace running for a temporary test environment. Do not use as a persistent host.
- --no-artifacts disables artifact collection.
- --dry-run previews the operation without creating the worker.

## Snapshot and execution behavior

- The runner creates a disposable Codespace from a minimal launcher and transfers a sanitized snapshot of the local worktree.
- Ordinary tracked, uncommitted, and untracked files are included unless excluded by snapshot rules. The snapshot excludes credentials, environment files, dependency directories, generated output, artifacts, editor metadata, and .git metadata.
- --include explicitly adds selected paths; it does not make their contents private. Sensitive paths require --allow-sensitive-snapshot.
- The command after -- runs in /workspaces/<repo>.
- Logs and artifacts are collected before the worker is deleted, unless --keep or --keep-running changes retention behavior.
- Codespaces have a 12-hour maximum lifetime. This is for temporary compute, builds, tests, and short-lived previews, not production hosting.

## Existing worker operations

- exec runs another command in an existing Codespace.
- cp copies files between the local host and an existing Codespace; use --recursive for directories.
- stop stops a named Codespace.
- delete deletes a named Codespace.
- status lists Codespaces for the selected account.
- clean removes local artifacts for one recorded run; use --dry-run to preview.
- tunnel connect/expose/status/disconnect manage a temporary bridge between two Codespaces and optional tailnet exposure. Inspect the command's current help before changing tunnel exposure.
- accounts lists configured GitHub account aliases.

## Safety

- Do not assume the --repo argument fetches source from GitHub. The worktree snapshot is uploaded from the local --workdir.
- Never add secrets or private keys to a snapshot unless the human explicitly authorizes that exact transfer.
- --keep-running is temporary only; stop/delete workers when no longer needed.
- clean affects local run artifacts; delete affects a remote Codespace. They are different operations.
- Do not delete or stop a Codespace unless its identity and ownership are clear.

## Related references

- Use burst-cli for the provider-neutral BURST command and deployment state.
- Use the central codespaces-burst skill for when to choose this compute path and how to handle remote results.
