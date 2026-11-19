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
2. **GitLab CLI** (`glab auth login --hostname git.sdp.surf.nl`) — enables git operations on SURF GitLab and `glab` commands
3. **OpenCode** (`opencode auth login`) — enables GitHub Copilot in OpenCode
4. **Claude Code** (`claude auth login`) — enables Claude Code CLI (subscription-based)

### Session Workflow

1. **Start container** → Run `onboard` (first time only)
2. **Open editor** — `nvim .` or `vim`
3. **Work** — use Claude Code CLI for assistance

## Autonomy (standing instruction from the user)

Work as autonomously as possible in this container. The container is the boundary, and
everything of value lives on GitHub and SURF GitLab, so a deleted local file is not a loss.
- Claude runs in bypass mode without permission prompts (`permissions.defaultMode:
  bypassPermissions` in `~/.claude/settings.json`, set by `post-create.sh`); only `.env` reads
  stay blocked. `/workspaces`, `/tmp` and `/home/dev` count as working directories
  (`additionalDirectories`), so `rm` and writes there do not trigger the outside-the-project
  prompt that bypass mode still shows. Do not ask for permission to run, edit or delete; act and report.
- Ask the user only for content decisions you cannot take from the repo, the issue or these
  instructions. Everything else: pick the sensible default, do it, say what you did.
- Before deleting a git clone or work tree, make sure nothing unpushed is lost (see `work-rm`).

## Working on another repo (factory)

**If your working directory is inside `/workspaces/dev-dots/work/`, you are the worker: skip
this whole section and just do the task in your own repo** (its own CLAUDE.md/AGENTS.md lead,
plus the brief you got as your first message).

When asked to pick up work (an issue, a fix) in a repo other than dev-dots, do not work on it
from this session. Clone it here and hand it to a separate Claude process inside that clone.
The user follows and steers that worker from their phone through remote control.

**Hands-off by default (standing instruction from the user).** Do not ask for permission or
confirmation in this flow: act, then report what you did in a few lines. Ask only for content
decisions you cannot take from the repo or the issue (which option to build, a design choice).
Everything of value lives on GitHub and SURF GitLab; local clones in `work/` are disposable.

### 1. Verify, then create
Before you create, move or hand over an issue, reproduce its claim: run the command, install
the package, start the server, grep the current code. Put the evidence (command + output) and
numbered, testable acceptance criteria in the issue. A claim that turns out stale or wrong:
close it with the reason, or correct the claim. Then create, close and move the issues without
asking (the user's own issues only; never close someone else's) and report a verdict table.

### 2. Preflight (before the tmux window opens)
Check, and fix what you can yourself, so a builder does not hit it halfway:
- `git config --global user.name` and `user.email` are set (the builder must commit); missing →
  set them to the `gh api user` login and its noreply address;
- `command -v entire` (without it the `claude()` function enables nothing; say so);
- `gh auth status` / `glab auth status --hostname git.sdp.surf.nl` for the repo's forge;
- the factory is installed in the clone (`.factory/VERSION`).

### 3. Clone and install
- Clone into `/workspaces/dev-dots/work/<repo>` (ignored by git). If the clone already exists
  and is clean, reuse it (`git fetch`, default branch). A clone that is broken, stale or in the
  way may be deleted and cloned again without asking.
- **Deleting in `work/`: always through `/workspaces/dev-dots/scripts/work-rm <repo>`, never a
  bare `rm -rf`.** It removes the clone and its `<repo>-worktrees/` only when nothing would be
  lost: no uncommitted, staged or untracked files (ignored files such as `.factory/` do not
  count), no stash, no commit that is on no remote, in the clone and in every worktree, and no
  tmux pane working inside it. `-n` is a dry run. When it refuses, the reason is real work
  (often an unpushed factory job): leave it, or finish/push it first. The factory's local state
  (`.factory/`, jobs) goes with the clone; that is accepted.
  - GitHub: `gh repo clone <owner>/<repo> work/<repo>`
  - SURF GitLab: `git clone https://git.sdp.surf.nl/<group>/<repo>.git work/<repo>`
- A fork gets an `upstream` remote: run `gh repo set-default <owner>/<repo>` so PRs go to the
  fork, not the parent.
- Factory missing: `/workspaces/dev-dots/factory-template/install --no-setup` from inside the
  clone. Not `factory-init`: it ends with `exec claude`, which skips the `claude()` function.
  The factory puts its worktrees next to the clone, in `work/<repo>-worktrees/` (ignored).

