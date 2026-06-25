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

# tinty (live `theme` switcher) — clone the configured items into tinty's data dir
# so the first `tinty apply` works. Idempotent; quiet + non-fatal so a missing
# network never breaks apply.
if command -v tinty >/dev/null 2>&1; then
    tinty install >/dev/null 2>&1 || true
fi

tinty_cfg="$HOME/.config/tinted-theming/tinty"
tinty_data="$HOME/.local/share/tinted-theming/tinty"

# Ship our custom feb scheme(s) into the data-dir. The tracked sources live in
# the config dir as feb.<system>.yaml (the data-dir custom-schemes/ is gitignored
# runtime state); copy each into custom-schemes/<system>/feb.yaml, where tinty
# and the colors generator look for it. Covers base16-feb and base24-feb.
for src in "$tinty_cfg"/feb.*.yaml; do
    [ -f "$src" ] || continue
    sys="$(sed -n 's/^[[:space:]]*system:[[:space:]]*"\(.*\)".*/\1/p' "$src" | head -n1)"
    [ -n "$sys" ] || continue
    mkdir -p "$tinty_data/custom-schemes/$sys"
    cp -f "$src" "$tinty_data/custom-schemes/$sys/feb.yaml"
done

# Convert Gogh's terminal themes into base24 custom-schemes so they show up in the
# `theme` switcher alongside the tinty catalog. Installs once, then exits instantly
# on subsequent applies; `gogh-to-base24.sh --update` refreshes from upstream.
if [ -x "$tinty_cfg/gogh-to-base24.sh" ]; then
    bash "$tinty_cfg/gogh-to-base24.sh" || true
fi

# WezTerm colors.lua and Zebar theme.css are generated HERE, at apply time — not
# on shell/WezTerm launch. config.nu only re-emits the live OSC retint; a terminal
# start should never be what writes them. Resolve the active scheme (a prior
# `theme` pick, else config's default-scheme) once and regenerate both from its
# base16/24 YAML — catalog or our chezmoi-shipped custom-schemes (base16-feb).
# Both must run so a config change (e.g. background-override) lands in WezTerm and
# Zebar together; the live `theme` switch chains the same two scripts. Non-fatal.
scheme="$(cat "$tinty_data/artifacts/current_scheme" 2>/dev/null)"
if [ -z "$scheme" ]; then
    scheme="$(sed -n 's/^[[:space:]]*default-scheme[[:space:]]*=[[:space:]]*"\(.*\)".*/\1/p' "$tinty_cfg/config.toml" 2>/dev/null)"
fi
if [ -n "$scheme" ]; then
    [ -x "$tinty_cfg/wezterm-colors.sh" ] && bash "$tinty_cfg/wezterm-colors.sh" "$scheme" || true
    [ -x "$tinty_cfg/zebar-colors.sh" ]   && bash "$tinty_cfg/zebar-colors.sh" "$scheme" || true
fi

# pass (password-store) — installing the binary does not create a store; that
# needs a one-time `pass init <gpg-id>` against a GPG key. Detect the unset state
# (store has no .gpg-id) and point at the README setup section. Purely advisory:
# never initializes anything (that needs the user's key) and never fails apply.
if command -v pass >/dev/null 2>&1; then
    pass_store="${PASSWORD_STORE_DIR:-$HOME/.password-store}"
    if [ ! -f "$pass_store/.gpg-id" ]; then
        printf '\033[1;33m!!\033[0m %s\n' "pass is installed but no store exists yet ($pass_store)."
        printf '\033[1;33m!!\033[0m %s\n' "  Set it up: see the \"Password manager\" section in the README (or docs/index.html)."
    fi
fi
