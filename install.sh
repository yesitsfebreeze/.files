#!/usr/bin/env bash
# Install the dotfiles' tool set on macOS or Linux. Idempotent — safe to re-run.
#
#   ./install.sh
#
# Installs tools (package manager + a few release/cargo/npm fallbacks), applies
# the configs with chezmoi if it is installed, and applies the small system
# tweaks (macOS menu-bar auto-hide, sudo PATH). Everything is best-effort and
# non-fatal: a tool that fails to install warns and the script continues.
set -uo pipefail

log()  { printf '\033[1;34m::\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*"; }

OS="$(uname -s)"
ARCH="$(uname -m)"
case "$ARCH" in
    x86_64|amd64)  ARCH=x86_64 ;;
    aarch64|arm64) ARCH=aarch64 ;;
esac

# --- 1. Package-manager batch install --------------------------------------
if [ "$OS" = "Darwin" ]; then
    # Homebrew (installed on first run)
    if ! command -v brew >/dev/null 2>&1; then
        log "installing Homebrew"
        NONINTERACTIVE=1 /bin/bash -c \
            "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv)"
    fi
    brew install \
        neovim nushell ripgrep fd fzf entr television bat zoxide starship jq \
        imagemagick python git git-delta lazygit gh worktrunk just gnupg pass
    brew install --cask font-caskaydia-cove-nerd-font
else
    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update -y
        sudo apt-get install -y \
            neovim ripgrep fd-find fzf entr bat zoxide jq imagemagick python3 git \
            git-delta lazygit gh just bubblewrap gnupg pass libnss3 libnspr4
    elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -S --needed --noconfirm \
            neovim nushell ripgrep fd fzf entr television bat zoxide starship jq \
            imagemagick python git git-delta lazygit github-cli just docker \
            bubblewrap gnupg pass nss nspr
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y \
            neovim ripgrep fd-find fzf entr bat zoxide jq imagemagick python3 git \
            git-delta lazygit gh just docker bubblewrap gnupg2 pass nss nspr
    else
        warn "no supported package manager (apt/pacman/dnf) — install tools manually"
    fi
    # Debian/Ubuntu ship bat/fd under different names; symlink to the expected ones.
    mkdir -p "$HOME/.local/bin"
    command -v batcat >/dev/null 2>&1 && [ ! -e "$HOME/.local/bin/bat" ] \
        && ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
    command -v fdfind >/dev/null 2>&1 && [ ! -e "$HOME/.local/bin/fd" ] \
        && ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
    # Build tools — needed by lazy.nvim's `build` step and cargo installs.
    if ! command -v make >/dev/null 2>&1; then
        if command -v apt-get >/dev/null 2>&1; then
            sudo apt-get install -y build-essential >/dev/null 2>&1 || true
        elif command -v pacman >/dev/null 2>&1; then
            sudo pacman -S --needed --noconfirm base-devel >/dev/null 2>&1 || true
        elif command -v dnf >/dev/null 2>&1; then
            sudo dnf install -y make gcc >/dev/null 2>&1 || true
        fi
    fi
fi

# --- 2. GitHub-release binaries (tools not in distro repos) -----------------
# Resolve the latest release tag for a repo.
latest_tag() {
    curl -fsSL "https://api.github.com/repos/$1/releases/latest" 2>/dev/null \
        | grep -m1 '"tag_name"' | sed -E 's/.*"tag_name"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/'
}

# fetch_release <binary> <url> — download a release tarball, extract it, and
# install the named binary to ~/.local/bin. Skips if the binary already exists.
fetch_release() {
    local bin="$1" url="$2"
    command -v "$bin" >/dev/null 2>&1 && return 0
    local td; td="$(mktemp -d)"
    if curl -fsSL -o "$td/a.tar" "$url" && tar -xf "$td/a.tar" -C "$td" 2>/dev/null; then
        local found; found="$(find "$td" -type f -name "$bin" 2>/dev/null | head -n1)"
        if [ -n "$found" ]; then
            mkdir -p "$HOME/.local/bin"
            cp "$found" "$HOME/.local/bin/$bin" && chmod +x "$HOME/.local/bin/$bin"
            log "installed $bin"
        else
            warn "$bin: binary not found in release asset"
        fi
    else
        warn "$bin: could not download $url"
    fi
    rm -rf "$td"
}

