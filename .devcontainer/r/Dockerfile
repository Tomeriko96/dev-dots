FROM rocker/tidyverse:latest

# Install system packages as root
USER root
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        git \
        curl \
        tmux \
        htop \
        ca-certificates \
        locales \
        fzf \
        fd-find \
        jq \
        wget \
        gnupg && \
    rm -rf /var/lib/apt/lists/*

# Install ripgrep
RUN curl -LO https://github.com/BurntSushi/ripgrep/releases/download/14.1.1/ripgrep_14.1.1-1_amd64.deb && \
    dpkg -i ripgrep_14.1.1-1_amd64.deb && \
    rm ripgrep_14.1.1-1_amd64.deb

# Configure locale
RUN sed -i 's/^# *en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen && \
    locale-gen

ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

# Install latest Neovim
RUN set -eux; \
    LATEST_VERSION=$(curl -s https://api.github.com/repos/neovim/neovim/releases/latest | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/'); \
    cd /tmp; \
    (curl -L --retry 3 --fail -O "https://github.com/neovim/neovim/releases/download/${LATEST_VERSION}/nvim-linux-x86_64.tar.gz" || \
     curl -L --retry 3 --fail -O "https://github.com/neovim/neovim/releases/download/${LATEST_VERSION}/nvim-linux64.tar.gz"); \
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

# Switch to default rocker user for user-level installs
USER rstudio

ENV PATH="/home/rstudio/.local/bin:/usr/local/bin:/usr/local/sbin:/usr/bin:/sbin:/bin"
ENV FZF_DEFAULT_COMMAND="fd --type f"

# Install OpenCode CLI
RUN curl -fsSL https://opencode.ai/install | bash

CMD ["bash"]
