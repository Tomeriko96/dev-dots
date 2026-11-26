---
icon: lucide/git-branch
---

# Git

dev-dots heeft drie git-tools die samenwerken: **lazygit** voor het dagelijkse werk, **gh** voor GitHub, en **delta** voor mooie diffs.

---

## lazygit

lazygit is een volledige git-TUI. Start het met:

```bash
lazygit
```

Of open het vanuit Neovim met `Space g g`.

### Navigatie

| Toets | Actie |
|---|---|
| `1–5` | Wissel tussen panelen (Status, Bestanden, Branches, Commits, Stash) |
| `↑↓` | Navigeer door de lijst |
| `Enter` | Open / bevestig |
| `q` | Verlaat lazygit |
| `?` | Toon alle sneltoetsen |

### Veelgebruikt

| Toets | Actie |
|---|---|
| `Spatiebalk` | Stage / unstage bestand |
| `a` | Stage alle bestanden |
| `c` | Commit (opent een prompt) |
| `C` | Commit met editor |
| `p` | Push |
| `P` | Pull |
| `f` | Fetch |
| `b` | Branches-menu |
| `n` | Nieuwe branch |
| `d` | Diff bekijken |
| `e` | Bestand bewerken |
| `z` | Undo laatste actie |

---

## gh — GitHub CLI

`gh` geeft je toegang tot GitHub vanuit de terminal. Authenticeer eenmalig met:

```bash
gh auth login
```

### Repositories

```bash
gh repo clone gebruiker/repo    # kloon een repository
gh repo create                  # maak een nieuwe repo
gh repo view                    # open repo in browser
```

### Pull requests

```bash
gh pr create                    # maak een PR aan
gh pr list                      # toon open PR's
gh pr checkout 42               # check PR #42 uit
gh pr merge                     # merge de huidige PR
gh pr view --web                # open PR in browser
```

### Issues

```bash
gh issue list
gh issue create
gh issue view 12
```

### Overig

```bash
gh run list                     # bekijk CI-runs
gh run view                     # details van de laatste run
gh release create v1.0.0
```

---

## delta — betere diffs

delta wordt automatisch gebruikt als git-pager. Je hoeft niets te doen — elke `git diff` en `git log -p` ziet er direct mooier uit.

```bash
git diff
git log -p
git show HEAD
```

Navigeer door diff-secties met `n` (next) en `N` (previous).

---

## gclone — fuzzy repo-kloner

`gclone` combineert `gh` en `fzf` om snel een repo te kiezen en te klonen:

```bash
gclone              # toon al je repos in een fuzzy-picker
gclone organisatie  # toon repos van een org of andere gebruiker
```

Na het klonen springt `gclone` automatisch de nieuwe map in.
