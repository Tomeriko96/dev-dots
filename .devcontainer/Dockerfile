FROM debian:bookworm-slim

# ==============================================================================
# Pinned versions
# ==============================================================================

ARG LAZYGIT_VERSION="0.60.0"
ARG DELTA_VERSION="0.18.0"
ARG RIPGREP_VERSION="15.1.0"
ARG CSVLENS_VERSION="0.15.1"
ARG NEOVIM_VERSION="0.11.6"
ARG GH_DASH_VERSION="4.23.1"
ARG TOKEI_VERSION="12.1.2"
ARG ONEFETCH_VERSION="2.22.0"
ARG STARSHIP_VERSION="1.24.2"
ARG UV_VERSION="0.11.1"
ARG ZOXIDE_VERSION="0.9.9"
ARG MICROMAMBA_VERSION="2.8.1-0"
ARG AZCOPY_VERSION="10.26.0"
ARG AZD_VERSION="1.9.5"
ARG GLAB_VERSION="1.58.0"
ARG SOPS_VERSION="3.10.2"

# Flux 0.48.0 is not a valid flux2 CLI release asset.
# Use a real flux2 release.
ARG FLUX_VERSION="2.4.0"

ARG KUBECTL_VERSION="1.31.14"
ARG HELM_VERSION="3.16.0"
ARG AWS_CLI_VERSION="2.17.34"

# NodeSource Node.js 24 LTS repository.
ARG NODE_MAJOR="24"

# ==============================================================================
# Bootstrap APT
#
# bookworm-slim does not necessarily contain curl/gpg.
# Therefore one initial apt update is unavoidable before external repositories
# can be configured.
# ==============================================================================

