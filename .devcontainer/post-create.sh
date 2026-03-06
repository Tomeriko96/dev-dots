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

# Copy bash dotfiles
WORKSPACE_DIR="$(cd "$(dirname "$0")/.." && pwd)"

if [[ -d "$WORKSPACE_DIR/bash/.config/bash" ]]; then
  mkdir -p "$HOME/.config/bash"
  for f in aliases functions rc; do
    if [[ -f "$WORKSPACE_DIR/bash/.config/bash/$f" ]]; then
      cp "$WORKSPACE_DIR/bash/.config/bash/$f" "$HOME/.config/bash/$f"
    else
      echo "⚠️ bash dotfile missing: bash/.config/bash/$f"
    fi
  done
  echo "✅ Bash dotfiles installed"
fi

# Copy starship config
if [[ -f "$WORKSPACE_DIR/starship/.config/starship.toml" ]]; then
  mkdir -p "$HOME/.config"
  cp "$WORKSPACE_DIR/starship/.config/starship.toml" "$HOME/.config/starship.toml"
  echo "✅ Starship config installed"
fi

# Configure git with delta
if command -v delta >/dev/null 2>&1; then
  git config --global core.pager delta
  git config --global interactive.diffFilter "delta --color-only"
  git config --global delta.navigate true
  git config --global delta.light false
  echo "✅ Git configured with delta"
fi
