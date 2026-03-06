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
- Core dev tools: `git`, `curl`, `tmux`, `htop`, `jq`, `wget`, `fd`, `tree-sitter-cli`
- Data and search utilities: `ripgrep`, `qsv`, `fzf`
- Latest Neovim install
- Non-root `dev` user and workspace-ready permissions
- CLI installs for `opencode` and `uv`

### Post-Create Provisioning

Defined in `.devcontainer/post-create.sh` and `.devcontainer/python-uv/post-create.sh`:

- PATH normalization for user-level CLIs
- Installs `starship` and `zoxide` if not already present
- Copies bash config files from `bash/` to `~/.config/bash/` and wires them into `.bashrc`
- Copies Starship config from `starship/` to `~/.config/starship.toml`
- Copies tmux dotfiles from `tmux/` to `~/` and wires them into `.bashrc`
- LazyVim starter bootstrap in `~/.config/nvim`
- CLI availability checks (for AI workflows)

### Shell and Prompt Experience

From `bash/` and `starship/`:

- Modular bash config (`aliases`, `functions`, `rc`)
- Productivity helpers (`fzf` history search, compression helpers, apt helpers)
- `zoxide`-powered directory jumping
- Starship prompt with concise git-aware status

### tmux Configuration

Defined in `tmux/.tmux.conf`:

- Mouse support for click, resize, and scroll
- True 24-bit color support for Neovim and modern CLI tools
- Reduced escape-time for Neovim responsiveness
- Focus events enabled (used by Neovim autoread)
- Vi copy mode with familiar `v`/`y` bindings
- Vim-style pane navigation with `prefix + h/j/k/l`
- Intuitive split shortcuts: `prefix + |` (horizontal) and `prefix + -` (vertical)
- Both `Ctrl-b` (default) and `Ctrl-a` (screen-style) as prefix keys
- Reload config with `prefix + r`
- Clean, minimal status bar showing session, user, host, and time

### AI + tmux Workflows

The tmux layout helpers are defined in `tmux/.tmux-dev-layouts.sh` and designed for coding with one or more AI assistants in parallel:

- `tdl <ai> [second_ai]`: editor + AI pane(s) + terminal strip
- `tdlm <ai> [second_ai]`: one dev window per subdirectory
- `tsl <pane_count> <command>`: command swarm across panes

All three commands auto-create a tmux session when run outside of tmux, so you can use them from any shell prompt. They are sourced during post-create for immediate availability.

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
├── tmux/
│   ├── .tmux.conf
│   └── .tmux-dev-layouts.sh
├── Makefile
└── README.md
```

## Quick Start

1. Open this repository in VS Code.
2. Run `Dev Containers: Reopen in Container`.
3. Wait for post-create setup to finish.
4. Start working with `nvim .`, `tmux`, or your preferred workflow.

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