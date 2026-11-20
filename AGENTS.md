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

> Working agreements for this session (the user steers you from a phone through remote control): deliver the way the repo note's delivery row says (default: a ready-for-review PR, draft false), without asking; in /factory setup ask nothing this brief or the repo note answers, and run the smoke test only on a repo's first setup. Take the recommended option yourself for routine choices (effort, bundling, starting a triage plan, clean-up; an issue that waits on an open PR/MR: leave it and take the next) and say so in one line; ask only content questions (which option to build, design choices, unblocking an issue). Keep questions phone-sized: at most 3 options, recommended first, one line each. After every job state change (PR open, merged, needs-human, failed) post one status line like "#233 → PR #281 open, CI running". When a job reaches PR or merged, run /factory next yourself until it finds nothing, then report once that you are done. Issues stay modular (one defect each), jobs bundle: build small related issues in the same area together (up to the factory's bundle limit) so one branch, one PR and one CI run serve them. After every merge to the base branch, bring your open PRs/MRs up to date (/factory sync): merge or rebase the base, resolve conflicts yourself, push, and switch auto-merge back on where it was; for Renovate MRs in the repo tick their rebase checkbox. After a merge, check CI on the base branch: if it fails, first analyse the cause and whether that check is still needed, then propose a fix; do not fix CI on your own. A CI job that fails on infrastructure (registry quota, runner, network, a missing CI variable) and not on your change is not a rework: say so in one line, retry that pipeline at most once an hour, and do not mark the job failed; when the forge is read-only or down, keep the work committed locally and push once it is back. Close issues and clean up worktrees of finished jobs without asking. When /factory next finds nothing to build, look for new work yourself (discovery): re-check the blockers of your blocked issues (blocker closed or gone: remove the label and say so, or close a stale issue with the reason), run the tests and linters, start the app locally without credentials (its dev/open mode and a local database; never ask for or read secrets or dotenv files) and use it like a user with headless Chromium, also to check your own UI changes (`uv run --no-project --python 3 --with playwright python …`, install it with `uv run --no-project --python 3 --with playwright playwright install chromium` if missing), and check the code against any audit or review markdown in the repo (e.g. `docs/audit*.md`, `AUDIT*.md`, `docs/review*`, `docs/audits/`). Only report real defects you reproduced (a failing command, a wrong output, a broken page, an audit finding that is still true in the code), not style preferences; search open and closed issues first to avoid duplicates. Open at most 5 new issues per night per repo, each with the evidence (command + output or screenshot) and numbered testable acceptance criteria, as the user (gh/glab), then build them with /factory issue <nr>. Never merge yourself; switching on the forge's auto-merge is fine when `delivery.auto_merge` is true.

**Repo notes.** Send the repo's rows from "Repo context" below (its delivery row, plus any other
row naming it) as a second one-line message right after the brief: the worker does not read this
file. `worker-start` sends the brief; send the note with `worker-send` (6).

### Repo context
**The user's own repos.** Personal `Tomeriko96/*` and the GitLab projects they author, plus
cedanl repos where they wrote most of the commits (2026-11): mbo-bekostiging-bestanden (93%),
onderwijsdata-chat (86%, primary on GitLab `surf-internal/npuls/ceda/`), dev-dots,
python-uv-devcontainer, r-devcontainer, savvy, 1cijferho (58%), 1cijferho-evaluatietool (56%),
and `surf-internal/npuls/sectoropgave/prompt-library` on GitLab. In these, workers may start the
app and inspect it visually (headless Chromium via uv playwright) during discovery and audits.
In repos where the user is a minor contributor (`.github`, sdp-tools, studentprognose, …) keep to
the issue at hand. Recount with
`gh api repos/<o>/<r>/contributors --jq '.[]|select(.login=="Tomeriko96").contributions'`.

**Delivery per repo** (the user's call; change a row when they say so, and the worker follows the
row, not a one-off night instruction that has since lapsed):

