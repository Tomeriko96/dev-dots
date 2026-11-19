FROM debian:bookworm-slim

# pipefail: a failed download in `curl ... | bash` or `curl ... | gpg` fails the build
# instead of silently piping nothing into the next command.
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# ==============================================================================
# Pinned versions
#
# CLI tool versions live in .devcontainer/mise.toml and are checksum-locked in
# .devcontainer/mise.lock (Linux x86_64). Only mise itself is pinned here.
# Refresh the lock with .devcontainer/update-mise-lock.sh after editing mise.toml.
# ==============================================================================

ARG MISE_VERSION="2026.11.10"
ARG MISE_SHA256="b603a4f48563fc379a794d9ea2cf9f709ed276c9141068604cb0c59fa3e674a9"

# ==============================================================================
# APT packages, locale and system git configuration
#
# bookworm-slim has no curl/gpg, so a first small apt-get update is needed to
# add the Microsoft repository; the second update installs everything at once.
# gh, eza and Node.js are no longer APT packages: mise installs them below.
# ==============================================================================

RUN set -eux; \
    export DEBIAN_FRONTEND=noninteractive; \
    apt-get update; \
    apt-get install -y --no-install-recommends ca-certificates curl gnupg; \
    \
    # Microsoft / Azure CLI ---------------------------------------------------
    mkdir -p /etc/apt/keyrings; \
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
        | gpg --dearmor -o /etc/apt/keyrings/microsoft.gpg; \
    test -s /etc/apt/keyrings/microsoft.gpg; \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/azure-cli/ bookworm main" \
        > /etc/apt/sources.list.d/azure-cli.list; \
    \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        azure-cli \
        bat \
        build-essential \
        fd-find \
        ffmpeg \
        fzf \
        git \
        htop \
        jq \
        locales \
        openssh-client \
        tmux \
        unzip \
        vim \
        wget \
        xz-utils \
        # Playwright / Chromium runtime libraries
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
    rm -rf /var/lib/apt/lists/* /etc/apt/sources.list.d/azure-cli.list /etc/apt/keyrings; \
    \
    # Locale ------------------------------------------------------------------
    sed -i 's/^# *en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen; \
    locale-gen; \
    \
    # Git ---------------------------------------------------------------------
    # Credential helpers per host: gh voor GitHub, glab voor GitLab (SURF + gitlab.com).
    # SURF GitLab staat sinds 16-11-2026 op git.sdp.surf.nl; git.ia.surf.nl blijft erbij
    # zolang daar gearchiveerde (alleen-lezen) projecten staan.
    # De '!'-vorm is nodig: een kale 'gh'/'glab' laat git zoeken naar het niet-bestaande
    # git-credential-gh/-glab. Systeemniveau, zodat het een rebuild overleeft zonder
    # 'gh auth setup-git' of handwerk in ~/.gitconfig.
    git config --system init.defaultBranch main; \
    for host in github.com gist.github.com; do \
      git config --system "credential.https://${host}.helper" '!gh auth git-credential'; \
    done; \
    for host in git.sdp.surf.nl git.ia.surf.nl gitlab.com; do \
      git config --system "credential.https://${host}.helper" '!glab auth git-credential'; \
    done; \
    # delta as pager (user ~/.gitconfig takes precedence)
    git config --system core.pager delta; \
    git config --system interactive.diffFilter "delta --color-only"; \
    git config --system delta.navigate true; \
    git config --system delta.light false; \
    git config --system merge.conflictStyle diff3; \
    git config --system diff.colorMoved default

ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV TZ=Europe/Amsterdam

# ==============================================================================
# mise
# ==============================================================================

RUN set -eux; \
    curl -fL --retry 3 -o /tmp/mise \
        "https://github.com/jdx/mise/releases/download/v${MISE_VERSION}/mise-v${MISE_VERSION}-linux-x64"; \
    echo "${MISE_SHA256}  /tmp/mise" | sha256sum -c -; \
    install -m 0755 /tmp/mise /usr/local/bin/mise; \
    rm -f /tmp/mise; \
    mise --version

# ==============================================================================
# Locked CLI toolchain (24 tools, see mise.toml)
#
# Installed system-wide under /usr/local/share/mise. --locked makes the build use
# only the URLs and checksums in mise.lock. Each executable is then symlinked into
# /usr/local/bin, so the tools don't depend on mise at runtime and don't clash
# with a project's own mise.toml. The list is explicit because the AWS CLI's
# bin dir also contains shared libraries.
# ==============================================================================

COPY .devcontainer/mise.toml .devcontainer/mise.lock /opt/dev-dots/mise/

RUN set -eux; \
    export MISE_DATA_DIR=/usr/local/share/mise \
           MISE_CACHE_DIR=/tmp/mise-cache \
           MISE_STATE_DIR=/tmp/mise-state \
           MISE_TRUSTED_CONFIG_PATHS=/opt/dev-dots/mise \
           MISE_YES=1; \
    cd /opt/dev-dots/mise; \
    mise install --locked; \
    for bin in \
        node npm npx corepack uv uvx micromamba \
        gh glab entire git-remote-entire lazygit delta gh-dash \
        rg eza tokei onefetch csvlens starship zoxide nvim \
        kubectl helm flux sops aws aws_completer azcopy azd; \
    do \
        target="$(mise which "$bin")"; \
        test -x "$target"; \
        ln -sf "$target" "/usr/local/bin/$bin"; \
    done; \
    rm -rf /tmp/mise-cache /tmp/mise-state "$MISE_DATA_DIR/downloads"; \
    \
    node --version; npm --version; uv --version; micromamba --version; \
    gh --version; glab version; entire version; lazygit --version; delta --version; gh-dash --version; \
    rg --version; eza --version; tokei --version; onefetch --version; csvlens --version; \
    starship --version; zoxide --version; nvim --version | head -n1; \
    kubectl version --client; helm version; flux --version; sops --version; \
    aws --version; azcopy --version; azd version

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

COPY --chown=${USERNAME}:${USERNAME} --chmod=0755 .devcontainer/onboard.sh \
    /home/${USERNAME}/.onboard.sh

COPY --chown=${USERNAME}:${USERNAME} --chmod=0755 .devcontainer/hooks/ \
    /home/${USERNAME}/.claude/hooks/

# ==============================================================================
# User environment
# ==============================================================================

WORKDIR /workspace

ENV PATH="/home/${USERNAME}/.local/bin:/usr/local/bin:/usr/local/sbin:/usr/bin:/sbin:/bin"
ENV FZF_DEFAULT_COMMAND="fdfind --type f"
ENV MAMBA_ROOT_PREFIX="/home/${USERNAME}/micromamba"
# uv hardlinkt venvs vanuit ~/.cache/uv: een extra worktree kost dan ~2 MB i.p.v. ~500 MB.
# (standaard valt uv op overlayfs terug op kopiëren)
ENV UV_LINK_MODE=hardlink

USER ${USERNAME}

# ==============================================================================
# micromamba shell integration, gh-dash as gh extension, LazyVim starter
# ==============================================================================

RUN set -eux; \
    micromamba shell init \
        --shell bash \
        --root-prefix "${MAMBA_ROOT_PREFIX}"; \
    \
    # 'gh dash' looks for the binary in gh's extension dir
    mkdir -p "$HOME/.local/share/gh/extensions/gh-dash"; \
    ln -sf /usr/local/bin/gh-dash "$HOME/.local/share/gh/extensions/gh-dash/gh-dash"; \
    \
    rm -rf "$HOME/.config/nvim"; \
    git clone --depth=1 https://github.com/LazyVim/starter "$HOME/.config/nvim"; \
    rm -rf "$HOME/.config/nvim/.git"

# ==============================================================================
# OpenCode and Claude Code (vendor installers, latest stable)
# ==============================================================================

RUN set -eux; \
    curl -fsSL https://opencode.ai/install \
        | bash

RUN set -eux; \
    curl -fsSL https://claude.ai/install.sh \
        | bash; \
    "$HOME/.local/bin/claude" --version

# ==============================================================================
# Default command
# ==============================================================================

CMD ["bash"]
