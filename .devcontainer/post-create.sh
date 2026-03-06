#!/usr/bin/env bash
set -euo pipefail

echo "🔥 Starting post-create.sh..."
echo "👤 Running as: $(id)"

# Ensure we're always working from the repository/workspace root
WORKSPACE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$WORKSPACE_DIR"

# FIXED PATH (ensures ALL CLIs work)
export PATH="$HOME/.local/bin:/usr/local/bin:/usr/local/sbin:/usr/bin:/sbin:/bin:$PATH"

# ── Bash dotfiles ────────────────────────────────────────────────────────────
echo "📋 Installing bash dotfiles..."
[[ -f "$HOME/.bashrc" ]] && cp "$HOME/.bashrc" "$HOME/.bashrc.backup"
cp bash/.bashrc "$HOME/.bashrc"
mkdir -p "$HOME/.config/bash"
cp -r bash/.config/bash/. "$HOME/.config/bash/"
echo "✅ Bash dotfiles installed"

# ── Starship config ──────────────────────────────────────────────────────────
echo "🚀 Installing starship config..."
mkdir -p "$HOME/.config"
cp starship/.config/starship.toml "$HOME/.config/starship.toml"
echo "✅ Starship config installed"

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
