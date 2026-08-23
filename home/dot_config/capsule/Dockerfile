# The one capsule dev-image definition (01-capsule/02-dev-image, task C.1).
# chezmoi deploys this file to ~/.config/capsule/Dockerfile; the capsule CLI
# (C.2) builds from that path and hashes it for rebuild detection.
#
# Layer order is R6's contract: cheapest-changing last. Editing the final
# config layer must invalidate nothing above it; tests/dev-image.sh --build
# proves exactly that.
#
# R7: the toolbox is closed. R2/R3/R4 plus the support set in layer 1 are
# exhaustive; tests/dev-image.sh --static fails the definition on any package
# outside them. No COPY/ADD: the build context stays empty, so no host file —
# and no credential — can enter a layer (credentials arrive by mount, C.3).

FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    TERM=xterm-256color \
    LANG=C.UTF-8

# 1 — apt toolbox: R2 (ripgrep fd-find fzf tmux neovim bat git build-essential
#     python3 python3-pip zsh) + the support set (curl ca-certificates sudo
#     openssh-client). Ubuntu names the fd-find/bat binaries fdfind/batcat;
#     symlink both to their real names (same convention as install.sh §1).
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ripgrep fd-find fzf tmux neovim bat git build-essential \
        python3 python3-pip zsh \
        curl ca-certificates sudo openssh-client \
    && ln -sf "$(command -v fdfind)" /usr/local/bin/fd \
    && ln -sf "$(command -v batcat)" /usr/local/bin/bat \
    && rm -rf /var/lib/apt/lists/*

# 2 — eza: not in Ubuntu 24.04's archive. Release tarball for the build
#     architecture: ARCH derives from uname -m, never a literal in the URL —
#     the legacy image pinned one architecture's tarball and that is exactly
#     the break this rule prevents.
ARG EZA_VERSION=v0.23.5
RUN ARCH="$(uname -m)" \
    && curl -fsSL "https://github.com/eza-community/eza/releases/download/${EZA_VERSION}/eza_${ARCH}-unknown-linux-gnu.tar.gz" \
       | tar -xz -C /usr/local/bin

# 3 — Node: NodeSource current LTS (R3, major >= 22).
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

# 4 — agents (R4): Claude Code via npm; OpenCode via its installer, with the
#     binary landing in /usr/local/bin/opencode wherever the installer put it.
RUN npm install -g @anthropic-ai/claude-code
RUN curl -fsSL https://opencode.ai/install | bash \
    && { command -v opencode > /dev/null \
         || install -m 0755 \
              "$(find /root \( -type f -o -type l \) -name opencode | head -n 1)" \
              /usr/local/bin/opencode; } \
    && command -v opencode > /dev/null

# 5 — oh-my-zsh, system-wide in /opt so the runtime user reads it (R1). Not
#     user-writable, so omz never attempts its self-update in a capsule.
ENV ZSH=/opt/oh-my-zsh
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended \
    && chmod -R 755 /opt/oh-my-zsh

# 6 — user (R5): unprivileged dev, passwordless sudo via a 0440 drop-in.
RUN useradd -m -s "$(command -v zsh)" dev \
    && printf 'dev ALL=(ALL:ALL) NOPASSWD: ALL\n' > /etc/sudoers.d/dev \
    && chmod 0440 /etc/sudoers.d/dev

# 7 — config layer, LAST: bake dev's .zshrc so zsh never shows the
#     zsh-newuser-install prompt. Container-only config; the host zshrc is
#     not ported (R1). Editing this layer must reuse every layer above.
RUN <<'EOS'
cat > /home/dev/.zshrc <<'ZSHRC'
export ZSH=/opt/oh-my-zsh
ZSH_THEME="robbyrussell"
plugins=(git)
source $ZSH/oh-my-zsh.sh
ZSHRC
chown dev:dev /home/dev/.zshrc
EOS

USER dev
WORKDIR /workspace
CMD ["sleep", "infinity"]
