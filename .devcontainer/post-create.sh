#!/usr/bin/env bash
set -euo pipefail

echo "🔥 Starting post-create.sh..."
echo "👤 Running as: $(id)"

# FIXED PATH (ensures ALL CLIs work)
if ! grep -q '.local/bin' "$HOME/.bashrc"; then
  echo 'export PATH="$HOME/.local/bin:/usr/local/bin:/usr/local/sbin:/usr/bin:/sbin:/bin:$PATH"' >> "$HOME/.bashrc"
fi
export PATH="$HOME/.local/bin:/usr/local/bin:/usr/local/sbin:/usr/bin:/sbin:/bin:$PATH"

# OpenCode CLI check
if which opencode >/dev/null 2>&1; then
  echo "✅ OpenCode CLI available: $(which opencode)"
else
  echo "❌ OpenCode CLI missing from PATH"
fi

# LazyVim setup
CONFIG_DIR="$HOME/.config/nvim"
LAZYVIM_REPO="https://github.com/LazyVim/starter"
mkdir -p "$(dirname "$CONFIG_DIR")"
if [[ ! -d "$CONFIG_DIR" ]]; then
  git clone "$LAZYVIM_REPO" "$CONFIG_DIR"
  rm -rf "$CONFIG_DIR/.git"
  echo "✅ LazyVim installed"
else
  echo "⚠️ LazyVim already exists"
fi

# Deploy bash dotfiles from repo
WORKSPACE_DIR="${PWD}"
echo "📦 Deploying dotfiles from $WORKSPACE_DIR..."

cp "$WORKSPACE_DIR/bash/.bashrc" "$HOME/.bashrc"
mkdir -p "$HOME/.config/bash"
cp -r "$WORKSPACE_DIR/bash/.config/bash/." "$HOME/.config/bash/"
echo "✅ Bash dotfiles deployed"

# Ensure uv shell completion is present (added by Dockerfile, may be missing after .bashrc overwrite)
if ! grep -q 'uv generate-shell-completion' "$HOME/.bashrc"; then
  echo 'eval "$(uv generate-shell-completion bash)"' >> "$HOME/.bashrc"
fi

# Deploy Starship config
mkdir -p "$HOME/.config"
cp "$WORKSPACE_DIR/starship/.config/starship.toml" "$HOME/.config/starship.toml"
echo "✅ Starship config deployed"

# Deploy git config (only if no gitconfig exists yet)
if [[ ! -f "$HOME/.gitconfig" ]]; then
  cp "$WORKSPACE_DIR/git/gitconfig" "$HOME/.gitconfig"
  echo "✅ Git config deployed"
else
  echo "⚠️ ~/.gitconfig already exists — skipping (add delta pager manually if desired)"
fi

# Deploy tmux config
cp "$WORKSPACE_DIR/.devcontainer/python-uv/tmux.conf" "$HOME/.tmux.conf"
echo "✅ tmux config deployed"

# Deploy tmux dev layout script
cp "$WORKSPACE_DIR/.devcontainer/python-uv/tmux-dev-layouts.sh" "$HOME/.tmux-dev-layouts.sh"
chmod +x "$HOME/.tmux-dev-layouts.sh"

# Source tmux layouts in .bashrc
sed -i '/\.tmux-dev-layouts\.sh/d' "$HOME/.bashrc" 2>/dev/null || true
echo 'source ~/.tmux-dev-layouts.sh' >> "$HOME/.bashrc"

# Add startup echo for tmux layouts
if ! grep -q 'Tmux layouts:' "$HOME/.bashrc" 2>/dev/null; then
  echo 'echo "📺 Tmux layouts: tdl <ai>, tdlm <ai>, tsl <count> <cmd>"' >> "$HOME/.bashrc"
fi
echo "✅ tmux dev layouts ready"
