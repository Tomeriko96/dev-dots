---
icon: lucide/square-pen
---

# Editor — Neovim

De editor is Neovim met [LazyVim](https://www.lazyvim.org/) als startconfiguratie. LazyVim laadt plugins slim en geeft je meteen een volwaardige IDE-ervaring.

```bash
nvim .           # open de huidige map als project
nvim bestand.py
```

De **leader-toets** is `Spatiebalk`.

---

## Eerste keer opstarten

Bij de eerste `nvim`-start downloadt LazyVim alle plugins. Dat ziet er druk en chaotisch uit — wacht rustig tot het scherm stabiliseert, dan is alles klaar. Dit gebeurt maar één keer.

---

## Neovim is modaal

Neovim heeft twee basismodi. Dit is het belangrijkste om te begrijpen:

| Modus | Wat je doet |
|---|---|
| **Normale modus** | Navigeren, kopiëren, commando's uitvoeren — hier start je altijd |
| **Invoermodus** | Tekst typen |

| Toets | Actie |
|---|---|
| `i` | Ga naar invoermodus (vóór cursor) |
| `a` | Ga naar invoermodus (na cursor) |
| `o` | Nieuwe regel onder, ga naar invoermodus |
| `Esc` | Terug naar normale modus |
| `:w` | Sla op |
| `:q` | Sluit (werkt alleen als er geen wijzigingen zijn) |
| `:wq` | Sla op en sluit |
| `:q!` | Sluit zonder opslaan |

!!! tip "Nieuw met vim?"
    ThePrimeagen heeft een toegankelijke introductieserie: [Vim As Your Editor](https://www.youtube.com/watch?v=X6AR2RMB5tE). Verwacht een leercurve — maar zodra het klikt, ga je nooit meer terug.

---

## Bestanden & navigatie

| Toets | Actie |
|---|---|
| `Space f f` | Zoek bestanden (fuzzy) |
| `Space f g` | Zoek in bestandsinhoud (live grep) |
| `Space f r` | Recente bestanden |
| `Space f b` | Open buffers |
| `Space e` | Bestandsverkenner (neo-tree) |

---

## Buffers & vensters

| Toets | Actie |
|---|---|
| `Space b d` | Sluit buffer |
| `Space b o` | Sluit alle andere buffers |
| `[b` / `]b` | Vorige / volgende buffer |
| `Ctrl+w s` | Splits venster horizontaal |
| `Ctrl+w v` | Splits venster verticaal |
| `Ctrl+h/j/k/l` | Navigeer tussen vensters |

---

## Code bewerken

| Toets | Actie |
|---|---|
| `g d` | Ga naar definitie |
| `g r` | Toon referenties |
| `g I` | Ga naar implementatie |
| `K` | Hover documentatie |
| `Space c r` | Hernoem symbool |
| `Space c a` | Code actions |
| `Space c f` | Formatteer bestand |
| `gcc` | Toggle comment (normale modus) |
| `gc` | Toggle comment (visuele selectie) |

---

## Diagnostics & fouten

| Toets | Actie |
|---|---|
| `]d` / `[d` | Volgende / vorige diagnostic |
| `Space x x` | Diagnostics-paneel |
| `Space x l` | Locatielijst |

---

## Git in de editor

| Toets | Actie |
|---|---|
| `Space g g` | Open lazygit in Neovim |
| `]h` / `[h` | Volgende / vorige git-hunk |
| `Space g h s` | Stage hunk |
| `Space g h r` | Reset hunk |
| `Space g h p` | Preview hunk |

---

## Pluginbeheer

| Toets | Actie |
|---|---|
| `Space l` | Open Lazy (plugin manager) |

Voer `:Lazy update` uit om alle plugins bij te werken.

!!! tip "LazyVim-extras"
    LazyVim heeft uitbreidingen voor talen als Python, TypeScript, Go en meer. Bekijk `~/.config/nvim/lazyvim.json` voor wat er actief is, of voeg extras toe via `:LazyExtras`.
