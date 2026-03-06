#!/usr/bin/env bash
set -euo pipefail

echo "🔥 Starting post-create.sh..."
echo "👤 Running as: $(id)"

# Resolve workspace root (directory containing this script's .devcontainer folder)
WORKSPACE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

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

# =====================
# Install starship (if not present)
# =====================
if ! command -v starship &>/dev/null; then
  echo "⭐ Installing starship..."
  curl -sS https://starship.rs/install.sh | sh -s -- --yes || { echo "❌ starship install failed"; exit 1; }
fi

# =====================
# Install zoxide (if not present)
# =====================
if ! command -v zoxide &>/dev/null; then
  echo "📁 Installing zoxide..."
  curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh || { echo "❌ zoxide install failed"; exit 1; }
fi

# =====================
# Bash dotfiles
# =====================
echo "🐚 Installing bash dotfiles..."
BASH_SRC="$WORKSPACE_ROOT/bash/.config/bash"
[[ -d "$BASH_SRC" ]] || { echo "❌ bash dotfiles not found at $BASH_SRC"; exit 1; }
mkdir -p "$HOME/.config/bash"
cp "$BASH_SRC/rc"        "$HOME/.config/bash/rc"
cp "$BASH_SRC/aliases"   "$HOME/.config/bash/aliases"
cp "$BASH_SRC/functions" "$HOME/.config/bash/functions"

# Source bash config from .bashrc (idempotent)
if ! grep -q 'source.*\.config/bash/rc' "$HOME/.bashrc" 2>/dev/null; then
  echo 'source "$HOME/.config/bash/rc"' >> "$HOME/.bashrc"
fi

# Init zoxide (idempotent)
if ! grep -q 'zoxide init' "$HOME/.bashrc" 2>/dev/null; then
  echo 'eval "$(zoxide init bash)"' >> "$HOME/.bashrc"
fi

# Init starship (idempotent)
if ! grep -q 'starship init' "$HOME/.bashrc" 2>/dev/null; then
  echo 'eval "$(starship init bash)"' >> "$HOME/.bashrc"
fi

echo "✅ Bash dotfiles installed"

# =====================
# Starship config
# =====================
echo "⭐ Installing starship config..."
STARSHIP_SRC="$WORKSPACE_ROOT/starship/.config/starship.toml"
[[ -f "$STARSHIP_SRC" ]] || { echo "❌ starship.toml not found at $STARSHIP_SRC"; exit 1; }
mkdir -p "$HOME/.config"
cp "$STARSHIP_SRC" "$HOME/.config/starship.toml"
echo "✅ ~/.config/starship.toml installed"

# =====================
# Tmux dotfiles
# =====================
echo "🖥️ Setting up tmux..."
TMUX_SRC="$WORKSPACE_ROOT/tmux"
[[ -d "$TMUX_SRC" ]] || { echo "❌ tmux dotfiles not found at $TMUX_SRC"; exit 1; }

# Remove legacy file if present
rm -f "$HOME/.tmux-dev-session.sh"

# Install tmux config
cp "$TMUX_SRC/.tmux.conf" "$HOME/.tmux.conf"
echo "✅ ~/.tmux.conf installed"

# Install tmux dev layout helpers
cp "$TMUX_SRC/.tmux-dev-layouts.sh" "$HOME/.tmux-dev-layouts.sh"
chmod +x "$HOME/.tmux-dev-layouts.sh"
echo "✅ ~/.tmux-dev-layouts.sh installed"

# Source layouts in bashrc (idempotent)
sed -i '/\.tmux-dev-layouts\.sh/d' "$HOME/.bashrc" 2>/dev/null || true
echo 'source "$HOME/.tmux-dev-layouts.sh"' >> "$HOME/.bashrc"

# Remind user about available layouts on shell startup (idempotent)
if ! grep -q 'Tmux layouts:' "$HOME/.bashrc" 2>/dev/null; then
  echo 'echo "📺 Tmux layouts: tdl <ai>, tdlm <ai>, tsl <count> <cmd>"' >> "$HOME/.bashrc"
fi

echo "✅ Tmux ready! Run: tdl opencode"

# =====================
# LazyVim setup
# =====================
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
