#!/usr/bin/env sh
# Remote one-liner installer (macOS / Linux).
#
# Run straight from GitHub - clones ~/.files (or updates it if present),
# then runs bootstrap:
#     curl -fsSL https://raw.githubusercontent.com/yesitsfebreeze/.files/main/install.sh | sh
set -eu

REPO='https://github.com/yesitsfebreeze/.files.git'
DEST="$HOME/.files"

say() { printf '\033[1;32m==>\033[0m %s\n' "$*"; }

if ! command -v git >/dev/null 2>&1; then
    echo "git is required but was not found on PATH. Install git and re-run." >&2
    exit 1
fi

if [ -d "$DEST/.git" ]; then
    say "Updating existing checkout at $DEST"
    git -C "$DEST" pull --ff-only
else
    if [ -e "$DEST" ]; then
        echo "$DEST exists but is not a git checkout. Move or remove it, then re-run." >&2
        exit 1
    fi
    say "Cloning $REPO into $DEST"
    git clone "$REPO" "$DEST"
fi

sh "$DEST/bootstrap.sh"