| Repo | Delivery |
|---|---|
| onderwijsdata-chat, prompt-library (GitLab) | PR/MR, `auto_merge: true` |
| cedanl GitHub repos (1cijferho, mbo-bekostiging-bestanden, sdp-tools, `.github`, …) | ready PR, no auto-merge (no required checks on main); the user merges |
| Tomeriko96 work repos (dev-dots, factory-template, devcontainers, savvy) | ready PR; the user merges |
| fun side projects (react-tetris) | no factory: commit and push to the default branch |

**Issue authors on GitLab.** Issues imported from the old GitLab show the author
`tomeriwan_placeholder_1h086uk`: that is the user. Put it in `issues.allowed_authors` next to
`tomer.iwan` at setup.

**Never touch:** `cedanl/studentprognose` (the user's instruction). Starting work there needs the
user to name it again.

**Bundling.** Issues stay modular (one defect per issue, so each is traceable and closable);
jobs bundle them. In the user's own repos set `"limits": {"bundle_max": 5, "full_bundle_max": 3}`
in `.factory/config.json` (`full_bundle_max` needs factory-template ≥ PR #3), so related audit
findings share one job, one PR and one CI run.

**External audits** (an audit the user pastes or sends, e.g. a live run on the test environment):
save it as `work/<repo>-audit-<YYYY-MM-DD>.md`, start a worker in its own clone with "verify each
finding against main, open modular issues for the reproduced ones (deduplicated), then bundle
them into jobs", and tell any audit session of that repo to deduplicate against it.

**Live audits** (the user's own apps; first run on prompt-library and onderwijsdata-chat,
2026-11-20): one subagent per theme on Opus at effort high, the app running locally without
credentials, driven with headless Chromium. Themes: one per end-user persona, accessibility
(WCAG 2.2 AA), privacy/AVG, security, technical/operational, content/language, plus
app-specific ones (an editorial workflow, data correctness, exports). Each theme has a
reusable instruction `docs/audits/<theme>.md` and dated reports
`docs/audits/reports/<YYYY-MM-DD>-<theme>-<short hash>.md` naming the full HEAD commit audited.
Only reproduced defects become issues (deduplicated; at most 10 per repo per day); the rest
stays in the report. In onderwijsdata-chat the agent plays the LLM through mock scenarios
(#1065) so the chat and report flow run without a key.

**Fun side projects** (personal, no users depending on them: e.g. `Tomeriko96/react-tetris`) need
not be perfect and get **no factory**: no `/factory`, no worker brief, no review rounds, no
Playwright gates, no heavy slots, no validation runs. Start a plain `claude` session in the clone
(`worker-start` without a factory command, or `claude --model sonnet`) with the task and "keep it
light, commit and push straight to the default branch, no PR". That push is the user's standing
approval for these repos only.

**Running the apps locally without credentials** (both checked end to end with headless
Chromium on 2026-11-20 in this container, which has no Docker; 0 console errors):
- **onderwijsdata-chat:** `uv sync && make dev` (backend :8000, frontend :5173; the Vite proxy is
  fixed to :8000, so keep the default ports, and only one copy can run at a time). It starts with no
  keys at all: SQLite, no login locally (OIDC is opt-in), and the catalogue, data tools and
  `mcp_server.py` need no key. Only chat answers need an LLM key; there is no mock-LLM mode, so
  test the chat flow up to the model call, or with litellm's `mock_response` in tests.
- **prompt-library:** needs PostgreSQL; `just db-up` uses Docker, which is not here. Instead:
  ```bash
  micromamba create -y -n pg -c conda-forge postgresql=16   # once
  P=~/micromamba/envs/pg/bin; D=/tmp/pgdata-prompts
  $P/initdb -D $D -U postgres --auth=trust && $P/pg_ctl -D $D -o "-p 5544 -k /tmp" -l /tmp/pg.log start
  $P/psql -h 127.0.0.1 -p 5544 -U postgres -c 'create database prompts'
  export POSTGRES_URI=postgresql+asyncpg://postgres@127.0.0.1:5544/prompts   # asyncpg, not psycopg
  just migrate && DEV_USER_FALLBACK=true just run      # :8080, open, seeded with the 12 POC prompts
  cd frontend && npx vite --port 5174 --strictPort     # UI; :5173 clashes with onderwijsdata-chat
  ```
  Call `$P/pg_ctl` directly, not through `micromamba run` (that hangs on the server process).
  Unset `OIDC_PROVIDER` = no login; `ENVIRONMENT=development` is required (`just run` sets it).

**1cijferho feeds other repos.** Its decoded/`_enriched` output (file names, suffixes, column
names and types) is read by: `cedanl/no-fairness-without-awareness` (R; `read_metadata.R`,
`transform_ev_data.R`, expects the `_enriched` file), `cedanl/1cho_ins_preparation_r`,
`cedanl/1cijferho_avans` and `cedanl/1cijferho-evaluatietool`. A 1cijferho job that changes the
output must grep those repos for the changed names, state the impact in the PR, and open a
follow-up issue in a consumer that breaks. Row to send: "1cijferho output is consumed by
no-fairness-without-awareness, 1cho_ins_preparation_r, 1cijferho_avans and 1cijferho-evaluatietool
(cedanl): when a job changes output file names, suffixes, columns or types, grep those repos,
state the impact in the PR and open a follow-up issue where one breaks."

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

**Sending a message to a worker:** always `/workspaces/dev-dots/scripts/worker-send <window> <text>`,
never bare `tmux send-keys`. It refuses text naming a dotenv file (the env hook would block the
command), clears Claude's dimmed suggestion but stops on text the user is typing, and presses
Enter until the prompt is empty (long text arrives as "[Pasted text]"; a busy worker queues it).
Start a message with "From the user:" only for the user's own words, and with "Orchestrator:"
for everything you add; never put your own extras under the user's name.

**Status.** When the user asks, answer with one table: window, job/issue, state, next step (from
`factory-watch`, `.factory/watch --once` per clone and the pane tails). While workers run
unattended, send one push notification per real change (an MR opened or merged, a worker stuck on
a question, an infra outage), never per poll.

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

### 8. Infra and capacity
Outages hit every worker at once; handle them here, not per worker:
- **Registry/CI infra** (Harbor `cr.surf.nl` quota full, runner down, missing CI variables): not a
  code failure. Tell the workers (their brief already says: no rework, retry hourly), tell the user
  the cause and what only they can do (Harbor cleanup, robot variables), retry the pipelines later.
- **Forge read-only or down:** `worker-send` every worker on that forge "Orchestrator: pause every
  write to <forge> (no push, MR, issue, comment, label), keep work committed locally" and lift it
  when the user says it is back (live audits and local builds go on meanwhile).
- **Usage limit** ("You've hit your … limit · resets 1:40pm"): `worker-watch` sends "continue" two
  minutes after the reset, once per limit (`work/worker-watch.resumed`). Many Opus sessions at
  effort high use up the 5-hour limit in a few hours: run builders' reviewers on Sonnet where the
  factory allows it, and keep Opus/high for audits and security.
- **Machine load** (4 cores, 8 GB; check `/proc/loadavg`): at most 3 worker sessions at a time, an
  audit session counting as 2; a session's headless browser and test suites go through
  `.factory/heavy`; only one session per repo runs the app (onderwijsdata-chat's ports are fixed).
  Above a load of 2× the cores, start no new jobs or sessions.

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
- Credentials in `.env` / `.env.<suffix>` are blocked for Claude's Read, Grep and Bash tools via hook (`block-env-read.sh`); best-effort denylist, not a sandbox (`.env.example` and `.env.sample` stay readable)
