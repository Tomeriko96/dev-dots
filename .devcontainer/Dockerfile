FROM debian:bookworm-slim

# ── Pinned versions ───────────────────────────────────────────────────────────
# This is the single place to update tool versions.
# To upgrade a tool: change the value and rebuild.
# renovate: datasource=github-releases depName=jesseduffield/lazygit extractVersion=^v(?<version>.+)$
ARG LAZYGIT_VERSION="0.60.0"
# renovate: datasource=github-releases depName=dandavison/delta
ARG DELTA_VERSION="0.18.0"
# renovate: datasource=github-releases depName=BurntSushi/ripgrep
ARG RIPGREP_VERSION="15.1.0"
# renovate: datasource=github-releases depName=YS-L/csvlens extractVersion=^v(?<version>.+)$
ARG CSVLENS_VERSION="0.15.1"
# renovate: datasource=github-releases depName=neovim/neovim extractVersion=^v(?<version>.+)$
ARG NEOVIM_VERSION="0.11.6"
# renovate: datasource=github-releases depName=starship/starship extractVersion=^v(?<version>.+)$
ARG STARSHIP_VERSION="1.24.2"
# renovate: datasource=github-releases depName=astral-sh/uv
ARG UV_VERSION="0.11.1"
# renovate: datasource=github-releases depName=ajeetdsouza/zoxide extractVersion=^v(?<version>.+)$
ARG ZOXIDE_VERSION="0.9.9"
# renovate: datasource=github-releases depName=mamba-org/micromamba-releases
ARG MICROMAMBA_VERSION="2.8.1-0"
# renovate: datasource=github-releases depName=Azure/azure-storage-azcopy extractVersion=^v(?<version>.+)$
ARG AZCOPY_VERSION="10.26.0"
# renovate: datasource=github-releases depName=Azure/azure-dev extractVersion=^azure-dev-cli_(?<version>.+)$
ARG AZD_VERSION="1.9.5"
# renovate: datasource=gitlab-releases depName=gitlab-org/cli extractVersion=^v(?<version>.+)$
ARG GLAB_VERSION="1.58.0"
# renovate: datasource=github-releases depName=entireio/cli extractVersion=^v(?<version>.+)$
ARG ENTIRE_VERSION="0.13.4"
# renovate: datasource=github-releases depName=getsops/sops extractVersion=^v(?<version>.+)$
ARG SOPS_VERSION="3.10.2"
# renovate: datasource=github-releases depName=fluxcd/flux2 extractVersion=^v(?<version>.+)$
ARG FLUX_VERSION="2.4.0"
# renovate: datasource=github-releases depName=kubernetes/kubernetes extractVersion=^v(?<version>.+)$
ARG KUBECTL_VERSION="1.31.14"
# renovate: datasource=github-releases depName=helm/helm extractVersion=^v(?<version>.+)$
ARG HELM_VERSION="3.16.0"
# renovate: datasource=node-version depName=node
ARG NODE_VERSION="24.22.2"
# ─────────────────────────────────────────────────────────────────────────────

# Resolve build architecture once; all subsequent RUN steps source /etc/arch_vars.
# ARCH_DEB : amd64 | arm64   (used by .deb packages and simple linux-* binaries)
# ARCH_TAR : x86_64 | aarch64 (used by *-unknown-linux-* tarballs)
# ARCH_NVIM: x86_64 | arm64        (lazygit + neovim use this mixed naming)
# ARCH_MAMBA: linux-64 | linux-aarch64  (micromamba release naming)
ARG TARGETARCH
RUN case "${TARGETARCH:-amd64}" in \
      arm64) ARCH_DEB=arm64; ARCH_TAR=aarch64; ARCH_NVIM=arm64;  ARCH_MAMBA=linux-aarch64 ;; \
      *)     ARCH_DEB=amd64; ARCH_TAR=x86_64;  ARCH_NVIM=x86_64; ARCH_MAMBA=linux-64 ;; \
    esac && \
    printf 'ARCH_DEB=%s\nARCH_TAR=%s\nARCH_NVIM=%s\nARCH_MAMBA=%s\n' \
      "$ARCH_DEB" "$ARCH_TAR" "$ARCH_NVIM" "$ARCH_MAMBA" > /etc/arch_vars

