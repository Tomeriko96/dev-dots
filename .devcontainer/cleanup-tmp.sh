#!/usr/bin/env bash
# Ruimt /tmp op: die staat op de container-overlay (geen tmpfs) en groeit anders onbeperkt.
#   - Claude Code-scratchpads (/tmp/claude-<uid>/<project>/<sessie>) zonder wijziging in $DAYS dagen;
#     daar staan worktrees met eigen .venv/node_modules van 1-2 GB per stuk. Een sessie met een
#     worktree met niet-gecommitte wijzigingen blijft staan (gemeld, niet verwijderd).
#   - .<hex>-NNNNNNNN.so die Bun-binaries (opencode) bij elke start uitpakken en laten staan
#   - uv-cache: `uv cache prune` ruimt ook de script-omgevingen op (~/.cache/uv/environments-v2)
#     die `uv run --with playwright <script>.py` per scriptnaam aanmaakt (~140 MB per stuk)
# Daarna `git worktree prune` zodat repos niet naar verdwenen worktrees blijven wijzen.
# Draait als postStartCommand; handmatig: bash .devcontainer/cleanup-tmp.sh [dagen]
set -uo pipefail

DAYS="${1:-3}"
SCRATCH="/tmp/claude-$(id -u)"
WORKSPACE="$(cd "$(dirname "$0")/.." && pwd)"

# Toont worktrees onder $1 met niet-gecommitte wijzigingen (venv/node_modules/cache tellen niet)
dirty_worktrees() {
  local g w
  while IFS= read -r g; do
    w="$(dirname "$g")"
    git -C "$w" status --porcelain 2>/dev/null \
      | grep -qvE '^\?\? (\.venv|\.uv_cache|node_modules|frontend/node_modules)/?$' && echo "$w"
  done < <(find "$1" -maxdepth 4 -name .git -type f 2>/dev/null)
}

# Sessies waar nu een proces in draait niet aanraken
in_use="$(for p in /proc/[0-9]*; do readlink "$p/cwd" 2>/dev/null; done | grep "^$SCRATCH/" || true)"

freed=0
for d in "$SCRATCH"/*/*/; do
  [[ -d "$d" ]] || continue
  d="${d%/}"
  grep -qF "$d" <<<"$in_use" && continue
  # recent gewijzigd bestand gevonden → sessie nog in gebruik
  [[ -n "$(find "$d" -mmin -$((DAYS * 1440)) -print -quit 2>/dev/null)" ]] && continue
  dirty="$(dirty_worktrees "$d")"
  if [[ -n "$dirty" ]]; then
    echo "cleanup-tmp: overgeslagen, niet-gecommit werk in:"; sed 's/^/  /' <<<"$dirty"
    continue
  fi
  freed=$((freed + $(du -sk "$d" 2>/dev/null | cut -f1)))
  rm -rf "$d"
done

find /tmp -maxdepth 1 -name '.*-[0-9]*.so' -type f -mtime +0 -delete 2>/dev/null

# Niet prunen terwijl een script uit een uv-omgeving draait: prune haalt die omgeving weg
if command -v uv >/dev/null; then
  # [2]: anders vindt grep zijn eigen zoekterm in /proc/<grep>/cmdline
  if grep -qs 'environments-v[2]' /proc/[0-9]*/cmdline; then
    echo "cleanup-tmp: uv-cache overgeslagen (er draait een uv-script)"
  else
    uv cache prune -q 2>/dev/null
  fi
fi

for r in "$WORKSPACE"/*/; do
  [[ -e "$r/.git" ]] && git -C "$r" worktree prune 2>/dev/null
done

echo "cleanup-tmp: $((freed / 1024)) MB aan scratchpads ouder dan $DAYS dagen verwijderd"
