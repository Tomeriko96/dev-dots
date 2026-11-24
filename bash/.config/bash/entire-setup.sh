#!/usr/bin/env bash
# entire-setup — zet Entire goed in voor CEDA-repo's, ongeacht waar je Claude start.
#
# Gebruik:  entire-setup [--check] [--quiet] [--agent claude-code] [pad ...]
#
#   zonder pad   de repo van de huidige map, plus elke repo direct onder de workspace-root
#                ($DEVDOTS_WORKSPACE, standaard /workspaces/dev-dots)
#   --check      alleen controleren en rapporteren, niets aanpassen
#   --quiet      alleen fouten en de eenmalige privacymelding tonen (voor de claude-wrapper)
#   --agent      agent waarvoor de hooks komen (standaard claude-code)
#
# CEDA-repo = origin met `cedanl/` (GitHub) of `surf-internal/npuls/ceda/` (GitLab, git.sdp.surf.nl).
# Alle checkpoints gaan naar dezelfde privé GitHub-repo; Entire kent als checkpoint-remote alleen `github`.
#
# Uitzetten:  export DEVDOTS_ENTIRE=0           (alle repo's)
#             git config devdots.entire false   (alleen deze repo)
#
# Idempotent en snel: een repo die al klopt wordt alleen gelezen. Exitcode 1 als een repo niet aan staat.

set -u

CHECKPOINT_REMOTE="github:cedanl/entire-checkpoints"
BACKEND="branch"
AGENT="claude-code"
CHECK=0
QUIET=0
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE="${DEVDOTS_WORKSPACE:-/workspaces/dev-dots}"

paths=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --check) CHECK=1 ;;
    --quiet) QUIET=1 ;;
    --agent) AGENT="${2:?--agent vraagt een waarde}"; shift ;;
    -h | --help) sed -n '2,19p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) paths+=("$1") ;;
  esac
  shift
done

[[ "${DEVDOTS_ENTIRE:-1}" == "0" ]] && { ((QUIET)) || echo "Entire staat uit (DEVDOTS_ENTIRE=0)."; exit 0; }
command -v entire >/dev/null 2>&1 || { echo "✗ entire is niet geïnstalleerd (niet op PATH)" >&2; exit 1; }

say() { ((QUIET)) || echo "$@"; }

