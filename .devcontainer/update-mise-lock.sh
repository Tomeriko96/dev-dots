#!/usr/bin/env bash
# Regenerate .devcontainer/mise.lock from .devcontainer/mise.toml.
#
# Run this after changing a version or tool in mise.toml, then commit both files.
# The lock covers Linux x86_64 only (the image's platform). Supporting ARM would
# need an explicit change here plus a tested arm64 build.
#
# Usage:
#   .devcontainer/update-mise-lock.sh            # lock pinned versions
#   .devcontainer/update-mise-lock.sh --bump     # re-resolve ranges such as node = "24"
#   .devcontainer/update-mise-lock.sh --verify   # also do a clean locked install in a temp dir
#
# Needs mise on PATH (the devcontainer has it). A GitHub token avoids API rate
# limits; it's taken from `gh auth token` when GITHUB_TOKEN isn't set.
set -euo pipefail

PLATFORM="linux-x64"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

verify=false
lock_args=()
for arg in "$@"; do
  case "$arg" in
    --verify) verify=true ;;
    --bump) lock_args+=(--bump) ;;
    -h|--help) sed -n '2,14p' "$0"; exit 0 ;;
    *) echo "unknown argument: $arg" >&2; exit 2 ;;
  esac
done

command -v mise >/dev/null || { echo "mise not found on PATH" >&2; exit 1; }

if [[ -z "${GITHUB_TOKEN:-}" ]] && command -v gh >/dev/null; then
  GITHUB_TOKEN="$(gh auth token 2>/dev/null || true)"
  export GITHUB_TOKEN
fi

# Keep the user's own mise config and settings out of the lock.
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
export MISE_GLOBAL_CONFIG_FILE="$tmp/global.toml"
export MISE_TRUSTED_CONFIG_PATHS="$DIR"
export MISE_YES=1

cd "$DIR"
mise lock --platform "$PLATFORM" "${lock_args[@]}"
mise lock --check --platform "$PLATFORM"

if "$verify"; then
  echo "Verifying with a clean locked install in $tmp ..."
  env -u GITHUB_TOKEN -u GH_TOKEN \
    MISE_DATA_DIR="$tmp/data" MISE_CACHE_DIR="$tmp/cache" MISE_STATE_DIR="$tmp/state" \
    mise install --locked
  echo "Locked install OK"
fi
