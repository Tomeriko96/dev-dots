#!/usr/bin/env bash
# Tests for the cd -> zd alias (#98) and the zoxide/starship hook order (#99).
#
# Runs interactive shells with this repo's bash/.bashrc and bash/.config/bash
# in a temporary HOME and a temporary zoxide database, so your own HOME and
# zoxide history are not touched. Needs zoxide, starship and uv on PATH (as in
# the devcontainer).
#
# Usage: bash bash/tests/test-cd.sh   (exits non-zero when a check fails)

# The commands passed to run_i expand in the inner shell, hence single quotes.
# shellcheck disable=SC2016
set -u

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
failed=0

for tool in zoxide starship uv; do
  if ! command -v "$tool" >/dev/null; then
    echo "[FAIL] $tool not on PATH; run this inside the devcontainer" >&2
    exit 1
  fi
done

tmp=$(mktemp -d)
# Resolve /tmp symlinks (e.g. on macOS) so $PWD comparisons are exact.
tmp=$(cd "$tmp" && pwd -P)
trap 'rm -rf "$tmp"' EXIT

home="$tmp/home"
mkdir -p "$home/.config" "$tmp/zo" "$tmp/a/b" "$tmp/other" "$tmp/projects/foobarproj"
cp "$repo/bash/.bashrc" "$home/.bashrc"
cp -R "$repo/bash/.config/bash" "$home/.config/bash"
ln -s "$tmp/a/b" "$tmp/link"

export HOME="$home" _ZO_DATA_DIR="$tmp/zo"
unset CDPATH PROMPT_COMMAND STARSHIP_PROMPT_COMMAND

# run_i <command>: run <command> in an interactive shell (rc loaded), stdout only.
run_i() {
  bash -ic "$1" 2>/dev/null
}

check() { # check <name> <expected> <actual>
  if [ "$2" = "$3" ]; then
    echo "[OK]   $1"
  else
    echo "[FAIL] $1"
    echo "       expected: $2"
    echo "       actual:   $3"
    failed=1
  fi
}

# --- Precondition: cd really is the zd alias -------------------------------
check "cd is aliased to zd" "alias cd='zd'" "$(run_i 'alias cd')"

# --- #98.1: failing cd gives a non-zero exit code --------------------------
check "cd /does/not/exist returns non-zero" "1" \
  "$(run_i 'cd /does/not/exist; echo $?')"
check "cd /does/not/exist && echo RAN does not run" "" \
  "$(run_i 'cd /does/not/exist && echo RAN')"

# --- #98.4: the error goes to stderr, not stdout ---------------------------
check "cd /nope prints nothing on stdout" "" "$(run_i 'cd /nope 2>/dev/null')"
check "cd /nope prints an error on stderr" "yes" \
  "$(bash -ic 'cd /nope' 2>&1 >/dev/null | grep -q 'zd: no such directory' && echo yes)"

# --- #98.2: options behave like builtin cd ---------------------------------
check "cd -P <symlink> resolves the physical dir" "0 $tmp/a/b" \
  "$(run_i "cd -P '$tmp/link'; echo \$? \$PWD")"
check "cd -L <symlink> keeps the logical dir" "0 $tmp/link" \
  "$(run_i "cd -L '$tmp/link'; echo \$? \$PWD")"
check "cd -- <dir>" "0 $tmp/other" \
  "$(run_i "cd -- '$tmp/other'; echo \$? \$PWD")"
check "cd - returns to the previous dir" "0 $tmp/a" \
  "$(run_i "cd '$tmp/a'; cd '$tmp/other'; cd - >/dev/null; echo \$? \$PWD")"
check "cd -P /does/not/exist returns non-zero" "1" \
  "$(run_i 'cd -P /does/not/exist; echo $?')"

# --- #98.3: no args, existing dir, zoxide fallback -------------------------
check "cd without args goes to HOME" "0 $home" \
  "$(run_i "cd '$tmp/other'; cd; echo \$? \$PWD")"
check "cd <existing dir>" "0 $tmp/a/b" \
  "$(run_i "cd '$tmp/a/b'; echo \$? \$PWD")"
zoxide add "$tmp/projects/foobarproj"
check "cd <term> falls back to a zoxide match" "0 $tmp/projects/foobarproj" \
  "$(run_i "cd '$tmp/other'; cd foobarproj >/dev/null; echo \$? \$PWD")"
check "cd <term> without zoxide match returns non-zero" "1 $tmp/other" \
  "$(run_i "cd '$tmp/other'; cd nomatchxyzzy; echo \$? \$PWD")"

# --- #99.1 and #99.4: PROMPT_COMMAND order ---------------------------------
pc=$(run_i 'echo "$PROMPT_COMMAND"')
check "PROMPT_COMMAND contains starship_precmd" "yes" \
  "$([[ $pc == *starship_precmd* ]] && echo yes)"
check "PROMPT_COMMAND contains __zoxide_hook" "yes" \
  "$([[ $pc == *__zoxide_hook* ]] && echo yes)"
check "starship_precmd is first in PROMPT_COMMAND" "yes" \
  "$([[ $pc == starship_precmd* ]] && echo yes)"
if grep -q 'history -a' "$home/.bashrc" "$home/.config/bash/"*; then
  check "history -a still runs from PROMPT_COMMAND" "yes" \
    "$(run_i 'echo "$PROMPT_COMMAND;${STARSHIP_PROMPT_COMMAND-}"' | grep -q 'history -a' && echo yes)"
fi

# --- #99.2 and #99.3: zoxide learns dirs, no doctor warning ----------------
# Commands come from stdin so the shell shows prompts and runs PROMPT_COMMAND.
mkdir -p "$tmp/learnme"
err=$(printf 'cd %q\nz foobarproj\n' "$tmp/learnme" | bash -i 2>&1 >/dev/null)
check "zoxide learns a dir after cd" "yes" \
  "$(zoxide query --list | grep -qxF "$tmp/learnme" && echo yes)"
check "no zoxide doctor warning" "" \
  "$(grep -F 'detected a possible configuration issue' <<<"$err")"

exit "$failed"
