#!/usr/bin/env bash
# chezmoi run_after — regenerate the files nushell's config.nu `source`s, so
# launching a shell does no setup work. TRAPs: the path is a literal, not
# XDG_CACHE_HOME; brew is evaluated first and ~/.local/bin prepended over it;
# the file must exist even when the tool does not. See internals/provisioning.
set -uo pipefail

[ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
hash -r

INIT_DIR="$HOME/.cache/nushell/init"
mkdir -p "$INIT_DIR"

# Output goes to a temp file in the SAME directory and is moved into place with
# `mv -f` (a same-directory rename, therefore atomic) and only when the tool
# exited 0. Half-written nushell would be a parse error in every shell, which
# is worse than nothing.
gen_init() {
    local out="$1"; shift
    local tmp="$out.tmp"
    rm -f "$tmp"
    if command -v "$1" > /dev/null 2>&1 && "$@" > "$tmp" 2> /dev/null; then
        mv -f "$tmp" "$out"
    else
        rm -f "$tmp"
        : > "$out"   # truncate-on-failure: empty beats partial
    fi
}

gen_init "$INIT_DIR/starship.nu"    starship init nu
gen_init "$INIT_DIR/zoxide.nu"      zoxide init nushell
gen_init "$INIT_DIR/television.nu"  tv init nu

exit 0   # a non-zero run_after kills the whole apply
