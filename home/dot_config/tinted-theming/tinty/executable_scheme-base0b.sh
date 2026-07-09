#!/usr/bin/env bash
# Print base0B (the theme's "green") of a tinty scheme id, e.g.
#   scheme-base0b.sh base16-chinoiserie-midnight  ->  #aeb831
#
# This is what lets .chezmoidata/theme.toml carry ONLY the scheme name: chezmoi calls
# this from config.yaml.tmpl to inline GlazeWM's focused-border color, so `green` is
# always derived from the scheme, never stored as a second synced value that can drift
# or conflict. Resolution mirrors wezterm-colors.sh (official repos clone first, then
# our chezmoi-shipped custom-schemes). Always exits 0 so a template `output` call never
# aborts apply: if the scheme yaml isn't cloned yet (first apply, before run_after runs
# `tinty install`), it prints the fallback, and run_after's wezterm-colors.sh rewrites
# the deployed border once the yaml exists.
set -uo pipefail

# Neutral green used only until the real scheme yaml is available.
FALLBACK="#aeb831"

SCHEME="${1:-}"
[ -n "$SCHEME" ] || { printf '%s\n' "$FALLBACK"; exit 0; }

SCHEMES_DIR="$HOME/.local/share/tinted-theming/tinty/repos/schemes"
CUSTOM_DIR="$HOME/.local/share/tinted-theming/tinty/custom-schemes"

SYSTEM="${SCHEME%%-*}"
NAME="${SCHEME#*-}"
YAML="$SCHEMES_DIR/$SYSTEM/$NAME.yaml"
[ -f "$YAML" ] || YAML="$CUSTOM_DIR/$SYSTEM/$NAME.yaml"
[ -f "$YAML" ] || { printf '%s\n' "$FALLBACK"; exit 0; }

# Same portable extraction as wezterm-colors.sh's color() (bash 3.2 / BSD+GNU sed):
# match `base0B: "#rrggbb"` case-insensitively, take the first, lowercase it.
val="$(grep -iE "^[[:space:]]*base0B:[[:space:]]*\"#[0-9A-Fa-f]{6}\"" "$YAML" \
    | head -n1 \
    | sed -E 's/.*"(#[0-9A-Fa-f]{6})".*/\1/' \
    | tr 'A-F' 'a-f')"

printf '%s\n' "${val:-$FALLBACK}"