is_ceda_repo() {
  case "$(git -C "$1" remote get-url origin 2>/dev/null || true)" in
    *cedanl/* | *surf-internal/npuls/ceda/*) return 0 ;;
    *) return 1 ;;
  esac
}

# Klopt de instelling én staan de hooks erin?
is_set_up() {
  local dir="$1" settings hooks
  # Lokale instellingen gaan voor op de gedeelde; lees ze beide, de lokale wint.
  settings="$(cat "$dir/.entire/settings.json" "$dir/.entire/settings.local.json" 2>/dev/null)"
  [[ -n "$settings" ]] || return 1
  grep -q '"enabled": *true' <<<"$settings" || return 1
  [[ "$(grep -oE '"git-(branch|refs)"' <<<"$settings" | tail -1)" == '"git-branch"' ]] || return 1
  grep -q 'cedanl/entire-checkpoints' <<<"$settings" || return 1
  hooks="$(git -C "$dir" rev-parse --git-path hooks 2>/dev/null)" || return 1
  [[ "$hooks" = /* ]] || hooks="$dir/$hooks"
  grep -qs 'entire' "$hooks/post-commit" || return 1
  # Agent-hooks: in de repo (lokaal of gedeeld) of globaal
  grep -qs 'entire hooks' "$dir/.claude/settings.local.json" "$dir/.claude/settings.json" "$HOME/.claude/settings.json" || return 1
}

# Eenmalig per repo; gebundeld tot één melding per run (zie einde van het script).
notified=()
privacy_notice() {
  local dir="$1" notice
  notice="$(git -C "$dir" rev-parse --git-path devdots-entire-notified 2>/dev/null)" || return 0
  [[ "$notice" = /* ]] || notice="$dir/$notice"
  [[ -e "$notice" ]] && return 0
  notified+=("$(basename "$dir")")
  : >"$notice" 2>/dev/null || true
}

print_privacy_notice() {
  ((${#notified[@]} > 0)) || return 0
  {
    echo "┌─ Entire staat aan voor: ${notified[*]}"
    echo "│ Sessietranscripten (prompts, tool-output en antwoorden) worden bewaard"
    echo "│ in github:cedanl/entire-checkpoints. Zet geen geheimen of persoonsgegevens"
    echo "│ in een sessie als je dat niet wilt delen."
    echo "│ Uitzetten: git config devdots.entire false   (per repo)"
    echo "│            export DEVDOTS_ENTIRE=0           (alle repo's)"
    echo "└──────────────────────────────────────────────────────────────────────"
  } >&2
}

# `entire enable` schrijft zijn hooks in .claude/settings.json, een bestand dat repo's vaak in git hebben.
# entire-local-hooks.py zet ze in .claude/settings.local.json en herstelt settings.json;
# .entire/ en het lokale bestand gaan in .git/info/exclude.
keep_local() {
  local dir="$1" exclude pattern
  exclude="$(git -C "$dir" rev-parse --git-path info/exclude 2>/dev/null)" || return 0
  [[ "$exclude" = /* ]] || exclude="$dir/$exclude"
  mkdir -p "$(dirname "$exclude")"
  for pattern in "/.entire/" "/.claude/settings.local.json"; do
    grep -qxF "$pattern" "$exclude" 2>/dev/null || echo "$pattern" >>"$exclude"
  done
  (cd "$dir" && python3 "$SCRIPT_DIR/entire-local-hooks.py") || true
}

failures=0
report() { # status naam tekst
  case "$1" in
    ok) say "✓ $2  $3" ;;
    fixed) say "✓ $2  $3" ;;
    skip) say "- $2  $3" ;;
    fail) echo "✗ $2  $3" >&2; failures=$((failures + 1)) ;;
  esac
}

first_line() { grep -v '^[[:space:]]*$' | head -1 | cut -c1-200; }

setup_repo() {
  local dir name out rc
  dir="$(git -C "$1" rev-parse --show-toplevel 2>/dev/null)" || return 0
  name="$(basename "$dir")"

  if ! is_ceda_repo "$dir"; then report skip "$name" "geen CEDA-repo (origin)"; return 0; fi
  if [[ "$(git -C "$dir" config --get devdots.entire 2>/dev/null)" == "false" ]]; then
    report skip "$name" "uitgezet (git config devdots.entire false)"; return 0
  fi
  if is_set_up "$dir"; then report ok "$name" "Entire staat goed"; return 0; fi
  if ((CHECK)); then report fail "$name" "Entire staat niet goed (draai: entire-setup)"; return 0; fi

  out="$(cd "$dir" && entire enable -y --agent "$AGENT" 2>&1)"; rc=$?
  if ((rc != 0)); then report fail "$name" "entire enable mislukt: $(echo "$out" | first_line)"; return 0; fi
  # Staat .entire/settings.json in git (zoals in dair-agentic-coding), pas dan alleen de lokale kopie aan.
  local scope=()
  git -C "$dir" ls-files --error-unmatch .entire/settings.json >/dev/null 2>&1 && scope=(--local)
  out="$(cd "$dir" && entire configure "${scope[@]}" --checkpoint-backend "$BACKEND" --checkpoint-remote "$CHECKPOINT_REMOTE" 2>&1)"; rc=$?
  if ((rc != 0)); then report fail "$name" "entire configure mislukt: $(echo "$out" | first_line)"; return 0; fi
  keep_local "$dir"
  if is_set_up "$dir"; then privacy_notice "$dir"; report fixed "$name" "aangezet"; else report fail "$name" "na het aanzetten klopt het nog niet (zie: cd $dir && entire status)"; fi
}

if ((${#paths[@]} > 0)); then
  for p in "${paths[@]}"; do setup_repo "$p"; done
else
  # De repo waar je staat, en elke repo direct onder de workspace-root.
  cwd_repo="$(git rev-parse --show-toplevel 2>/dev/null || true)"
  [[ -n "$cwd_repo" ]] && setup_repo "$cwd_repo"
  for d in "$WORKSPACE"/*/; do
    d="${d%/}"
    [[ -e "$d/.git" ]] || continue
    [[ "$d" == "$cwd_repo" ]] && continue
    setup_repo "$d"
  done
  # Staat de workspace-root zelf ook onder git (de dev-dots-repo)?
  [[ -e "$WORKSPACE/.git" && "$WORKSPACE" != "$cwd_repo" ]] && setup_repo "$WORKSPACE"
fi

print_privacy_notice
exit $((failures > 0))
