#!/usr/bin/env bash
# television preview command for the `theme` channel (apply-on-focus).
# $1 is the focused scheme id, e.g. "base16-mocha" or "base24-alucard". Two jobs:
#   1. Apply the scheme LIVE to the terminal. tinty emits OSC palette sequences on
#      stdout, but television captures this process's stdout for the preview panel,
#      so we route the apply to /dev/tty to retint WezTerm as you scroll.
#   2. Render a real syntax-highlighted sample file so you judge the theme on actual
#      content. bat's "ansi" theme maps tokens onto the 16 ANSI slots, which the live
#      apply just retinted — so the sample recolors with the scheme as you scroll.
set -u

id="${1:-}"
[ -z "$id" ] && exit 0
system="${id%%-*}"
slug="${id#*-}"
data="${XDG_DATA_HOME:-$HOME/.local/share}/tinted-theming/tinty"
scheme="$data/repos/schemes/$system/$slug.yaml"
# Custom schemes (base24-feb, the converted base24-gogh-*) live outside the
# catalog clone — fall back to the custom-schemes dir for their name.
[ -f "$scheme" ] || scheme="$data/custom-schemes/$system/$slug.yaml"
sample="$HOME/.config/television/theme-preview-sample.ts"

# (1) live apply to the terminal device (not our captured stdout).
if command -v tinty >/dev/null 2>&1; then
    tinty apply "$id" >/dev/tty 2>/dev/null || true
fi

# (2) header: scheme name + variant.
if [ -f "$scheme" ]; then
    name=$(sed -n 's/^name: *"\(.*\)".*/\1/p' "$scheme" | head -n1)
    variant=$(sed -n 's/^variant: *"\(.*\)".*/\1/p' "$scheme" | head -n1)
    printf '%s  (%s)\n\n' "${name:-$slug}" "${variant:-?}"
else
    printf '%s\n\n' "$id"
fi

# (3) sample file rendered through the ANSI palette the scheme just set.
if command -v bat >/dev/null 2>&1; then
    bat --color=always --theme=ansi --style=numbers --paging=never "$sample"
else
    cat "$sample"
fi