# kern (memory daemon) — release-only on both platforms
case "$OS:$ARCH" in
    Darwin:aarch64) fetch_release kern "https://github.com/yesitsfebreeze/relay-kern/releases/latest/download/kern-aarch64-apple-darwin.tar.gz" ;;
    Linux:x86_64)   fetch_release kern "https://github.com/yesitsfebreeze/relay-kern/releases/latest/download/kern-x86_64-unknown-linux-gnu.tar.gz" ;;
    Linux:aarch64)  fetch_release kern "https://github.com/yesitsfebreeze/relay-kern/releases/latest/download/kern-aarch64-unknown-linux-gnu.tar.gz" ;;
esac

# Linux-only fallbacks (macOS gets these from brew)
if [ "$OS" != "Darwin" ]; then
    # worktrunk (wt)
    fetch_release wt "https://github.com/max-sixty/worktrunk/releases/latest/download/worktrunk-$ARCH-unknown-linux-musl.tar.xz"
    # television (tv) — not in Debian/Ubuntu repos
    tag="$(latest_tag alexpasmantier/television)"
    [ -n "$tag" ] && fetch_release tv "https://github.com/alexpasmantier/television/releases/download/$tag/tv-$tag-$ARCH-unknown-linux-musl.tar.gz"
    # gh — not in Debian/Ubuntu default repos
    tag="$(latest_tag cli/cli)"
    [ -n "$tag" ] && fetch_release gh "https://github.com/cli/cli/releases/download/$tag/gh_${tag#v}_linux_$ARCH.tar.gz"
    # nushell — not in Debian/Ubuntu repos
    tag="$(latest_tag nushell/nushell)"
    [ -n "$tag" ] && fetch_release nu "https://github.com/nushell/nushell/releases/download/$tag/nu-$tag-$ARCH-unknown-linux-musl.tar.gz"
    # lazygit — not in Debian/Ubuntu default repos
    tag="$(latest_tag jesseduffield/lazygit)"
    [ -n "$tag" ] && fetch_release lazygit "https://github.com/jesseduffield/lazygit/releases/download/$tag/lazygit_${tag#v}_linux_$ARCH.tar.gz"
    # starship — not in Debian/Ubuntu repos
    fetch_release starship "https://github.com/starship/starship/releases/latest/download/starship-$ARCH-unknown-linux-musl.tar.gz"
    # delta — not in Debian/Ubuntu default repos
    tag="$(latest_tag dandavison/delta)"
    [ -n "$tag" ] && fetch_release delta "https://github.com/dandavison/delta/releases/download/$tag/delta-$tag-$ARCH-unknown-linux-gnu.tar.gz"
    # neovim — distro versions are too old for the modern config (< 0.11)
    nvim_minor="$(command -v nvim >/dev/null 2>&1 && nvim --version 2>/dev/null | sed -n '1s/^NVIM v0\.\([0-9]*\).*/\1/p' || echo 0)"
    if [ -z "$nvim_minor" ] || [ "$nvim_minor" -lt 11 ]; then
        tag="$(latest_tag neovim/neovim)"
        if [ -n "$tag" ]; then
            nd="$(mktemp -d)"
            if curl -fsSL -o "$nd/nvim.tar.gz" "https://github.com/neovim/neovim/releases/download/$tag/nvim-linux-$ARCH.tar.gz" \
                && tar -xzf "$nd/nvim.tar.gz" -C "$nd" 2>/dev/null; then
                rm -rf "$HOME/.local/opt/neovim"
                mkdir -p "$HOME/.local/opt" "$HOME/.local/bin"
                cp -r "$nd/nvim-linux-$ARCH" "$HOME/.local/opt/neovim"
                ln -sf "$HOME/.local/opt/neovim/bin/nvim" "$HOME/.local/bin/nvim"
                log "installed neovim (release)"
            else
                warn "neovim: could not download release tarball"
            fi
            rm -rf "$nd"
        fi
    fi
fi