# Checksum helpers (sha_in_list / sha_single / verify_sha256), sourced next to /etc/arch_vars
COPY .devcontainer/verify.sh /usr/local/lib/verify.sh

# Install all system dependencies first (including gnupg for eza/qsv repos)
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
        iptables \
        ipset \
        sudo \
        unzip \
        ffmpeg && \
    rm -rf /var/lib/apt/lists/*

# Install Node.js (pinned LTS, for npm/Slidev and other Node-based tools).
# Official tarball verified against the SHASUMS256.txt of the same release; replaces the
# unpinned `curl | bash` NodeSource setup script.
RUN set -eux; . /etc/arch_vars; . /usr/local/lib/verify.sh; \
    NODE_ARCH=$([ "$ARCH_DEB" = "arm64" ] && echo arm64 || echo x64); \
    NODE_TARBALL="node-v${NODE_VERSION}-linux-${NODE_ARCH}.tar.xz"; \
    curl -fsSLo /tmp/node.tar.xz "https://nodejs.org/dist/v${NODE_VERSION}/${NODE_TARBALL}"; \
    verify_sha256 /tmp/node.tar.xz "$(sha_in_list "https://nodejs.org/dist/v${NODE_VERSION}/SHASUMS256.txt" "$NODE_TARBALL")"; \
    tar -C /usr/local --strip-components=1 --no-same-owner -xJf /tmp/node.tar.xz; \
    rm -f /tmp/node.tar.xz /usr/local/CHANGELOG.md /usr/local/LICENSE /usr/local/README.md; \
    node --version; npm --version

# Install GitHub CLI (gh)
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        -o /usr/share/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        > /etc/apt/sources.list.d/github-cli.list && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends gh && \
    rm -rf /var/lib/apt/lists/* && \
    rm /etc/apt/sources.list.d/github-cli.list

# Install Azure CLI (az)
RUN mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /etc/apt/keyrings/microsoft.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/azure-cli/ bookworm main" \
        > /etc/apt/sources.list.d/azure-cli.list && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends azure-cli && \
    rm -rf /var/lib/apt/lists/* && \
    rm /etc/apt/sources.list.d/azure-cli.list /etc/apt/keyrings/microsoft.gpg

# Install lazygit
RUN set -eux; . /etc/arch_vars; . /usr/local/lib/verify.sh; \
    curl -fLo /tmp/lazygit.tar.gz \
        "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_linux_${ARCH_NVIM}.tar.gz"; \
    verify_sha256 /tmp/lazygit.tar.gz "$(sha_in_list "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/checksums.txt" "lazygit_${LAZYGIT_VERSION}_linux_${ARCH_NVIM}.tar.gz")"; \
    tar -C /tmp -xzf /tmp/lazygit.tar.gz lazygit; \
    mv /tmp/lazygit /usr/local/bin/lazygit; \
    rm /tmp/lazygit.tar.gz; \
    lazygit --version

# Install delta (better git diffs)
RUN set -eux; . /etc/arch_vars; \
    curl -Lo /tmp/delta.deb \
        "https://github.com/dandavison/delta/releases/download/${DELTA_VERSION}/git-delta_${DELTA_VERSION}_${ARCH_DEB}.deb"; \
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

# Configure git credential helpers (gh for GitHub, glab for GitLab/Custom)
# The "!<cmd>" form makes git run a shell command as the helper (gh/glab have
# no standalone git-credential-* binary). gitlab.com is the default host; a
# self-hosted instance needs an extra `credential.<host>.helper` entry.
RUN git config --system init.defaultBranch main && \
    git config --system credential.https://github.com.helper "!gh auth git-credential" && \
    git config --system credential.https://gitlab.com.helper "!glab auth git-credential"

# Install ripgrep
# No arm64 .deb is published; arm64 falls back to the gnu tarball.
RUN set -eux; . /etc/arch_vars; . /usr/local/lib/verify.sh; \
    if [ "$ARCH_DEB" = "amd64" ]; then \
        curl -fLo /tmp/ripgrep.deb \
            "https://github.com/BurntSushi/ripgrep/releases/download/${RIPGREP_VERSION}/ripgrep_${RIPGREP_VERSION}-1_amd64.deb"; \
        verify_sha256 /tmp/ripgrep.deb "$(sha_single "https://github.com/BurntSushi/ripgrep/releases/download/${RIPGREP_VERSION}/ripgrep_${RIPGREP_VERSION}-1_amd64.deb.sha256")"; \
        dpkg -i /tmp/ripgrep.deb; \
        rm /tmp/ripgrep.deb; \
    else \
        curl -fLo /tmp/ripgrep.tar.gz \
            "https://github.com/BurntSushi/ripgrep/releases/download/${RIPGREP_VERSION}/ripgrep-${RIPGREP_VERSION}-aarch64-unknown-linux-gnu.tar.gz"; \
        verify_sha256 /tmp/ripgrep.tar.gz "$(sha_single "https://github.com/BurntSushi/ripgrep/releases/download/${RIPGREP_VERSION}/ripgrep-${RIPGREP_VERSION}-aarch64-unknown-linux-gnu.tar.gz.sha256")"; \
        tar -C /tmp -xzf /tmp/ripgrep.tar.gz; \
        RG_BIN=$(find /tmp -name 'rg' -type f | head -n1); \
        mv "$RG_BIN" /usr/local/bin/rg; \
        rm -rf /tmp/ripgrep.tar.gz /tmp/ripgrep-${RIPGREP_VERSION}-aarch64-unknown-linux-gnu; \
    fi; \
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

# Install csvlens (interactive CSV viewer)
RUN set -eux; . /etc/arch_vars; . /usr/local/lib/verify.sh; \
    curl -fLo /tmp/csvlens.tar.xz \
        "https://github.com/YS-L/csvlens/releases/download/v${CSVLENS_VERSION}/csvlens-${ARCH_TAR}-unknown-linux-gnu.tar.xz"; \
    verify_sha256 /tmp/csvlens.tar.xz "$(sha_in_list "https://github.com/YS-L/csvlens/releases/download/v${CSVLENS_VERSION}/sha256.sum" "csvlens-${ARCH_TAR}-unknown-linux-gnu.tar.xz")"; \
    tar -C /tmp -xJf /tmp/csvlens.tar.xz; \
    CSVLENS_BIN=$(find /tmp -maxdepth 2 -name 'csvlens' -type f | head -n1); \
    [ -z "$CSVLENS_BIN" ] && { echo "ERROR: csvlens binary not found after extraction"; exit 1; }; \
    mv "$CSVLENS_BIN" /usr/local/bin/csvlens; \
    chmod +x /usr/local/bin/csvlens; \
    rm -f /tmp/csvlens.tar.xz; \
    csvlens --version

# Configure locale
RUN sed -i 's/^# *en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen && \
    locale-gen

ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    TZ=Europe/Amsterdam

# Install Neovim
RUN set -eux; . /etc/arch_vars; \
    curl -L --retry 3 --fail -o /tmp/nvim.tar.gz \
        "https://github.com/neovim/neovim/releases/download/v${NEOVIM_VERSION}/nvim-linux-${ARCH_NVIM}.tar.gz"; \
    tar -C /usr -xzf /tmp/nvim.tar.gz; \
    ln -sf "/usr/nvim-linux-${ARCH_NVIM}/bin/nvim" /usr/bin/nvim; \
    rm /tmp/nvim.tar.gz; \
    nvim --version | head -n1

# Playwright / headless Chromium system deps (no display server needed)
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        libglib2.0-0 libnss3 libnspr4 libdbus-1-3 \
        libatk1.0-0 libatk-bridge2.0-0 libcups2 libdrm2 \
        libxkbcommon0 libxcomposite1 libxdamage1 libxfixes3 \
        libxrandr2 libgbm1 libpango-1.0-0 libcairo2 \
        libasound2 libx11-6 libxext6 && \
    rm -rf /var/lib/apt/lists/*

# Install micromamba (static binary; conda-compatible environment manager)
RUN set -eux; . /etc/arch_vars; . /usr/local/lib/verify.sh; \
    curl -fLo /usr/local/bin/micromamba \
        "https://github.com/mamba-org/micromamba-releases/releases/download/${MICROMAMBA_VERSION}/micromamba-${ARCH_MAMBA}"; \
    verify_sha256 /usr/local/bin/micromamba "$(sha_single "https://github.com/mamba-org/micromamba-releases/releases/download/${MICROMAMBA_VERSION}/micromamba-${ARCH_MAMBA}.sha256")"; \
    chmod +x /usr/local/bin/micromamba; \
    micromamba --version

# Install azcopy (Azure Storage CLI)
RUN set -eux; . /etc/arch_vars; \
    curl -Lo /tmp/azcopy.tar.gz \
        "https://github.com/Azure/azure-storage-azcopy/releases/download/v${AZCOPY_VERSION}/azcopy_linux_${ARCH_DEB}_${AZCOPY_VERSION}.tar.gz"; \
    tar -C /tmp -xzf /tmp/azcopy.tar.gz; \
    AZCOPY_BIN=$(find /tmp -maxdepth 3 -type f -name azcopy | head -n1); \
    test -n "$AZCOPY_BIN"; \
    mv "$AZCOPY_BIN" /usr/local/bin/azcopy; \
    chmod +x /usr/local/bin/azcopy; \
    rm -rf /tmp/azcopy.tar.gz /tmp/azcopy_linux_${ARCH_DEB}_*; \
    azcopy --version

# Install Azure Developer CLI (azd)
RUN set -eux; . /etc/arch_vars; \
    curl -Lo /tmp/azd.deb \
        "https://github.com/Azure/azure-dev/releases/download/azure-dev-cli_${AZD_VERSION}/azd_${AZD_VERSION}_${ARCH_DEB}.deb"; \
    dpkg -i /tmp/azd.deb; \
    rm -f /tmp/azd.deb; \
    azd version

# Install kubectl (pinned upstream binary; avoids kubernetes apt repo version drift)
RUN set -eux; . /etc/arch_vars; . /usr/local/lib/verify.sh; \
    curl -fLo /usr/local/bin/kubectl \
        "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/${ARCH_DEB}/kubectl"; \
    verify_sha256 /usr/local/bin/kubectl "$(sha_single "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/${ARCH_DEB}/kubectl.sha256")"; \
    chmod +x /usr/local/bin/kubectl; \
    kubectl version --client

# Install Helm (pinned upstream binary)
RUN set -eux; . /etc/arch_vars; . /usr/local/lib/verify.sh; \
    curl -fLo /tmp/helm.tar.gz \
        "https://get.helm.sh/helm-v${HELM_VERSION}-linux-${ARCH_DEB}.tar.gz"; \
    verify_sha256 /tmp/helm.tar.gz "$(sha_single "https://get.helm.sh/helm-v${HELM_VERSION}-linux-${ARCH_DEB}.tar.gz.sha256sum")"; \
    tar -C /tmp -xzf /tmp/helm.tar.gz; \
    HELM_BIN=$(find /tmp -maxdepth 3 -type f -name helm | head -n1); \
    test -n "$HELM_BIN"; \
    mv "$HELM_BIN" /usr/local/bin/helm; \
    chmod +x /usr/local/bin/helm; \
    rm -rf /tmp/helm.tar.gz /tmp/linux-${ARCH_DEB}; \
    helm version

# Install sops (secrets encryption)
RUN set -eux; . /etc/arch_vars; . /usr/local/lib/verify.sh; \
    curl -fLo /tmp/sops \
        "https://github.com/getsops/sops/releases/download/v${SOPS_VERSION}/sops-v${SOPS_VERSION}.linux.${ARCH_DEB}"; \
    verify_sha256 /tmp/sops "$(sha_in_list "https://github.com/getsops/sops/releases/download/v${SOPS_VERSION}/sops-v${SOPS_VERSION}.checksums.txt" "sops-v${SOPS_VERSION}.linux.${ARCH_DEB}")"; \
    chmod +x /tmp/sops; \
    mv /tmp/sops /usr/local/bin/sops; \
    sops --version

# Install glab (GitLab CLI; uses GitLab generic package API)
RUN set -eux; . /etc/arch_vars; . /usr/local/lib/verify.sh; \
    curl -fLo /tmp/glab.tar.gz \
        "https://gitlab.com/api/v4/projects/gitlab-org%2Fcli/packages/generic/glab/${GLAB_VERSION}/glab_${GLAB_VERSION}_linux_${ARCH_DEB}.tar.gz"; \
    verify_sha256 /tmp/glab.tar.gz "$(sha_in_list "https://gitlab.com/api/v4/projects/gitlab-org%2Fcli/packages/generic/glab/${GLAB_VERSION}/checksums.txt" "glab_${GLAB_VERSION}_linux_${ARCH_DEB}.tar.gz")"; \
    tar -C /tmp -xzf /tmp/glab.tar.gz; \
    GLAB_BIN=$(find /tmp -type f -path '*/bin/glab' | head -n1); \
    test -n "$GLAB_BIN"; \
    mv "$GLAB_BIN" /usr/local/bin/glab; \
    chmod +x /usr/local/bin/glab; \
    rm -rf /tmp/glab.tar.gz /tmp/bin /tmp/glab_*; \
    glab version

