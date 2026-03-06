#!/usr/bin/env bash
# fzf configuration
# Source this file from ~/.bashrc or ~/.config/bash/rc

# Use fd as the default fzf source (faster, respects .gitignore)
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'

# Default fzf options
export FZF_DEFAULT_OPTS="
  --height=50%
  --layout=reverse
  --border=rounded
  --info=inline
  --prompt='❯ '
  --pointer='▶'
  --marker='✓'
  --bind='ctrl-/:toggle-preview'
  --bind='ctrl-u:preview-page-up'
  --bind='ctrl-d:preview-page-down'
  --color=fg:#c0caf5,bg:#1a1b26,hl:#bb9af7
  --color=fg+:#c0caf5,bg+:#292e42,hl+:#7dcfff
  --color=info:#7aa2f7,prompt:#7dcfff,pointer:#f7768e
  --color=marker:#9ece6a,spinner:#9ece6a,header:#9ece6a
"

# Ctrl-T: Paste selected file path into command line
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS="
  --preview 'command -v batcat >/dev/null && batcat --style=numbers --color=always --line-range :200 {} || cat {}'
  --preview-window=right:60%:wrap
"

# Alt-C: cd into selected directory
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
export FZF_ALT_C_OPTS="
  --preview 'ls -la {}'
  --preview-window=right:50%
"

# Ctrl-R: Enhanced history search (already bound in functions, but keep opts)
export FZF_CTRL_R_OPTS="
  --preview 'echo {}'
  --preview-window=down:3:hidden:wrap
  --bind='?:toggle-preview'
  --sort
  --exact
"

# Load fzf shell integration if available
if [[ -f /usr/share/doc/fzf/examples/key-bindings.bash ]]; then
  source /usr/share/doc/fzf/examples/key-bindings.bash
fi
if [[ -f /usr/share/bash-completion/completions/fzf ]]; then
  source /usr/share/bash-completion/completions/fzf
fi
