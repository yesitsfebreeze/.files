#!/bin/sh
# dotfiles.sh — the whole deploy: copy home/ over $HOME, then run the hooks.
#
# This replaces chezmoi. The repo's home/ tree keeps REAL filenames — what
# you see in the tree is what lands in $HOME — and deployment is a replace:
# every file in home/ overwrites its target, hooks run after the copy, and
# nothing is templated. Dynamic values are runtime concerns, not deploy-time
# ones: secrets are read from the Keychain by the shell (env.nu, capsule.nu),
# and the one thing that used to be a template (gitconfig's name and email)
# is written below as plain text.
#
#   sh dotfiles.sh                # deploy: copy, retire, hooks (what `rr` runs)
#   sh dotfiles.sh --status       # dry-run: what a deploy would change + drift
#   sh dotfiles.sh --adopt <path> # copy a live file back into home/
#
# The contract, explicit:
#   1. PATH first — hooks run tools (the generator runs brew's nushell).
#   2. A preflight exec-bit guard: every .sh and every .local/bin file must
#      be +x in the tree, or the deploy warns — the rename once lost three
#      exec bits and shipped dead scripts (git 258ae5e's root cause).
#   3. The copy: every file under home/ overwrites its target (cp -p; the
#      exec bit rides git, no name prefixes). .DS_Store, .git and
#      __pycache__ are excluded by the find.
#   4. Retire: every path in removed.txt is deleted in $HOME. Retiring a
#      file is still two edits: the source file goes, the target path joins
#      removed.txt (docs/llms/decisions.txt).
#   5. Hooks: hooks/*.sh in a fixed order, each non-fatal — one failure
#      warns and the rest run. The reload comes last (a running tmux keeps
#      the config it started with).
#
# --status changes nothing and runs no hooks; it reports three buckets:
# NEW (no target yet), DIFFERS (source and target disagree — WHICH SIDE
# moved is `git status` in the repo, there is no state database by design),
# and RETIRE (removed.txt paths still present in $HOME).
set -u

repo=$(cd "$(dirname "$0")" && pwd)
home_src=$repo/home

log()  { printf '\033[1;34m::\033[0m %s\n' "$*" >&2; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }

# --- the tree walk, shared by deploy and status -------------------------------
walk() {
    (cd "$home_src" && find . -type f ! -name .DS_Store ! -path '*/.git/*' ! -path '*/__pycache__/*')
}

# --- preflight: nothing that must run ships without +x ------------------------
preflight() {
    (cd "$home_src" && {
        find . -type f -name '*.sh' ! -perm -u+x
        find . -type f -path './.local/bin/*' ! -perm -u+x
    }) | while read -r f; do
        warn "not executable, would ship dead: $f"
    done
}

# --- --status: the dry-run -----------------------------------------------------
status() {
    n_new=0; n_diff=0; n_ret=0
    walk | while read -r f; do
        if   [ ! -e "$HOME/$f" ]; then printf 'NEW     %s\n' "$f"
        elif ! cmp -s "$home_src/$f" "$HOME/$f"; then printf 'DIFFERS %s\n' "$f"
        fi
    done
    if [ -f "$repo/removed.txt" ]; then
        while read -r p; do
            case $p in ''|'#'*) continue ;; esac
            [ -e "$HOME/$p" ] && printf 'RETIRE  %s\n' "$p"
        done < "$repo/removed.txt"
    fi
}

# --- --adopt: live file into the repo ------------------------------------------
# The reverse direction: $HOME/.config/x/y becomes home/.config/x/y, so the
# next deploy owns it. Refuses anything outside $HOME (~/dev/... is not a
# dotfile) and anything that would escape home/.
adopt() {
    [ $# -eq 1 ] || { warn "usage: sh dotfiles.sh --adopt <path>"; exit 1; }
    src=$1
    case $src in
        "$HOME"/*) rel=${src#"$HOME"/} ;;
        *) warn "adopt: not under \$HOME: $src"; exit 1 ;;
    esac
    # `..` segments escape the tree; a plain leading dot is just a dotfile.
    case $rel in
        ..|../*|*/../*|*/..) warn "adopt: refuses to escape home/: $rel"; exit 1 ;;
    esac
    [ -e "$src" ] || { warn "adopt: no such file: $src"; exit 1; }
    dst="$home_src/$rel"
    [ -e "$dst" ] && { warn "adopt: already in the tree: $rel"; exit 1; }
    mkdir -p "$(dirname "$dst")"
    cp -Rp "$src" "$dst"
    printf '%s\n' "adopted: home/$rel"
}

case ${1-} in
    --status)
        status
        exit 0
        ;;
    --adopt)
        shift
        adopt "$@"
        exit 0
        ;;
esac

# --- 1. PATH: hooks run tools --------------------------------------------------
if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

preflight

# --- 2. The copy ---------------------------------------------------------------
cd "$home_src" || exit 1
walk | while read -r f; do
    mkdir -p "$HOME/$(dirname "$f")"
    cp -p "$f" "$HOME/$f"
    printf '%s\n' "$f"
done
log "deployed $(walk | wc -l | tr -d ' ') files into $HOME"

# --- 3. Retirements ------------------------------------------------------------
if [ -f "$repo/removed.txt" ]; then
    while read -r p; do
        case $p in ''|'#'*) continue ;; esac
        [ -e "$HOME/$p" ] && { rm -rf "$HOME/$p"; printf '%s\n' "removed: $p"; }
    done < "$repo/removed.txt"
fi

# --- 4. Hooks ------------------------------------------------------------------
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