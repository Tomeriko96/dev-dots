#!/usr/bin/env bash
set -euo pipefail

echo "🔥 Starting post-create.sh..."
echo "👤 Running as: $(id)"

# Verify key CLIs are available (all installed via Dockerfile)
echo "✅ CLIs available:"
for cli in nvim opencode claude uv starship zoxide node npm Rscript csvlens; do
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
echo "💡 Tip: Run 'claude-setup' to set your ANTHROPIC_FOUNDRY_API_KEY and ANTHROPIC_FOUNDRY_RESOURCE"
echo "📺 Tmux layouts: tdl <ai>, tdlm <ai>, tsl <count> <cmd>"

echo ""
echo "🧭 Run 'onboard' to launch the interactive post-build checklist wizard"
echo "   (gh auth login + opencode auth + claude-setup in one guided flow)"

echo "✅ Post-create complete. Run 'nvim .' or 'tdl opencode' to get started."

