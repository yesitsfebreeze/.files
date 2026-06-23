#!/usr/bin/env bash
# chezmoi run_after — regenerate the shell-integration files Nushell sources.
# Runs last on every apply (after the package installer), never at shell start;
# config.nu only *sources* these files, so launching nu/WezTerm does zero setup.
set -uo pipefail

# Pick up tools installed earlier in this same apply (brew shellenv / user bins).
[ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
[ -x /usr/local/bin/brew ] && eval "$(/usr/local/bin/brew shellenv)"
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

# Starship prompt init -> ~/.cache/starship/init.nu
starship_init="$HOME/.cache/starship/init.nu"
mkdir -p "$(dirname "$starship_init")"
if command -v starship >/dev/null 2>&1; then
    starship init nu > "$starship_init" 2>/dev/null || true
fi
# Guarantee each init file exists (empty = harmless no-op) so `source` never
# fails when the tool isn't installed yet. Repeated after each integration below.
[ -s "$starship_init" ] || : > "$starship_init"

# Zoxide init -> ~/.zoxide.nu
zoxide_init="$HOME/.zoxide.nu"
if command -v zoxide >/dev/null 2>&1; then
    zoxide init nushell > "$zoxide_init" 2>/dev/null || true
fi
[ -s "$zoxide_init" ] || : > "$zoxide_init"

# Television (tv) -> ~/.cache/television/init.nu. `tv init nu` emits the Ctrl-T
# (autocomplete) and Ctrl-R (history) Nushell keybindings; tv replaces fzf.
tv_init="$HOME/.cache/television/init.nu"
mkdir -p "$(dirname "$tv_init")"
if command -v tv >/dev/null 2>&1; then
    tv init nu > "$tv_init" 2>/dev/null || true
fi
[ -s "$tv_init" ] || : > "$tv_init"

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

# WezTerm colors.lua is generated HERE, at apply time — not on shell/WezTerm
# launch. config.nu only re-emits the live OSC retint; a terminal start should
# never be what writes colors.lua. Resolve the active scheme (a prior `theme`
# pick, else config's default-scheme) and regenerate colors.lua from its base16
# YAML — catalog or our chezmoi-shipped custom-schemes (base16-feb). Non-fatal.
if [ -x "$tinty_cfg/wezterm-colors.sh" ]; then
    scheme="$(cat "$tinty_data/artifacts/current_scheme" 2>/dev/null)"
    if [ -z "$scheme" ]; then
        scheme="$(sed -n 's/^[[:space:]]*default-scheme[[:space:]]*=[[:space:]]*"\(.*\)".*/\1/p' "$tinty_cfg/config.toml" 2>/dev/null)"
    fi
    [ -n "$scheme" ] && bash "$tinty_cfg/wezterm-colors.sh" "$scheme" || true
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
