# dev-dots

Devcontainer voor dagelijks ontwikkelwerk — AI-first, reproduceerbaar, direct bruikbaar.

## Inhoud

- **Base**: Debian bookworm-slim, `amd64` + `arm64`
- **Shell**: bash, starship, zoxide, eza, fzf, bat, fd, ripgrep, jq
- **Editor**: Neovim + LazyVim
- **Git**: lazygit, gh, glab, delta
- **Data**: csvlens
- **AI**: claude, opencode, entire, org-skills via `cedanl/.github` — met `--dangerously-skip-permissions`
- **Python**: uv
- **Node**: LTS
- **Cloud**: az, azcopy, azd, aws, kubectl, helm, flux, sops
- **Media & automatisering**: ffmpeg, Playwright headless Chromium

## Snel starten

1. Open in VS Code → `Dev Containers: Reopen in Container`
2. Wacht op post-create
3. Voer `onboard` uit — begeleide authenticatie (gh, opencode, claude) + git-identiteit
4. Aan de slag met `nvim .` of `claude`

> Claude Code en OpenCode starten met `--dangerously-skip-permissions` (ingebakken als shell-alias).
> Git gebruikt per user een expliciete identiteit (ingesteld door `onboard`) en `user.useConfigOnly true`.

## Screenshots en GIFs automatiseren

De container bevat `ffmpeg` en de systeembibliotheken voor Playwright headless Chromium, zodat je zonder displayserver screenshots en animaties kunt genereren.

### Screenshots met Playwright (Python)

```python
from playwright.sync_api import sync_playwright

with sync_playwright() as p:
    browser = p.chromium.launch()
    page = browser.new_page()
    page.goto("https://example.com")
    page.screenshot(path="screenshot.png", full_page=True)
    browser.close()
```

Installeer de Playwright-bibliotheek en de Chromium-binary:

```bash
uv add playwright
playwright install chromium
```

> De vereiste systeembibliotheken zijn al ingebakken in het image — `playwright install-deps` is niet nodig.

### Meerdere pagina's naar PDF

```python
page.pdf(path="rapport.pdf", format="A4")
```

### Screenshots omzetten naar GIF met ffmpeg

```bash
# Reeks PNG-screenshots → geanimeerde GIF
ffmpeg -framerate 2 -pattern_type glob -i 'screenshot_*.png' \
       -vf "scale=1280:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" \
       demo.gif
```

### Schermopname van een webpagina als GIF (volledig voorbeeld)

```python
import subprocess
from pathlib import Path
from playwright.sync_api import sync_playwright

out = Path("frames")
out.mkdir(exist_ok=True)

with sync_playwright() as p:
    browser = p.chromium.launch()
    page = browser.new_page(viewport={"width": 1280, "height": 720})
    page.goto("https://example.com")

    for i in range(10):
        page.screenshot(path=out / f"frame_{i:03d}.png")
        page.evaluate("window.scrollBy(0, 200)")

    browser.close()

subprocess.run([
    "ffmpeg", "-y", "-framerate", "5",
    "-pattern_type", "glob", "-i", "frames/frame_*.png",
    "-vf", "scale=1280:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse",
    "demo.gif"
], check=True)
```

### Video opnemen met ffmpeg

```bash
# MP4 van een reeks frames
ffmpeg -framerate 24 -pattern_type glob -i 'frames/frame_*.png' \
       -c:v libx264 -pix_fmt yuv420p output.mp4
```

## Image

Gepubliceerd op `ghcr.io/cedanl/dev-dots:latest` — gebouwd voor `amd64` en `arm64`.

`devcontainer.json` pint op `major.minor` (nu `:1.3`; ook in `.devcontainer/firewall/devcontainer.json`), zodat iedereen dezelfde versie krijgt. Een release (`vX.Y.Z`) levert de tags `X.Y.Z` en `X.Y`; verhoog de pin in beide `devcontainer.json`-bestanden na een nieuwe release.

### Toolversies en globale instructies

- Toolversies staan als `ARG` bovenaan de `Dockerfile`. Zet er een `# renovate: datasource=… depName=…`-regel boven (kopieer een buur), dan houdt Renovate ze bij (zodra de Renovate GitHub App op de repo staat).
- `global_claude.md` is de gedeelde baseline. Die komt in `~/.claude/ceda-baseline.md` (geïmporteerd vanuit je eigen `~/.claude/CLAUDE.md`) en als beheerd blok in `~/.config/opencode/AGENTS.md`. Je eigen tekst in die bestanden blijft staan.

### Supply chain: wat is gepind en geverifieerd

- **Gepind en geverifieerd (sha256 tegen het checksum-bestand van de release):** Node.js, lazygit, ripgrep, csvlens, micromamba, kubectl, helm, sops, glab, flux en starship (`.devcontainer/verify.sh`). Een ontbrekende of foute hash laat de build falen. Dit vangt corrupte of verwisselde bestanden, geen gecompromitteerde release zelf.
- **Gepind, zonder checksum van de uitgever:** delta, azcopy, azd, zoxide, neovim en uv (het uv-installatiescript controleert zelf).
- **Gepind via het installatiescript:** Entire (`--version`, `ENTIRE_VERSION` in de Dockerfile; Renovate houdt het bij).
- **Niet pinbaar (`curl | bash`):** de installers van Claude Code en OpenCode, en het AWS CLI ("latest"). Ze worden bewust ongepind geïnstalleerd; een rebuild haalt de dan actuele versie.
- **Skills:** de `skills`-CLI is gepind (`install-skills.sh`). De inhoud volgt `cedanl/.github` HEAD, omdat die repo geen tags heeft en `post-attach` bewust ververst.
- De apt-repo's van gh, azure-cli en eza zijn ondertekend; de sleutels worden bij de build opgehaald.

> Uitgebreide documentatie en sneltoetsen: zie de [projectdocumentatie](https://cedanl.github.io/dev-dots).
