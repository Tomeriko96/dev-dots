#!/usr/bin/env bash
# =============================================================================
# onboard.sh — Post-build onboarding wizard
# =============================================================================
# Guides you through the three authentication/setup steps needed after each
# fresh container build:
#
#   1. gh auth login       – primary GitHub account (git + gh CLI)
#   2. opencode auth login – secondary GitHub account (GitHub Copilot in OpenCode)
#   3. claude-setup        – Anthropic Foundry API key & resource name
#
# Run via the shell function:  onboard
# Or directly:                 bash ~/.onboard.sh
# =============================================================================

# Note: -e is intentionally omitted.  The check helpers (_gh_authed etc.) use
# commands that return non-zero to signal "not configured" — adding -e would
# abort the script in those cases.  Each step runner captures its own exit
# codes and uses '|| true' where failure should be non-fatal.
set -uo pipefail

# ── colour helpers ────────────────────────────────────────────────────────────
BOLD='\033[1m'
DIM='\033[2m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

_bold()   { printf "${BOLD}%s${RESET}"   "$*"; }
_dim()    { printf "${DIM}%s${RESET}"    "$*"; }
_red()    { printf "${RED}%s${RESET}"    "$*"; }
_green()  { printf "${GREEN}%s${RESET}"  "$*"; }
_yellow() { printf "${YELLOW}%s${RESET}" "$*"; }
_cyan()   { printf "${CYAN}%s${RESET}"   "$*"; }

# ── status helpers ────────────────────────────────────────────────────────────
_done()    { echo -e "  ${GREEN}✔${RESET}  $*"; }
_pending() { echo -e "  ${YELLOW}◌${RESET}  $*"; }
_skip()    { echo -e "  ${DIM}–${RESET}  $* ${DIM}(skipped)${RESET}"; }
_info()    { echo -e "  ${CYAN}ℹ${RESET}  $*"; }
_error()   { echo -e "  ${RED}✖${RESET}  $*" >&2; }
_section() { echo -e "\n${BOLD}${CYAN}▶ $*${RESET}"; }

# ── check helpers ─────────────────────────────────────────────────────────────

# Returns 0 if gh is authenticated (any account), non-zero otherwise
_gh_authed() {
  gh auth status &>/dev/null
}

# Returns 0 if the Claude secrets file has non-empty key and resource values
_claude_configured() {
  local secrets="$HOME/.claude/secrets.sh"
  [[ -f "$secrets" ]] \
    && grep -qE 'ANTHROPIC_FOUNDRY_API_KEY="[^"]+"' "$secrets" \
    && grep -qE 'ANTHROPIC_FOUNDRY_RESOURCE="[^"]+"' "$secrets"
}

# Returns 0 if opencode appears to have auth credentials stored
_opencode_authed() {
  # OpenCode stores provider config in ~/.config/opencode/config.json
  # (or the XDG_CONFIG_HOME equivalent).  We look for a copilot/github entry.
  local cfg="${XDG_CONFIG_HOME:-$HOME/.config}/opencode/config.json"
  [[ -f "$cfg" ]] && grep -qi '"copilot"\|"github_copilot"\|"github-copilot"' "$cfg" 2>/dev/null
}

# ── prompt helpers ────────────────────────────────────────────────────────────

# Ask user a yes/no question; default answer shown in brackets.
# Usage: _ask_yn "prompt" [Y|N]   → returns 0 for yes, 1 for no
_ask_yn() {
  local prompt="$1"
  local default="${2:-Y}"
  local hint
  if [[ "${default^^}" == "Y" ]]; then
    hint="[Y/n]"
  else
    hint="[y/N]"
  fi

  while true; do
    read -r -p "$(echo -e "  ${YELLOW}?${RESET}  ${prompt} ${DIM}${hint}${RESET} ")" answer
    answer="${answer:-$default}"
    case "${answer^^}" in
      Y) return 0 ;;
      N) return 1 ;;
      *) echo -e "  Please answer y or n." ;;
    esac
  done
}

# ── step runners ──────────────────────────────────────────────────────────────

run_gh_auth() {
  _section "Step 1 / 3 — GitHub CLI authentication (primary account)"
  echo ""
  _info "This authenticates $(_bold 'gh') and $(_bold 'git') with your primary GitHub account."
  _info "You will be prompted to choose a protocol (HTTPS/SSH) and login method."
  echo ""

  if _gh_authed; then
    _done "Already authenticated:"
    gh auth status 2>&1 | sed 's/^/        /'
    echo ""
    if ! _ask_yn "Re-authenticate (switch account or refresh token)?"; then
      _skip "gh auth login"
      return 0
    fi
  fi

  echo ""
  gh auth login
  local rc=$?
  echo ""
  if [[ $rc -eq 0 ]]; then
    _done "gh auth login completed successfully."
  else
    _error "gh auth login exited with code $rc. You can retry with: $(_bold 'gh auth login')"
  fi
  return $rc
}