# Install Flux CD (pinned upstream binary)
RUN set -eux; . /etc/arch_vars; . /usr/local/lib/verify.sh; \
    curl -fLo /tmp/flux.tar.gz \
        "https://github.com/fluxcd/flux2/releases/download/v${FLUX_VERSION}/flux_${FLUX_VERSION}_linux_${ARCH_DEB}.tar.gz"; \
    verify_sha256 /tmp/flux.tar.gz "$(sha_in_list "https://github.com/fluxcd/flux2/releases/download/v${FLUX_VERSION}/flux_${FLUX_VERSION}_checksums.txt" "flux_${FLUX_VERSION}_linux_${ARCH_DEB}.tar.gz")"; \
    tar -C /tmp -xzf /tmp/flux.tar.gz flux; \
    mv /tmp/flux /usr/local/bin/flux; \
    chmod +x /usr/local/bin/flux; \
    rm -f /tmp/flux.tar.gz; \
    flux --version

# Install AWS CLI v2. The official installer only ships "latest", so we cannot
# pin a version at build time (AWS publishes PGP .sig files, not sha256 sums).
# Track the actual version via post-create's tool-versions.txt.
RUN set -eux; . /etc/arch_vars; \
    curl -Lo /tmp/awscliv2.zip \
        "https://awscli.amazonaws.com/awscli-exe-linux-${ARCH_TAR}.zip"; \
    unzip -q /tmp/awscliv2.zip -d /tmp; \
    /tmp/aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli; \
    rm -rf /tmp/awscliv2.zip /tmp/aws; \
    aws --version

