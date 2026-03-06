#!/usr/bin/env bash
set -euo pipefail

echo "🔥 Starting post-create.sh..."
echo "👤 Running as: $(id)"

# FIXED PATH (ensures ALL CLIs work, no host PATH inheritance)
export PATH="$HOME/.local/bin:/usr/local/bin:/usr/local/sbin:/usr/bin:/sbin:/bin"
if ! grep -qF '.local/bin' "$HOME/.bashrc"; then
  echo 'export PATH="$HOME/.local/bin:/usr/local/bin:/usr/local/sbin:/usr/bin:/sbin:/bin"' >> "$HOME/.bashrc"
fi

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
