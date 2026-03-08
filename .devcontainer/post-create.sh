#!/usr/bin/env bash
set -euo pipefail

echo "🔥 Starting post-create.sh..."
echo "👤 Running as: $(id)"

# Verify key CLIs are available (all installed via Dockerfile)
echo "✅ CLIs available:"
for cli in nvim opencode uv starship zoxide node npm Rscript; do
  which "$cli" 2>/dev/null && echo "  ✅ $cli: $(which $cli)" || echo "  ⚠️  $cli: missing"
done

# Print git tooling summary
echo ""
echo "🛠️  Git tooling available:"
for cli in git lazygit gh delta; do
  which "$cli" >/dev/null 2>&1 && echo "  ✅ $cli: $(which $cli)" || echo "  ❌ $cli: missing"
done
GH_DASH_BIN="$HOME/.local/share/gh/extensions/gh-dash/gh-dash"
[[ -x "$GH_DASH_BIN" ]] && echo "  ✅ gh-dash: $GH_DASH_BIN" || echo "  ❌ gh-dash: missing"

echo ""
echo "💡 Tip: Run 'gh auth login' to authenticate with GitHub (enables gh and gh-dash)"
echo "💡 Tip: Run 'lazygit' to open the lazygit TUI"
echo "💡 Tip: Run 'gh dash' to open the GitHub dashboard TUI (after gh auth login)"
echo "💡 Tip: Run 'tdl opencode' to open a tmux dev layout with OpenCode"
echo "📺 Tmux layouts: tdl <ai>, tdlm <ai>, tsl <count> <cmd>"

echo "✅ Post-create complete. Run 'nvim .' or 'tdl opencode' to get started."

