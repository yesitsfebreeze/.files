#!/bin/sh
# deploy.sh — the whole deploy: copy home/ over $HOME, then run the hooks.
#
# This replaces chezmoi. The repo's home/ tree keeps REAL filenames — what
# you see in the tree is what lands in $HOME — and deployment is a replace:
# every file in home/ overwrites its target, hooks run after the copy, and
# nothing is templated. Dynamic values are runtime concerns, not deploy-time
# ones: secrets are read from the Keychain by the shell (env.nu, capsule.nu),
# and the one thing that used to be a template (gitconfig's name and email)
# is written below as plain text.
#
# The contract, explicit:
#   1. PATH first — hooks run tools (the generator runs brew's nushell).
#   2. Copy home/ -> $HOME, file by file, overwriting. Modes ride along
#      (cp -p); git already tracks the exec bit.
#   3. Retire: every path in removed.txt is deleted in $HOME. Retiring a
#      file is still two edits: the source file goes, the target path joins
#      removed.txt (memos/decision/a-retirement-is-two-edits).
#   4. Hooks, in order, each non-fatal — one failure warns and the rest run.
# rr in the shell is `git pull` + this script.
set -u

repo=$(cd "$(dirname "$0")" && pwd)
home_src=$repo/home

log()  { printf '\033[1;34m::\033[0m %s\n' "$*" >&2; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }

# --- 1. PATH: hooks run tools ----------------------------------------------
if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

# --- 2. The copy -------------------------------------------------------------
cd "$home_src" || exit 1
find . -type f ! -name .DS_Store ! -path '*/.git/*' ! -path '*/__pycache__/*' | while read -r f; do
    mkdir -p "$HOME/$(dirname "$f")"
    cp -p "$f" "$HOME/$f"
    printf '%s\n' "$f"
done
log "deployed $(find . -type f ! -name .DS_Store ! -path '*/.git/*' ! -path '*/__pycache__/*' | wc -l | tr -d ' ') files into $HOME"

# --- 3. Retirements -----------------------------------------------------------
# Every line of removed.txt is a target path that no longer has a source.
if [ -f "$repo/removed.txt" ]; then
    while read -r p; do
        case $p in ''|'#'*) continue ;; esac
        [ -e "$HOME/$p" ] && { rm -rf "$HOME/$p"; printf '%s\n' "removed: $p"; }
    done < "$repo/removed.txt"
fi

# --- 4. Hooks -----------------------------------------------------------------
# In order; a running tmux keeps the config it started with, so the reload
# comes last, after tmux.conf and cockpit.json have landed.
for h in \
    generate-shell-init.sh \
    install-claude-hooks.sh \
    register-mcp.sh \
    seed-mason-registry.sh \
    sync-claude-plugins.sh \
    reload-tmux.sh
do
    if [ -f "$repo/hooks/$h" ]; then
        "$repo/hooks/$h" || warn "$h: failed"
    else
        warn "$h: hook missing from hooks/"
    fi
done

exit 0