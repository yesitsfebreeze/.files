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
#   sh dotfiles.sh --install      # fresh machine: brew, sshd, tools, then deploy
#   sh dotfiles.sh --manual       # regenerate the manual's generated halves
#   sh dotfiles.sh --push         # stage, commit, push — git only, no deploy
#
# The contract, explicit:
#   1. PATH first — hooks run tools (the generator runs brew's nushell).
#   2. A preflight exec-bit guard: every .sh and every .local/bin file must
#      be +x in the tree, or the deploy warns — the rename once lost three
#      exec bits and shipped dead scripts (git 258ae5e's root cause).
#   3. The copy: every file under home/ overwrites its target (cp -p; the
#      exec bit rides git, no name prefixes). .DS_Store, .git and
#      __pycache__ are excluded by the find.
#   4. Hooks: hooks/*.sh in a fixed order, each non-fatal — one failure
#      warns and the rest run. The reload comes last (a running tmux keeps
#      the config it started with).
#
# RETIRING A FILE is two actions in one change: delete the source in home/
# and rm the live copy in $HOME — explicit, once, at the moment you decide.
# There is no retirement ledger: the old removed.txt fired its whole life
# on paths that were already gone, and a stale entry would silently delete
# any future file created at a retired path. No hidden state survives.
#
# --status changes nothing and runs no hooks; it reports two buckets:
# NEW (no target yet) and DIFFERS (source and target disagree — WHICH SIDE
# moved is `git status` in the repo, there is no state database by design).
set -u

repo=$(cd "$(dirname "$0")" && pwd)
home_src=$repo/home

log()  { printf '\033[1;34m::\033[0m %s\n' "$*" >&2; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }
have() { command -v "$1" >/dev/null 2>&1; }

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
    walk | while read -r f; do
        if   [ ! -e "$HOME/$f" ]; then printf 'NEW     %s\n' "$f"
        elif ! cmp -s "$home_src/$f" "$HOME/$f"; then printf 'DIFFERS %s\n' "$f"
        fi
    done
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

# --- 0. PATH: everything below runs tools -------------------------------------
if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

# --- --install: the fresh-machine bootstrap, then fall through to the deploy ---
# Order is the contract: every tool is on PATH before the deploy, because the
# hooks generate shell init by running those tools. A failed step warns and
# the run continues — a missing tool must be a warning, never a dead install.
install() {
    if ! have brew; then
        log "installing Homebrew"
        NONINTERACTIVE=1 /bin/bash -c \
            "$(curl -fsSL --max-time 60 https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" \
            || warn "Homebrew: bootstrap failed — install it by hand and re-run"
    fi
    if have brew; then
        # TRAP: Homebrew 6 refuses a formula from an untrusted third-party tap
        # and `brew bundle` will not trust one for you — without this the
        # Brewfile's tinty is skipped with an error, and tinty owns the palette.
        brew trust --tap tinted-theming/tinted || warn "could not trust the tinted tap"
        brew bundle install --file "$home_src/.config/Brewfile" \
            || warn "brew bundle incomplete"
    else
        warn "no brew — nothing was installed"
    fi

    # Remote access: sshd over the tailnet. The GUI cask cannot be a Tailscale
    # SSH server on macOS, so tailnet peers reach this machine over the built-in
    # sshd with a key. Loading its launchd job is Remote Login; the one sudo
    # prompt in the run (launchctl, not `systemsetup`, which wants Full Disk
    # Access on top of sudo).
    if [ "$(uname -s)" = Darwin ]; then
        if launchctl print system/com.openssh.sshd >/dev/null 2>&1; then
            log "Remote Login already on"
        else
            sudo launchctl load -w /System/Library/LaunchDaemons/ssh.plist && log "Remote Login on" \
                || warn "Remote Login: could not load sshd — System Settings > General > Sharing"
        fi
        [ -x /Applications/Tailscale.app/Contents/MacOS/Tailscale ] \
            && ! /Applications/Tailscale.app/Contents/MacOS/Tailscale status >/dev/null 2>&1 \
            && warn "Tailscale: open Tailscale.app and sign in"
    fi

    # tmux-mcp: no package manager has it; prebuilt release. TRAP: the assets
    # are named with an UNDERSCORE, tmux-mcp_<os>_<arch>.
    if ! have tmux-mcp; then
        case "$(uname -m)" in arm64|aarch64) a=arm64 ;; *) a=amd64 ;; esac
        t="$(curl -fsSL --max-time 30 https://api.github.com/repos/MadAppGang/tmux-mcp/releases/latest \
            | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)"
        d="$(mktemp -d)"
        if [ -n "$t" ] && curl -fsSL --max-time 300 -o "$d/a.tgz" \
            "https://github.com/MadAppGang/tmux-mcp/releases/download/$t/tmux-mcp_$(uname -s | tr A-Z a-z)_$a.tar.gz" \
            && tar -xf "$d/a.tgz" -C "$d"; then
            mkdir -p "$HOME/.local/bin"
            install -m 755 "$d/tmux-mcp" "$HOME/.local/bin/tmux-mcp" && log "installed tmux-mcp $t"
        else
            warn "tmux-mcp: could not install (GitHub rate limit?)"
        fi
        rm -rf "$d"
    fi

    # tmux plugins: the path must equal tmux.conf's two `run-shell` lines. No
    # tpm — the install and the deploy keep them updated instead.
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
    --manual)
        node "$repo/hooks/generate-manual.mjs" || warn "manual regeneration failed"
        exit 0
        ;;
    --push)
        git -C "$repo" add --all
        git -C "$repo" diff --cached --quiet || git -C "$repo" commit -m "chore: update"
        git -C "$repo" push
        exit 0
        ;;
    --install)
        install
        ;;
esac

preflight

# --- 2. The copy ---------------------------------------------------------------
cd "$home_src" || exit 1
walk | while read -r f; do
    mkdir -p "$HOME/$(dirname "$f")"
    cp -p "$f" "$HOME/$f"
    printf '%s\n' "$f"
done
log "deployed $(walk | wc -l | tr -d ' ') files into $HOME"

# --- 3. Hooks ------------------------------------------------------------------
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