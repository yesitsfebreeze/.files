#!/usr/bin/env bash
# television preview for the `theme` channel. $1 is the focused scheme id,
# e.g. "base16-mocha" or "base24-espresso". Prints the scheme's name and
# variant, live-retints the terminal background so the real (translucent)
# window previews it, and lists the full palette as a swatch grid — all read
# from the scheme's own hex values.
#
# It deliberately never applies anything. An apply-on-focus preview retints
# the real terminal on every scroll, which fires tinty's whole hook chain per
# keystroke — the canonical apply happens exactly once, on Enter, in
# theme.nu, after tv has exited. Here we draw the swatch, plus one OSC 11
# escape to live-retint just the terminal background (see below) — hook-free,
# and theme.nu re-asserts the active background when the picker closes.
set -u

id="${1:-}"
# The A/B slot pair heads the list tagged " (A · current)" / " (B)" (see
# _theme_list in theme.nu) — strip any trailing parenthetical back to the
# bare id. A scheme id never contains " (", so this cannot eat part of a
# real name.
case "$id" in *" ("*) id="${id%% (*}" ;; esac
[ -z "$id" ] && exit 0
system="${id%%-*}"
slug="${id#*-}"
data="${XDG_DATA_HOME:-$HOME/.local/share}/tinted-theming/tinty"
scheme="$data/repos/schemes/$system/$slug.yaml"
# Custom schemes live outside the catalog clone — fall back to the
# custom-schemes dir for their yaml.
[ -f "$scheme" ] || scheme="$data/custom-schemes/$system/$slug.yaml"
[ -f "$scheme" ] || { printf '%s\n\n(scheme file not found)\n' "$id"; exit 0; }

name=$(sed -n 's/^name: *"\{0,1\}\([^"]*\)"\{0,1\}.*/\1/p' "$scheme" | head -n1)
variant=$(sed -n 's/^variant: *"\{0,1\}\([^"]*\)"\{0,1\}.*/\1/p' "$scheme" | head -n1)
[ -z "$name" ] && name="$slug"
[ -z "$variant" ] && variant="?"

# ── palette extraction ───────────────────────────────────────────────────────
# base16 keys are 00..0F; base24 adds 10..17 for distinct bright ANSI. Two
# PARALLEL indexed arrays, built in one pass — no associative array (macOS
# ships bash 3.2, which has none) and no name-keyed lookup to work around it;
# the swatch loop below walks both by position instead.
keys=(00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F)
[ "$system" = base24 ] && keys+=(10 11 12 13 14 15 16 17)
vals=()
for k in "${keys[@]}"; do
    vals+=("$(grep -iE "^[[:space:]]*base$k:[[:space:]]*\"?#[0-9A-Fa-f]{6}" "$scheme" \
        | head -n1 | sed -E 's/.*(#[0-9A-Fa-f]{6}).*/\1/' | tr 'A-F' 'a-f')")
done
# Bail to a plain header line if the palette didn't parse, never a broken frame.
[ -z "${vals[0]}" ] && { printf '%s  (%s)\n' "$name" "$variant"; exit 0; }

# ── color helpers ────────────────────────────────────────────────────────────
# Honor NO_COLOR completely (no-color.org): emit ZERO escapes — reset and
# bold included, and no OSC 11 either. The header line carries the layout.
color=1; [ -n "${NO_COLOR:-}" ] && color=0
R=""; BOLD=""
[ "$color" = 1 ] && { R=$'\033[0m'; BOLD=$'\033[1m'; }
rgb() { local h="${1#\#}"; printf '%d;%d;%d' "0x${h:0:2}" "0x${h:2:2}" "0x${h:4:2}"; }
fg() { [ "$color" = 1 ] && printf '\033[38;2;%sm' "$(rgb "$1")"; }

# Live-retint ONLY the terminal background to the focused scheme's base00 so
# the real (translucent) wezterm window previews it for real. OSC 11 is a
# single escape straight to the tty — no apply, no hook chain, nothing else
# is touched. theme.nu re-asserts the active background once the picker
# closes.
[ "$color" = 1 ] && { printf '\033]11;%s\033\\' "${vals[0]}" > /dev/tty; } 2>/dev/null

# ── header line ───────────────────────────────────────────────────────────
HI=$(fg "${vals[5]}")$BOLD  # base05, brightest foreground
DIM=$(fg "${vals[3]}")      # base03, muted
printf '%b%s%b  %b(%s · %s)%b\n\n' "$HI" "$name" "$R" "$DIM" "$system" "$variant" "$R"

# ── palette (labelled divider + two-column swatch grid) ──────────────────────
printf '%b── palette ──────────────────────%b\n' "$DIM" "$R"
swatch() {  # label hex -> "████ 0D #a78bfa"
    local k="$1" hx="$2"
    if [ "$color" = 1 ]; then
        printf '%b████%b %b%s%b %b%s%b' "$(fg "$hx")" "$R" "$HI" "$k" "$R" "$DIM" "$hx" "$R"
    else
        printf '%-4s %s %s' "$k" "$k" "$hx"
    fi
}
n=${#keys[@]}
for ((i=0;i<n;i+=2)); do
    left="$(swatch "${keys[i]}" "${vals[i]}")"
    if [ -n "${keys[i+1]:-}" ]; then
        printf ' %s   %s\n' "$left" "$(swatch "${keys[i+1]}" "${vals[i+1]}")"
    else
        printf ' %s\n' "$left"
    fi
done