RUN set -eux; \
    apt-get update; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        gnupg; \
    rm -rf /var/lib/apt/lists/*

# ==============================================================================
# Configure all external APT repositories
# ==============================================================================

RUN set -eux; \
    mkdir -p /etc/apt/keyrings; \
    \
    # GitHub CLI ---------------------------------------------------------------
    curl -fsSL \
        https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        -o /etc/apt/keyrings/githubcli.gpg; \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli.gpg] https://cli.github.com/packages stable main" \
        > /etc/apt/sources.list.d/github-cli.list; \
    \
    # eza ----------------------------------------------------------------------
    curl -fsSL \
        https://raw.githubusercontent.com/eza-community/eza/main/deb.asc \
        | gpg --dearmor -o /etc/apt/keyrings/eza.gpg; \
    echo "deb [signed-by=/etc/apt/keyrings/eza.gpg] http://deb.gierens.de stable main" \
        > /etc/apt/sources.list.d/eza.list; \
    \
    # Microsoft / Azure CLI ---------------------------------------------------
    curl -fsSL \
        https://packages.microsoft.com/keys/microsoft.asc \
        | gpg --dearmor -o /etc/apt/keyrings/microsoft.gpg; \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/azure-cli/ bookworm main" \
        > /etc/apt/sources.list.d/azure-cli.list; \
    \
    # NodeSource ---------------------------------------------------------------
    curl -fsSL \
        https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
        | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg; \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_MAJOR}.x nodistro main" \
        > /etc/apt/sources.list.d/nodesource.list; \
    \
    # Validate repository configuration --------------------------------------
    test -s /etc/apt/keyrings/githubcli.gpg; \
    test -s /etc/apt/keyrings/eza.gpg; \
    test -s /etc/apt/keyrings/microsoft.gpg; \
    test -s /etc/apt/keyrings/nodesource.gpg

# ==============================================================================
# Install all APT-managed packages
#
# This is the single full apt-get update for all configured repositories.
# ==============================================================================

RUN set -eux; \
    apt-get update; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        azure-cli \
        bat \
        build-essential \
        eza \
        fd-find \
        ffmpeg \
        fzf \
        gh \
        git \
        htop \
        jq \
        locales \
        nodejs \
        openssh-client \
        tmux \
        unzip \
        vim \
        wget \
        xz-utils; \
    rm -rf /var/lib/apt/lists/*; \
    rm -f \
        /etc/apt/sources.list.d/github-cli.list \
        /etc/apt/sources.list.d/eza.list \
        /etc/apt/sources.list.d/azure-cli.list \
        /etc/apt/sources.list.d/nodesource.list; \
    rm -rf /etc/apt/keyrings

# ==============================================================================
# Git configuration
# ==============================================================================

RUN set -eux; \
    git config --system init.defaultBranch main

# ==============================================================================
# lazygit
# ==============================================================================

RUN set -eux; \
    curl -fL --retry 3 \
        -o /tmp/lazygit.tar.gz \
        "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"; \
    tar -C /tmp -xzf /tmp/lazygit.tar.gz lazygit; \
    install -m 0755 /tmp/lazygit /usr/local/bin/lazygit; \
    rm -f /tmp/lazygit.tar.gz /tmp/lazygit; \
    lazygit --version

# ==============================================================================
# delta
# ==============================================================================

RUN set -eux; \
    curl -fL --retry 3 \
        -o /tmp/delta.deb \
        "https://github.com/dandavison/delta/releases/download/${DELTA_VERSION}/git-delta_${DELTA_VERSION}_amd64.deb"; \
    dpkg -i /tmp/delta.deb; \
    rm -f /tmp/delta.deb; \
    delta --version

RUN set -eux; \
    git config --system core.pager delta; \
    git config --system interactive.diffFilter "delta --color-only"; \
    git config --system delta.navigate true; \
    git config --system delta.light false; \
    git config --system merge.conflictStyle diff3; \
    git config --system diff.colorMoved default

# ==============================================================================
# ripgrep
# ==============================================================================

RUN set -eux; \
    curl -fL --retry 3 \
        -o /tmp/ripgrep.deb \
        "https://github.com/BurntSushi/ripgrep/releases/download/${RIPGREP_VERSION}/ripgrep_${RIPGREP_VERSION}-1_amd64.deb"; \
    dpkg -i /tmp/ripgrep.deb; \
    rm -f /tmp/ripgrep.deb; \
    rg --version

# ==============================================================================
# tokei
# ==============================================================================

RUN set -eux; \
    curl -fL --retry 3 \
        -o /tmp/tokei.tar.gz \
        "https://github.com/XAMPPRocky/tokei/releases/download/v${TOKEI_VERSION}/tokei-x86_64-unknown-linux-musl.tar.gz"; \
    tar -C /tmp -xzf /tmp/tokei.tar.gz tokei; \
    install -m 0755 /tmp/tokei /usr/local/bin/tokei; \
    rm -f /tmp/tokei.tar.gz /tmp/tokei; \
    tokei --version

# ==============================================================================
# onefetch
# ==============================================================================

RUN set -eux; \
    curl -fL --retry 3 \
        -o /tmp/onefetch.tar.gz \
        "https://github.com/o2sh/onefetch/releases/download/${ONEFETCH_VERSION}/onefetch-linux.tar.gz"; \
    tar -C /tmp -xzf /tmp/onefetch.tar.gz; \
    install -m 0755 /tmp/onefetch /usr/local/bin/onefetch; \
    rm -f /tmp/onefetch.tar.gz /tmp/onefetch; \
    onefetch --version

# ==============================================================================
# csvlens
# ==============================================================================

RUN set -eux; \
    curl -fL --retry 3 \
        -o /tmp/csvlens.tar.xz \
        "https://github.com/YS-L/csvlens/releases/download/v${CSVLENS_VERSION}/csvlens-x86_64-unknown-linux-gnu.tar.xz"; \
    tar -C /tmp -xJf /tmp/csvlens.tar.xz; \
    CSVLENS_BIN="$(find /tmp -maxdepth 3 -type f -name csvlens -print -quit)"; \
    test -n "$CSVLENS_BIN"; \
    install -m 0755 "$CSVLENS_BIN" /usr/local/bin/csvlens; \
    rm -f /tmp/csvlens.tar.xz; \
    csvlens --version

# ==============================================================================
# azcopy
# ==============================================================================

RUN set -eux; \
    curl -fL --retry 3 \
        -o /tmp/azcopy.tar.gz \
        "https://github.com/Azure/azure-storage-azcopy/releases/download/v${AZCOPY_VERSION}/azcopy_linux_amd64_${AZCOPY_VERSION}.tar.gz"; \
    tar -C /tmp -xzf /tmp/azcopy.tar.gz; \
    AZCOPY_BIN="$(find /tmp -maxdepth 3 -type f -name azcopy -print -quit)"; \
    test -n "$AZCOPY_BIN"; \
    install -m 0755 "$AZCOPY_BIN" /usr/local/bin/azcopy; \
    rm -rf /tmp/azcopy.tar.gz /tmp/azcopy_linux_amd64_*; \
    azcopy --version

# ==============================================================================
# Azure Developer CLI
# ==============================================================================

RUN set -eux; \
    curl -fL --retry 3 \
        -o /tmp/azd.deb \
        "https://github.com/Azure/azure-dev/releases/download/azure-dev-cli_${AZD_VERSION}/azd_${AZD_VERSION}_amd64.deb"; \
    dpkg -i /tmp/azd.deb; \
    rm -f /tmp/azd.deb; \
    azd version

# ==============================================================================
# Locale
# ==============================================================================

RUN set -eux; \
    sed -i 's/^# *en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen; \
    locale-gen

ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV TZ=Europe/Amsterdam

# ==============================================================================
# Neovim
# ==============================================================================

RUN set -eux; \
    curl -fL --retry 3 \
        -o /tmp/nvim.tar.gz \
        "https://github.com/neovim/neovim/releases/download/v${NEOVIM_VERSION}/nvim-linux-x86_64.tar.gz"; \
    tar -C /usr -xzf /tmp/nvim.tar.gz; \
    ln -sf /usr/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim; \
    rm -f /tmp/nvim.tar.gz; \
    nvim --version | head -n1

# ==============================================================================
# Playwright / Chromium runtime dependencies
# ==============================================================================

RUN set -eux; \
    apt-get update; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        libasound2 \
        libatk-bridge2.0-0 \
        libatk1.0-0 \
        libcairo2 \
        libcups2 \
        libdbus-1-3 \
        libdrm2 \
        libgbm1 \
        libglib2.0-0 \
        libnss3 \
        libnspr4 \
        libpango-1.0-0 \
        libx11-6 \
        libxcomposite1 \
        libxdamage1 \
        libxext6 \
        libxfixes3 \
        libxkbcommon0 \
        libxrandr2; \
    rm -rf /var/lib/apt/lists/*

# ==============================================================================
# micromamba
# ==============================================================================

RUN set -eux; \
    curl -fL --retry 3 \
        -o /usr/local/bin/micromamba \
        "https://github.com/mamba-org/micromamba-releases/releases/download/${MICROMAMBA_VERSION}/micromamba-linux-64"; \
    chmod 0755 /usr/local/bin/micromamba; \
    micromamba --version

# ==============================================================================
# kubectl
#
# Installed as a pinned upstream binary rather than from the Kubernetes APT
# repository, so KUBECTL_VERSION actually means something.
# ==============================================================================

RUN set -eux; \
    curl -fL --retry 3 \
        -o /usr/local/bin/kubectl \
        "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl"; \
    chmod 0755 /usr/local/bin/kubectl; \
    kubectl version --client

# ==============================================================================
# Helm
#
# Installed as a pinned upstream binary. This avoids the Buildkite repository
# silently giving you Helm 4.x when HELM_VERSION says 3.x.
# ==============================================================================

RUN set -eux; \
    curl -fL --retry 3 \
        -o /tmp/helm.tar.gz \
        "https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz"; \
    tar -C /tmp -xzf /tmp/helm.tar.gz; \
    install -m 0755 /tmp/linux-amd64/helm /usr/local/bin/helm; \
    rm -rf /tmp/helm.tar.gz /tmp/linux-amd64; \
    helm version

# ==============================================================================
# sops
# ==============================================================================

RUN set -eux; \
    curl -fL --retry 3 \
        -o /tmp/sops \
        "https://github.com/getsops/sops/releases/download/v${SOPS_VERSION}/sops-v${SOPS_VERSION}.linux.amd64"; \
    install -m 0755 /tmp/sops /usr/local/bin/sops; \
    rm -f /tmp/sops; \
    sops --version

# ==============================================================================
# glab
#
# GitLab's generic package API is used because the GitHub-style release URL
# previously used here does not exist for this version.
# ==============================================================================

RUN set -eux; \
    curl -fL --retry 3 \
        -o /tmp/glab.tar.gz \
        "https://gitlab.com/api/v4/projects/gitlab-org%2Fcli/packages/generic/glab/${GLAB_VERSION}/glab_${GLAB_VERSION}_linux_amd64.tar.gz"; \
    tar -C /tmp -xzf /tmp/glab.tar.gz; \
    GLAB_BIN="$(find /tmp -type f -path '*/bin/glab' -print -quit)"; \
    test -n "$GLAB_BIN"; \
    install -m 0755 "$GLAB_BIN" /usr/local/bin/glab; \
    rm -rf /tmp/glab.tar.gz /tmp/glab_* /tmp/bin; \
    glab version

