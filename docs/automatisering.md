---
icon: lucide/bot
---

# Automatisering

dev-dots bevat `ffmpeg` en de systeembibliotheken voor **Playwright headless Chromium**, zodat je zonder displayserver screenshots, GIFs en video's kunt genereren — handig voor rapporten, demo's of geautomatiseerde visuele tests.

---

## Playwright instellen

De vereiste systeembibliotheken zijn al ingebakken in het image. Je hoeft alleen de Python-bibliotheek en de Chromium-binary nog te installeren:

```bash
uv add playwright
playwright install chromium
```

!!! info "playwright install-deps is niet nodig"
    Alle systeemafhankelijkheden (libglib, libnss, libatk, libgbm, enzovoort) zijn al aanwezig in het image.

---

## Screenshot van een webpagina

```python
from playwright.sync_api import sync_playwright

with sync_playwright() as p:
    browser = p.chromium.launch()
    page = browser.new_page(viewport={"width": 1280, "height": 720})
    page.goto("https://example.com")
    page.screenshot(path="screenshot.png", full_page=True)
    browser.close()
```

---

## Pagina exporteren als PDF

```python
page.pdf(path="rapport.pdf", format="A4")
```

---

## Reeks screenshots → GIF met ffmpeg

Maak meerdere frames en zet ze om naar een vloeiende GIF:

```python
import subprocess
from pathlib import Path
from playwright.sync_api import sync_playwright

frames_dir = Path("frames")
frames_dir.mkdir(exist_ok=True)

with sync_playwright() as p:
    browser = p.chromium.launch()
    page = browser.new_page(viewport={"width": 1280, "height": 720})
    page.goto("https://example.com")

    for i in range(10):
        page.screenshot(path=frames_dir / f"frame_{i:03d}.png")
        page.evaluate("window.scrollBy(0, 200)")

    browser.close()

subprocess.run([
    "ffmpeg", "-y", "-framerate", "5",
    "-pattern_type", "glob", "-i", "frames/frame_*.png",
    "-vf", "scale=1280:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse",
    "demo.gif"
], check=True)
```

De `palettegen`/`paletteuse` filter geeft scherpe kleuren in de GIF zonder kleurband-artefacten.

---

## Losse ffmpeg-recepten

### PNG-reeks → geanimeerde GIF

```bash
ffmpeg -framerate 2 -pattern_type glob -i 'screenshot_*.png' \
       -vf "scale=1280:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" \
       demo.gif
```

### PNG-reeks → MP4

```bash
ffmpeg -framerate 24 -pattern_type glob -i 'frames/frame_*.png' \
       -c:v libx264 -pix_fmt yuv420p output.mp4
```

### GIF verkleinen

```bash
ffmpeg -i input.gif -vf "scale=640:-1:flags=lanczos" small.gif
```

### Video bijsnijden

```bash
ffmpeg -i input.mp4 -ss 00:00:05 -t 00:00:10 -c copy clip.mp4
```

---

## Gebruik met Claude Code

Vraag Claude om het scroll-en-screenshot script voor jouw specifieke pagina te schrijven:

```
Maak een Playwright-script dat elke sectie van /dashboard screenshottert
en de frames samenvoegt tot een GIF van 800×600 met 3 fps.
```

Claude kan de frames genereren, ffmpeg aanroepen en het resultaat direct openen — allemaal vanuit de container.
