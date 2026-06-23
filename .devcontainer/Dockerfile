FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      git \
      zsh \
    && rm -rf /var/lib/apt/lists/* \
    && curl -fsSL https://mise.run | MISE_INSTALL_PATH=/usr/local/bin/mise sh \
    && sh -c "$(curl -fsLS get.chezmoi.io)" -- -b /usr/local/bin \
    && echo 'eval "$(mise activate zsh)"' >> /home/vscode/.zshrc \
    && echo 'eval "$(mise activate bash)"' >> /home/vscode/.bashrc