# --- 3. cargo / git-built tools --------------------------------------------
# keydr (typing tutor) — fork built from source
if ! command -v keydr >/dev/null 2>&1; then
    cargo install --git https://github.com/yesitsfebreeze/keydr >/dev/null 2>&1 \
        && log "installed keydr" || warn "keydr: cargo install failed"
fi

# burrito (multiplexer) — built by its own justfile
if ! command -v brr >/dev/null 2>&1; then
    td="$(mktemp -d)"
    if git clone --depth 1 https://github.com/yesitsfebreeze/burrito "$td/burrito" >/dev/null 2>&1 \
        && (cd "$td/burrito" && just install) >/dev/null 2>&1; then
        log "installed burrito"
    else
        warn "burrito: install failed — see github.com/yesitsfebreeze/burrito"
    fi
    rm -rf "$td"
fi

# --- 4. Node / npm / pi -----------------------------------------------------
# nvm + Node (npm needs node; nvm keeps it current and user-local)
export NVM_DIR="$HOME/.nvm"
if [ ! -s "$NVM_DIR/nvm.sh" ]; then
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash >/dev/null 2>&1 || true
fi
if [ -s "$NVM_DIR/nvm.sh" ]; then
    # shellcheck disable=SC1091
    . "$NVM_DIR/nvm.sh"
    if ! command -v node >/dev/null 2>&1; then
        nvm install node >/dev/null 2>&1 && nvm alias default node >/dev/null 2>&1 || true
    fi
fi

# pi coding agent + its npm-published extensions
if command -v npm >/dev/null 2>&1; then
    npm install -g @earendil-works/pi-coding-agent >/dev/null 2>&1 \
        && log "installed pi" || warn "pi: npm install failed"
    if command -v pi >/dev/null 2>&1; then
        pi install npm:pi-mcp-adapter npm:@vanillagreen/pi-claude-bridge >/dev/null 2>&1 || true
    fi
else
    warn "npm not found — install Node.js, then: npm install -g @earendil-works/pi-coding-agent"
fi

# --- 5. macOS tweaks --------------------------------------------------------
if [ "$OS" = "Darwin" ]; then
    # Auto-hide the system menu bar (reveals on hover at the top edge)
    have="$(defaults read NSGlobalDomain _HIHideMenuBar 2>/dev/null || echo unset)"
    if [ "$have" != "1" ]; then
        osascript -e 'tell application "System Events" to tell dock preferences to set autohide menu bar to true' >/dev/null 2>&1 \
            || defaults write NSGlobalDomain _HIHideMenuBar -bool true >/dev/null 2>&1 \
            || warn "could not enable menu-bar auto-hide (set it in System Settings → Control Center)"
    fi
fi

# --- 6. sudo PATH (Linux) ---------------------------------------------------
# Let sudo resolve ~/.local/bin and ~/.cargo/bin so `sudo just`, `sudo nu`, …
# find the same binaries the interactive shell does. Scoped to this user.
if [ -d /etc/sudoers.d ] && [ "$(id -u)" != 0 ]; then
    user="$(id -un)"
    dropin="/etc/sudoers.d/10-${user}-path"
    content="Defaults:${user} secure_path=\"$HOME/.local/bin:$HOME/.cargo/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin\""
    if [ "$(cat "$dropin" 2>/dev/null || true)" != "$content" ]; then
        tmp="$(mktemp)"
        printf '%s\n' "$content" > "$tmp"
        if sudo visudo -cf "$tmp" >/dev/null 2>&1; then
            sudo install -m 0440 -o root -g root "$tmp" "$dropin" \
                && log "sudo now sees ~/.local/bin + ~/.cargo/bin ($dropin)" \
                || warn "could not install $dropin"
        else
            warn "sudo PATH drop-in needs root; run once manually:"
            warn "  echo '$content' | sudo install -m 0440 /dev/stdin $dropin"
        fi
        rm -f "$tmp"
    fi
fi

# --- 7. Apply configs -------------------------------------------------------
if command -v chezmoi >/dev/null 2>&1; then
    log "applying configs with chezmoi"
    chezmoi apply
else
    warn "chezmoi not found — install it, then run: chezmoi init --apply yesitsfebreeze/.files"
fi

log "done."
