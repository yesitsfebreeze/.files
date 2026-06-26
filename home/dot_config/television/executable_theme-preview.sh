#!/usr/bin/env bash
# television preview for the `theme` channel. $1 is the focused scheme id, e.g.
# "base16-mocha" or "base24-feb". This renders a SELF-CONTAINED, representative
# preview of the scheme — a banner, a small UI mockup, and the full palette — by
# reading the scheme's own hex values and painting them with truecolor escapes.
#
# It deliberately does NOT `tinty apply`. The old apply-on-focus preview retinted
# the real terminal on every scroll, which fired tinty's hook chain — and that
# chain kill+relaunches Zebar across the WSL->Windows boundary on every focus
# (a "browser refresh" per keystroke that stalled the picker). The canonical apply
# now happens exactly once, on Enter, in theme.nu. Here we only draw colors; the
# terminal and the bar are never touched.
set -u

id="${1:-}"
[ -z "$id" ] && exit 0
system="${id%%-*}"
slug="${id#*-}"
data="${XDG_DATA_HOME:-$HOME/.local/share}/tinted-theming/tinty"
scheme="$data/repos/schemes/$system/$slug.yaml"
# Custom schemes (base24-feb, the converted gogh-* themes) live outside the
# catalog clone — fall back to the custom-schemes dir for their name.
[ -f "$scheme" ] || scheme="$data/custom-schemes/$system/$slug.yaml"
[ -f "$scheme" ] || { printf '%s\n\n(scheme file not found)\n' "$id"; exit 0; }

shopt -s extglob

# ── palette extraction ───────────────────────────────────────────────────────
# Pull one base key's hex (portable: macOS bash 3.2, BSD+GNU sed), lowercased.
hex() {
    grep -iE "^[[:space:]]*$1:[[:space:]]*\"?#[0-9A-Fa-f]{6}" "$scheme" \
        | head -n1 | sed -E 's/.*(#[0-9A-Fa-f]{6}).*/\1/' | tr 'A-F' 'a-f'
}
name=$(sed -n 's/^name: *"\{0,1\}\([^"]*\)"\{0,1\}.*/\1/p' "$scheme" | head -n1)
variant=$(sed -n 's/^variant: *"\{0,1\}\([^"]*\)"\{0,1\}.*/\1/p' "$scheme" | head -n1)
[ -z "$name" ] && name="$slug"
[ -z "$variant" ] && variant="?"

# base16 keys are 00..0F; base24 adds 10..17 for distinct bright ANSI.
keys=(00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F)
[ "$system" = base24 ] && keys+=(10 11 12 13 14 15 16 17)
declare -A C
for k in "${keys[@]}"; do C[$k]="$(hex "base$k")"; done
# Bail to a plain id line if the palette didn't parse, never a broken frame.
[ -z "${C[00]:-}" ] && { printf '%s  (%s)\n' "$name" "$variant"; exit 0; }

# ── color helpers ────────────────────────────────────────────────────────────
# Honor NO_COLOR completely (no-color.org): emit zero escapes, glyphs carry it.
color=1; [ -n "${NO_COLOR:-}" ] && color=0
R=$'\033[0m'; BOLD=$'\033[1m'
rgb() { local h="${1#\#}"; printf '%d;%d;%d' "0x${h:0:2}" "0x${h:2:2}" "0x${h:4:2}"; }
fg() { [ "$color" = 1 ] && printf '\033[38;2;%sm' "$(rgb "${C[$1]}")"; }
bg() { [ "$color" = 1 ] && printf '\033[48;2;%sm' "$(rgb "${C[$1]}")"; }

# roles by base24 convention (brightness carries hierarchy; two accents on top)
BRD=$(fg 03)      # borders / dividers — muted
DIM=$(fg 03)      # comments, hints
PUN=$(fg 04)      # punctuation, secondary
TXT=$(fg 05)      # primary foreground
HI=$(fg 06)$BOLD  # brightest — focused / selected
KW=$(fg 0E)       # keywords  (accent)
FN=$(fg 0D)       # functions (accent)
STR=$(fg 0B)      # strings
NUM=$(fg 09)      # numbers / constants
ERR=$(fg 08)      # errors / variables
# Window background: mirror what the terminal ACTUALLY renders, not the scheme's own
# base00. tinty's background-override (config.toml) replaces base00 for wezterm/zebar, so
# the preview uses it too. A "transparent"/"none" override (or no solid colour) hides the
# fill, so the card shows the real transparent terminal background behind it. A blank
# override keeps the documented "track the scheme's base00" behaviour.
bg_hex() { [ "$color" = 1 ] && printf '\033[48;2;%sm' "$(rgb "$1")"; }
ovr=$(grep -iE '^[[:space:]]*background-override[[:space:]]*=' \
        "$HOME/.config/tinted-theming/tinty/config.toml" 2>/dev/null \
      | head -n1 | sed -E 's/^[^=]*=[[:space:]]*"?([^"]*)"?.*/\1/' | tr 'A-F' 'a-f' | tr -d '[:space:]')
