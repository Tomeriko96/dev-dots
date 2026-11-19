# Beveiliging

Agents draaien hier met `--dangerously-skip-permissions`. Dat is de bedoelde workflow, maar het betekent dat een prompt injection (of een kwaadaardige dependency) alles kan doen wat jouw gebruiker in de container kan, inclusief je tokens versturen naar een willekeurige host. Deze pagina beschrijft de maatregelen en hun grenzen.

## Egress-firewall (opt-in)

Standaard is het netwerk open. Wil je dat uitgaand verkeer alleen naar een allowlist kan, gebruik dan de **firewall-variant** van de devcontainer.

!!! warning "Experimenteel"
    De firewall is geschreven en op logica getest met een dry-run, maar nog niet op een echte podman/docker-host met `NET_ADMIN` doorgemeten. Gebruik hem als extra laag, niet als enige verdediging, en meld wat er stukgaat.

**Aanzetten**

```bash
# VS Code: kies bij "Reopen in Container" de configuratie "dev (egress-firewall)"
# CLI:
devcontainer up --config .devcontainer/firewall/devcontainer.json --workspace-folder .
devcontainer exec --config .devcontainer/firewall/devcontainer.json --workspace-folder . bash
```

De variant voegt `--cap-add=NET_ADMIN --cap-add=NET_RAW` toe en draait bij elke start `sudo /usr/local/sbin/init-firewall.sh`. Als de firewall niet geactiveerd kan worden, of `example.com` nog bereikbaar is, meldt de `postStartCommand` een fout (de container blijft wel draaien). Je merkt dus dat je zonder bescherming zit, maar je wordt er niet door geblokkeerd.

**Wat is toegestaan**

- GitHub (via de gepubliceerde IP-bereiken van `api.github.com/meta`), Anthropic, npm, PyPI, `gitlab.com`, `git.sdp.surf.nl` (SURF GitLab), `git.ia.surf.nl` (oude SURF GitLab, gearchiveerd), OpenCode en Entire (zie `CORE_DOMAINS` in `.devcontainer/init-firewall.sh`)
- DNS naar de resolvers uit `/etc/resolv.conf`, loopback en antwoorden op inkomende verbindingen (forwarded ports)
- IPv6 naar buiten is geblokkeerd

**Extra hosts toevoegen** (bijv. SURF Object Store, Azure, clusters):

```bash
export DEVDOTS_FIREWALL_EXTRA="objectstore.surf.nl login.microsoftonline.com"   # op je host, vóór devcontainer up
```

Dit gaat bewust via de omgeving van de container (alleen PID 1 wordt gelezen) en niet via een bestand in je workspace: wat een agent kan schrijven, kan een aanvaller ook aan de allowlist toevoegen. Na het wijzigen van de lijst: container herstarten. Het IP-adres van CDN-hosts kan veranderen; `sudo /usr/local/sbin/init-firewall.sh` ververst ze.

**De agent kan hem niet uitzetten.** De sudo-regel staat precies dit root-eigendom-script toe, zonder argumenten. Je kunt hem dus opnieuw toepassen, maar niet uitzetten of verruimen vanuit de container.

**Grenzen**

- Allowlisten op IP is grof: andere sites achter dezelfde CDN-/GitHub-bereiken blijven bereikbaar.
- DNS naar de resolver staat open, dus DNS-tunneling is mogelijk.
- Dit stopt geen exfiltratie naar een *toegestane* host, bijvoorbeeld pushen naar een GitHub-repo waar je token schrijfrechten op heeft. Daarvoor is een beperkte token nodig (hieronder).

## Tokens met beperkte rechten

- Gebruik een **fine-grained token** met alleen de repo's en rechten die je nodig hebt, en met een korte looptijd, in plaats van een token met brede `repo`-scope.
- Laat cloud-CLI's (`az`, `aws`, `kubectl`, `flux`) alleen ingelogd staan als de taak het vraagt; log uit als je klaar bent. Een aparte "ops"-variant zonder deze credentials is een mogelijk vervolg.

## Sessiebewaking (Entire)

Zie [AI-workflows](ai.md) voor wat er wordt bewaard en hoe je uitzet.

## Supply chain

Zie de README voor wat is gepind en geverifieerd.
