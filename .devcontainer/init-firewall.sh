#!/usr/bin/env bash
# init-firewall.sh — OPT-IN egress allowlist for the devcontainer (cedanl/dev-dots#23).
#
# Goal: a prompt-injected or malicious agent/dependency must not be able to send credentials or
# code to an arbitrary host. Outbound traffic is dropped except to an allowlist (GitHub, Anthropic,
# npm, PyPI, GitLab, ...). Loopback, DNS to the configured resolvers and replies to inbound
# connections (forwarded ports) keep working. IPv6 egress is blocked.
#
# Not active by default. It runs only from the "firewall" devcontainer variant
# (.devcontainer/firewall/devcontainer.json), which adds NET_ADMIN and calls
# `sudo /usr/local/sbin/init-firewall.sh` on start. The sudoers rule allows exactly this script
# with no arguments, and the script is root-owned, so the dev user (and any agent running as dev)
# can re-apply the firewall but cannot disable or widen it.
#
# Extra allowed hosts: set DEVDOTS_FIREWALL_EXTRA (space/comma separated domains) in the
# *container environment* (containerEnv in the variant). It is read from PID 1's environment,
# which the dev user cannot change; a file or variable the dev user controls would let an
# attacker add their own host. Re-run `sudo /usr/local/sbin/init-firewall.sh` to refresh the IPs
# (CDN-backed hosts rotate addresses).
#
# Limits (be honest about them): allowlisting by resolved IP is coarse (shared CDNs, e.g. a
# github.io page behind the same range, are reachable); DNS to the resolver is open, so DNS
# tunnelling is possible; this does not stop exfiltration to an allowed host (e.g. pushing to a
# GitHub repo the token can write to) -- use fine-grained, short-lived tokens for that.
#
# FIREWALL_DRY_RUN=1 (only honoured when run directly, sudo strips the environment) prints the
# rules instead of applying them and does not need root.
set -euo pipefail
IFS=$'\n\t'

DRY_RUN="${FIREWALL_DRY_RUN:-0}"
log() { echo "[firewall] $*" >&2; }
run() { if [ "$DRY_RUN" = 1 ]; then (IFS=' '; echo "+ $*"); else "$@"; fi; }

# Domains every CEDA workflow needs. GitHub is covered by its published IP ranges (below).
CORE_DOMAINS=(
  # Claude Code / Anthropic
  api.anthropic.com console.anthropic.com claude.ai sentry.io
  # GitHub content hosts (also in the meta ranges; listed in case the ranges lag)
  raw.githubusercontent.com objects.githubusercontent.com codeload.github.com api.githubcopilot.com
  # Package registries
  registry.npmjs.org pypi.org files.pythonhosted.org
  # GitLab (gitlab.com and SURF; SURF moved to git.sdp.surf.nl on 2026-11-16, git.ia.surf.nl holds archived projects)
  gitlab.com git.sdp.surf.nl git.ia.surf.nl
  # Tooling
  opencode.ai entire.io
)

if [ "$DRY_RUN" != 1 ]; then
  [ "$(id -u)" -eq 0 ] || { log "must run as root (sudo /usr/local/sbin/init-firewall.sh)"; exit 1; }
fi

# iptables backend: try the default, fall back to legacy (some hosts lack nf_tables in containers).
IPT=iptables
IP6T=ip6tables
if [ "$DRY_RUN" != 1 ]; then
  if ! iptables -S >/dev/null 2>&1; then
    if command -v iptables-legacy >/dev/null 2>&1 && iptables-legacy -S >/dev/null 2>&1; then
      IPT=iptables-legacy
      IP6T=ip6tables-legacy
    else
      log "iptables is not usable (does the container have --cap-add=NET_ADMIN?). Firewall NOT active."
      exit 1
    fi
  fi
fi

# ipset is nicer (one rule, atomic swap) but needs host kernel support that rootless podman may
# lack; fall back to one iptables rule per address.
USE_IPSET=0
if [ "$DRY_RUN" = 1 ] || { command -v ipset >/dev/null 2>&1 && ipset create -exist dd-probe hash:net 2>/dev/null && ipset destroy dd-probe 2>/dev/null; }; then
  USE_IPSET=1
fi

tmp=$(mktemp)
trap 'rm -f "$tmp" "$tmp.cidrs"' EXIT

# --- Collect allowed IPv4 networks -------------------------------------------------------------
: >"$tmp.cidrs"