# Create non-root dev user
ARG USERNAME=dev
ARG UID=1000
ARG GID=1000

RUN groupadd --gid ${GID} ${USERNAME} && \
    useradd --uid ${UID} --gid ${GID} -m -s /bin/bash ${USERNAME} && \
    mkdir -p /workspace && chown ${USERNAME}:${USERNAME} /workspace

# Opt-in egress firewall (see .devcontainer/init-firewall.sh and .devcontainer/firewall/).
# Inert unless the "firewall" devcontainer variant runs it. The sudoers rule allows exactly this
# root-owned script with no arguments: the dev user (and agents running as dev) can re-apply the
# firewall but cannot disable or widen it.
COPY .devcontainer/init-firewall.sh /usr/local/sbin/init-firewall.sh
RUN chown root:root /usr/local/sbin/init-firewall.sh && chmod 0755 /usr/local/sbin/init-firewall.sh && \
    echo "${USERNAME} ALL=(root) NOPASSWD: /usr/local/sbin/init-firewall.sh \"\"" > /etc/sudoers.d/dev-firewall && \
    chmod 0440 /etc/sudoers.d/dev-firewall && \
    visudo -cf /etc/sudoers.d/dev-firewall

# Install starship prompt system-wide (requires root, installs to /usr/local/bin)
# Pinned tarball verified against the release's .sha256 (replaces the `curl | sh` installer).
RUN set -eux; . /etc/arch_vars; . /usr/local/lib/verify.sh; \
    STARSHIP_TARBALL="starship-${ARCH_TAR}-unknown-linux-musl.tar.gz"; \
    curl -fLo /tmp/starship.tar.gz \
        "https://github.com/starship/starship/releases/download/v${STARSHIP_VERSION}/${STARSHIP_TARBALL}"; \
    verify_sha256 /tmp/starship.tar.gz "$(sha_single "https://github.com/starship/starship/releases/download/v${STARSHIP_VERSION}/${STARSHIP_TARBALL}.sha256")"; \
    tar -C /usr/local/bin -xzf /tmp/starship.tar.gz starship; \
    rm -f /tmp/starship.tar.gz; \
    starship --version

