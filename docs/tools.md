---
icon: lucide/wrench
---

# Extra tools

---

## csvlens — CSV-viewer

Bekijk en verken CSV-bestanden interactief in de terminal.

```bash
csvlens bestand.csv      # open een specifiek bestand
csvlens                  # kies een CSV-bestand via fuzzy-picker
```

Navigeer met de pijltjestoetsen. Zoek met `/`. Sluit af met `q`.

---

## uv — Python-pakketbeheer

`uv` is een snelle Python package en project manager.

```bash
uv init                  # nieuw Python-project
uv add requests          # voeg een pakket toe
uv run script.py         # voer een script uit in de projectomgeving
uv sync                  # installeer alle dependencies
uv pip install pakket    # pip-compatible installatie
```

---

## Node & npm

Node.js LTS is voorgeïnstalleerd voor npm-gebaseerde tools.

```bash
node --version
npm install
npm run dev
```

---

## fd — snelle bestandszoeker

`fd` is een gebruiksvriendelijk alternatief voor `find`. Op Debian heet het commando `fdfind`.

```bash
fdfind patroon           # zoek bestanden op naam
fdfind -e py             # zoek op extensie
fdfind -t d              # zoek alleen mappen
```

`fzf` gebruikt `fdfind` intern voor snelle bestandssuggesties.

---

## jq — JSON-verwerking

```bash
cat data.json | jq '.items[]'
curl -s api/endpoint | jq '.data.name'
```

---

## htop — systeemmonitor

```bash
htop
```

Toont CPU, geheugen en actieve processen interactief. Navigeer met de pijltjestoetsen, sluit af met `q`.
