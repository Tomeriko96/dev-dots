#!/usr/bin/env bash
set -euo pipefail

echo "🔥 Starting post-create.sh..."
echo "👤 Running as: $(id)"

# Verify key CLIs are available (all installed via Dockerfile)
echo "✅ CLIs available:"
for cli in nvim opencode claude uv starship zoxide node npm csvlens micromamba az azcopy azd; do
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
echo "💡 Tip: Run 'az login' to authenticate with Azure (enables az, azcopy, azd)"
echo "💡 Tip: Run 'gh auth login' to authenticate with GitHub (enables gh and gh-dash)"
echo "💡 Tip: Run 'lazygit' to open the lazygit TUI"
echo "💡 Tip: Run 'gh dash' to open the GitHub dashboard TUI (after gh auth login)"
echo "💡 Tip: Run 'tdl opencode' to open a tmux dev layout with OpenCode"
echo "💡 Tip: Run 'claude-setup' to set your ANTHROPIC_FOUNDRY_API_KEY and ANTHROPIC_FOUNDRY_RESOURCE"
echo "📺 Tmux layouts: tdl <ai>, tdlm <ai>, tsl <count> <cmd>"

echo ""
echo "🧭 Run 'onboard' to launch the interactive post-build checklist wizard"
echo "   (gh auth login + opencode auth + claude-setup in one guided flow)"

# ── Claude Code container-wide settings ──────────────────────────────────────
echo ""
echo "🤖 Configuring Claude Code container-wide settings..."

CLAUDE_DIR="$HOME/.claude"
CLAUDE_SETTINGS="$CLAUDE_DIR/settings.json"
CLAUDE_HOOKS_DIR="$CLAUDE_DIR/hooks"
REPO_HOOKS_DIR="/workspaces/dev-dots/.devcontainer/hooks"

mkdir -p "$CLAUDE_HOOKS_DIR"

# Install hook scripts
if [ -d "$REPO_HOOKS_DIR" ]; then
  cp "$REPO_HOOKS_DIR"/*.sh "$CLAUDE_HOOKS_DIR/" 2>/dev/null && \
    chmod +x "$CLAUDE_HOOKS_DIR"/*.sh
  echo "  ✅ Hooks installed to $CLAUDE_HOOKS_DIR"
fi

# Container-wide settings to merge (hook + common permissions)
CONTAINER_SETTINGS=$(cat <<'JSONEOF'
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Read|Bash",
        "command": "~/.claude/hooks/block-env-read.sh"
      }
    ]
  },
  "permissions": {
    "allow": [
      "Bash(gh repo:*)",
      "Bash(git clone:*)",
      "Bash(git add:*)",
      "Bash(git commit:*)",
      "Bash(git push:*)",
      "Bash(git log *)",
      "Bash(gh api *)",
      "Bash(gh auth *)",
      "Skill(update-config)"
    ]
  }
}
JSONEOF
)

# Merge into existing settings (preserves user preferences like model/theme)
if [ -f "$CLAUDE_SETTINGS" ]; then
  MERGED=$(jq -n --argjson existing "$(cat "$CLAUDE_SETTINGS")" --argjson new "$CONTAINER_SETTINGS" '
    $existing + {
      hooks: (($existing.hooks // {}) + $new.hooks),
      permissions: {
        allow: (($existing.permissions.allow // []) + ($new.permissions.allow // []) | unique)
      }
    }
  ')
  echo "$MERGED" > "$CLAUDE_SETTINGS"
else
  echo "$CONTAINER_SETTINGS" > "$CLAUDE_SETTINGS"
fi
echo "  ✅ Container-wide settings merged into $CLAUDE_SETTINGS"

echo ""
echo "✅ Post-create complete. Run 'nvim .' or 'tdl opencode' to get started."

