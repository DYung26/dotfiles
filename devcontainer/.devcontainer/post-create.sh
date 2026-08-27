#!/usr/bin/env bash
set -euo pipefail

# One-time setup for a fresh minimal (javascript-node) devcontainer image.
# Reinstalls the shell tools the universal image used to bundle for free:
# tmux, zsh, and neovim (prebuilt binary release, not compiled from source
# — avoids pulling in gcc/cmake/make just to get an editor, which would
# defeat the whole point of moving off the universal image).

sudo apt-get update
sudo apt-get install -y --no-install-recommends stow git-lfs zsh curl ca-certificates gnupg ripgrep
git lfs install --force

# Syncthing: not in Ubuntu's default apt repos on any image (universal or
# minimal) — needs the official apt.syncthing.net repo + GPG key added
# first, same steps regardless of base image.
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://syncthing.net/release-key.txt | sudo gpg --dearmor -o /etc/apt/keyrings/syncthing-archive-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/syncthing-archive-keyring.gpg] https://apt.syncthing.net/ syncthing stable" | sudo tee /etc/apt/sources.list.d/syncthing.list
sudo apt-get update
sudo apt-get install -y syncthing

# cloudflared: official apt repo, same pattern as syncthing above. Pinned
# to bookworm rather than $(lsb_release -cs): Cloudflare's repo doesn't
# publish a trixie component yet, and bookworm's cloudflared .deb installs
# fine on trixie since it has no glibc/kernel-specific dependencies.
sudo mkdir -p --mode=0755 /usr/share/keyrings
curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | sudo tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null
echo "deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared bookworm main" | sudo tee /etc/apt/sources.list.d/cloudflared.list
sudo apt-get update
sudo apt-get install -y cloudflared

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

# tmux: prebuilt static release tarball from tmux/tmux-builds, not apt —
# Debian bookworm ships 3.3a, too old for several popup-related features
# this config relies on. Unlike Neovim, tmux-builds doesn't publish assets
# under a stable filename, so the asset URL is resolved via the GitHub API
# rather than guessed.
TMUX_ASSET_URL=$(curl -fsSL https://api.github.com/repos/tmux/tmux-builds/releases/latest | grep -o "browser_download_url[^,]*linux-x86_64[^,]*tar.gz\"" | head -n1 | grep -o "https://[^\"]*")
TMUX_TARBALL="$(basename "${TMUX_ASSET_URL}")"
TMUX_EXTRACT_DIR="$(mktemp -d /tmp/tmux-build.XXXXXX)"
curl -fsSLo "/tmp/${TMUX_TARBALL}" "${TMUX_ASSET_URL}"
tar -C "${TMUX_EXTRACT_DIR}" -xzf "/tmp/${TMUX_TARBALL}"
sudo install -m 0755 "${TMUX_EXTRACT_DIR}/tmux" /usr/local/bin/tmux
rm -f "/tmp/${TMUX_TARBALL}"
rm -rf "${TMUX_EXTRACT_DIR}"

# Rust toolchain (rustup, cargo, rustc): nvim-treesitter's newer "main"
# branch calls out to the tree-sitter CLI to build parsers, and installing
# tree-sitter-cli via cargo (rather than npm, whose prebuilt binaries are
# linked against a newer glibc than some base images provide) compiles it
# locally against whatever glibc is actually on this image.
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal
source "${HOME}/.cargo/env"

echo "tmux, zsh, neovim, syncthing, rust installed."

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

# Stow the cloudflared credentials + config.yml for this tunnel: same
# pattern and same reasoning as the mcp env stow above — real content lives
# in dotfiles/cloudflared/.cloudflared/ on /workspaces, gitignored except
# config.yml, and re-stowed on every fresh container.
if ls /workspaces/dotfiles/cloudflared/.cloudflared/*.json >/dev/null 2>&1; then
  mkdir -p "${HOME}/.cloudflared"
  (cd /workspaces/dotfiles && stow -t "${HOME}" cloudflared)
else
  echo "post-create.sh: no credentials JSON in dotfiles/cloudflared/.cloudflared/ —" >&2
  echo "  add this codespace's tunnel credentials file before relying on cloudflared startup." >&2
fi
