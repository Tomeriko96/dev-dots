#!/usr/bin/env bash
set -euo pipefail

echo "🔥 Starting post-create.sh..."
echo "👤 Running as: $(id)"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULES_DIR="$SCRIPT_DIR/modules"

# Setup PATH
# shellcheck source=modules/setup-path.sh
source "$MODULES_DIR/setup-path.sh"

# OpenCode CLI check
if which opencode >/dev/null 2>&1; then
  echo "✅ OpenCode CLI available: $(which opencode)"
else
  echo "❌ OpenCode CLI missing from PATH"
fi

# LazyVim setup
# shellcheck source=modules/setup-lazyvim.sh
source "$MODULES_DIR/setup-lazyvim.sh"
