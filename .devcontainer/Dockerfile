FROM python:3.12-slim

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
        tree-sitter-cli \
        fd-find \
        bat \
        jq \
        wget \
        gnupg \
        bash-completion && \
    ln -sf /usr/bin/fdfind /usr/local/bin/fd && \
    rm -rf /var/lib/apt/lists/*

# Install ripgrep
RUN curl -LO https://github.com/BurntSushi/ripgrep/releases/download/14.1.1/ripgrep_14.1.1-1_amd64.deb && \
    dpkg -i ripgrep_14.1.1-1_amd64.deb && \
    rm ripgrep_14.1.1-1_amd64.deb

# Install qsv from external repo (gnupg now available)
RUN wget -O - https://dathere.github.io/qsv-deb-releases/qsv-deb.gpg | \
    gpg --dearmor -o /usr/share/keyrings/qsv-deb.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/qsv-deb.gpg] https://dathere.github.io/qsv-deb-releases ./" > /etc/apt/sources.list.d/qsv.list && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends qsv && \
    rm -rf /var/lib/apt/lists/* && \
    rm /etc/apt/sources.list.d/qsv.list

# Install eza (modern ls replacement)
RUN set -eux; \
    ARCH=$(uname -m); \
    EZA_URL="https://github.com/eza-community/eza/releases/latest/download/eza_${ARCH}-unknown-linux-gnu.tar.gz"; \
    curl -fsSL "$EZA_URL" | tar -xz -C /usr/local/bin; \
    eza --version

# Configure locale
RUN sed -i 's/^# *en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen && \
    locale-gen

ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

# Install latest Neovim
RUN set -eux; \
    LATEST_VERSION=$(curl -s https://api.github.com/repos/neovim/neovim/releases/latest | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/'); \
    NVIM_TARBALL_X64="nvim-linux-x86_64.tar.gz"; \
    NVIM_TARBALL_64="nvim-linux64.tar.gz"; \
    NVIM_URL_X64="https://github.com/neovim/neovim/releases/download/${LATEST_VERSION}/${NVIM_TARBALL_X64}"; \
    NVIM_URL_64="https://github.com/neovim/neovim/releases/download/${LATEST_VERSION}/${NVIM_TARBALL_64}"; \
    cd /tmp; \
    (curl -L --retry 3 --fail -O "$NVIM_URL_X64" || curl -L --retry 3 --fail -O "$NVIM_URL_64"); \
    if [ -f nvim-linux-x86_64.tar.gz ]; then \
        tar -C /usr -xzf nvim-linux-x86_64.tar.gz; \
        ln -sf /usr/nvim-linux-x86_64/bin/nvim /usr/bin/nvim; \
        rm nvim-linux-x86_64.tar.gz; \
    elif [ -f nvim-linux64.tar.gz ]; then \
        tar -C /usr -xzf nvim-linux64.tar.gz; \
        ln -sf /usr/nvim-linux64/bin/nvim /usr/bin/nvim; \
        rm nvim-linux64.tar.gz; \
    fi; \
    nvim --version | head -n1

# Create non-root dev user
ARG USERNAME=dev
ARG UID=1000
ARG GID=1000

RUN groupadd --gid ${GID} ${USERNAME} && \
    useradd --uid ${UID} --gid ${GID} -m -s /bin/bash ${USERNAME} && \
    mkdir -p /workspace && chown ${USERNAME}:${USERNAME} /workspace

WORKDIR /workspace
USER ${USERNAME}

# User environment
ENV PATH="/home/${USERNAME}/.local/bin:/usr/local/bin:/usr/local/sbin:/usr/bin:/sbin:/bin"
ENV FZF_DEFAULT_COMMAND="fd --type f"

# Install OpenCode CLI
RUN curl -fsSL https://opencode.ai/install | bash

# Install uv
RUN curl -LsSf https://astral.sh/uv/install.sh | sh && \
    echo 'eval "$(uv generate-shell-completion bash)"' >> ~/.bashrc

# Install Starship prompt
RUN curl -sS https://starship.rs/install.sh | sh -s -- --yes --bin-dir "$HOME/.local/bin"

# Install zoxide (smart cd)
RUN curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash

# Default command
CMD ["bash"]

