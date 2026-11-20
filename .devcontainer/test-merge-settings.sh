#!/usr/bin/env bash
# Tests merge-claude-settings.jq, the filter post-create.sh uses to merge the
# container's Claude settings into ~/.claude/settings.json. Needs only jq and
# works in a temp dir; the real ~/.claude/settings.json is never touched.
# Usage: bash .devcontainer/test-merge-settings.sh
set -euo pipefail

FILTER="${MERGE_FILTER:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/merge-claude-settings.jq}"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
export HOME="$TMP/home"
mkdir -p "$HOME"

failed=0
pass() { echo "[PASS] $1"; }
fail() { echo "[FAIL] $1"; failed=1; }
# check <description> <jq expression that must be true> <json file>
check() {
  if jq -e "$2" "$3" >/dev/null; then pass "$1"; else fail "$1"; jq . "$3"; fi
}
# merge <existing file> <new file> <output file>
merge() {
  jq -n --argjson existing "$(cat "$1")" --argjson new "$(cat "$2")" -f "$FILTER" > "$3"
}

# shellcheck disable=SC2088  # literal tilde, as in settings.json
CMD='~/.claude/hooks/block-env-read.sh'

cat > "$TMP/new.json" <<JSON
{
  "hooks": {
    "PreToolUse": [
      { "matcher": "Read|Bash", "hooks": [ { "type": "command", "command": "$CMD" } ] }
    ]
  },
  "permissions": { "allow": ["Bash(git log *)"], "deny": ["Read(**/.env)"] }
}
JSON

cat > "$TMP/existing.json" <<'JSON'
{
  "model": "opus",
  "hooks": {
    "PreToolUse": [
      { "matcher": "Write", "hooks": [ { "type": "command", "command": "~/my-own-hook.sh" } ] }
    ],
    "PostToolUse": [
      { "matcher": "Edit", "hooks": [ { "type": "command", "command": "~/format.sh" } ] }
    ],
    "Stop": [
      { "hooks": [ { "type": "command", "command": "~/notify.sh" } ] }
    ]
  },
  "permissions": { "allow": ["Bash(ls:*)"], "deny": [] }
}
JSON

# 1. The user's own PreToolUse group survives next to the container group
merge "$TMP/existing.json" "$TMP/new.json" "$TMP/out1.json"
check "1: own PreToolUse hook kept" \
  '[.hooks.PreToolUse[] | select(.matcher == "Write" and .hooks[0].command == "~/my-own-hook.sh")] | length == 1' "$TMP/out1.json"
if jq -e --arg c "$CMD" '[.hooks.PreToolUse[] | select(.hooks[].command == $c)] | length == 1' "$TMP/out1.json" >/dev/null; then
  pass "1: container PreToolUse hook added once"
else
  fail "1: container PreToolUse hook added once"; jq . "$TMP/out1.json"
fi
check "1: other keys kept" '.model == "opus"' "$TMP/out1.json"

# 2. Events the container does not use stay unchanged
if jq -e --slurpfile old "$TMP/existing.json" \
    '.hooks.PostToolUse == $old[0].hooks.PostToolUse and .hooks.Stop == $old[0].hooks.Stop' \
    "$TMP/out1.json" >/dev/null; then
  pass "2: PostToolUse and Stop unchanged"
else
  fail "2: PostToolUse and Stop unchanged"; jq . "$TMP/out1.json"
fi

# 3. Merging again on its own output gives byte-identical JSON
merge "$TMP/out1.json" "$TMP/new.json" "$TMP/out2.json"
if cmp -s "$TMP/out1.json" "$TMP/out2.json"; then
  pass "3: second merge is byte-identical"
else
  fail "3: second merge is byte-identical"; diff "$TMP/out1.json" "$TMP/out2.json" || true
fi

# 4. An older container group (same command, other matcher) is replaced; a user
#    group with the container's matcher but another command is kept
cat > "$TMP/existing4.json" <<JSON
{
  "hooks": {
    "PreToolUse": [
      { "matcher": "Read", "hooks": [ { "type": "command", "command": "$CMD" } ] },
      { "matcher": "Read|Bash", "hooks": [ { "type": "command", "command": "~/audit.sh" } ] }
    ]
  }
}
JSON
merge "$TMP/existing4.json" "$TMP/new.json" "$TMP/out4.json"
if jq -e --arg c "$CMD" \
    '[.hooks.PreToolUse[] | select(.hooks[].command == $c)] == [{matcher: "Read|Bash", hooks: [{type: "command", command: $c}]}]' \
    "$TMP/out4.json" >/dev/null; then
  pass "4: stale container group replaced by the new one"
else
  fail "4: stale container group replaced by the new one"; jq . "$TMP/out4.json"
fi
check "4: user group with the same matcher kept" \
  '[.hooks.PreToolUse[] | select(.hooks[0].command == "~/audit.sh" and .matcher == "Read|Bash")] | length == 1' "$TMP/out4.json"

# 5. Existing settings without a hooks key
echo '{"theme": "dark"}' > "$TMP/existing5.json"
merge "$TMP/existing5.json" "$TMP/new.json" "$TMP/out5.json"
if jq -e --slurpfile new "$TMP/new.json" '.hooks == $new[0].hooks and .theme == "dark"' "$TMP/out5.json" >/dev/null; then
  pass "5: missing hooks key gets the container hooks"
else
  fail "5: missing hooks key gets the container hooks"; jq . "$TMP/out5.json"
fi

if [ "$failed" -ne 0 ]; then
  echo "merge-claude-settings: tests FAILED"
  exit 1
fi
echo "merge-claude-settings: all tests passed"
