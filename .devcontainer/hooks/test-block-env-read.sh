#!/usr/bin/env bash
# Tests for block-env-read.sh: feeds synthetic tool-input JSON to the hook and
# checks its exit code (2 = blocked, 0 = allowed). Reads no real env file.
# Usage: bash .devcontainer/hooks/test-block-env-read.sh
set -uo pipefail

HOOK="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/block-env-read.sh"
failed=0
total=0

# check <expected-exit> <label> <json>
check() {
  local expected=$1 label=$2 json=$3 out actual
  total=$((total + 1))
  out=$(printf '%s' "$json" | bash "$HOOK" 2>&1)
  actual=$?
  if [[ "$actual" -ne "$expected" ]]; then
    echo "[FAIL] $label: expected exit $expected, got $actual"
    failed=$((failed + 1))
  elif [[ "$expected" -eq 2 ]] && ! printf '%s' "$out" | jq -e '.decision == "block"' >/dev/null 2>&1; then
    echo "[FAIL] $label: exit 2 without block JSON: $out"
    failed=$((failed + 1))
  else
    echo "[OK]   $label (exit $actual)"
  fi
}

read_case() { check "$1" "Read $2" "$(jq -nc --arg p "$2" '{tool_name:"Read",tool_input:{file_path:$p}}')"; }
bash_case() { check "$1" "Bash $2" "$(jq -nc --arg c "$2" '{tool_name:"Bash",tool_input:{command:$c}}')"; }
grep_case() {
  # grep_case <expected> <path> <glob> (empty = field absent)
  check "$1" "Grep path='$2' glob='$3'" "$(jq -nc --arg p "$2" --arg g "$3" \
    '{tool_name:"Grep",tool_input:({pattern:"x"} + (if $p == "" then {} else {path:$p} end) + (if $g == "" then {} else {glob:$g} end))}')"
}

E=.env   # keeps the literal file name out of this file's command lines

# 1. Grep tool
grep_case 2 "/p/$E" ""
grep_case 2 "$E.local" ""
grep_case 2 "" "**/$E*"
grep_case 2 "" "$E.production"
grep_case 2 "src" "$E"

# 2. Bash: .env.<suffix>
bash_case 2 "cat $E.local"
bash_case 2 "cat $E.production"

# 3. Bash: more readers, existing blocks, paths with directories
bash_case 2 "grep . $E"
bash_case 2 "rg x $E"
bash_case 2 "rg x $E.local"
bash_case 2 "sed -n p $E"
bash_case 2 "awk 1 $E"
bash_case 2 "source $E"
bash_case 2 ". $E"
bash_case 2 ". ./$E.local"
bash_case 2 "cat $E"
bash_case 2 "cat < $E"
bash_case 2 "cat /p/$E"
bash_case 2 "cat \"./sub/$E\""
bash_case 2 "head -n1 $E.example $E"
read_case 2 "/p/$E"
read_case 2 "/p/$E.local"
read_case 2 "/p/prod.env"

# 4. Still allowed
bash_case 0 "cat ${E}rc"
bash_case 0 "cat environment.md"
bash_case 0 "cat $E.example"
bash_case 0 "cat $E.sample"
bash_case 0 "grep foo README.md"
bash_case 0 "rg process.env src/"
grep_case 0 "src/" "*.md"
grep_case 0 "/p/$E.example" ""
read_case 0 "/p/${E}rc"
read_case 0 "/p/$E.example"
check 0 "Write (other tool)" "$(jq -nc --arg p "/p/$E" '{tool_name:"Write",tool_input:{file_path:$p}}')"

echo "$((total - failed))/$total passed"
[[ "$failed" -eq 0 ]]
