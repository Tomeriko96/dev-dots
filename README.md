# dev-dots

A single, multipurpose developer devcontainer: fast startup, strong terminal ergonomics, AI-ready workflows, and reproducible tooling.

This repository combines dotfiles, container setup scripts, and workspace automation so any project can boot into a consistent, high-signal development environment.

## Vision

`dev-dots` is an opinionated, production-ready devcontainer built to cover the full range of everyday development work — Python, data, content, and beyond — in a single container:

- Reproducible CLI toolchain
- Excellent shell UX out of the box
- AI-assisted tmux layouts for rapid coding sessions
- Minimal host setup required

## What You Get Today

### Container Baseline

Defined in `.devcontainer/Dockerfile`:

- Debian bookworm-slim base image
- Core dev tools: `git`, `curl`, `tmux`, `htop`, `jq`, `wget`, `fd-find`, `bat`, `openssh-client`, `build-essential`
- Data and search utilities: `ripgrep`, `qsv`, `fzf`
- Modern shell utilities: `eza` (ls replacement)
- Node.js LTS (for npm and Node-based tools)
- R base (for R programming and data science)
- Latest Neovim install
- Non-root `dev` user and workspace-ready permissions
- CLI installs for `opencode`, `uv`, `starship`, and `zoxide`
- Dotfiles pre-loaded: `.bashrc`, bash helpers, starship config, tmux config, tmux layout scripts
- LazyVim starter pre-cloned to `~/.config/nvim` (plugins download on first `nvim` launch)
- **Git tooling**: `lazygit` (TUI git client), `gh` (GitHub CLI), `delta` (syntax-highlighted diffs), `gh-dash` (GitHub dashboard TUI)
- System-level git pager configured to use `delta` (user `~/.gitconfig` takes precedence)

### Post-Create Provisioning

Defined in `.devcontainer/post-create.sh`:

- CLI availability verification (nvim, opencode, uv, starship, zoxide, node, npm, Rscript)
- Git tooling availability summary on startup
- Helpful tips printed on startup (lazygit, gh auth login, gh dash, tdl opencode)

### Git Workflow Out of the Box

Host credentials are forwarded into the container via `devcontainer.json` bind mounts (readonly):

- `~/.gitconfig` → `/home/dev/.gitconfig`
- `~/.ssh/` → `/home/dev/.ssh/`

Git operations (`git push`, `git pull`, SSH cloning) work inside the container without any extra setup.

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

### AI + tmux Workflows

The tmux layout helpers are designed for coding with one or more AI assistants in parallel:

- `tdl <ai> [second_ai]`: editor + AI pane(s) + terminal
- `tdlm <ai> [second_ai]`: one dev window per subdirectory
- `tsl <pane_count> <command>`: command swarm across panes

These commands are sourced from `~/.tmux-dev-layouts.sh`, which is pre-installed in the image and automatically loaded by `.bashrc`.

## Repository Layout

```text
.
├── .devcontainer/
│   ├── Dockerfile
│   ├── devcontainer.json
│   ├── post-create.sh
│   ├── tmux.conf
│   └── tmux-dev-layouts.sh
├── bash/
│   ├── .bashrc
│   └── .config/bash/
│       ├── aliases
│       ├── functions
│       └── rc
├── starship/
│   └── .config/starship.toml
└── README.md
```

## Quick Start

1. Open this repository in VS Code.
2. Run `Dev Containers: Reopen in Container`.
3. Wait for post-create setup to finish.
4. Start working with `nvim .`, `tmux`, or your preferred workflow.
5. *(Optional)* Run `gh auth login` once to enable `gh` and `gh dash` with your GitHub account.

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

