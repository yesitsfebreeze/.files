# §source home/dot_config/television/executable_theme-preview.sh
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
# now happens exactly once, on Enter, in theme.nu. Here we draw the swatch, plus
# one OSC 11 escape to live-retint just the terminal background (see below) —
# hook-free, and theme.nu re-asserts the active background when the picker closes.
set -u

id="${1:-}"
# The current theme is listed first tagged " (current)" — strip it to the bare id.
id="${id% (current)}"
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
# §.splinter/home/dot_config/television/executable_theme-preview/hex.fs
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
rgb() {
# §.splinter/home/dot_config/television/executable_theme-preview/rgb.fs
}
fg() {
# §.splinter/home/dot_config/television/executable_theme-preview/fg.fs
}
bg() {
# §.splinter/home/dot_config/television/executable_theme-preview/bg.fs
}

# Live-retint ONLY the terminal background to the focused scheme's base00 so the
# real (translucent) wezterm window previews it for real. OSC 11 is a single
# escape straight to the tty — no `tinty apply`, no hook chain, nothing else is
# touched. theme.nu re-asserts the active background once the picker closes.
[ "$color" = 1 ] && { printf '\033]11;%s\033\\' "${C[00]}" > /dev/tty; } 2>/dev/null

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
# Window background: the terminal is translucent (wezterm window_background_opacity),
# so the card must NOT paint an opaque fill — an escape-set bg renders fully opaque and
# prints a solid rectangle over the see-through terminal. Leave WBG empty so every card
# row inherits the real (translucent) terminal background behind it. The selection bar
# below still gets a solid accent fill so the focused row stands out.
WBG=""
SBG=$(bg 02)      # selection background

INNER=44   # interior content cells of the card
WTOT=$((INNER + 4))

# vis: visible length of a string with ANSI escapes stripped (grid math).
vis() {
# §.splinter/home/dot_config/television/executable_theme-preview/vis.fs
}
# repeat <glyph> <n>
rep() {
# §.splinter/home/dot_config/television/executable_theme-preview/rep.fs
}

# row: one card interior line. $1 = colored content (fg only, bg inherits), padded
# to INNER over the window background, framed by single-cell pads and borders.
row() {
# §.splinter/home/dot_config/television/executable_theme-preview/row.fs
}
# srow: a full-width selection bar (reverse-fill role) — selection bg, not window.
srow() {
# §.splinter/home/dot_config/television/executable_theme-preview/srow.fs
}
_row() {
# §.splinter/home/dot_config/television/executable_theme-preview/_row.fs
}

# ── banner (rounded box in the foreground colour — same INNER+4 width as the card) ──
HDR=$(fg 05)
sub="$system · $variant"
nl=$(vis "$name"); ((nl>INNER)) && { name="${name:0:$((INNER-1))}…"; nl=$INNER; }
sl=${#sub};        ((sl>INNER)) && { sub="${sub:0:$((INNER-1))}…"; sl=$INNER; }
printf '%b╭%s╮%b\n' "$HDR" "$(rep ─ $((INNER+2)))" "$R"
printf '%b│%b %b%s%b%*s %b│%b\n' "$HDR" "$R" "$HI" "$name" "$R" "$((INNER-nl))" "" "$HDR" "$R"
printf '%b│%b %b%s%b%*s %b│%b\n' "$HDR" "$R" "$DIM" "$sub" "$R" "$((INNER-sl))" "" "$HDR" "$R"
printf '%b╰%s╯%b\n\n' "$HDR" "$(rep ─ $((INNER+2)))" "$R"

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
swatch() {
# §.splinter/home/dot_config/television/executable_theme-preview/swatch.fs
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
