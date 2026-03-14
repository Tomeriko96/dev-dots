#!/usr/bin/env bash
set -euo pipefail

echo "🔥 Starting post-create.sh..."
echo "👤 Running as: $(id)"

# Verify key CLIs are available (all installed via Dockerfile)
echo "✅ CLIs available:"
for cli in nvim opencode claude uv starship zoxide node npm csvlens; do
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

  # --- Section 1: all dpkg/apt-managed system packages ---
  echo "## System packages (dpkg)"
  dpkg-query -W -f='  ${Package}: ${Version}\n' 2>/dev/null | sort
  echo ""

  # --- Section 2: executables found in non-system PATH dirs ---
  # Standard system dirs (/usr/bin, /bin, /sbin, /usr/sbin) are already
  # fully covered by dpkg above; scanning them again would be redundant and slow.
  # This section only probes user/local dirs (e.g. /usr/local/bin, ~/.local/bin)
  # where manually-installed tools live.
  # Uses `timeout 2` per binary to avoid hangs; tries --version then -V.
  echo "## PATH executables (non-system)"
  declare -A _seen
  while IFS= read -r _dir; do
    [ -d "$_dir" ] || continue
    # Skip standard system directories already covered by dpkg
    case "$_dir" in /usr/bin|/bin|/sbin|/usr/sbin) continue ;; esac
    for _bin in "$_dir"/*; do
      [ -x "$_bin" ] && [ -f "$_bin" ] || continue
      _name=$(basename "$_bin")
      [ "${_seen[$_name]+_}" ] && continue   # skip duplicates across PATH dirs
      _seen["$_name"]=1
      _ver=$(timeout 2 "$_bin" --version 2>&1 | grep -m1 '.' 2>/dev/null || true)
      [ -z "$_ver" ] && _ver=$(timeout 2 "$_bin" -V 2>&1 | grep -m1 '.' 2>/dev/null || true)
      [ -z "$_ver" ] && _ver="(version unknown)"
      echo "  $_name: $_ver"
    done
  done < <(echo "$PATH" | tr ':' '\n' | awk '!seen[$0]++') | sort

  # gh-dash lives outside PATH; append it separately
  echo ""
  echo "## gh extensions"
  if [[ -x "$GH_DASH_BIN" ]]; then
    _gdver=$("$GH_DASH_BIN" --version 2>&1 | grep -m1 '.' || true)
    echo "  gh-dash: $_gdver"
  else
    echo "  gh-dash: (not found)"
  fi
} > "$TOOL_VERSIONS_FILE"

echo "  ✅ Written to $TOOL_VERSIONS_FILE"

echo ""
echo "💡 Tip: Run 'gh auth login' to authenticate with GitHub (enables gh and gh-dash)"
echo "💡 Tip: Run 'lazygit' to open the lazygit TUI"
echo "💡 Tip: Run 'gh dash' to open the GitHub dashboard TUI (after gh auth login)"
echo "💡 Tip: Run 'tdl opencode' to open a tmux dev layout with OpenCode"
echo "💡 Tip: Run 'claude-setup' to set your ANTHROPIC_FOUNDRY_API_KEY and ANTHROPIC_FOUNDRY_RESOURCE"
echo "📺 Tmux layouts: tdl <ai>, tdlm <ai>, tsl <count> <cmd>"

echo "✅ Post-create complete. Run 'nvim .' or 'tdl opencode' to get started."