# ==============================================================================
# Flux CD
# ==============================================================================

RUN set -eux; \
    curl -fL --retry 3 \
        -o /tmp/flux.tar.gz \
        "https://github.com/fluxcd/flux2/releases/download/v${FLUX_VERSION}/flux_${FLUX_VERSION}_linux_amd64.tar.gz"; \
    tar -C /tmp -xzf /tmp/flux.tar.gz flux; \
    install -m 0755 /tmp/flux /usr/local/bin/flux; \
    rm -f /tmp/flux.tar.gz /tmp/flux; \
    flux --version

# ==============================================================================
# AWS CLI
#
# The official v2 installer does not expose the version in its download URL,
# so AWS_CLI_VERSION is retained as documentation but the official installer
# remains unpinned.
# ==============================================================================

RUN set -eux; \
    curl -fL --retry 3 \
        -o /tmp/awscliv2.zip \
        "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"; \
    unzip -q /tmp/awscliv2.zip -d /tmp; \
    /tmp/aws/install \
        --bin-dir /usr/local/bin \
        --install-dir /usr/local/aws-cli; \
    rm -rf /tmp/awscliv2.zip /tmp/aws; \
    aws --version

# ==============================================================================
# Non-root development user
# ==============================================================================

ARG USERNAME=dev
ARG UID=1000
ARG GID=1000

