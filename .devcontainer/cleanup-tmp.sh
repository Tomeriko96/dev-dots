#!/usr/bin/env bash
# Ruimt /tmp op: die staat op de container-overlay (geen tmpfs) en groeit anders onbeperkt.
#   - Claude Code-scratchpads (/tmp/claude-<uid>/<project>/<sessie>) zonder wijziging in $DAYS dagen;
#     daar staan worktrees met eigen .venv/node_modules van 1-2 GB per stuk
#   - .<hex>-NNNNNNNN.so die Bun-binaries (opencode) bij elke start uitpakken en laten staan
# Daarna `git worktree prune` zodat repos niet naar verdwenen worktrees blijven wijzen.
# Draait als postStartCommand; handmatig: bash .devcontainer/cleanup-tmp.sh [dagen]
set -uo pipefail

DAYS="${1:-3}"
SCRATCH="/tmp/claude-$(id -u)"
WORKSPACE="$(cd "$(dirname "$0")/.." && pwd)"

# Sessies waar nu een proces in draait niet aanraken
in_use="$(for p in /proc/[0-9]*; do readlink "$p/cwd" 2>/dev/null; done | grep "^$SCRATCH/" || true)"

freed=0
for d in "$SCRATCH"/*/*/; do
  [[ -d "$d" ]] || continue
  d="${d%/}"
  grep -qF "$d" <<<"$in_use" && continue
  # recent gewijzigd bestand gevonden → sessie nog in gebruik
  [[ -n "$(find "$d" -mmin -$((DAYS * 1440)) -print -quit 2>/dev/null)" ]] && continue
  freed=$((freed + $(du -sk "$d" 2>/dev/null | cut -f1)))
  rm -rf "$d"
done

find /tmp -maxdepth 1 -name '.*-[0-9]*.so' -type f -mtime +0 -delete 2>/dev/null

for r in "$WORKSPACE"/*/; do
  [[ -e "$r/.git" ]] && git -C "$r" worktree prune 2>/dev/null
done

echo "cleanup-tmp: $((freed / 1024)) MB aan scratchpads ouder dan $DAYS dagen verwijderd"
