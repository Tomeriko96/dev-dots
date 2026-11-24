# AI-workflows

dev-dots is gebouwd rond AI-ondersteund ontwikkelen. Twee CLI-assistenten staan klaar: **Claude Code** (Anthropic) en **OpenCode** (OpenAI-compatible). Beide starten met `--dangerously-skip-permissions` — binnen de devcontainer de bedoelde workflow. Claude Code is daarnaast uitgebreid met automatische Entire-integratie voor sessie-opslag.

---

## Eerste keer instellen

Voer `onboard` uit voor een begeleide setup:

```bash
onboard
```

Dit authenticeert in drie stappen:

1. **gh auth login** — GitHub CLI (en stelt je git-identiteit in via `gh api user`)
2. **opencode auth login** — GitHub Copilot in OpenCode
3. **claude auth login** — Claude Code CLI (subscription)

---

## Claude Code

```bash
claude           # start Claude Code in de huidige map (skip-permissions alias)
```

Claude Code werkt als een autonome agent die bestanden leest, aanpast en commando's uitvoert. Geef een taak in gewone taal.

Authenticatie verloopt via subscription: `claude auth login` (browser / device-code flow).

> De shell-alias zet `claude` om in `claude --dangerously-skip-permissions`. Een subcommando zoals `auth login` gaat dan óók door die alias: in zeldzame gevallen kan een leading flag een subcommando overschaduwen. Gebruik `command claude auth login` om de alias expliciet te omzeilen als het login-scherm niet opent.

---

## OpenCode

```bash
opencode         # start OpenCode in de huidige map (skip-permissions alias)
```

OpenCode werkt op dezelfde manier maar is compatible met verschillende providers. Authenticeer via:

```bash
opencode auth login
```

De globale config staat in `~/.config/opencode/opencode.json` met `permission: "allow"` — naast de skip-permissions alias.

---

## Entire — AI-sessies vastleggen

Entire legt AI-sessies (prompts, tool calls, file changes, transcripts) vast naast je commits, zodat je elke wijziging kunt herleiden naar de prompt die hem veroorzaakte.

**Automatische activatie:** de `claude`-functie roept `entire-setup` aan, dat Entire aanzet voor de repo waar je staat **én voor elke repo direct onder de workspace-root** (`/workspaces/dev-dots`). Het maakt dus niet uit of je Claude in de projectmap of in de root start. Een CEDA-repo is een repo met `cedanl/` (GitHub-org) of `surf-internal/npuls/ceda/` (GitLab-groep) in de origin-URL. Een repo die al klopt wordt alleen gelezen, dus de start blijft snel.

```bash
claude              # zet Entire aan in de repo waar je staat en in de zustermappen
entire-setup        # zelf draaien en per repo zien wat er staat
entire-setup --check  # alleen controleren, niets aanpassen (exitcode 1 als iets niet klopt)
```

Een mislukte `entire enable` wordt getoond met de reden, niet meer stilgehouden. Checkpoints worden opgeslagen op de gedeelde branch `entire/checkpoints/v1` (`git-branch`). De Entire-versie is gepind in de Dockerfile (`ENTIRE_VERSION`).

Alle checkpoints worden gesynchroniseerd naar de centrale private repo **`cedanl/entire-checkpoints`** bij elke `git push`. Entire kent als checkpoint-remote alleen GitHub, dus ook de sessies van GitLab-repo's gaan daarheen. Persoonlijke repos en andere organisaties of groepen worden overgeslagen.

!!! warning "Privacy: wat wordt bewaard"
    Een sessie bevat je prompts, tool-output en de antwoorden, en kan dus geheimen of persoonsgegevens bevatten. Bij de eerste keer per repo toont `claude` daarom een melding. Uitzetten kan per repo met `git config devdots.entire false`, of voor alle repo's met `export DEVDOTS_ENTIRE=0`. Dan blijft `claude` gewoon werken, zonder Entire.

**Hooks blijven lokaal:** `entire enable` schrijft zijn hooks in `.claude/settings.json`, een bestand dat repo's vaak in git hebben. `bash/.config/bash/entire-local-hooks.py` zet ze daarom in `.claude/settings.local.json` en herstelt `settings.json`; `.entire/` en het lokale bestand gaan in `.git/info/exclude`. Zo blijft `git status` schoon en komen de hooks niet in een (publieke) spiegel. Is `settings.json` niet in git, dan blijft alles zoals Entire het schrijft.

```bash
entire status                      # toon huidige configuratie
entire checkpoint list             # bekijk alle checkpoints in deze repo
entire checkpoint explain          # leg uit waarom code veranderd is
entire why <bestand>               # welke prompt heeft deze regel veroorzaakt?
entire session resume <branch>     # hervat een eerdere sessie
entire dispatch                    # markdown samenvatting van recent AI-werk
```

---

## Git-identiteit per user

`onboard` leidt na `gh auth login` je git-identiteit af (`user.name` / `user.email`) en zet `user.useConfigOnly true`. Commits zonder ingestelde identiteit falen met een duidelijke fout — zo wordt misattributie tussen collega's voorkomen.
