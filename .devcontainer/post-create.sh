#!/usr/bin/env bash
set -euo pipefail

echo "🔥 Starting post-create.sh..."
echo "👤 Running as: $(id)"

# Verify key CLIs are available (all installed via Dockerfile)
echo "✅ CLIs available:"
for cli in nvim opencode uv starship zoxide node npm Rscript csvlens; do
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

# Collect all installed tool versions and write to tool-versions.txt
# This file is .gitignore'd; useful for debugging when a build has issues.
TOOL_VERSIONS_FILE="/workspace/tool-versions.txt"
echo ""
echo "📋 Collecting tool versions → $TOOL_VERSIONS_FILE"
{
  echo "# Tool versions captured at devcontainer post-create"
  echo "# Date: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
  echo ""

  _ver() {
    local name="$1"; shift
    if command -v "$name" >/dev/null 2>&1; then
      # Run the version command; keep only the first non-empty line
      local ver
      ver=$("$@" 2>&1 | grep -m1 '.' || true)
      echo "$name: $ver"
    else
      echo "$name: (not found)"
    fi
  }

  _ver git        git --version
  _ver lazygit    lazygit --version
  _ver gh         gh --version
  _ver delta      delta --version
  _ver nvim       nvim --version
  _ver node       node --version
  _ver npm        npm --version
  _ver uv         uv --version
  _ver starship   starship --version
  _ver zoxide     zoxide --version
  _ver fzf        fzf --version
  _ver rg         rg --version
  _ver bat        bat --version
  _ver eza        eza --version
  _ver jq         jq --version
  _ver fdfind     fdfind --version
  _ver qsv        qsv --version
  _ver csvlens    csvlens --version
  _ver Rscript    Rscript --version
  _ver opencode   opencode --version
  _ver tmux       tmux -V
  _ver htop       htop --version

  # gh-dash is not on PATH; check its binary directly
  if [[ -x "$GH_DASH_BIN" ]]; then
    local_ver=$("$GH_DASH_BIN" --version 2>&1 | grep -m1 '.' || true)
    echo "gh-dash: $local_ver"
  else
    echo "gh-dash: (not found)"
  fi
} > "$TOOL_VERSIONS_FILE"

echo "  ✅ Written to $TOOL_VERSIONS_FILE"

echo ""
echo "💡 Tip: Run 'gh auth login' to authenticate with GitHub (enables gh and gh-dash)"
echo "💡 Tip: Run 'lazygit' to open the lazygit TUI"
echo "💡 Tip: Run 'gh dash' to open the GitHub dashboard TUI (after gh auth login)"
echo "💡 Tip: Run 'tdl opencode' to open a tmux dev layout with OpenCode"
echo "📺 Tmux layouts: tdl <ai>, tdlm <ai>, tsl <count> <cmd>"

echo "✅ Post-create complete. Run 'nvim .' or 'tdl opencode' to get started."

