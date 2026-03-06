#!/usr/bin/env bash
# Module: setup-tmux.sh
# Installs tmux.conf and tmux-dev-layouts.sh from the supplied config directory,
# and wires them up in ~/.bashrc for future shells.
#
# Usage (source from a post-create script):
#   TMUX_CONFIG_DIR="/path/to/dir/containing/tmux.conf" source setup-tmux.sh
# Or pass the directory as the first positional argument:
#   source setup-tmux.sh /path/to/dir/containing/tmux.conf

echo "🖥️  Setting up tmux..."

_tmux_config_dir="${1:-${TMUX_CONFIG_DIR:-}}"

if [[ -z "$_tmux_config_dir" ]]; then
  echo "❌ setup-tmux.sh: no config directory provided (set TMUX_CONFIG_DIR or pass as \$1)" >&2
  unset _tmux_config_dir
  return 1
fi

# Install tmux.conf
if [[ -f "$_tmux_config_dir/tmux.conf" ]]; then
  cp "$_tmux_config_dir/tmux.conf" "$HOME/.tmux.conf"
  echo "✅ tmux.conf installed"
else
  echo "⚠️  tmux.conf not found in $_tmux_config_dir"
fi

# Install tmux-dev-layouts.sh
if [[ -f "$_tmux_config_dir/tmux-dev-layouts.sh" ]]; then
  cp "$_tmux_config_dir/tmux-dev-layouts.sh" "$HOME/.tmux-dev-layouts.sh"
  chmod +x "$HOME/.tmux-dev-layouts.sh"

  # Remove any stale source line and append a fresh one
  sed -i '/\.tmux-dev-layouts\.sh/d' "$HOME/.bashrc" 2>/dev/null || true
  echo 'source "$HOME/.tmux-dev-layouts.sh"' >> "$HOME/.bashrc"

  if ! grep -q 'Tmux layouts:' "$HOME/.bashrc" 2>/dev/null; then
    echo 'echo "📺 Tmux layouts: tdl <ai>, tdlm <ai>, tsl <count> <cmd>"' >> "$HOME/.bashrc"
  fi

  echo "✅ Tmux dev layouts ready! Run: tdl copilot"
else
  echo "⚠️  tmux-dev-layouts.sh not found in $_tmux_config_dir"
fi

unset _tmux_config_dir
