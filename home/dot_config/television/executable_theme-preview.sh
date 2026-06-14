#!/usr/bin/env bash
# television preview command for the `theme` channel (apply-on-focus).
# $1 is the focused scheme id, e.g. "base24-3024-night". Two jobs:
#   1. Apply the scheme LIVE to the terminal. tinty emits OSC palette sequences on
#      stdout, but television captures this process's stdout for the preview panel,
#      so we route the apply to /dev/tty to retint WezTerm as you scroll.
#   2. Print a color swatch to stdout for the preview panel.
set -u

id="${1:-}"
[ -z "$id" ] && exit 0
slug="${id#base24-}"
data="${XDG_DATA_HOME:-$HOME/.local/share}/tinted-theming/tinty"
scheme="$data/custom-schemes/base24/$slug.yaml"

# (1) live apply to the terminal device (not our captured stdout).
if command -v tinty >/dev/null 2>&1; then
    tinty apply "$id" >/dev/tty 2>/dev/null || true
fi

# (2) swatch for the preview panel.
if [ ! -f "$scheme" ]; then
    printf '%s\n(no scheme file)\n' "$id"
    exit 0
fi

name=$(sed -n 's/^name: *"\(.*\)".*/\1/p' "$scheme" | head -n1)
variant=$(sed -n 's/^variant: *"\(.*\)".*/\1/p' "$scheme" | head -n1)
printf '%s  (%s)\n\n' "${name:-$slug}" "${variant:-?}"

# Each "baseXX: \"#rrggbb\"" line -> a truecolor block plus its label.
while read -r key hex; do
    [ -z "$hex" ] && continue
    r=$((16#${hex:0:2})); g=$((16#${hex:2:2})); b=$((16#${hex:4:2}))
    printf '\033[48;2;%d;%d;%dm      \033[0m  \033[38;2;%d;%d;%dm%s  #%s\033[0m\n' \
        "$r" "$g" "$b" "$r" "$g" "$b" "$key" "$hex"
done < <(sed -n 's/^ *\(base[0-9A-Fa-f][0-9A-Fa-f]\): *"#\([0-9a-fA-F]\{6\}\)".*/\1 \2/p' "$scheme")