log "Fetching GitHub IP ranges"
if meta=$(curl -fsS --connect-timeout 10 https://api.github.com/meta); then
  echo "$meta" |
    jq -r '(.web + .api + .git + .packages + .pages + .copilot)[]' |
    grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/[0-9]+$' >>"$tmp.cidrs" || true
else
  log "WARNING: could not fetch https://api.github.com/meta (GitHub ranges missing)"
fi

extra=""
if [ "$DRY_RUN" = 1 ]; then
  extra="${DEVDOTS_FIREWALL_EXTRA:-}"
elif [ -r /proc/1/environ ]; then
  extra=$(tr '\0' '\n' </proc/1/environ | sed -n 's/^DEVDOTS_FIREWALL_EXTRA=//p' | head -n1)
fi

domains=("${CORE_DOMAINS[@]}")
for d in $(echo "$extra" | tr ', ' '\n\n'); do
  if [[ "$d" =~ ^[A-Za-z0-9]([A-Za-z0-9.-]*[A-Za-z0-9])?$ ]]; then
    domains+=("$d")
  else
    log "ignoring invalid extra domain: $d"
  fi
done

for d in "${domains[@]}"; do
  ips=$(getent ahostsv4 "$d" 2>/dev/null | awk '{print $1}' | sort -u || true)
  if [ -z "$ips" ]; then
    log "WARNING: $d did not resolve"
    continue
  fi
  while read -r ip; do echo "$ip/32" >>"$tmp.cidrs"; done <<<"$ips"
done
sort -u "$tmp.cidrs" -o "$tmp.cidrs"
log "Allowing $(wc -l <"$tmp.cidrs") networks ($(printf '%s\n' "${domains[@]}" | wc -l) domains + GitHub ranges)"

# --- Resolvers ---------------------------------------------------------------------------------
mapfile -t NS4 < <(awk '$1=="nameserver" && $2 ~ /^[0-9.]+$/ {print $2}' /etc/resolv.conf)
mapfile -t NS6 < <(awk '$1=="nameserver" && $2 ~ /:/ {print $2}' /etc/resolv.conf)

# --- Apply (IPv4) ------------------------------------------------------------------------------
# Only the filter table's OUTPUT chain is touched, so the runtime's own NAT/DNS rules survive.
if [ "$USE_IPSET" = 1 ]; then
  run ipset create -exist allowed-domains-new hash:net maxelem 65536
  run ipset flush allowed-domains-new
  if [ "$DRY_RUN" = 1 ]; then
    echo "+ ipset add allowed-domains-new <$(wc -l <"$tmp.cidrs") networks>"
  else
    sed 's/^/add -exist allowed-domains-new /' "$tmp.cidrs" | ipset restore
  fi
  run ipset create -exist allowed-domains hash:net maxelem 65536
  run ipset swap allowed-domains-new allowed-domains
  run ipset destroy allowed-domains-new
fi

run "$IPT" -F OUTPUT
run "$IPT" -A OUTPUT -o lo -j ACCEPT
run "$IPT" -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
for ns in "${NS4[@]}"; do
  run "$IPT" -A OUTPUT -p udp -d "$ns" --dport 53 -j ACCEPT
  run "$IPT" -A OUTPUT -p tcp -d "$ns" --dport 53 -j ACCEPT
done
if [ "$USE_IPSET" = 1 ]; then
  run "$IPT" -A OUTPUT -m set --match-set allowed-domains dst -j ACCEPT
else
  while read -r cidr; do run "$IPT" -A OUTPUT -d "$cidr" -j ACCEPT; done <"$tmp.cidrs"
fi
run "$IPT" -A OUTPUT -j REJECT --reject-with icmp-admin-prohibited
run "$IPT" -P OUTPUT DROP

# --- Apply (IPv6): nothing but loopback, replies and the resolvers ---------------------------
if [ "$DRY_RUN" = 1 ] || command -v "$IP6T" >/dev/null 2>&1; then
  run "$IP6T" -F OUTPUT
  run "$IP6T" -A OUTPUT -o lo -j ACCEPT
  run "$IP6T" -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
  for ns in "${NS6[@]}"; do
    run "$IP6T" -A OUTPUT -p udp -d "$ns" --dport 53 -j ACCEPT
    run "$IP6T" -A OUTPUT -p tcp -d "$ns" --dport 53 -j ACCEPT
  done
  run "$IP6T" -P OUTPUT DROP
fi

[ "$DRY_RUN" = 1 ] && { log "dry run done"; exit 0; }

# --- Verify ------------------------------------------------------------------------------------
log "Verifying"
if curl -fsS --connect-timeout 5 -o /dev/null https://example.com 2>/dev/null; then
  log "FAIL: https://example.com is still reachable -- firewall is not enforcing"
  exit 1
fi
if ! curl -fsS --connect-timeout 5 -o /dev/null https://api.github.com/zen 2>/dev/null; then
  log "FAIL: https://api.github.com is not reachable -- allowlist or DNS problem"
  exit 1
fi
curl -fsS --connect-timeout 5 -o /dev/null https://api.anthropic.com 2>/dev/null ||
  [ "$?" -eq 22 ] || log "WARNING: api.anthropic.com may be unreachable (Claude Code needs it)"
log "Egress firewall active: only the allowlist is reachable (extra hosts: DEVDOTS_FIREWALL_EXTRA)"
