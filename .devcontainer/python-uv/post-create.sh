#!/usr/bin/env bash
set -euo pipefail

echo "🔥 Starting post-create.sh..."
echo "👤 Running as: $(id)"

# FIXED PATH (ensures ALL CLIs work)
if ! grep -q '.local/bin' "$HOME/.bashrc"; then
  echo 'export PATH="$HOME/.local/bin:/usr/local/bin:/usr/local/sbin:/usr/bin:/sbin:/bin:$PATH"' >> "$HOME/.bashrc"
fi
export PATH="$HOME/.local/bin:/usr/local/bin:/usr/local/sbin:/usr/bin:/sbin:/bin:$PATH"

# Verify ALL CLIs work
echo "✅ CLIs available:"
for cli in opencode claude copilot; do
  which "$cli" 2>/dev/null && echo "  ✅ $cli: $(which $cli)" || echo "  ❌ $cli: missing"
done

# Install bash dotfiles from repo
echo "🐚 Installing bash dotfiles..."
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
if [[ -d "$REPO_ROOT/bash" ]]; then
  cp "$REPO_ROOT/bash/.bashrc" "$HOME/.bashrc"
  mkdir -p "$HOME/.config/bash"
  cp -r "$REPO_ROOT/bash/.config/bash/." "$HOME/.config/bash/"
  echo "✅ Bash dotfiles installed"
else
  echo "⚠️ bash/ directory not found, skipping dotfiles"
fi

# Install starship config from repo
echo "⭐ Installing starship config..."
if [[ -d "$REPO_ROOT/starship" ]]; then
  mkdir -p "$HOME/.config"
  cp -r "$REPO_ROOT/starship/.config/." "$HOME/.config/"
  echo "✅ Starship config installed"
else
  echo "⚠️ starship/ directory not found, skipping starship config"
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

# Tmux Dev Layouts setup
echo "🖥️ Setting up tmux dev layouts..."

# Install tmux config from repo
cp "$(dirname "${BASH_SOURCE[0]}")/tmux.conf" "$HOME/.tmux.conf"

# Install tmux layouts from repo
cp "$(dirname "${BASH_SOURCE[0]}")/tmux-dev-layouts.sh" "$HOME/.tmux-dev-layouts.sh"
chmod +x "$HOME/.tmux-dev-layouts.sh"

# Source layouts in bashrc (remove old source line if exists, add new)
sed -i '/\.tmux-dev-layouts\.sh/d' "$HOME/.bashrc" 2>/dev/null || true
echo 'source "$HOME/.tmux-dev-layouts.sh"' >> "$HOME/.bashrc"

# Add startup echo
if ! grep -q 'Tmux layouts:' "$HOME/.bashrc" 2>/dev/null; then
  echo 'echo "📺 Tmux layouts: tdl <ai>, tdlm <ai>, tsl <count> <cmd>"' >> "$HOME/.bashrc"
fi

echo "✅ Tmux dev layouts ready! Run: tdl copilot"
