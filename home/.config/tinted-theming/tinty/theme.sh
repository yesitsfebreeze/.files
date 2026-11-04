#!/bin/bash
# shellcheck disable=SC2154  # baseXX are assigned by `printf -v` from the yaml
# The whole theme system: tinty keeps the scheme catalog (`tinty install`),
# this paints and records the pick. manual → internals/tmux, Palette delivery.
#
#   theme.sh             paint the current scheme (tinty hook, tmux attach, Esc)
#   theme.sh --apply ID  paint ID, record it as current and as its variant's
#                        slot (F5 t s, `theme`)
#   theme.sh --toggle    switch to the other variant's slot: dark <-> light (F5 t t)
#   theme.sh --preview ID  paint ID everywhere, unrecorded; print a swatch
#   theme.sh --list      current, then the curated list of its variant
#                        (tv source; themes.txt, else the whole catalog)
#
# Two channels: colors.conf for tmux's own surfaces, OSC 4/10/11/12 for the
# terminal. Preview drives both, so the screen around the picker looks exactly
# as the pick would: its tmux styles go to colors.preview.conf instead, and
# Esc or the pick re-sources colors.conf. The picker's popup sits on its own
# tmux server (`modal`), so a restyle here no longer redraws it.
#
# TRAP: every exec costs ~80 ms on this host (2026-09-23), so everything below
# is bash builtins and tmux is called once. grep|sed per colour took 5 s.

DATA="${XDG_DATA_HOME:-$HOME/.local/share}/tinted-theming/tinty"
SLOTS="${XDG_STATE_HOME:-$HOME/.local/state}/tinted-theming"
CONF="${XDG_CONFIG_HOME:-$HOME/.config}/tmux/colors.conf"

# yaml_of ID: the scheme file, or "". variant_of FILE: its `variant:` field.
yaml_of() {
    local f
    for f in "$DATA"/{repos/schemes,custom-schemes}/"${1%%-*}/${1#*-}".{yaml,yml}; do
        [[ -f "$f" ]] && { yaml="$f"; return; }
    done
    yaml=""
}
variant_of() {
    local l; variant=dark
    [[ -f "$1" ]] || return
    while IFS= read -r l; do
        [[ "$l" =~ ^variant:[[:space:]]*\"?([a-z]+) ]] && { variant="${BASH_REMATCH[1]}"; return; }
    done < "$1"
}

# `read`, never `$(< f)`: a subshell per file is a fork this host bills for.
# Two slots, dark and light: F5 t t swaps them, a pick overwrites its own.
# Ids read from files are validated too: a slot once held raw OSC bytes.
idre='^base(16|24)-[A-Za-z0-9._-]+$'
readid() { local v=""; [[ -f "$1" ]] && read -r v < "$1"; [[ "$v" =~ $idre ]] || v=""; printf -v "$2" '%s' "$v"; }
cur="" old=""; readid "$DATA/current_scheme" cur
yaml_of "$cur"; variant_of "$yaml"; active="$variant"

mode="${1:-}" id="${2:-}" id="${id%% (*}"  # --list tags the head " (current)"

case "$mode" in
--list)
    [[ -n "$cur" ]] && echo "$cur (current)"
    # themes.txt curates the ~900-scheme catalog down to the web's recurring
    # favourites and its most curious one-offs (ranked there). Entries keep
    # file order, but only ids that exist and match the active variant print.
    CURATED="${XDG_CONFIG_HOME:-$HOME/.config}/tinted-theming/tinty/themes.txt"
    if [[ -r "$CURATED" ]]; then
        while IFS= read -r id || [[ -n "$id" ]]; do
            id="${id%%#*}" id="${id//[[:space:]]/}"
            [[ "$id" =~ $idre && "$id" != "$cur" ]] || continue
            yaml_of "$id"; [[ -n "$yaml" ]] || continue
            variant_of "$yaml"
            [[ "$variant" == "$active" ]] && echo "$id"
        done < "$CURATED"
    else
        # No curated list: one rg, not a read per file; the filter is the variant.
        rg -l --sort path "^variant: *\"?$active" "$DATA"/{repos/schemes,custom-schemes}/base{16,24} 2>/dev/null |
        while IFS= read -r f; do
            s="${f%/*}" s="${s##*/}-${f##*/}" s="${s%.y*ml}"
            [[ "$s" != "$cur" ]] && echo "$s"
        done
    fi
    exit 0 ;;
--toggle)
    [[ "$active" == light ]] && want=dark || want=light
    # Remember the scheme being left, even one set outside --apply (tinty
    # directly, a first run) — else the way back falls to the default.
    [[ -n "$cur" ]] && { mkdir -p "$SLOTS"; printf '%s\n' "$cur" > "$SLOTS/$active.txt"; }
    readid "$SLOTS/$want.txt" id
    [[ -z "$id" && "$want" == dark ]] && id=base16-gruvbox-material-dark-medium
    [[ -z "$id" && "$want" == light ]] && id=base16-gruvbox-material-light-medium
    mode=--apply ;;
