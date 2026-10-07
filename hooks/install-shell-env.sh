#!/bin/sh
# Add the shared cockpit loader without replacing personal shell startup files.
set -eu
line='[ ! -r "$HOME/.config/shell/env.sh" ] || . "$HOME/.config/shell/env.sh"'
for file in .zshenv .bash_profile .bashrc; do
    target="$HOME/$file"
    touch "$target"
    if ! grep -Fqx "$line" "$target"; then
        printf '\n%s\n' "$line" >> "$target"
    fi
done
