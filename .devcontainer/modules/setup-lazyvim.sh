#!/usr/bin/env bash
# Module: setup-lazyvim.sh
# Clones the LazyVim starter config into ~/.config/nvim if not already present.

CONFIG_DIR="$HOME/.config/nvim"
LAZYVIM_REPO="https://github.com/LazyVim/starter"

mkdir -p "$(dirname "$CONFIG_DIR")"
if [[ ! -d "$CONFIG_DIR" ]]; then
  git clone "$LAZYVIM_REPO" "$CONFIG_DIR"
  rm -rf "$CONFIG_DIR/.git"
  echo "✅ LazyVim installed"
else
  echo "⚠️  LazyVim already exists at $CONFIG_DIR"
fi