--preview) CONF="${CONF%.conf}.preview.conf" ;;
"") id="$cur" ;;
esac
# Every id — argument, slot file or tinty's record — must be a plain scheme
# name. A slot once came back prefixed with raw OSC bytes and F5 t t silently did
# nothing; refusing here keeps garbage out of every file written below.
[[ "$id" =~ $idre ]] || { [[ -n "$id" ]] && echo "theme.sh: not a scheme id" >&2; exit 0; }
[[ "$mode" == --apply && "$id" == "$cur" ]] && exit 0

system="${id%%-*}"
yaml_of "$id"; [[ -n "$yaml" ]] || exit 0

# Every `baseXX: "#hex"` lands in a lowercase-keyed variable `baseXX`.
name="$id" variant="?"
re='^[[:space:]]*base([0-9A-Fa-f]{2}):[[:space:]]*"?(#[0-9A-Fa-f]{6})'
while IFS= read -r l || [[ -n "$l" ]]; do
    if [[ "$l" =~ $re ]]; then
        k="${BASH_REMATCH[1]}"
        k="${k//A/a}" k="${k//B/b}" k="${k//C/c}" k="${k//D/d}" k="${k//E/e}" k="${k//F/f}"
        printf -v "base$k" '%s' "${BASH_REMATCH[2]}"
    elif [[ "$l" =~ ^(name|variant):[[:space:]]*\"?([^\"]*) ]]; then
        printf -v "${BASH_REMATCH[1]}" '%s' "${BASH_REMATCH[2]}"
    fi
done < "$yaml"
# A scheme that did not parse must never overwrite a good conf.
[[ -z "${base00:-}" || -z "${base05:-}" || -z "${base02:-}" || -z "${base03:-}" ]] && exit 0

# --palette ID: baseXX=#hex lines, tinted-nvim's fallback (nvim never parses a yaml).
[[ "$mode" == --palette ]] && { echo "variant=$variant"; for v in $(compgen -A variable base); do echo "$v=${!v}"; done; exit 0; }

# WezTerm's wallpaper tint lays base00 over the image (wezterm-bg tint N).
# Two ways in: the `bg` user var below, sent with the palette on every paint,
# recolours each open window at once (a window override, no config reload);
# this file, written only when it changes and never on a preview, is what a
# new window or a config reload reads. TRAP: not the file alone — the watch
# reload it fires took ~700 ms to reach the screen, too slow to browse with.
# Its dir is wezterm-bg's, no mkdir (an exec).
tbg="${XDG_STATE_HOME:-$HOME/.local/state}/wezterm/theme-bg"
if [[ "$mode" != --preview ]]; then
    [[ -f "$tbg" ]] && IFS= read -r oldbg < "$tbg"
    [[ "${oldbg:-}" == "$base00" ]] || printf '%s\n' "$base00" > "$tbg" 2>/dev/null
fi

# The inactive panes recede 45%: the foreground (base05) blended that far
# toward the background (base00), per scheme. A COLOUR, because tmux style
# syntax has no percentage and drops every attribute — `dim` emits nothing.
# manual → internals/tmux, "The inactive panes recede".
mix45() {
    local h="${1#\#}" g="${2#\#}" o="" i
    for i in 0 2 4; do
        printf -v o '%s%02x' "$o" $(( (0x${h:i:2} * 55 + 0x${g:i:2} * 45) / 100 ))
    done
    printf -v "$3" '#%s' "$o"
}
mix45 "$base05" "$base00" dim

# Only STYLES, never formats: tmux.conf owns the bar's shape and sets these
# same options with ANSI slots, so sourcing this is a pure override.
# Border roles follow tinted-tmux's own template (base24.mustache): inactive
# frame base01, active frame base04 — the theme's choice, not ours.
conf="# Generated by theme.sh — do not edit (scheme: $id)
set -g status-style 'bg=default,fg=$base03'
set -g message-style 'bg=$base02,fg=$base05'
set -g message-command-style 'bg=$base02,fg=$base05'
setw -g window-status-style 'bg=default,fg=$base03'
setw -g window-status-current-style 'fg=$base0d'
setw -g window-status-activity-style 'bg=default,fg=$base0a'
setw -g mode-style 'bg=$base02,fg=$base05'
setw -g pane-border-style 'fg=$base01'
setw -g pane-active-border-style 'fg=$base04'
setw -g window-style 'fg=$dim'
setw -g window-active-style 'fg=terminal,bg=terminal'"
if [[ -n "$CONF" ]]; then
    [[ -f "$CONF" ]] && IFS= read -r -d '' old < "$CONF"
    [[ "$conf"$'\n' == "$old" ]] || { mkdir -p "${CONF%/*}"; printf '%s\n' "$conf" > "$CONF"; }
fi

# OSC 4 slots 0-15 (base16 brights reuse the normal colours), 18 base01 (the
# tmux-sys gauges' empty cells), then 10/11/12 foreground, background, cursor.
# TRAP: ESC held as a character, never through `printf %b` — %b doubled a
# backslash and corrupted every slot after the first (2026-09-01).
E=$'\033' ST=$'\033\\' seq="" i=0
for c in "$base00" "$base08" "$base0b" "$base0a" "$base0d" "$base0e" "$base0c" "$base05" \
         "$base03" "$base08" "$base0b" "$base0a" "$base0d" "$base0e" "$base0c" "${base07:-$base05}"; do
    seq+="$E]4;$i;$c$ST"; i=$((i + 1))
done
seq+="$E]4;18;$base01$ST$E]10;$base05$ST$E]11;$base00$ST$E]12;$base05$ST"
seq+="$E]1337;SetUserVar=bg=$(printf '%s' "$base00" | base64)$ST"

# Sent as tmux PASSTHROUGH into each client's active pane, never written raw
# to the client tty: a raw write lands in the middle of tmux's own escape
# stream and garbles what it is drawing — the popup's top border broke that
# way. tmux forwards a passthrough between its own sequences, whole.
# TRAP: `$TMUX` names the CALLING shell's server — reach the one you are
# looking at, not whichever owns the default socket.
pt="${E}Ptmux;${seq//$E/$E$E}${E}\\"
sock=(); [[ -n "${TMUX:-}" ]] && sock=(-S "${TMUX%%,*}")
src=(); [[ -n "$CONF" ]] && src=(source-file "$CONF" \;)
while IFS= read -r tty; do
    [[ "$tty" == /dev/* && -w "$tty" ]] && printf '%s' "$pt" > "$tty" 2>/dev/null
done < <(tmux "${sock[@]}" "${src[@]}" list-clients -F '#{pane_tty}' 2>/dev/null | sort -u)

case "$mode" in
--apply)
    # Record the pick exactly as tinty would; no `tinty apply` — it only wrote
    # this same file again, late enough to revert a quick second F5 t t.
    printf '%s\n' "$id" > "$DATA/current_scheme"
    mkdir -p "$SLOTS"; printf '%s\n' "$id" > "$SLOTS/${variant:-dark}.txt" ;;
--preview)
    rgb() { local h="${1#\#}"; printf -v "$2" '\033[38;2;%d;%d;%dm' "0x${h:0:2}" "0x${h:2:2}" "0x${h:4:2}"; }
    R=$'\033[0m'; rgb "$base05" HI; rgb "$base03" DIM
    printf '%s\033[1m%s%s  %s(%s · %s)%s\n\n%s── palette ──────────────────────%s\n' \
        "$HI" "$name" "$R" "$DIM" "$system" "$variant" "$R" "$DIM" "$R"
    keys=(00 01 02 03 04 05 06 07 08 09 0a 0b 0c 0d 0e 0f)
    [[ "$system" == base24 ]] && keys+=(10 11 12 13 14 15 16 17)
    for i in "${!keys[@]}"; do
        v="base${keys[i]}" v="${!v:-#000000}"; rgb "$v" C
        (( i % 2 )) && printf '   ' || printf ' '
        printf '%s████%s %s%s%s %s%s%s' "$C" "$R" "$HI" "${keys[i]}" "$R" "$DIM" "$v" "$R"
        (( i % 2 )) && echo
    done ;;
esac
exit 0
