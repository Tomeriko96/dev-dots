# dev-dots

A practical foundation for building the ultimate developer devcontainer(s): fast startup, strong terminal ergonomics, AI-ready workflows, and reproducible tooling.

This repository combines dotfiles, container setup scripts, and workspace automation so every project can boot into a consistent, high-signal development environment.

## Vision

`dev-dots` aims to become a collection of opinionated, production-ready devcontainers for different stacks (Python, Slidev, R, and more) while sharing a common baseline:

- Reproducible CLI toolchain
- Excellent shell UX out of the box
- AI-assisted tmux layouts for rapid coding sessions
- Minimal host setup required

## Current Status

- One active container profile: `.devcontainer/devcontainer.json` (`python-uv-dev`)
- Additional profile folders scaffolded for expansion: `.devcontainer/slidev/`, `.devcontainer/r/`, `.devcontainer/python-uv/`
- Shared post-create setup script and shell customizations are in place

## What You Get Today

### Container Baseline

Defined in `.devcontainer/Dockerfile`:

- Python 3.12 slim base image
- Core dev tools: `git`, `curl`, `tmux`, `htop`, `jq`, `wget`, `fd`, `tree-sitter-cli`, `openssh-client`
- Data and search utilities: `ripgrep`, `qsv`, `fzf`
- Latest Neovim install
- Non-root `dev` user and workspace-ready permissions
- CLI installs for `opencode` and `uv`
- **Git tooling**: `lazygit` (TUI git client), `gh` (GitHub CLI), `delta` (syntax-highlighted diffs), `gh-dash` (GitHub dashboard TUI)
- System-level git pager configured to use `delta` (user `~/.gitconfig` takes precedence)

### Post-Create Provisioning

Defined in `.devcontainer/post-create.sh` and `.devcontainer/python-uv/post-create.sh`:

- PATH normalization for user-level CLIs
- LazyVim starter bootstrap in `~/.config/nvim`
- CLI availability checks (for AI workflows)
- tmux configuration and helper layout scripts
- Git tooling availability summary on startup

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

These commands are generated/sourced during post-create and are intended for fast, repeatable session setup.

## Repository Layout

```text
.
├── .devcontainer/
│   ├── Dockerfile
│   ├── devcontainer.json
│   ├── post-create.sh
│   ├── python-uv/
│   ├── r/
│   └── slidev/
├── bash/
├── starship/
├── Makefile
└── README.md
```

## Quick Start

1. Open this repository in VS Code.
2. Run `Dev Containers: Reopen in Container`.
3. Wait for post-create setup to finish.
4. Start working with `nvim .`, `tmux`, or your preferred workflow.
5. *(Optional)* Run `gh auth login` once to enable `gh` and `gh dash` with your GitHub account.

If you use the `devcontainer` CLI locally, Make targets are available:

- `make python-uv`
- `make base`
- `make slidev`

Note: `base` and `slidev` targets currently assume corresponding `devcontainer.json` files will be added under their directories.

## Goal State

The long-term target is a small set of stack-focused devcontainers sharing a single high-quality developer baseline, so switching projects does not mean relearning environments.

Planned direction:

- Add first-class profiles for Python, frontend/content, and data workflows
- Keep shell/editor defaults portable and easy to override
- Make every profile AI-collaboration friendly by default
- Preserve reproducibility with minimal manual machine setup