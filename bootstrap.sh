#!/usr/bin/env sh
# One-click dotfiles bootstrap (macOS / Linux).
#
# From a checkout of this repo:
#     ./setup/bootstrap.sh
#
# Or one line (clones into ~/.dotfiles, then bootstraps):
#     git clone https://github.com/yesitsfebreeze/kern.git ~/.dotfiles && ~/.dotfiles/setup/bootstrap.sh
#
# It installs chezmoi (and Homebrew on macOS if absent), then applies the dotfiles,
# which in turn installs every tool from setup/home/.chezmoidata/packages.yaml.
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

say() { printf '\033[1;32m==>\033[0m %s\n' "$*"; }

# 1. macOS: ensure Homebrew (covers all packages cleanly).
if [ "$(uname -s)" = "Darwin" ] && ! command -v brew >/dev/null 2>&1; then
    say "Installing Homebrew (non-interactive)"
    NONINTERACTIVE=1 /bin/bash -c \
        "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    [ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
    [ -x /usr/local/bin/brew ] && eval "$(/usr/local/bin/brew shellenv)"
fi

# 2. Ensure chezmoi is installed.
BIN_DIR="$HOME/.local/bin"
if ! command -v chezmoi >/dev/null 2>&1 && [ ! -x "$BIN_DIR/chezmoi" ]; then
    say "Installing chezmoi to $BIN_DIR"
    mkdir -p "$BIN_DIR"
    sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$BIN_DIR"
fi
CHEZMOI="$(command -v chezmoi 2>/dev/null || echo "$BIN_DIR/chezmoi")"

# 3. Initialise + apply from this repo's setup/ directory.
say "Applying dotfiles from $SCRIPT_DIR"
"$CHEZMOI" init --apply --source "$SCRIPT_DIR"

say "Done. Launch WezTerm to start a Nushell session."
say "Re-sync any time with:  chezmoi apply"
