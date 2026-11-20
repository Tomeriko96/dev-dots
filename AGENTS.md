# Claude Code Devcontainer Guide

This devcontainer is optimized for AI-assisted development with Claude and your toolkit. Built for podman + devcontainer-cli on Fedora.

## Setup & First Use

### Initial Authentication

Run the onboarding wizard once per fresh build:

```bash
onboard
```

This authenticates:
1. **GitHub CLI** (`gh auth login`) — enables git operations on github.com and `gh` commands; then sets an empty global git `user.name`/`user.email` from the gh login (noreply address), never overwriting an existing value
2. **GitLab CLI** (`glab auth login --hostname git.sdp.surf.nl`) — enables git operations on SURF GitLab and `glab` commands
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
Edit the `apt-get install` list in the `Dockerfile` section "Install all APT-managed packages".

### Add or update a CLI tool
CLI tools are pinned in `.devcontainer/mise.toml` and checksum-locked in `.devcontainer/mise.lock` (Linux x86_64).
1. Edit or add the entry in `mise.toml`. Prefer an explicit `aqua:` or `github:` backend.
2. Run `.devcontainer/update-mise-lock.sh --verify`
3. If it adds an executable, add it to the symlink list in the `Dockerfile` "Locked CLI toolchain" step
4. Commit `mise.toml` and `mise.lock` together

### Customize bash
- **Functions:** `bash/.config/bash/functions`
- **Aliases:** `bash/.config/bash/aliases`

## Environment & Credentials

- **Git auth:** HTTPS via credential helpers per host, set system-wide in the `Dockerfile` — `gh` for github.com, `glab` for git.sdp.surf.nl, git.ia.surf.nl (old SURF GitLab, archived, read-only) and gitlab.com (no SSH keys, no `gh auth setup-git` needed)
- **Claude Code auth:** Handled automatically via browser login; uses subscription, not Azure Foundry
- **Bash helpers:** Auto-loaded from `bash/.config/bash/`
- **Claude Code hooks:** Installed to `~/.claude/hooks/` (e.g., blocks reading `.env` files)
- **Container settings:** Merged into `~/.claude/settings.json` during post-create (`merge-claude-settings.jq`; your own keys, hooks and rules are kept)
- **Permission mode:** Claude runs in bypass mode without permission prompts (`permissions.defaultMode: bypassPermissions`, `skipDangerousModePermissionPrompt`); `/workspaces`, `/tmp` and `/home/dev` are extra working directories (`additionalDirectories`). The dotenv deny rules (`.env`, `.env.local`, `.env.*.local`, `.env.production`, `.env.development`, `.env.test`, `.env.staging`, `.env.prod`, `.env.dev`) and the hook stay active

## Skills Integration

Claude skills from `cedanl/.github` are automatically loaded during post-create. To reload after updates:

```bash
npx --yes skills add cedanl/.github --skill '*' -a claude-code -a opencode -a pi -y --copy -g
```

## Notes

- Autonomous orchestration (an orchestrator Claude that starts factory workers per repo in tmux) lives in [Tomeriko96/dev-server](https://github.com/Tomeriko96/dev-server), not here
- CLI tool versions are pinned in `.devcontainer/mise.toml` / `mise.lock` (rebuild needed after a change). `mise` itself is pinned in the `Dockerfile`.
- First build takes 5–10 minutes; subsequent builds are cached
- Container runs on Debian Bookworm; your host (Fedora Atomic Sway) is separate
- Credentials in `.env` / `.env.<suffix>` are blocked for Claude's Read, Grep and Bash tools via hook (`block-env-read.sh`); best-effort denylist, not a sandbox (`.env.example` and `.env.sample` stay readable)
