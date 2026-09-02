#!/usr/bin/env bash
# install.sh — turn a fresh clone of this repo into a working machine. macOS.
#
# Order is the contract: every tool is on PATH before the apply, because the
# apply's run_after scripts generate shell init by running those tools. No
# `set -e`: a failed package warns and the run continues.
set -uo pipefail

log()  { printf '\033[1;34m::\033[0m %s\n' "$*" >&2; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }
have() { command -v "$1" >/dev/null 2>&1; }

cd "$(dirname "$0")" || exit 1
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

# --- 1. Homebrew and the Brewfile ------------------------------------------
if ! have brew; then
    log "installing Homebrew"
    NONINTERACTIVE=1 /bin/bash -c \
        "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" \
        || warn "Homebrew: bootstrap failed — install it by hand and re-run"
fi
# `hash -r`: bash caches resolved command paths, and PATH just changed.
for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    [ -x "$b" ] && { eval "$("$b" shellenv)"; hash -r; break; }
done
if have brew; then
    # TRAP: Homebrew 6 refuses to load a formula from an untrusted third-party
    # tap and `brew bundle` will not trust one for you — without this line the
    # Brewfile's tinty is skipped with an error, and tinty owns the palette.
    brew trust --tap tinted-theming/tinted || warn "could not trust the tinted tap"
    brew bundle install --file Brewfile || warn "brew bundle incomplete"
else
    warn "no brew — nothing was installed"
fi

# --- 2. tmux-mcp ------------------------------------------------------------
# No package manager has it; prebuilt release, so no Go toolchain is needed.
# TRAP: the release assets are named with an UNDERSCORE, tmux-mcp_<os>_<arch>.
if ! have tmux-mcp; then
    case "$(uname -m)" in arm64|aarch64) a=arm64 ;; *) a=amd64 ;; esac
    t="$(curl -fsSL https://api.github.com/repos/MadAppGang/tmux-mcp/releases/latest \
        | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)"
    d="$(mktemp -d)"
    if [ -n "$t" ] && curl -fsSL -o "$d/a.tgz" \
        "https://github.com/MadAppGang/tmux-mcp/releases/download/$t/tmux-mcp_darwin_$a.tar.gz" \
        && tar -xf "$d/a.tgz" -C "$d"; then
        mkdir -p "$HOME/.local/bin"
        install -m 755 "$d/tmux-mcp" "$HOME/.local/bin/tmux-mcp" && log "installed tmux-mcp $t"
    else
        warn "tmux-mcp: could not install (GitHub rate limit?)"
    fi
    rm -rf "$d"
fi

# --- 3. tmux plugins --------------------------------------------------------
# The path must equal the one tmux.conf's two `run-shell` lines name. No tpm:
# chezmoi and this script already install and update them.
P="${XDG_DATA_HOME:-$HOME/.local/share}/tmux/plugins"
for r in tmux-resurrect tmux-continuum; do
    if [ -d "$P/$r/.git" ]; then
        git -C "$P/$r" pull --ff-only --quiet || warn "$r: pull failed"
    else
        mkdir -p "$P"
        git clone --depth 1 --quiet "https://github.com/tmux-plugins/$r" "$P/$r" \
            || warn "$r: clone failed"
    fi
done

# --- 4. Apply the configs, last --------------------------------------------
if have chezmoi; then
    log "chezmoi apply"
    chezmoi apply || warn "chezmoi apply failed"
else
    warn "chezmoi not found — install it, then re-run this script"
fi

exit 0   # a failed package already warned on its own line
