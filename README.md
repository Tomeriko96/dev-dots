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

- Four container profiles, each with its own `Dockerfile`, `devcontainer.json`, and `post-create.sh`:
  - `python-uv` — Python 3.12 slim with `uv`, data tools, and AI-ready terminal
  - `r` — `rocker/tidyverse` with neovim, OpenCode, and tmux layouts (default user: `rstudio`)
  - `slidev` — MCR universal image with `fonts-noto-cjk`, latest neovim, and OpenCode (default user: `codespace`)
  - `base` — placeholder for a minimal shared baseline
- Shared `post-create.sh` at `.devcontainer/post-create.sh` serves as a fallback; each profile has its own dedicated version
- Shell customizations and tmux layout helpers are set up consistently across all profiles

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
- LazyVim starter bootstrap in `~/.config/nvim`
- CLI availability checks (for AI workflows)
- tmux configuration and helper layout scripts

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
│   ├── Dockerfile            # python-uv base image
│   ├── devcontainer.json     # root config (python-uv-dev)
│   ├── post-create.sh        # shared baseline post-create script
│   ├── python-uv/            # Python + uv profile
│   ├── r/                    # R tidyverse profile (rocker/tidyverse, user: rstudio)
│   └── slidev/               # Slidev presentation profile (MCR universal, user: codespace)
├── bash/
├── starship/
├── Makefile
└── README.md
```

## Quick Start

Use the `devcontainer` CLI to start any profile with Make:

```bash
make python-uv   # Python 3.12 + uv + data tools
make r           # R tidyverse (rocker/tidyverse, port 8787)
make slidev      # Slidev presentation (MCR universal, port 3030)
make base        # Minimal shared baseline
```

Each target builds the container, mounts the workspace, and drops you into a `bash` shell. The `postCreateCommand` wires up LazyVim, OpenCode, and the tmux layout helpers automatically.

## Goal State

The long-term target is a small set of stack-focused devcontainers sharing a single high-quality developer baseline, so switching projects does not mean relearning environments.

Planned direction:

- Keep shell/editor defaults portable and easy to override
- Make every profile AI-collaboration friendly by default
- Preserve reproducibility with minimal manual machine setup