# Install zoxide (smart cd replacement)
RUN set -eux; . /etc/arch_vars; \
    curl -Lo /tmp/zoxide.deb \
        "https://github.com/ajeetdsouza/zoxide/releases/download/v${ZOXIDE_VERSION}/zoxide_${ZOXIDE_VERSION}-1_${ARCH_DEB}.deb"; \
    dpkg -i /tmp/zoxide.deb; \
    rm /tmp/zoxide.deb; \
    zoxide --version

# Copy dotfiles into the user home directory (baked into the image for instant availability)
COPY --chown=${USERNAME}:${USERNAME} bash/.bashrc /home/${USERNAME}/.bashrc
COPY --chown=${USERNAME}:${USERNAME} bash/.config/ /home/${USERNAME}/.config/
COPY --chown=${USERNAME}:${USERNAME} starship/.config/starship.toml /home/${USERNAME}/.config/starship.toml
COPY --chown=${USERNAME}:${USERNAME} .devcontainer/tmux.conf /home/${USERNAME}/.tmux.conf
COPY --chown=${USERNAME}:${USERNAME} .devcontainer/onboard.sh /home/${USERNAME}/.onboard.sh
RUN chmod +x /home/${USERNAME}/.onboard.sh
COPY --chown=${USERNAME}:${USERNAME} .devcontainer/hooks/ /home/${USERNAME}/.claude/hooks/
RUN chmod +x /home/${USERNAME}/.claude/hooks/*.sh

WORKDIR /workspace
USER ${USERNAME}

# Mountpoints for the named volumes in devcontainer.json. They must exist and be
# owned by the dev user, otherwise the volumes are created root-owned and unwritable.
RUN mkdir -p ~/.claude ~/.config/gh ~/.config/glab-cli ~/.local/share/opencode ~/.local/state/bash

# User environment
ENV PATH="/home/${USERNAME}/.local/bin:/usr/local/bin:/usr/local/sbin:/usr/bin:/sbin:/bin"
ENV FZF_DEFAULT_COMMAND="fdfind --type f"

ENV MAMBA_ROOT_PREFIX="/home/${USERNAME}/micromamba"

# Wire micromamba shell hook into ~/.bashrc (appends eval block)
RUN micromamba shell init --shell bash --root-prefix ~/micromamba

# Install OpenCode CLI (unpinned: install script does not expose a version flag)
RUN curl -fsSL https://opencode.ai/install | bash

# Install Claude Code CLI (unpinned: install script does not expose a version flag)
RUN curl -fsSL https://claude.ai/install.sh | bash

# Install Entire CLI (pinned: the install script takes --version)
RUN curl -fsSL https://entire.io/install.sh | bash -s -- --version "${ENTIRE_VERSION}"

# Install uv
RUN curl -LsSf https://astral.sh/uv/install.sh | UV_VERSION=${UV_VERSION} sh

# Bootstrap LazyVim starter config (plugins are downloaded on first nvim launch)
RUN git clone --depth=1 https://github.com/LazyVim/starter /home/${USERNAME}/.config/nvim && \
    rm -rf /home/${USERNAME}/.config/nvim/.git

# Default command
CMD ["bash"]
