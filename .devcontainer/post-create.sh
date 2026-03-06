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

# Install bash dotfiles from repo
echo "🐚 Installing bash dotfiles..."
REPO_BASH="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/bash"
if [[ -d "$REPO_BASH" ]]; then
  cp "$REPO_BASH/.bashrc" "$HOME/.bashrc"
  mkdir -p "$HOME/.config/bash"
  cp -r "$REPO_BASH/.config/bash/." "$HOME/.config/bash/"
  echo "✅ Bash dotfiles installed"
else
  echo "⚠️ bash/ directory not found, skipping dotfiles"
fi

# Install starship config from repo
echo "⭐ Installing starship config..."
REPO_STARSHIP="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/starship"
if [[ -d "$REPO_STARSHIP" ]]; then
  mkdir -p "$HOME/.config"
  cp -r "$REPO_STARSHIP/.config/." "$HOME/.config/"
  echo "✅ Starship config installed"
else
  echo "⚠️ starship/ directory not found, skipping starship config"
fi

# Install tmux config and dev layouts from repo
echo "🖥️ Installing tmux config..."
PYTHON_UV_CONFIG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/.devcontainer/python-uv"
if [[ -d "$PYTHON_UV_CONFIG_DIR" ]]; then
  cp "$PYTHON_UV_CONFIG_DIR/tmux.conf" "$HOME/.tmux.conf"
  cp "$PYTHON_UV_CONFIG_DIR/tmux-dev-layouts.sh" "$HOME/.tmux-dev-layouts.sh"
  chmod +x "$HOME/.tmux-dev-layouts.sh"
  echo "✅ Tmux config installed"
else
  echo "⚠️ python-uv/ directory not found, skipping tmux config"
fi

# Source tmux dev layouts in bashrc
sed -i '/\.tmux-dev-layouts\.sh/d' "$HOME/.bashrc" 2>/dev/null || true
echo 'source "$HOME/.tmux-dev-layouts.sh"' >> "$HOME/.bashrc"

if ! grep -q 'Tmux layouts:' "$HOME/.bashrc" 2>/dev/null; then
  echo 'echo "📺 Tmux layouts: tdl <ai>, tdlm <ai>, tsl <count> <cmd>"' >> "$HOME/.bashrc"
fi

# LazyVim setup
echo "✨ Setting up LazyVim..."
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
