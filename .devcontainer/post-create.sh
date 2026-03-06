#!/usr/bin/env bash
set -euo pipefail

echo "🔥 Starting post-create.sh..."
echo "👤 Running as: $(id)"

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# =====================
# Install dotfiles
# =====================
echo "📦 Installing dotfiles..."

# bash
cp "$DOTFILES_DIR/bash/.bashrc" "$HOME/.bashrc"
mkdir -p "$HOME/.config/bash"
cp "$DOTFILES_DIR/bash/.config/bash/aliases"   "$HOME/.config/bash/aliases"
cp "$DOTFILES_DIR/bash/.config/bash/functions"  "$HOME/.config/bash/functions"
cp "$DOTFILES_DIR/bash/.config/bash/rc"         "$HOME/.config/bash/rc"
echo "  ✅ bash"

# starship
mkdir -p "$HOME/.config"
cp "$DOTFILES_DIR/starship/.config/starship.toml" "$HOME/.config/starship.toml"
echo "  ✅ starship"

# tmux
cp "$DOTFILES_DIR/tmux/.tmux.conf" "$HOME/.tmux.conf"
echo "  ✅ tmux"

# bat
mkdir -p "$HOME/.config/bat"
cp "$DOTFILES_DIR/bat/.config/bat/config" "$HOME/.config/bat/config"
echo "  ✅ bat"

# git
cp "$DOTFILES_DIR/git/.gitconfig" "$HOME/.gitconfig"
echo "  ✅ git"

# ripgrep
cp "$DOTFILES_DIR/ripgrep/.ripgreprc" "$HOME/.ripgreprc"
echo "  ✅ ripgrep"

# fzf
mkdir -p "$HOME/.config/fzf"
cp "$DOTFILES_DIR/fzf/.config/fzf/fzf.bash" "$HOME/.config/fzf/fzf.bash"
echo "  ✅ fzf"

echo "✅ Dotfiles installed"

# Ensure PATH is set for the rest of this script
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
