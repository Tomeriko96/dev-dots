#!/usr/bin/env bash
# Block Claude from reading .env files (receives tool input JSON on stdin)
set -euo pipefail

input=$(cat)
tool_name=$(echo "$input" | jq -r '.tool_name // empty')

case "$tool_name" in
  Read)
    file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')
    if [[ "$file_path" == *.env || "$file_path" == */.env.* || "$file_path" == */.env ]]; then
      echo '{"decision":"block","reason":"reading .env files is not allowed"}'
      exit 2
    fi
    ;;
  Bash)
    command=$(echo "$input" | jq -r '.tool_input.command // empty')
    if echo "$command" | grep -qE '(cat|head|tail|less|more|bat)\s+.*\.env(\s|$|")'; then
      echo '{"decision":"block","reason":"reading .env files via shell is not allowed"}'
      exit 2
    fi
    ;;
esac

exit 0
