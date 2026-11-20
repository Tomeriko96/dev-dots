#!/usr/bin/env python3
"""Verplaats de hooks die `entire enable` in .claude/settings.json zette naar .claude/settings.local.json.

Aanroep vanuit de repo-root, na `entire enable`. Alleen als .claude/settings.json in git gevolgd wordt;
dan haalt het script alleen wat Entire toevoegde uit dat bestand, zodat de hooks niet gecommit worden.
Was het bestand verder gelijk aan de versie in git, dan herstelt `git checkout` het byte voor byte;
eigen, nog niet gecommitte wijzigingen van de gebruiker blijven staan.
"""

import json
import os
import re
import subprocess
import sys
from pathlib import Path

SETTINGS = Path(".claude/settings.json")
LOCAL = Path(".claude/settings.local.json")
MARKER = "entire hooks "  # zo begint elk commando dat Entire installeert
DENY = "Read(./.entire/metadata/**)"


def git(*args: str) -> subprocess.CompletedProcess:
    return subprocess.run(["git", *args], capture_output=True, text=True)


def is_entire(hook: dict) -> bool:
    return MARKER in hook.get("command", "")


def sleutel(hook: dict) -> str:
    return json.dumps(hook, sort_keys=True)


def vaste_hooks(hooks: dict | None) -> dict:
    """Per event de hooks (als sleutel) die in de gecommitte versie staan."""
    return {e: {sleutel(h) for g in gs for h in g.get("hooks", [])} for e, gs in (hooks or {}).items()}


def entire_groups(hooks: dict, behoud: dict | None = None) -> dict:
    """Per event alleen de hook-groepen met Entire-commando's (andere hooks van de repo blijven staan).

    Entire-hooks die al in `behoud` (de gecommitte versie) stonden, tellen niet mee.
    """
    vast = vaste_hooks(behoud)
    uit: dict = {}
    for event, groepen in hooks.items():
        for groep in groepen:
            eigen = [h for h in groep.get("hooks", []) if is_entire(h) and sleutel(h) not in vast.get(event, set())]
            if eigen:
                uit.setdefault(event, []).append({**groep, "hooks": eigen})
    return uit


def zonder_entire(hooks: dict, behoud: dict | None = None) -> dict:
    """De hooks zonder Entire-regels, zodat herhalen geen dubbelen geeft.

    Een groep of event valt alleen weg als hij leeg raakte door het weghalen; Entire-hooks die al in
    `behoud` (de gecommitte versie) stonden, blijven staan.
    """
    vast = vaste_hooks(behoud)
    uit: dict = {}
    for event, groepen in hooks.items():
        nieuw = []
        for groep in groepen:
            oud = groep.get("hooks", [])
            rest = [h for h in oud if not is_entire(h) or sleutel(h) in vast.get(event, set())]
            if rest or not oud or len(rest) == len(oud):
                nieuw.append({**groep, "hooks": rest} if "hooks" in groep else groep)
        if nieuw or not groepen:
            uit[event] = nieuw
    return uit


def opgeschoond(werk: dict, head: dict) -> dict:
    """`werk` zonder wat Entire toevoegde: zijn hooks, de deny-regel en lege sleutels die niet in `head` stonden."""
    uit = dict(werk)
    if isinstance(werk.get("hooks"), dict):
        hooks = zonder_entire(werk["hooks"], head.get("hooks") if isinstance(head.get("hooks"), dict) else {})
        if hooks or "hooks" in head:
            uit["hooks"] = hooks
        else:
            del uit["hooks"]
    if isinstance(werk.get("permissions"), dict):
        perms = dict(werk["permissions"])
        oud_perms = head.get("permissions") if isinstance(head.get("permissions"), dict) else {}
        if isinstance(perms.get("deny"), list) and DENY not in oud_perms.get("deny", []):
            perms["deny"] = [r for r in perms["deny"] if r != DENY]
        for soort in ("allow", "deny", "ask"):
            if perms.get(soort) == [] and soort not in oud_perms:
                del perms[soort]
        if perms or "permissions" in head:
            uit["permissions"] = perms
        else:
            del uit["permissions"]
    return uit


