#!/usr/bin/env bash
set -euo pipefail

echo "🔥 Starting post-create.sh..."
echo "👤 Running as: $(id)"

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

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

# Verify ALL CLIs work
echo "✅ CLIs available:"
for cli in opencode claude copilot; do
  which "$cli" 2>/dev/null && echo "  ✅ $cli: $(which $cli)" || echo "  ❌ $cli: missing"
done

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

# Remove old tmux layout files if present
rm -f "$HOME/.tmux-dev-session.sh"

# Copy tmux dev layouts script
cp "$DOTFILES_DIR/.devcontainer/python-uv/tmux-dev-layouts.sh" "$HOME/.tmux-dev-layouts.sh"
chmod +x "$HOME/.tmux-dev-layouts.sh"

# Source layouts in bashrc (remove old source line if exists, add new)
sed -i '/\.tmux-dev-layouts\.sh/d' "$HOME/.bashrc" 2>/dev/null || true
echo 'source "$HOME/.tmux-dev-layouts.sh"' >> "$HOME/.bashrc"

# Add startup echo
if ! grep -q 'Tmux layouts:' "$HOME/.bashrc" 2>/dev/null; then
  echo 'echo "📺 Tmux layouts: tdl <ai>, tdlm <ai>, tsl <count> <cmd>"' >> "$HOME/.bashrc"
fi

echo "✅ Tmux dev layouts ready! Run: tdl copilot"
