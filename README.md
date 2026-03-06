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
- File and shell utilities: `bat` (syntax-highlighted cat), `eza` (modern ls), `zoxide` (smart cd)
- Git workflow: `delta` (diff viewer), `gh` (GitHub CLI), `lazygit` (TUI git client)
- Markdown and content: `glow` (terminal markdown renderer)
- Shell prompt: `starship`
- Latest Neovim install
- Non-root `dev` user and workspace-ready permissions
- CLI installs for `opencode` and `uv`

### Post-Create Provisioning

Defined in `.devcontainer/post-create.sh` and `.devcontainer/python-uv/post-create.sh`:

- PATH normalization for user-level CLIs
- Bash dotfiles copied to `~/.config/bash/` (aliases, functions, rc)
- Starship config copied to `~/.config/starship.toml`
- LazyVim starter bootstrap in `~/.config/nvim`
- Git configured to use `delta` for improved diffs
- CLI availability checks (for AI workflows)
- tmux configuration and helper layout scripts

### Shell and Prompt Experience

From `bash/` and `starship/`:

- Modular bash config (`aliases`, `functions`, `rc`)
- Productivity helpers (`fzf` history search, compression helpers, apt helpers)
- `zoxide`-powered directory jumping with `cd` override
- `eza` for modern directory listing with icons and git status
- `bat` (via `batcat`) for syntax-highlighted file viewing
- `lazygit` aliased as `lg` for a TUI git workflow
- `glow` aliased as `preview` for rendering Markdown in the terminal
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