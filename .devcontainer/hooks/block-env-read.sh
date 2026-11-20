#!/usr/bin/env bash
# Block Claude from reading .env files (receives tool input JSON on stdin).
#
# Covers the Read and Grep tools and Bash commands that name an env file
# (.env or .env.<suffix>; .env.example and .env.sample are allowed).
# This is a best-effort denylist, not a sandbox: obfuscated commands (eval,
# variable expansion, python -c, ...) can still get around it.
set -euo pipefail

# is_env_name <basename>: true for .env, .env.<suffix> and globs such as
# .env* that match them; false for .env.example and .env.sample.
is_env_name() {
  case "$1" in
    .env.example | .env.sample) return 1 ;;
    .env | .env.* | .env[*?[]*) return 0 ;;
  esac
  return 1
}

# is_env_path <path>: is_env_name on the last path component, plus *.env
# (e.g. prod.env), which the Read check has always blocked.
is_env_path() {
  local name=${1##*/}
  is_env_name "$name" && return 0
  [[ "$name" == *.env ]]
}

block() {
  echo "{\"decision\":\"block\",\"reason\":\"$1\"}"
  exit 2
}

input=$(cat)
tool_name=$(echo "$input" | jq -r '.tool_name // empty')

case "$tool_name" in
  Read)
    file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')
    if [[ -n "$file_path" ]] && is_env_path "$file_path"; then
      block "reading .env files is not allowed"
    fi
    ;;
  Grep)
    for field in path glob; do
      value=$(echo "$input" | jq -r --arg f "$field" '.tool_input[$f] // empty')
      if [[ -n "$value" ]] && is_env_path "$value"; then
        block "searching .env files is not allowed"
      fi
    done
    ;;
  Bash)
    command=$(echo "$input" | jq -r '.tool_input.command // empty')
    # Split the command into words on whitespace, quotes and shell operators,
    # then check the last path component of every word. This catches any
    # reader (cat, grep, rg, sed, awk, source, ., < redirects, ...).
    while IFS= read -r word; do
      if [[ -n "$word" ]] && is_env_name "${word##*/}"; then
        block "reading .env files via shell is not allowed"
      fi
    done < <(printf '%s\n' "$command" | tr -s " \t;&|<>(){}\`\"'=," '\n')
    ;;
esac

exit 0
