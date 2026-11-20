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

- Debian bookworm-slim base image (Linux x86_64)
- Core dev tools (APT): `git`, `curl`, `tmux`, `htop`, `jq`, `wget`, `fd-find`, `fzf`, `bat`, `vim`, `openssh-client`, `build-essential`, Azure CLI (`az`)
- A checksum-locked toolchain of 24 CLIs installed with [mise](https://mise.jdx.dev) (see [Pinned toolchain](#pinned-toolchain-mise)):
  - Runtimes: Node.js 24 (npm/npx), `uv`, `micromamba`
  - Git: `gh`, `glab`, `entire` (Entire checkpoints), `lazygit`, `delta`, `gh-dash`
  - Search, data and shell: `ripgrep`, `eza`, `tokei`, `onefetch`, `csvlens`, `starship`, `zoxide`
  - Editor: Neovim
  - DevOps and cloud: `kubectl`, `helm`, `flux`, `sops`, `aws`, `azcopy`, `azd`
- `claude` (Claude Code) and `opencode` from their vendor installers
- Non-root `dev` user and workspace-ready permissions
- Media and browser automation: `ffmpeg` and the Playwright Chromium runtime libraries
- Dotfiles pre-loaded: `.bashrc`, bash helpers, starship config, tmux config, `onboard` wizard
- LazyVim starter pre-cloned to `~/.config/nvim` (plugins download on first `nvim` launch)
- **Git tooling**: `lazygit` (TUI git client), `gh` (GitHub CLI), `delta` (syntax-highlighted diffs), `gh-dash` (GitHub dashboard TUI)
- System-level git pager configured to use `delta` (user `~/.gitconfig` takes precedence)

### Pinned toolchain (mise)

The 24 CLIs above are declared in `.devcontainer/mise.toml` and locked in `.devcontainer/mise.lock`, which records the exact download URL and sha256 for each tool on Linux x86_64. The image build runs `mise install --locked`, so it fails instead of installing anything that doesn't match the lock. The tools are installed under `/usr/local/share/mise` and symlinked into `/usr/local/bin`. They don't need mise at runtime and don't interfere with a project's own `mise.toml`.

To add or update a tool:

1. Edit its version (or add an entry) in `.devcontainer/mise.toml`.
2. Run `.devcontainer/update-mise-lock.sh --verify` inside the container. It rewrites `mise.lock`, checks that it matches the manifest and does a clean locked install in a temp dir. Use `--bump` to move ranges such as `node = "24"` to the newest matching release.
3. If the tool brings a new executable, add it to the symlink list in the Dockerfile.
4. Commit `mise.toml` and `mise.lock` together and rebuild.

The lock only covers Linux x86_64. Building on ARM needs emulation, or an arm64 entry in the lock plus a tested build. Claude Code and OpenCode stay on their vendor installers (latest stable at build time). `mise` itself is pinned by version and sha256 in the Dockerfile.

### Post-Create Provisioning

Defined in `.devcontainer/post-create.sh`:

- CLI availability verification (claude, opencode, mise, the mise toolchain, az and the main APT tools)
- Git tooling availability summary on startup
- Helpful tips printed on startup (az login, lazygit, gh dash, onboard)
- Tool versions written to `/workspace/tool-versions.txt`
- Claude Code hooks and container-wide settings merged into `~/.claude/settings.json`
- Claude/OpenCode skills from `cedanl/.github` installed

`.devcontainer/cleanup-tmp.sh` runs on every container start (`postStartCommand`). It clears old Claude scratchpads, leftover `.so` files and the uv cache in `/tmp`, which sits on the container overlay and otherwise grows without limit.

### Git Workflow Out of the Box

Run `onboard` for a guided login. It walks through the CLIs below:

- `gh auth login` — GitHub CLI, and git over HTTPS for github.com; afterwards an empty global git `user.name` / `user.email` is filled from the gh login (`<id>+<login>@users.noreply.github.com`); existing values are kept
- `glab auth login --hostname git.sdp.surf.nl` — GitLab CLI, and git over HTTPS for the SURF GitLab
- `opencode auth login` — GitHub Copilot in OpenCode
- `claude auth login` — Claude Code

Git credential helpers are configured per host at system level in the Dockerfile (`gh` for github.com, `glab` for git.sdp.surf.nl, the old archived git.ia.surf.nl, and gitlab.com), so plain `git clone/pull/push` over HTTPS works once `gh` and `glab` are logged in. No `gh auth setup-git` or SSH keys needed.

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
- Productivity helpers (`fzf` history search, compression helpers)
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
│   ├── mise.lock
│   ├── mise.toml
│   ├── onboard.sh
│   ├── post-create.sh
│   ├── tmux.conf
│   └── update-mise-lock.sh
├── bash/
│   ├── .bashrc
│   └── .config/bash/
│       ├── aliases
│       ├── entire-local-hooks.py
│       ├── functions
│       └── rc
├── starship/
│   └── .config/starship.toml
├── tests/
│   └── test_entire_local_hooks.py
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

