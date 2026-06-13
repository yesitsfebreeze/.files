#!/usr/bin/env bash
# chezmoi run_after — regenerate the shell-integration files that Nushell sources.
# Runs on every `chezmoi apply`/`update` (the run_after_ prefix makes it run last,
# after the package installer), NEVER at shell start. config.nu only *sources*
# these files, so launching nu/WezTerm does zero setup work.
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
# Guarantee the file exists (empty = harmless no-op) so `source` never fails.
[ -s "$starship_init" ] || : > "$starship_init"

# Zoxide init -> ~/.zoxide.nu
zoxide_init="$HOME/.zoxide.nu"
if command -v zoxide >/dev/null 2>&1; then
    zoxide init nushell > "$zoxide_init" 2>/dev/null || true
fi
[ -s "$zoxide_init" ] || : > "$zoxide_init"
