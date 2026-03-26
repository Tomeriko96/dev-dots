FROM debian:bookworm-slim

# ── Pinned versions ───────────────────────────────────────────────────────────
# This is the single place to update tool versions.
# To upgrade a tool: change the value and rebuild.
ARG LAZYGIT_VERSION="0.60.0"
ARG DELTA_VERSION="0.18.0"
ARG RIPGREP_VERSION="15.1.0"
ARG CSVLENS_VERSION="0.15.1"
ARG TEALDEER_VERSION="1.8.1"
ARG NEOVIM_VERSION="0.11.6"
ARG GH_DASH_VERSION="4.23.1"
ARG YAZI_VERSION="26.1.22"
ARG STARSHIP_VERSION="1.24.2"
ARG UV_VERSION="0.11.1"
ARG ZOXIDE_VERSION="0.9.9"
# ─────────────────────────────────────────────────────────────────────────────

# Install all system dependencies first (including gnupg for qsv)
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        build-essential \
        git \
        curl \
        tmux \
        htop \
        ca-certificates \
        locales \
        xz-utils \
        fzf \
        fd-find \
        bat \
        jq \
        wget \
        gnupg \
        openssh-client \
        unzip && \
    rm -rf /var/lib/apt/lists/*

# Install Node.js LTS (for npm/Slidev and other Node-based tools)
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends nodejs && \
    rm -rf /var/lib/apt/lists/*

# Install GitHub CLI (gh)
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        -o /usr/share/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        > /etc/apt/sources.list.d/github-cli.list && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends gh && \
    rm -rf /var/lib/apt/lists/* && \
    rm /etc/apt/sources.list.d/github-cli.list

# Install lazygit
RUN set -eux; \
    curl -Lo /tmp/lazygit.tar.gz \
        "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"; \
    tar -C /tmp -xzf /tmp/lazygit.tar.gz lazygit; \
    mv /tmp/lazygit /usr/local/bin/lazygit; \
    rm /tmp/lazygit.tar.gz; \
    lazygit --version

# Install delta (better git diffs)
RUN set -eux; \
    curl -Lo /tmp/delta.deb \
        "https://github.com/dandavison/delta/releases/download/${DELTA_VERSION}/git-delta_${DELTA_VERSION}_amd64.deb"; \
    dpkg -i /tmp/delta.deb; \
    rm /tmp/delta.deb; \
    delta --version

# Configure delta as system-level git pager (lowest priority; user ~/.gitconfig takes precedence)
RUN git config --system core.pager delta && \
    git config --system interactive.diffFilter "delta --color-only" && \
    git config --system delta.navigate true && \
    git config --system delta.light false && \
    git config --system merge.conflictStyle diff3 && \
    git config --system diff.colorMoved default

# Install ripgrep
RUN set -eux; \
    curl -Lo /tmp/ripgrep.deb \
        "https://github.com/BurntSushi/ripgrep/releases/download/${RIPGREP_VERSION}/ripgrep_${RIPGREP_VERSION}-1_amd64.deb"; \
    dpkg -i /tmp/ripgrep.deb; \
    rm /tmp/ripgrep.deb; \
    rg --version

# Install eza (modern ls replacement)
RUN mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | gpg --dearmor -o /etc/apt/keyrings/gierens.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" > /etc/apt/sources.list.d/gierens.list && \
    chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends eza && \
    rm -rf /var/lib/apt/lists/* && \
    rm /etc/apt/sources.list.d/gierens.list

# Install qsv from external repo (gnupg now available)
RUN wget -O - https://dathere.github.io/qsv-deb-releases/qsv-deb.gpg | \
    gpg --dearmor -o /usr/share/keyrings/qsv-deb.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/qsv-deb.gpg] https://dathere.github.io/qsv-deb-releases ./" > /etc/apt/sources.list.d/qsv.list && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends qsv && \
    rm -rf /var/lib/apt/lists/* && \
    rm /etc/apt/sources.list.d/qsv.list

# Install yazi (terminal file manager)
# Using .zip instead of .deb to avoid heavy preview deps (ffmpeg, imagemagick, etc.)
RUN set -eux; \
    curl -Lo /tmp/yazi.zip \
        "https://github.com/sxyazi/yazi/releases/download/v${YAZI_VERSION}/yazi-x86_64-unknown-linux-musl.zip"; \
    unzip -q /tmp/yazi.zip -d /tmp/yazi; \
    mv /tmp/yazi/yazi-x86_64-unknown-linux-musl/yazi /usr/local/bin/yazi; \
    mv /tmp/yazi/yazi-x86_64-unknown-linux-musl/ya /usr/local/bin/ya; \
    rm -rf /tmp/yazi /tmp/yazi.zip; \
    yazi --version

# Install csvlens (interactive CSV viewer)
RUN set -eux; \
    curl -Lo /tmp/csvlens.tar.xz \
        "https://github.com/YS-L/csvlens/releases/download/v${CSVLENS_VERSION}/csvlens-x86_64-unknown-linux-gnu.tar.xz"; \
    tar -C /tmp -xJf /tmp/csvlens.tar.xz; \
    CSVLENS_BIN=$(find /tmp -maxdepth 2 -name 'csvlens' -type f | head -n1); \
    [ -z "$CSVLENS_BIN" ] && { echo "ERROR: csvlens binary not found after extraction"; exit 1; }; \
    mv "$CSVLENS_BIN" /usr/local/bin/csvlens; \
    chmod +x /usr/local/bin/csvlens; \
    rm -f /tmp/csvlens.tar.xz; \
    csvlens --version

# Install tealdeer (fast tldr client)
RUN set -eux; \
    curl -fLo /usr/local/bin/tldr \
        "https://github.com/dbrgn/tealdeer/releases/download/v${TEALDEER_VERSION}/tealdeer-linux-x86_64-musl"; \
    chmod +x /usr/local/bin/tldr; \
    tldr --version

# Configure locale
RUN sed -i 's/^# *en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen && \
    locale-gen

ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    TZ=Europe/Amsterdam

# Install Neovim
RUN set -eux; \
    curl -L --retry 3 --fail -o /tmp/nvim.tar.gz \
        "https://github.com/neovim/neovim/releases/download/v${NEOVIM_VERSION}/nvim-linux-x86_64.tar.gz"; \
    tar -C /usr -xzf /tmp/nvim.tar.gz; \
    ln -sf /usr/nvim-linux-x86_64/bin/nvim /usr/bin/nvim; \
    rm /tmp/nvim.tar.gz; \
    nvim --version | head -n1

# Create non-root dev user
ARG USERNAME=dev
ARG UID=1000
ARG GID=1000

RUN groupadd --gid ${GID} ${USERNAME} && \
    useradd --uid ${UID} --gid ${GID} -m -s /bin/bash ${USERNAME} && \
    mkdir -p /workspace && chown ${USERNAME}:${USERNAME} /workspace

# Install starship prompt system-wide (requires root, installs to /usr/local/bin)
RUN curl -sS https://starship.rs/install.sh | sh -s -- -y --version v${STARSHIP_VERSION}

# Install zoxide (smart cd replacement)
RUN set -eux; \
    curl -Lo /tmp/zoxide.deb \
        "https://github.com/ajeetdsouza/zoxide/releases/download/v${ZOXIDE_VERSION}/zoxide_${ZOXIDE_VERSION}-1_amd64.deb"; \
    dpkg -i /tmp/zoxide.deb; \
    rm /tmp/zoxide.deb; \
    zoxide --version

# Copy dotfiles into the user home directory (baked into the image for instant availability)
COPY --chown=${USERNAME}:${USERNAME} bash/.bashrc /home/${USERNAME}/.bashrc
COPY --chown=${USERNAME}:${USERNAME} bash/.config/ /home/${USERNAME}/.config/
COPY --chown=${USERNAME}:${USERNAME} starship/.config/starship.toml /home/${USERNAME}/.config/starship.toml
COPY --chown=${USERNAME}:${USERNAME} .devcontainer/tmux.conf /home/${USERNAME}/.tmux.conf
COPY --chown=${USERNAME}:${USERNAME} .devcontainer/tmux-dev-layouts.sh /home/${USERNAME}/.tmux-dev-layouts.sh
RUN chmod +x /home/${USERNAME}/.tmux-dev-layouts.sh
COPY --chown=${USERNAME}:${USERNAME} .devcontainer/onboard.sh /home/${USERNAME}/.onboard.sh
RUN chmod +x /home/${USERNAME}/.onboard.sh

WORKDIR /workspace
USER ${USERNAME}

# User environment
ENV PATH="/home/${USERNAME}/.local/bin:/usr/local/bin:/usr/local/sbin:/usr/bin:/sbin:/bin"
ENV FZF_DEFAULT_COMMAND="fdfind --type f"

# Claude / Anthropic environment (non-secret, baked in)
ENV CLAUDE_CODE_USE_FOUNDRY=1 \
    ANTHROPIC_DEFAULT_OPUS_MODEL=claude-opus-4-6 \
    ANTHROPIC_DEFAULT_SONNET_MODEL=claude-sonnet-4-6 \
    ANTHROPIC_DEFAULT_HAIKU_MODEL=claude-haiku-4-6

# Install OpenCode CLI (unpinned: install script does not expose a version flag)
RUN curl -fsSL https://opencode.ai/install | bash

# Install Claude Code CLI (unpinned: install script does not expose a version flag)
RUN curl -fsSL https://claude.ai/install.sh | bash

# Install gh-dash as a gh extension
RUN set -eux; \
    GH_DASH_DIR="$HOME/.local/share/gh/extensions/gh-dash"; \
    mkdir -p "$GH_DASH_DIR"; \
    curl -fLo "$GH_DASH_DIR/gh-dash" \
        "https://github.com/dlvhdr/gh-dash/releases/download/v${GH_DASH_VERSION}/gh-dash_v${GH_DASH_VERSION}_linux-amd64"; \
    chmod +x "$GH_DASH_DIR/gh-dash"

# Install uv
RUN curl -LsSf https://astral.sh/uv/install.sh | UV_VERSION=${UV_VERSION} sh

# Bootstrap LazyVim starter config (plugins are downloaded on first nvim launch)
RUN git clone --depth=1 https://github.com/LazyVim/starter /home/${USERNAME}/.config/nvim && \
    rm -rf /home/${USERNAME}/.config/nvim/.git

# Pre-populate tealdeer (tldr) page cache
RUN tldr --update && echo "tealdeer cache updated" || echo "WARNING: tealdeer cache update failed; run 'tldr --update' manually"

# Default command
CMD ["bash"]