run_opencode_auth() {
  _section "Step 2 / 3 — OpenCode × GitHub Copilot (secondary account)"
  echo ""
  _info "This connects $(_bold 'opencode') to GitHub Copilot using your secondary GitHub account."
  _info "OpenCode will open an interactive setup — select $(_bold 'GitHub Copilot') as the provider"
  _info "and follow the browser / device-code flow to sign in."
  echo ""

  if _opencode_authed; then
    _done "A Copilot/GitHub provider entry already exists in the OpenCode config."
    echo ""
    if ! _ask_yn "Run opencode auth login again anyway?"; then
      _skip "opencode auth login"
      return 0
    fi
  fi

  if ! command -v opencode &>/dev/null; then
    _error "opencode is not installed. Skipping."
    return 1
  fi

  echo ""
  _info "Running: $(_bold 'opencode auth login')"
  echo ""
  opencode auth login
  local rc=$?
  echo ""
  if [[ $rc -eq 0 ]]; then
    _done "opencode auth login completed successfully."
  else
    _error "opencode auth login exited with code $rc."
    _info "You can retry later with: $(_bold 'opencode auth login')"
  fi
  return $rc
}

run_claude_setup() {
  _section "Step 3 / 3 — Claude / Anthropic Foundry setup"
  echo ""
  _info "This sets your $(_bold 'ANTHROPIC_FOUNDRY_API_KEY') and $(_bold 'ANTHROPIC_FOUNDRY_RESOURCE')"
  _info "in $(_dim '~/.claude/secrets.sh') — they will be sourced into your shell when the wizard exits."
  echo ""

  if _claude_configured; then
    _done "Claude secrets already configured in ~/.claude/secrets.sh"
    echo ""
    if ! _ask_yn "Edit the secrets file again (rotate key / change resource)?"; then
      _skip "claude-setup"
      return 0
    fi
  fi

  # claude-setup is a shell function; if this script is sourced it's available,
  # but if run as a subprocess we fall back to the inline implementation.
  if declare -f claude-setup &>/dev/null; then
    echo ""
    claude-setup
  else
    _info "Opening ~/.claude/secrets.sh in nvim…"
    local secrets="$HOME/.claude/secrets.sh"
    if [[ ! -f "$secrets" ]]; then
      mkdir -p "$(dirname -- "$secrets")"
      cat >"$secrets" <<'TMPL'
# Claude Foundry secrets — fill these in after container creation
# Edit this file: use 'claude-setup' or edit directly at ~/.claude/secrets.sh
export ANTHROPIC_FOUNDRY_API_KEY=""
export ANTHROPIC_FOUNDRY_RESOURCE=""
TMPL
      _info "Created template secrets file: $secrets"
    fi
    if command -v nvim &>/dev/null; then
      nvim "$secrets"
    else
      _error "nvim not found. Please edit $secrets manually."
      return 1
    fi
    # Validate syntax before sourcing to avoid partial execution of a bad file
    if ! bash -n "$secrets" 2>/dev/null; then
      _error "Syntax error in $secrets. Please fix it and run 'claude-setup' again."
      return 1
    fi
    if source "$secrets"; then
      _done "Claude secrets saved. They will be loaded into your shell when the wizard exits."
    else
      _error "Failed to source $secrets. Please check the file for syntax errors."
      return 1
    fi
  fi
}

# ── summary ───────────────────────────────────────────────────────────────────

print_summary() {
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo -e "${BOLD}  Onboarding summary${RESET}"
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo ""

  if _gh_authed; then
    _done "gh / git  — authenticated"
  else
    _pending "gh / git  — $(_bold 'not authenticated')  →  run: $(_yellow 'gh auth login')"
  fi

  if _opencode_authed; then
    _done "opencode  — Copilot provider configured"
  else
    _pending "opencode  — $(_bold 'not configured')  →  run: $(_yellow 'opencode auth login')"
  fi

  if _claude_configured; then
    _done "claude    — Foundry secrets configured"
  else
    _pending "claude    — $(_bold 'not configured')  →  run: $(_yellow 'claude-setup')"
  fi

  echo ""
}

# ── main ──────────────────────────────────────────────────────────────────────

main() {
  clear
  echo ""
  echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════╗${RESET}"
  echo -e "${BOLD}${CYAN}║       dev-dots — post-build onboarding       ║${RESET}"
  echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════╝${RESET}"
  echo ""
  echo -e "  Welcome! This wizard walks you through the three auth/setup"
  echo -e "  steps needed after each fresh container build."
  echo ""

  # Quick pre-flight status
  echo -e "${BOLD}  Current status:${RESET}"
  if _gh_authed;       then _done "gh auth login";   else _pending "gh auth login"; fi
  if _opencode_authed; then _done "opencode auth login"; else _pending "opencode auth login"; fi
  if _claude_configured; then _done "claude-setup";  else _pending "claude-setup"; fi
  echo ""

  if _ask_yn "Run the wizard now?"; then
    echo ""

    # Step 1
    run_gh_auth || true

    # Step 2
    run_opencode_auth || true

    # Step 3
    run_claude_setup || true

    print_summary
    echo -e "  All done! Run ${BOLD}onboard${RESET} at any time to re-run individual steps."
    echo ""
  else
    echo ""
    echo -e "  Skipped. Run ${BOLD}onboard${RESET} at any time to start the wizard."
    echo ""
  fi
}

main "$@"
