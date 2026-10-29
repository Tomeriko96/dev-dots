# Claude Code Devcontainer Guide

This devcontainer is optimized for AI-assisted development with Claude and your toolkit. Built for podman + devcontainer-cli on Fedora.

## Setup & First Use

### Initial Authentication

Run the onboarding wizard once per fresh build:

```bash
onboard
```

This authenticates:
1. **GitHub CLI** (`gh auth login`) — enables git operations on github.com and `gh` commands
2. **GitLab CLI** (`glab auth login --hostname git.ia.surf.nl`) — enables git operations on SURF GitLab and `glab` commands
3. **OpenCode** (`opencode auth login`) — enables GitHub Copilot in OpenCode
4. **Claude Code** (`claude auth login`) — enables Claude Code CLI (subscription-based)

### Session Workflow

1. **Start container** → Run `onboard` (first time only)
2. **Open editor** — `nvim .` or `vim`
3. **Work** — use Claude Code CLI for assistance

## Container Tools

### AI & Development
- **Claude Code CLI** — subscription-based, authenticate via `claude auth login`
- **OpenCode** — GitHub Copilot support
- **Editors:** Neovim (LazyVim) + vim
- **Git:** lazygit, gh (GitHub CLI), glab (GitLab CLI), gh-dash, delta (syntax-highlighted diffs)

### Search & Data
- **Search:** ripgrep, fzf, fd-find
- **Data tools:** csvlens, tokei (code stats), onefetch (git summary)
- **Terminal:** starship prompt, zoxide (smart cd), fzf history search

### Languages & Runtimes
- **Node.js** LTS with npm
- **Python** via uv (fast installer/resolver)
- **micromamba** (conda-compatible package manager)

### DevOps & Kubernetes
- **kubectl**, **helm**, **flux** (Flux CD)
- **AWS CLI**, **Azure CLI**, **azcopy**, **azd**
- **sops** (encryption/secrets management)
- **glab** (GitLab CLI)

### System & Media
- **tmux** — terminal multiplexer
- **ffmpeg** — media processing (for video/GIF creation)
- **Playwright** Chromium runtime dependencies

## Configuration & Customization

### View installed tool versions
After post-create setup completes, check all pinned versions:

```bash
cat /workspace/tool-versions.txt
```

### Add a system package
Edit `Dockerfile` lines 98–120 (apt-get install section)

### Add a CLI tool version
1. Add version pin at top: `Dockerfile` lines 7–31 (ARG section)
2. Add installation block before line 406 (before "Non-root development user" section)

### Customize bash
- **Functions:** `bash/.config/bash/functions`
- **Aliases:** `bash/.config/bash/aliases`

## Environment & Credentials

- **Git auth:** HTTPS via credential helpers per host, set system-wide in the `Dockerfile` — `gh` for github.com, `glab` for git.ia.surf.nl and gitlab.com (no SSH keys, no `gh auth setup-git` needed)
- **Claude Code auth:** Handled automatically via browser login; uses subscription, not Azure Foundry
- **Bash helpers:** Auto-loaded from `bash/.config/bash/`
- **Claude Code hooks:** Installed to `~/.claude/hooks/` (e.g., blocks reading `.env` files)
- **Container settings:** Merged into `~/.claude/settings.json` during post-create

## Skills Integration

Claude skills from `cedanl/.github` are automatically loaded during post-create. To reload after updates:

```bash
npx --yes skills add cedanl/.github --skill '*' -a claude-code -a opencode -a pi -y --copy -g
```

## Notes

- Tool versions are pinned in `Dockerfile` (update manually; rebuild needed)
- First build takes 5–10 minutes; subsequent builds are cached
- Container runs on Debian Bookworm; your host (Fedora Atomic Sway) is separate
- Credentials in `.env` are not readable by Claude via hook (`block-env-read.sh`)
