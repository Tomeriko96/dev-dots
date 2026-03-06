#!/usr/bin/env bash

# ~/.tmux-dev-layouts.sh — Tmux dev layout helpers
# Source this file in your .bashrc: source ~/.tmux-dev-layouts.sh

# =====================
# Internal helpers
# =====================

_in_tmux() {
  [[ -n "$TMUX" ]]
}

# =====================
# tdl — editor + AI pane(s) + terminal
# =====================
# Usage: tdl <ai_cmd> [<second_ai_cmd>]
# Example: tdl opencode
# Example: tdl opencode claude
tdl() {
  if [[ -z $1 ]]; then
    echo "Usage: tdl <ai_cmd> [<second_ai_cmd>]"
    echo "  Opens: nvim (main) | terminal strip (bottom) | AI pane(s) (right)"
    return 1
  fi

  local ai="$1"
  local ai2="${2:-}"
  local current_dir="${PWD}"

  if ! _in_tmux; then
    # Not in tmux — create a new session and bootstrap the layout
    tmux new-session -d -s "dev" -c "$current_dir"
    tmux send-keys -t "dev" "tdl $ai${ai2:+ $ai2}" C-m
    exec tmux attach-session -t "dev"
    return
  fi

  local editor_pane="$TMUX_PANE"
  local ai_pane ai2_pane

  tmux rename-window -t "$editor_pane" "$(basename "$current_dir")"

  # Terminal strip at the bottom (15% height)
  tmux split-window -v -p 15 -t "$editor_pane" -c "$current_dir"

  # AI pane on the right (30% width)
  ai_pane=$(tmux split-window -h -p 30 -t "$editor_pane" -c "$current_dir" -P -F '#{pane_id}')

  if [[ -n $ai2 ]]; then
    ai2_pane=$(tmux split-window -v -t "$ai_pane" -c "$current_dir" -P -F '#{pane_id}')
    tmux send-keys -t "$ai2_pane" "$ai2" C-m
  fi

  tmux send-keys -t "$ai_pane" "$ai" C-m
  tmux send-keys -t "$editor_pane" "nvim ." C-m
  tmux select-pane -t "$editor_pane"
}

# =====================
# tdlm — one tdl window per subdirectory
# =====================
# Usage: tdlm <ai_cmd> [<second_ai_cmd>]
# Example: tdlm opencode
tdlm() {
  if [[ -z $1 ]]; then
    echo "Usage: tdlm <ai_cmd> [<second_ai_cmd>]"
    echo "  Opens a tdl window for every subdirectory of the current directory"
    return 1
  fi

  local ai="$1"
  local ai2="${2:-}"
  local base_dir="$PWD"

  if ! _in_tmux; then
    tmux new-session -d -s "dev" -c "$base_dir"
    tmux send-keys -t "dev" "tdlm $ai${ai2:+ $ai2}" C-m
    exec tmux attach-session -t "dev"
    return
  fi

  tmux rename-session "$(basename "$base_dir" | tr '.:' '--')"

  local first=true
  for dir in "$base_dir"/*/; do
    [[ -d $dir ]] || continue
    local dirpath="${dir%/}"

    if $first; then
      tmux send-keys -t "$TMUX_PANE" "cd '$dirpath' && tdl $ai${ai2:+ $ai2}" C-m
      first=false
    else
      local pane_id
      pane_id=$(tmux new-window -c "$dirpath" -P -F '#{pane_id}')
      tmux send-keys -t "$pane_id" "tdl $ai${ai2:+ $ai2}" C-m
    fi
  done
}

# =====================
# tsl — command swarm across N panes
# =====================
# Usage: tsl <pane_count> <command>
# Example: tsl 4 opencode
tsl() {
  if [[ -z $1 || -z $2 ]]; then
    echo "Usage: tsl <pane_count> <command>"
    echo "  Starts <command> in <pane_count> tiled panes"
    return 1
  fi

  local count="$1"
  local cmd="$2"
  local current_dir="${PWD}"

  if ! _in_tmux; then
    tmux new-session -d -s "dev" -c "$current_dir"
    tmux send-keys -t "dev" "tsl $count $cmd" C-m
    exec tmux attach-session -t "dev"
    return
  fi

  local -a panes
  tmux rename-window -t "$TMUX_PANE" "$(basename "$current_dir")"
  panes+=("$TMUX_PANE")

  while (( ${#panes[@]} < count )); do
    local split_target="${panes[-1]}"
    local new_pane
    new_pane=$(tmux split-window -h -t "$split_target" -c "$current_dir" -P -F '#{pane_id}')
    panes+=("$new_pane")
    tmux select-layout -t "${panes[0]}" tiled
  done

  for pane in "${panes[@]}"; do
    tmux send-keys -t "$pane" "$cmd" C-m
  done

  tmux select-pane -t "${panes[0]}"
}
