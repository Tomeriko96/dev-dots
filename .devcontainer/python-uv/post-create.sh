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

# LazyVim setup Setting up LazyV
echo "✨im..."
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

# Remove old tmux files
rm -f "$HOME/.tmux-dev-session.sh"
rm -f "$HOME/.tmux-dev-session.sh"

# Create tmux config
cat > "$HOME/.tmux.conf" << 'EOF'
# Tmux configuration
# Start windows and panes at 1 (not 0)
set -g base-index 1
setw -g pane-base-index 1

# Renumber windows when one is closed
set -g renumber-windows on

# Status bar
set -g status-style bg=default
set -g status-left-length 20
set -g status-right-length 50
set -g status-left '#[fg=green]#S#[default]'
set -g status-right '#[fg=yellow]#(whoami)@#h#[default]'

# Activity monitoring
setw -g monitor-activity on
set -g visual-activity off
EOF

# Create tmux layouts functions
cat > "$HOME/.tmux-dev-layouts.sh" << 'EOF'
#!/usr/bin/env bash

# Tmux Dev Layouts - Create editor+AI tmux layouts
# Source this file or add to your .bashrc: source ~/.tmux-dev-layouts.sh

# Helper to check if in tmux
_in_tmux() {
  [[ -n "$TMUX" ]] && return 0
  return 1
}

# Create a Tmux Dev Layout with editor, ai, and terminal
# Usage: tdl <claude|copilot|opencode> [<second_ai>]
tdl() {
  [[ -z $1 ]] && { echo "Usage: tdl <claude|copilot|opencode> [<second_ai>]"; return 1; }

  local ai="$1"
  local ai2="$2"
  local current_dir="${PWD}"

  if ! _in_tmux; then
    # Not in tmux - create session and run layout
    tmux new-session -d -s "dev" -c "$current_dir"
    tmux send-keys -t "dev" "tdl $ai${ai2:+ $ai2}" C-m
    exec tmux attach-session -t "dev"
  fi

  # Inside tmux - run layout
  local editor_pane="$TMUX_PANE"
  local ai_pane ai2_pane

  tmux rename-window -t "$editor_pane" "$(basename "$current_dir")"

  tmux split-window -v -p 15 -t "$editor_pane" -c "$current_dir"

  ai_pane=$(tmux split-window -h -p 30 -t "$editor_pane" -c "$current_dir" -P -F '#{pane_id}')

  if [[ -n $ai2 ]]; then
    ai2_pane=$(tmux split-window -v -t "$ai_pane" -c "$current_dir" -P -F '#{pane_id}')
    tmux send-keys -t "$ai2_pane" "$ai2" C-m
  fi

  tmux send-keys -t "$ai_pane" "$ai" C-m

  tmux send-keys -t "$editor_pane" "nvim ." C-m

  tmux select-pane -t "$editor_pane"
}

# Create multiple tdl windows with one per subdirectory in the current directory
# Usage: tdlm <claude|copilot|opencode> [<second_ai>]
tdlm() {
  [[ -z $1 ]] && { echo "Usage: tdlm <claude|copilot|opencode> [<second_ai>]"; return 1; }

  local ai="$1"
  local ai2="$2"
  local base_dir="$PWD"

  if ! _in_tmux; then
    tmux new-session -d -s "dev" -c "$base_dir"
    tmux send-keys -t "dev" "tdlm $ai${ai2:+ $ai2}" C-m
    exec tmux attach-session -t "dev"
  fi

  # Inside tmux - run layout
  local first=true

  tmux rename-session "$(basename "$base_dir" | tr '.:' '--')"

  for dir in "$base_dir"/*/; do
    [[ -d $dir ]] || continue
    local dirpath="${dir%/}"

    if $first; then
      tmux send-keys -t "$TMUX_PANE" "cd '$dirpath' && tdl $ai $ai2" C-m
      first=false
    else
      local pane_id=$(tmux new-window -c "$dirpath" -P -F '#{pane_id}')
      tmux send-keys -t "$pane_id" "tdl $ai $ai2" C-m
    fi
  done
}

# Create a multi-pane swarm layout with the same command started in each pane (great for AI)
# Usage: tsl <pane_count> <command>
tsl() {
  [[ -z $1 || -z $2 ]] && { echo "Usage: tsl <pane_count> <command>"; return 1; }

  local count="$1"
  local cmd="$2"
  local current_dir="${PWD}"

  if ! _in_tmux; then
    local escaped_cmd
    printf -v escaped_cmd '%q' "$cmd"
    tmux new-session -d -s "dev" -c "$current_dir"
    tmux send-keys -t "dev" "tsl $count $escaped_cmd" C-m
    exec tmux attach-session -t "dev"
  fi

  # Inside tmux - run layout
  local -a panes

  tmux rename-window -t "$TMUX_PANE" "$(basename "$current_dir")"

  panes+=("$TMUX_PANE")

  while (( ${#panes[@]} < count )); do
    local new_pane
    local split_target="${panes[-1]}"
    new_pane=$(tmux split-window -h -t "$split_target" -c "$current_dir" -P -F '#{pane_id}')
    panes+=("$new_pane")
    tmux select-layout -t "${panes[0]}" tiled
  done

  for pane in "${panes[@]}"; do
    tmux send-keys -t "$pane" "$cmd" C-m
  done

  tmux select-pane -t "${panes[0]}"
}
EOF

chmod +x "$HOME/.tmux-dev-layouts.sh"

# Source layouts in bashrc (remove old source line if exists, add new)
sed -i '/\.tmux-dev-layouts\.sh/d' "$HOME/.bashrc" 2>/dev/null || true
echo 'source "$HOME/.tmux-dev-layouts.sh"' >> "$HOME/.bashrc"

# Add startup echo
if ! grep -q 'Tmux layouts:' "$HOME/.bashrc" 2>/dev/null; then
  echo 'echo "📺 Tmux layouts: tdl <ai>, tdlm <ai>, tsl <count> <cmd>"' >> "$HOME/.bashrc"
fi

echo "✅ Tmux dev layouts ready! Run: tdl copilot"
