#!/usr/bin/env bash
set -euo pipefail

echo "🔥 Starting post-create.sh..."
echo "👤 Running as: $(id)"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULES_DIR="$SCRIPT_DIR/../modules"

# Setup PATH
# shellcheck source=../modules/setup-path.sh
source "$MODULES_DIR/setup-path.sh"

# Verify ALL CLIs are available
echo "✅ CLIs available:"
for cli in opencode claude copilot; do
  which "$cli" 2>/dev/null && echo "  ✅ $cli: $(which $cli)" || echo "  ❌ $cli: missing"
done

# LazyVim setup
# shellcheck source=../modules/setup-lazyvim.sh
source "$MODULES_DIR/setup-lazyvim.sh"

# Tmux dev layouts setup
# shellcheck source=../modules/setup-tmux.sh
source "$MODULES_DIR/setup-tmux.sh" "$SCRIPT_DIR"