case "${ovr#\#}" in
    [0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]) WBG=$(bg_hex "${ovr#\#}") ;;  # real solid background
    transparent|none|hidden|off)                       WBG="" ;;                       # transparent → hide
    *)                                                 WBG=$(bg 00) ;;                 # blank → scheme base00
esac
SBG=$(bg 02)      # selection background

INNER=44   # interior content cells of the card
WTOT=$((INNER + 4))

# vis: visible length of a string with ANSI escapes stripped (grid math).
vis() { local s="$1"; s="${s//$'\033'\[*([0-9;])m/}"; printf '%s' "${#s}"; }
# repeat <glyph> <n>
rep() { local i n="$2" o=""; for ((i=0;i<n;i++)); do o+="$1"; done; printf '%s' "$o"; }

# row: one card interior line. $1 = colored content (fg only, bg inherits), padded
# to INNER over the window background, framed by single-cell pads and borders.
row() { _row "$WBG" "$1"; }
# srow: a full-width selection bar (reverse-fill role) — selection bg, not window.
srow() { _row "$SBG" "$1"; }
_row() {
    local b="$1" c="$2" pad; pad=$((INNER - $(vis "$c"))); ((pad<0)) && pad=0
    printf '%b%s│%s %b%*s %b│%b\n' "$b" "$BRD" "$R$b" "$c" "$pad" "" "$BRD" "$R"
}

# ── banner (block weight = header/banner role) ───────────────────────────────
ACC=$(fg 0D)
sub="$system · $variant"
nl=$(vis "$name"); ((nl>INNER)) && { name="${name:0:$((INNER-1))}…"; nl=$INNER; }
sl=${#sub};        ((sl>INNER)) && { sub="${sub:0:$((INNER-1))}…"; sl=$INNER; }
printf '%b%s%b\n' "$ACC" "▛$(rep ▀ $((INNER+2)))▜" "$R"
printf '%b▐█%b %b%s%b%*s %b█▌%b\n' "$ACC" "$R" "$HI" "$name" "$R" "$((INNER-nl))" "" "$ACC" "$R"
printf '%b▐█%b %b%s%b%*s %b█▌%b\n' "$ACC" "$R" "$DIM" "$sub" "$R" "$((INNER-sl))" "" "$ACC" "$R"
printf '%b%s%b\n\n' "$ACC" "▙$(rep ▄ $((INNER+2)))▟" "$R"

# ── UI mockup card (rounded weight = default panel) ──────────────────────────
ttl="preview"
fill=$((INNER - ${#ttl} - 1))
printf '%b%s%b\n' "$BRD" "╭─ ${ttl} $(rep ─ $fill)╮" "$R"
row ""
row "${DIM}# theme preview${R}"
row "${KW}fn ${FN}render${PUN}(${TXT}theme${PUN}):${R}"
row "  ${KW}let ${ERR}name ${PUN}= ${STR}\"${name}\"${R}"
row "  ${KW}return ${NUM}0xb24${R}"
row ""
srow "${HI}▸ ${id}${R}"
row "${FN}✦${R} ${TXT}accent${R}   ${ERR}✕${R} ${TXT}error${R}   ${DIM}· muted${R}"
printf '%b%s%b\n\n' "$BRD" "╰$(rep ─ $((INNER+2)))╯" "$R"

# ── palette (labelled divider + two-column swatch grid) ──────────────────────
printf '%b── %bpalette %b%s%b\n' "$BRD" "${HI}" "$BRD" "$(rep ─ $((WTOT-12)))" "$R"
swatch() {  # key -> "████ 0D #a78bfa" sized to 15 cells
    local k="$1"; local hx="${C[$k]}"
    if [ "$color" = 1 ]; then
        printf '%b████%b %b%s%b %b%s%b' "$(bg "$k")" "$R" "$HI" "$k" "$R" "$DIM" "$hx" "$R"
    else
        printf '%-4s %s %s' "$k" "$k" "$hx"
    fi
}
n=${#keys[@]}
for ((i=0;i<n;i+=2)); do
    left="${keys[i]}"; right="${keys[i+1]:-}"
    if [ -n "$right" ]; then
        printf ' %s   %s\n' "$(swatch "$left")" "$(swatch "$right")"
    else
        printf ' %s\n' "$(swatch "$left")"
    fi
done
