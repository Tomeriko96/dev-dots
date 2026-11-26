---
icon: lucide/square-terminal
---

# Shell

De shell is Bash met een laag productiviteitstools. Alles is geladen via `~/.bashrc` en de bestanden in `~/.config/bash/`.

---

## Navigatie

### zoxide — slimme cd

`cd` is vervangen door zoxide. Het onthoudt mappen die je eerder hebt bezocht en springt er snel naartoe op basis van een gedeeltelijke naam.

Stel dat je één keer naar een diep pad bent gegaan:

```bash
cd /workspace/klant/project-backend/src/api
```

De volgende keer kun je typen:

```bash
cd api        # springt direct naar …/src/api
cd backend    # springt naar …/project-backend
cd klant      # springt naar …/klant (de best overeenkomende map)
```

Hoe vaker je een map bezoekt, hoe hoger de prioriteit. Werkt meteen, wordt slimmer met gebruik.

### Directory-shortcuts

```bash
..               # cd ..
...              # cd ../..
....             # cd ../../..
```

---

## Bestandsbeheer

### ls met eza

```bash
ls               # mooie lijst met iconen en bestandsformaten
lsa              # inclusief verborgen bestanden
lt               # boomstructuur (2 niveaus diep)
lta              # boomstructuur inclusief verborgen
```

### Bestanden bekijken

```bash
bat bestand.py   # (alias voor batcat) syntaxgemarkeerde bestandsweergave met regelnummers
```

---

## Zoeken

### fzf — fuzzy finder

```bash
ff               # zoek een bestand in de huidige map met live preview
```

**Shell-geschiedenis:** druk op `Ctrl+r` voor een fuzzy zoekbalk door alle vorige commando's. Begin te typen, selecteer met de pijltjestoetsen, bevestig met `Enter` — het commando verschijnt meteen op de prompt.

### ripgrep

```bash
rg patroon           # zoek recursief in de huidige map
rg patroon src/      # zoek in een specifieke map
rg -t py patroon     # zoek alleen in Python-bestanden
rg -l patroon        # toon alleen bestandsnamen, geen regels
```

---

## Archivering

```bash
compress map/        # maakt map.tar.gz
decompress bestand.tar.gz
```

---

## Prompt — starship

De prompt toont de huidige map, git-branch en status compact op één regel:

```
~/workspace/project main * + >
```

| Symbool | Betekenis |
|---|---|
| `+n` | n commits vóór op remote (nog niet gepusht) |
| `-n` | n commits achter op remote |
| `+n/-m` | Gedivergeerd van remote |
| `*` | Gewijzigde bestanden |
| `?` | Untracked bestanden |
| `+` | Gestagede wijzigingen |
| `-` | Verwijderde bestanden |
| `~` | Hernoemde bestanden |
| `!` | Merge-conflict |
| `$` | Stash aanwezig |
| `=` | Alles up-to-date |
| `>` | Laatste commando geslaagd (groen) |
| `x` | Laatste commando mislukt (rood) |

De instellingen staan in `starship/.config/starship.toml`.
