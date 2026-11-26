---
icon: lucide/house
---

# Welkom bij dev-dots

**dev-dots** is een eigenzinnige devcontainer voor ontwikkelaars. Alles wat je dagelijks nodig hebt — van een krachtige editor tot AI-assistenten — is voorgeladen en meteen bruikbaar. Open je project, typ één commando, en je werkt.

Dit is geen grab-bag van willekeurige tools. Het is één consistent systeem, ontworpen zodat elke sessie voelt als thuis — ongeacht welke machine of welk project.

---

## Wat je krijgt

| Categorie | Tool |
|---|---|
| Editor | Neovim met LazyVim |
| Terminal multiplexer | tmux |
| Git TUI | lazygit |
| GitHub CLI | gh, glab |
| Git diffs | delta |
| Fuzzy finder | fzf |
| Moderne `ls` | eza |
| Bestandsviewer | bat |
| Zoeken in code | ripgrep (`rg`) |
| Bestanden zoeken | fd (commando `fdfind`) |
| JSON verwerken | jq |
| Systeemmonitor | htop |
| Slimme `cd` | zoxide |
| Prompt | starship |
| CSV-viewer | csvlens |
| AI (Anthropic) | Claude Code |
| AI (OpenAI-compatible) | OpenCode |
| AI-sessies | entire |
| Python packages | uv, micromamba |
| JavaScript | Node.js (LTS) met npm |
| Cloud & k8s | az, azcopy, azd, aws, kubectl, helm, flux, sops |
| Schermopname & GIF | ffmpeg |
| Headless browser | Playwright (Chromium) |

---

## Snel starten

Open de repository in VS Code en kies **Dev Containers: Reopen in Container**. Na de post-create setup ben je klaar.

Voer `onboard` uit voor een begeleide setup van GitHub-authenticatie, OpenCode, Claude en je git-identiteit:

```bash
onboard
```

Start daarna een werksessie:

```bash
nvim .
claude
```

> Claude Code en OpenCode starten met `--dangerously-skip-permissions` (ingebakken: `claude` is een shell-functie, `opencode` een alias) — binnen de devcontainer de bedoelde workflow.

---

## Een typische werksessie

Zo ziet een complete AI-codesessie eruit van begin tot eind:

```bash
# 1. Ga naar je project
cd mijn-project

# 2. Start Claude Code (met --dangerously-skip-permissions)
claude

# 3. Geef Claude een taak
#    Claude leest je bestanden, schrijft code, voert tests uit

# 4. Review de wijzigingen in Neovim
#    Space g g   → open lazygit
#    spatiebalk  → stage bestanden
#    c           → commit

# 5. Maak een pull request
gh pr create
```

---

## Wat overleeft een container-rebuild?

| Wat | Overleeft rebuild? |
|---|---|
| Bestanden in `/workspace` | Ja — gemount vanuit de host |
| Dotfiles (`~/.bashrc`, etc.) | Ja — ingebakken in de image |
| `~/.local` (npm globals, etc.) | Nee — opnieuw aanmaken na rebuild |
| `~/.config/nvim/` (LazyVim) | Ja — ingebakken in de image |
| LazyVim plugins (`~/.local/share/nvim`) | Nee — worden opnieuw gedownload bij eerste `nvim` |
| Zoxide-geschiedenis | Nee — begint leeg na rebuild |
| Git-identiteit (`user.name`, `user.email`) | Nee — opnieuw instellen via `onboard` |

!!! tip "Eerste keer na rebuild"
    Start `nvim` één keer en wacht tot alle plugins geladen zijn. Voer daarna `onboard` uit om GitHub, OpenCode, Claude en je git-identiteit opnieuw in te stellen.
