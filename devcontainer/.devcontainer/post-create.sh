#!/usr/bin/env bash
set -euo pipefail

# One-time setup for a fresh minimal (javascript-node) devcontainer image.
# Reinstalls the shell tools the universal image used to bundle for free:
# tmux, zsh, and neovim (prebuilt binary release, not compiled from source
# — avoids pulling in gcc/cmake/make just to get an editor, which would
# defeat the whole point of moving off the universal image).

sudo apt-get update
sudo apt-get install -y --no-install-recommends stow git-lfs tmux zsh curl ca-certificates gnupg
git lfs install

# Syncthing: not in Ubuntu's default apt repos on any image (universal or
# minimal) — needs the official apt.syncthing.net repo + GPG key added
# first, same steps regardless of base image.
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://syncthing.net/release-key.txt | sudo gpg --dearmor -o /etc/apt/keyrings/syncthing-archive-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/syncthing-archive-keyring.gpg] https://apt.syncthing.net/ syncthing stable" | sudo tee /etc/apt/sources.list.d/syncthing.list
sudo apt-get update
sudo apt-get install -y syncthing

# Neovim: prebuilt release tarball, not apt (Debian/Ubuntu repos are often
# far behind) and not compiled from source. Uses GitHub's "latest" alias so
# this always grabs current stable without needing a version bump here.
NVIM_TARBALL="nvim-linux-x86_64.tar.gz"
curl -fsSLo "/tmp/${NVIM_TARBALL}" \
  "https://github.com/neovim/neovim/releases/latest/download/${NVIM_TARBALL}"
sudo rm -rf /usr/local/nvim-linux-x86_64
sudo tar -C /usr/local -xzf "/tmp/${NVIM_TARBALL}"
sudo ln -sf /usr/local/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
rm -f "/tmp/${NVIM_TARBALL}"

echo "tmux, zsh, neovim, syncthing installed."

# Stow the mcp env file: ~/.config/mcp/env lives on the container's own
# filesystem (wiped every rebuild), but its real source content lives in
# dotfiles/mcp/.config/mcp/env on /workspaces (persistent, and gitignored +
# .stignore'd at this path so this codespace's own values never get
# clobbered by another machine's copy via Syncthing). Re-stow on every
# fresh container so the symlink exists again after a rebuild.
if [ -f /workspaces/dotfiles/mcp/.config/mcp/env ]; then
  mkdir -p "${HOME}/.config"
  (cd /workspaces/dotfiles && stow -t "${HOME}" mcp)
else
  echo "post-create.sh: /workspaces/dotfiles/mcp/.config/mcp/env not found —" >&2
  echo "  create it with this codespace's own values before relying on the mcp/cloudflared startup." >&2
fi
