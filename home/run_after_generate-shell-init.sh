#!/usr/bin/env bash
# chezmoi run_after — regenerate the shell-integration files Nushell sources.
# Runs last on every apply (after the package installer), never at shell start;
# config.nu only *sources* these files, so launching nu/WezTerm does zero setup.
set -uo pipefail

# Pick up tools installed earlier in this same apply (brew shellenv / user bins).
[ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
[ -x /usr/local/bin/brew ] && eval "$(/usr/local/bin/brew shellenv)"
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

# Write a tool's init file, guaranteeing it always exists (empty = harmless
# no-op) so config.nu's `source` never fails when the tool isn't installed yet.
#   gen_init <out-file> <tool> <init args...>
gen_init() {
    local out="$1"; shift
    mkdir -p "$(dirname "$out")"
    if command -v "$1" >/dev/null 2>&1; then
        "$@" > "$out" 2>/dev/null || true
    fi
    [ -s "$out" ] || : > "$out"
}

gen_init "$HOME/.cache/starship/init.nu"    starship init nu
gen_init "$HOME/.zoxide.nu"                 zoxide init nushell
# `tv init nu` emits the Ctrl-T (autocomplete) + Ctrl-R (history) keybindings.
gen_init "$HOME/.cache/television/init.nu"  tv init nu

# pass (password-store) — installing the binary does not create a store; that
# needs a one-time `pass init <gpg-id>` against a GPG key. Detect the unset state
# (store has no .gpg-id) and point at the README setup section. Purely advisory:
# never initializes anything (that needs the user's key) and never fails apply.
if command -v pass >/dev/null 2>&1; then
    pass_store="${PASSWORD_STORE_DIR:-$HOME/.password-store}"
    if [ ! -f "$pass_store/.gpg-id" ]; then
        printf '\033[1;33m!!\033[0m %s\n' "pass is installed but no store exists yet ($pass_store)."
        printf '\033[1;33m!!\033[0m %s\n' "  Set it up: see the \"Password manager\" section in the README."
    fi
fi
