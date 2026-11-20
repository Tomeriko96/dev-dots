#!/usr/bin/env bash
# =============================================================================
# test-onboard-identity.sh — tests _set_git_identity from onboard.sh
# =============================================================================
# Uses a stub 'gh' on PATH and a temporary HOME / GIT_CONFIG_GLOBAL, so the
# real git config and gh login are never touched.
#
# Run: bash .devcontainer/test-onboard-identity.sh
# =============================================================================
set -uo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

mkdir -p "$tmp/bin" "$tmp/home"
# Stub gh: 'auth status' succeeds unless GH_STUB_AUTHED=0; 'api user -q .X'
# prints GH_STUB_LOGIN / GH_STUB_ID (empty when unset).
cat >"$tmp/bin/gh" <<'STUB'
#!/usr/bin/env bash
case "$1 $2" in
  "auth status") [[ "${GH_STUB_AUTHED:-1}" == 1 ]] ;;
  "api user")
    [[ "${GH_STUB_API_FAIL:-0}" == 1 ]] && exit 1
    case "$4" in
      .login) echo "${GH_STUB_LOGIN:-}" ;;
      .id)    echo "${GH_STUB_ID:-}" ;;
    esac ;;
  *) exit 2 ;;
esac
STUB
chmod +x "$tmp/bin/gh"

export PATH="$tmp/bin:$PATH"
export HOME="$tmp/home"
export GIT_CONFIG_GLOBAL="$tmp/gitconfig"
export GIT_CONFIG_NOSYSTEM=1

# shellcheck source=onboard.sh
source "$here/onboard.sh"

failed=0
_reset() { rm -f "$GIT_CONFIG_GLOBAL"; unset GH_STUB_AUTHED GH_STUB_API_FAIL; GH_STUB_LOGIN=octo; GH_STUB_ID=42; export GH_STUB_LOGIN GH_STUB_ID; }
_get()   { git config --global --get "$1" || true; }
_check() { # name, expected, actual
  if [[ "$2" == "$3" ]]; then echo "[PASS] $1"; else echo "[FAIL] $1: expected '$2', got '$3'"; failed=1; fi
}

# 1. Empty config: both are set from the gh login
_reset
_set_git_identity >/dev/null; rc=$?
_check "empty: rc 0" 0 "$rc"
_check "empty: user.name" octo "$(_get user.name)"
_check "empty: user.email" "42+octo@users.noreply.github.com" "$(_get user.email)"

# 2. Running twice gives the same config
first="$(git config --global --list)"
_set_git_identity >/dev/null
_check "twice: identical config" "$first" "$(git config --global --list)"

# 3. Only user.name set: name kept, email set
_reset
git config --global user.name "Jane Doe"
_set_git_identity >/dev/null
_check "partial name: user.name kept" "Jane Doe" "$(_get user.name)"
_check "partial name: user.email set" "42+octo@users.noreply.github.com" "$(_get user.email)"

# 4. Only user.email set: email kept, name set
_reset
git config --global user.email "jane@example.org"
_set_git_identity >/dev/null
_check "partial email: user.name set" octo "$(_get user.name)"
_check "partial email: user.email kept" "jane@example.org" "$(_get user.email)"

# 5. Both set: nothing changes, even with gh logged out
_reset
git config --global user.name "Jane Doe"
git config --global user.email "jane@example.org"
before="$(git config --global --list)"
GH_STUB_AUTHED=0 _set_git_identity >/dev/null; rc=$?
_check "both set: rc 0" 0 "$rc"
_check "both set: unchanged" "$before" "$(git config --global --list)"

# 6. gh not authenticated: message, rc 0, nothing set
_reset
out="$(GH_STUB_AUTHED=0 _set_git_identity)"; rc=$?
_check "no login: rc 0" 0 "$rc"
_check "no login: skip message" 1 "$([[ "$out" == *"[SKIPPED]"* ]] && echo 1 || echo 0)"
_check "no login: user.name empty" "" "$(_get user.name)"
_check "no login: user.email empty" "" "$(_get user.email)"

# 7. gh api fails or returns empty: message, rc 0, nothing set
_reset
out="$(GH_STUB_API_FAIL=1 _set_git_identity)"; rc=$?
_check "api fails: rc 0" 0 "$rc"
_check "api fails: skip message" 1 "$([[ "$out" == *"[SKIPPED]"* ]] && echo 1 || echo 0)"
_check "api fails: nothing set" "" "$(_get user.name)$(_get user.email)"
_reset
out="$(GH_STUB_LOGIN='' _set_git_identity)"; rc=$?
_check "api empty: rc 0" 0 "$rc"
_check "api empty: nothing set" "" "$(_get user.name)$(_get user.email)"

[[ $failed -eq 0 ]] && echo "All onboard identity tests passed."
exit "$failed"
