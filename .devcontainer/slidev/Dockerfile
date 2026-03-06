FROM mcr.microsoft.com/vscode/devcontainers/universal:2-linux

# Install CJK fonts and latest Neovim
USER root
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends fonts-noto-cjk \
    && rm -rf /var/lib/apt/lists/*

# Install latest Neovim (override any bundled version)
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

USER codespace

ENV PATH="/home/codespace/.local/bin:/usr/local/bin:/usr/local/sbin:/usr/bin:/sbin:/bin"
ENV FZF_DEFAULT_COMMAND="fd --type f"

# Install OpenCode CLI
RUN curl -fsSL https://opencode.ai/install | bash

CMD ["bash"]