def inspringing(tekst: str) -> int | str:
    """De inspringing van een JSON-tekst (eerste ingesprongen regel), standaard twee spaties."""
    m = re.search(r"^([ \t]+)\S", tekst, re.MULTILINE)
    if not m:
        return 2
    return "\t" if m.group(1).startswith("\t") else len(m.group(1))


def schrijf(pad: Path, data: dict, indent: int | str = 2) -> None:
    tmp = pad.with_name(pad.name + ".tmp")
    tmp.write_text(json.dumps(data, indent=indent, ensure_ascii=False) + "\n")
    os.replace(tmp, pad)


def lees(pad: Path) -> dict | None:
    try:
        data = json.loads(pad.read_text())
    except (OSError, ValueError) as fout:
        print(f"entire_local: kan {pad} niet lezen ({fout}); niets aangepast", file=sys.stderr)
        return None
    if not isinstance(data, dict):
        print(f"entire_local: {pad} is geen JSON-object; niets aangepast", file=sys.stderr)
        return None
    return data


def main() -> int:
    if not SETTINGS.exists() or git("ls-files", "--error-unmatch", str(SETTINGS)).returncode != 0:
        return 0  # ongevolgd bestand: er is niets te beschermen
    werk = lees(SETTINGS)
    if werk is None:
        return 1
    hooks_werk = werk.get("hooks") if isinstance(werk.get("hooks"), dict) else {}
    nieuw = entire_groups(hooks_werk)
    if not nieuw:
        return 0  # Entire heeft niets toegevoegd
    # de versie in de index: die zet `git checkout --` terug (normaal gelijk aan HEAD)
    show = git("show", f":{SETTINGS.as_posix()}")
    try:
        head = json.loads(show.stdout) if show.returncode == 0 else None
    except ValueError:
        head = None
    if not isinstance(head, dict):
        print("entire_local: kan de gecommitte .claude/settings.json niet lezen; niets aangepast", file=sys.stderr)
        return 1
    # alleen de Entire-hooks die niet al gecommit waren, gaan naar het lokale bestand
    hooks_head = head.get("hooks") if isinstance(head.get("hooks"), dict) else {}
    nieuw = entire_groups(hooks_werk, hooks_head)
    lokaal = lees(LOCAL) if LOCAL.exists() else {}
    if lokaal is None:
        return 1
    voor = json.dumps(lokaal)
    if nieuw:
        hooks = zonder_entire(lokaal.get("hooks", {}))
        for event, groepen in nieuw.items():
            hooks.setdefault(event, []).extend(groepen)
        lokaal["hooks"] = hooks
    perms_werk = werk.get("permissions") if isinstance(werk.get("permissions"), dict) else {}
    perms_head = head.get("permissions") if isinstance(head.get("permissions"), dict) else {}
    if DENY in perms_werk.get("deny", []) and DENY not in perms_head.get("deny", []):
        deny = lokaal.setdefault("permissions", {}).setdefault("deny", [])
        if DENY not in deny:
            deny.append(DENY)
    if json.dumps(lokaal) != voor:
        schrijf(LOCAL, lokaal)
    schoon = opgeschoond(werk, head)
    if schoon == head:
        # alleen Entire-toevoegingen: herstel byte voor byte
        if git("checkout", "--", str(SETTINGS)).returncode != 0:
            print("entire_local: kon .claude/settings.json niet herstellen", file=sys.stderr)
            return 1
    elif schoon != werk:
        schrijf(SETTINGS, schoon, inspringing(show.stdout))  # Entire herschrijft het bestand; neem de stijl uit git
    return 0


if __name__ == "__main__":
    sys.exit(main())
