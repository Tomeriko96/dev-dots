#!/usr/bin/env bash
# Module: setup-path.sh
# Ensures $HOME/.local/bin and standard system paths are on PATH,
# and persists the export in ~/.bashrc for future shells.

if ! grep -q '.local/bin' "$HOME/.bashrc"; then
  echo 'export PATH="$HOME/.local/bin:/usr/local/bin:/usr/local/sbin:/usr/bin:/sbin:/bin:$PATH"' >> "$HOME/.bashrc"
fi
export PATH="$HOME/.local/bin:/usr/local/bin:/usr/local/sbin:/usr/bin:/sbin:/bin:$PATH"
echo "✅ PATH configured"
