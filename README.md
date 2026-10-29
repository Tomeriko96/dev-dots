# dev-dots

A single, multipurpose developer devcontainer: fast startup, strong terminal ergonomics, AI-ready workflows, and reproducible tooling.

This repository combines dotfiles, container setup scripts, and workspace automation so any project can boot into a consistent, high-signal development environment.

## Vision

`dev-dots` is an opinionated, production-ready devcontainer built to cover the full range of everyday development work — Python, data, content, and beyond — in a single container:

- Reproducible CLI toolchain
- Excellent shell UX out of the box
- Claude Code and OpenCode preinstalled, with tmux preconfigured (mouse, vi copy-mode, OSC 52 clipboard)
- Minimal host setup required

## What You Get Today

### Container Baseline

Defined in `.devcontainer/Dockerfile`:

- Debian bookworm-slim base image
- Core dev tools: `git`, `curl`, `tmux`, `htop`, `jq`, `wget`, `fd-find`, `bat`, `openssh-client`, `build-essential`
- Data and search utilities: `ripgrep`, `fzf`, `csvlens`, `tokei`, `onefetch`
- Modern shell utilities: `eza` (ls replacement)
- Node.js LTS (for npm and Node-based tools)
- Neovim (pinned version)
- Non-root `dev` user and workspace-ready permissions
- CLI installs for `claude` (Claude Code), `opencode`, `uv`, `micromamba`, `starship`, and `zoxide`
- DevOps and cloud CLIs: `kubectl`, `helm`, `flux`, `sops`, `glab`, `aws`, `az`, `azcopy`, `azd`
- Media and browser automation: `ffmpeg` and the Playwright Chromium runtime libraries
- Dotfiles pre-loaded: `.bashrc`, bash helpers, starship config, tmux config, `onboard` wizard
- LazyVim starter pre-cloned to `~/.config/nvim` (plugins download on first `nvim` launch)
- **Git tooling**: `lazygit` (TUI git client), `gh` (GitHub CLI), `delta` (syntax-highlighted diffs), `gh-dash` (GitHub dashboard TUI)
- System-level git pager configured to use `delta` (user `~/.gitconfig` takes precedence)

### Post-Create Provisioning

Defined in `.devcontainer/post-create.sh`:

- CLI availability verification (nvim, opencode, claude, uv, starship, zoxide, node, npm, csvlens, micromamba, az, azcopy, azd, kubectl, helm, flux, glab, aws)
- Git tooling availability summary on startup
- Helpful tips printed on startup (az login, lazygit, gh dash, onboard)
- Tool versions written to `/workspace/tool-versions.txt`
- Claude Code hooks and container-wide settings merged into `~/.claude/settings.json`
- Claude/OpenCode skills from `cedanl/.github` installed

`.devcontainer/cleanup-tmp.sh` runs on every container start (`postStartCommand`). It clears old Claude scratchpads, leftover `.so` files and the uv cache in `/tmp`, which sits on the container overlay and otherwise grows without limit.

### Git Workflow Out of the Box

Run `onboard` for a guided login. It walks through the CLIs below:

- `gh auth login` — GitHub CLI, and git over HTTPS for github.com
- `glab auth login --hostname git.ia.surf.nl` — GitLab CLI, and git over HTTPS for the SURF GitLab
- `opencode auth login` — GitHub Copilot in OpenCode
- `claude auth login` — Claude Code

Git credential helpers are configured per host at system level in the Dockerfile (`gh` for github.com, `glab` for git.ia.surf.nl and gitlab.com), so plain `git clone/pull/push` over HTTPS works once `gh` and `glab` are logged in. No `gh auth setup-git` or SSH keys needed.

Available git TUI tools:

| Tool | Command | Notes |
|------|---------|-------|
| lazygit | `lazygit` | Full-featured TUI git client; integrates with LazyVim |
| GitHub CLI | `gh` | Baked in; run `gh auth login` once to enable authenticated ops |
| gh-dash | `gh dash` | GitHub dashboard TUI (PRs, issues, notifications) |
| delta | automatic | Syntax-highlighted diffs for every `git diff` / `git log -p` |

### Shell and Prompt Experience

From `bash/` and `starship/`:

- Modular bash config (`aliases`, `functions`, `rc`)
- Productivity helpers (`fzf` history search, compression helpers, apt helpers)
- `zoxide`-powered directory jumping
- Starship prompt with concise git-aware status

## Repository Layout

```text
.
├── .claude/
│   └── settings.json
├── .devcontainer/
│   ├── Dockerfile
│   ├── cleanup-tmp.sh
│   ├── devcontainer.json
│   ├── hooks/
│   │   └── block-env-read.sh
│   ├── onboard.sh
│   ├── post-create.sh
│   └── tmux.conf
├── bash/
│   ├── .bashrc
│   └── .config/bash/
│       ├── aliases
│       ├── functions
│       └── rc
├── starship/
│   └── .config/starship.toml
├── AGENTS.md
├── CLAUDE.md
└── README.md
```

`AGENTS.md` holds the instructions for AI agents; `CLAUDE.md` only imports it.

## Quick Start

1. Clone this repository.
2. Start the devcontainer: `devcontainer-cli open .`
3. Wait for post-create setup to finish.
4. Run `onboard` to log in to `gh`, `glab`, OpenCode and Claude Code (once per fresh build).
5. Start working with `nvim .`, `vim`, `tmux`, or your preferred workflow.

## Goal State

Keep `dev-dots` a single, well-maintained multipurpose container that stays current with tooling updates and remains easy to extend for any project type. The focus is depth and quality over breadth of profiles:

- Keep shell/editor defaults portable and easy to override
- Make every session AI-collaboration friendly by default
- Preserve reproducibility with minimal manual machine setup

## Slidev

To present from inside the container, run:

```bash
npm run dev -- --remote
```

This exposes the Slidev dev server so you can access it from outside the container. Port `3030` is forwarded by default via `devcontainer.json`.