RUN set -eux; \
    groupadd --gid "${GID}" "${USERNAME}"; \
    useradd \
        --uid "${UID}" \
        --gid "${GID}" \
        --create-home \
        --shell /bin/bash \
        "${USERNAME}"; \
    mkdir -p /workspace; \
    chown "${USERNAME}:${USERNAME}" /workspace

# ==============================================================================
# Starship
# ==============================================================================

RUN set -eux; \
    curl -fsSL https://starship.rs/install.sh \
        | sh -s -- -y --version "v${STARSHIP_VERSION}"; \
    starship --version

# ==============================================================================
# zoxide
# ==============================================================================

RUN set -eux; \
    curl -fL --retry 3 \
        -o /tmp/zoxide.deb \
        "https://github.com/ajeetdsouza/zoxide/releases/download/v${ZOXIDE_VERSION}/zoxide_${ZOXIDE_VERSION}-1_amd64.deb"; \
    dpkg -i /tmp/zoxide.deb; \
    rm -f /tmp/zoxide.deb; \
    zoxide --version

# ==============================================================================
# User dotfiles
# ==============================================================================

COPY --chown=${USERNAME}:${USERNAME} bash/.bashrc \
    /home/${USERNAME}/.bashrc

COPY --chown=${USERNAME}:${USERNAME} bash/.config/ \
    /home/${USERNAME}/.config/

COPY --chown=${USERNAME}:${USERNAME} starship/.config/starship.toml \
    /home/${USERNAME}/.config/starship.toml

COPY --chown=${USERNAME}:${USERNAME} .devcontainer/tmux.conf \
    /home/${USERNAME}/.tmux.conf

COPY --chown=${USERNAME}:${USERNAME} .devcontainer/onboard.sh \
    /home/${USERNAME}/.onboard.sh

COPY --chown=${USERNAME}:${USERNAME} .devcontainer/hooks/ \
    /home/${USERNAME}/.claude/hooks/

RUN set -eux; \
    chmod +x /home/${USERNAME}/.onboard.sh; \
    find /home/${USERNAME}/.claude/hooks \
        -type f \
        -name '*.sh' \
        -exec chmod +x {} +

# ==============================================================================
# User environment
# ==============================================================================

WORKDIR /workspace

ENV PATH="/home/${USERNAME}/.local/bin:/usr/local/bin:/usr/local/sbin:/usr/bin:/sbin:/bin"
ENV FZF_DEFAULT_COMMAND="fdfind --type f"
ENV MAMBA_ROOT_PREFIX="/home/${USERNAME}/micromamba"

USER ${USERNAME}

# ==============================================================================
# micromamba shell integration
# ==============================================================================

RUN set -eux; \
    micromamba shell init \
        --shell bash \
        --root-prefix "${MAMBA_ROOT_PREFIX}"

# ==============================================================================
# OpenCode
# ==============================================================================

RUN set -eux; \
    curl -fsSL https://opencode.ai/install \
        | bash

# ==============================================================================
# Claude Code
# ==============================================================================

RUN set -eux; \
    curl -fsSL https://claude.ai/install.sh \
        | bash

# ==============================================================================
# gh-dash
# ==============================================================================

RUN set -eux; \
    GH_DASH_DIR="$HOME/.local/share/gh/extensions/gh-dash"; \
    mkdir -p "$GH_DASH_DIR"; \
    curl -fL --retry 3 \
        -o "$GH_DASH_DIR/gh-dash" \
        "https://github.com/dlvhdr/gh-dash/releases/download/v${GH_DASH_VERSION}/gh-dash_v${GH_DASH_VERSION}_linux-amd64"; \
    chmod 0755 "$GH_DASH_DIR/gh-dash"

# ==============================================================================
# uv
# ==============================================================================

RUN set -eux; \
    curl -LsSf https://astral.sh/uv/install.sh \
        | UV_VERSION="${UV_VERSION}" sh; \
    "$HOME/.local/bin/uv" --version

# ==============================================================================
# LazyVim
# ==============================================================================

RUN set -eux; \
    rm -rf /home/${USERNAME}/.config/nvim; \
    git clone --depth=1 \
        https://github.com/LazyVim/starter \
        /home/${USERNAME}/.config/nvim; \
    rm -rf /home/${USERNAME}/.config/nvim/.git

# ==============================================================================
# Default command
# ==============================================================================

CMD ["bash"]