### 4. Start the worker and the factory, in one go
**Use `/workspaces/dev-dots/scripts/worker-start <window> <dir in work/> /factory issue <nr>…`.**
It does all of the below: it only presses Enter on a popup once the cursor is on "Yes", runs
`/factory setup` when the clone has no factory config yet, and stops before typing anything
else when Claude did not start (otherwise the commands land in bash). The manual steps:
Open a tmux window, `cd` into the clone and type `claude`; the window's interactive shell loads
the `claude()` function from `bash/.config/bash/functions` (Entire + bypass mode). Not the Agent
tool: a subagent runs in this session, in dev-dots, without Entire, without the clone's factory
agents and skill, and without the factory's guard hooks.
```bash
tmux new-window -d -n <repo> -c /workspaces/dev-dots
tmux send-keys -t <repo> 'cd /workspaces/dev-dots/work/<repo>' Enter
tmux send-keys -t <repo> 'claude --model opus' Enter
# accept the popups (standing approval below), then without waiting for the user:
tmux send-keys -t <repo> '/remote-control' Enter
tmux send-keys -t <repo> '<worker brief, one line>' Enter   # see 5
tmux send-keys -t <repo> '/factory setup' Enter             # first run in this clone only
tmux send-keys -t <repo> '/factory issue <nr> [<nr>…]' Enter # or '/factory next'
```
Send the commands right after each other: Claude Code queues them. Use `/factory issue <nr>`
for the issues the user picked (other people's issues in the repo stay out),
`/factory next` when they want the whole backlog. The user should never have to type "start".

**Standing approval from the user:** accept every popup the worker's Claude shows (workspace
trust, "allow external imports" for this file, permission prompts) without asking; mention in
your report what you accepted.

### 5. The worker brief
Send this as the worker's first message (one line, so `send-keys` sends it as one message):

> Working agreements for this session (the user steers you from a phone through remote control): delivery is a ready-for-review PR (pr, draft false) and run the smoke test, without asking. Take the recommended option yourself for routine choices (effort, bundling, starting a triage plan, smoke test, clean-up) and say so in one line; ask only content questions (which option to build, design choices, unblocking an issue). Keep questions phone-sized: at most 3 options, recommended first, one line each. After every job state change (PR open, merged, needs-human, failed) post one status line like "#233 → PR #281 open, CI running". When a job reaches PR or merged, run /factory next yourself until it finds nothing, then report once that you are done. After a merge, check CI on the base branch: if it fails, first analyse the cause and whether that check is still needed, then propose a fix; do not fix CI on your own. Close issues and clean up worktrees of finished jobs without asking.

### 6. Hand over, then stay out
**Unattended (the user is away or asleep):** run `/workspaces/dev-dots/scripts/worker-watch [hours]`
in the background. It approves permission prompts in every worker window (logged in
`work/worker-watch.log`) and wakes you (exits) when a worker waits more than 10 minutes on a
question dialog (exit 3) or sits idle with an unchanged screen for 15 minutes (exit 4). Then:
- the worker asks something: answer it (routine: the recommended option; a fix a reviewer or
  the worker itself found in its own PR: `/factory rework <id> <what>`); never merge;
- its factory is finished (step 7): close it;
- it rightly waits (a PR for the user to merge): `scripts/worker-watch ack <window>`, so that
  screen does not wake you again;
then start the watch again in the background.

Once `/remote-control` is on and the factory command is sent, the worker talks to the user, not
you. Report the window name and the remote-control URL, then leave it: do not read its
questions back to the user, do not ask about them here, do not send keys (popups included).
Send keys again only when the user asks you to, or to send the worker brief (5) to a worker
that was started without it. Follow along with `factory-watch` (all repos)
or `.factory/watch` in the clone if the user asks for status.

### 7. Close a finished worker
A worker is finished when `.factory/watch --once` in its clone shows nothing running or queued
and **no open PRs** (a PR waiting for a human merge still needs the worker for rework and sync),
and the issues it worked on are closed. Then, without asking:
1. Clear the prompt and quit: `tmux send-keys -t <w> C-u`, then `/exit` + Enter. Text shown
   dimmed in the prompt (`tmux capture-pane -e`, `ESC[2m`) is Claude's own suggestion, not the
   user typing; anything not dimmed may be the user on remote control: leave that worker.
2. `tmux kill-window -t <w>`.
3. `/workspaces/dev-dots/scripts/work-rm <repo>`.
Report the result in one line, including the `--resume` id that `/exit` prints.

Entire only switches on for origins under GitHub `cedanl/` and GitLab `surf-internal/npuls/ceda/`
(see `_entire_auto_enable`); personal repos (`Tomeriko96/*`) get no checkpoints.

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
- **Container settings:** Merged into `~/.claude/settings.json` during post-create

## Skills Integration

Claude skills from `cedanl/.github` are automatically loaded during post-create. To reload after updates:

```bash
npx --yes skills add cedanl/.github --skill '*' -a claude-code -a opencode -a pi -y --copy -g
```

## Notes

- CLI tool versions are pinned in `.devcontainer/mise.toml` / `mise.lock` (rebuild needed after a change). `mise` itself is pinned in the `Dockerfile`.
- First build takes 5–10 minutes; subsequent builds are cached
- Container runs on Debian Bookworm; your host (Fedora Atomic Sway) is separate
- Credentials in `.env` are not readable by Claude via hook (`block-env-read.sh`)
