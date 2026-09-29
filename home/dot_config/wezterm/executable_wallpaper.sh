#!/bin/bash
# The `wallpaper` channel of the F5 t w picker. wezterm-bg owns the image;
# this lists ~/wallpapers and previews a row by putting it behind the terminal.
# manual → internals/wezterm, Background.
#
#   wallpaper.sh --list       images in ~/wallpapers, the current one first, `off` last
#   wallpaper.sh --preview F  put F behind every window (wezterm-bg F), header below
#   wallpaper.sh --apply F    keep F
#   wallpaper.sh dark|blur ±N nudge darkness or blur (px), print the header
#   wallpaper.sh              put back what the picker opened on (Esc)
#
# A preview IS a wezterm-bg apply — wezterm.lua's reload watch repaints every
# window — so the state the picker opened on is parked in background.orig and
# Esc re-renders it. An empty .orig means there was no image.

DIR="$HOME/.local/state/wezterm"
STATE="$DIR/background.txt"
ORIG="$DIR/background.orig"
WALL="${WALLPAPERS:-$HOME/wallpapers}"
cur="" blur=20 dark=60
[[ -f "$STATE" ]] && { read -r cur; read -r blur; read -r dark; } < "$STATE"
[[ -f "$DIR/background" ]] || cur=""

id="${2:-}"
id="${id%% (current)}"
[[ "$id" == off || "$id" == "" || "$id" == /* ]] || id="$WALL/$id"
show() { if [[ "$1" == off ]]; then wezterm-bg off; else wezterm-bg "$1"; fi; }
park() { [[ -f "$ORIG" ]] || { [[ -n "$cur" ]] && cat "$STATE" || :; } > "$ORIG"; }
header() { printf 'dark %s  ←/→      blur %spx  shift-←/→\n' "$dark" "$blur"; }
case "${1:-}" in
--list)
    [[ -n "$cur" ]] && echo "${cur#"$WALL"/} (current)"
    find "$WALL" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.gif' -o -iname '*.webp' \) \
        -not -path "$cur" -exec basename {} \; | sort
    [[ -n "$cur" ]] && echo off || echo "off (current)" ;;
--preview)
    park
    [[ "$id" == "$cur" ]] || show "$id"
    header
    [[ "$id" == off ]] || magick identify -format '\n%f  %wx%h\n' "$id" 2>/dev/null ;;
--apply) rm -f "$ORIG"; [[ "$id" == "$cur" ]] || show "$id" ;;
dark|blur)
    park
    v=$([[ $1 == dark ]] && echo "$dark" || echo "$blur")
    ((v += ${2:-0})); ((v < 0)) && v=0
    wezterm-bg "$1" "$v"
    { read -r _; read -r blur; read -r dark; } < "$STATE"
    header ;;
*)
    [[ -f "$ORIG" ]] || exit 0
    if [[ -s "$ORIG" ]]; then cp "$ORIG" "$STATE"; show "$(head -1 "$ORIG")"; else show off; fi
    rm -f "$ORIG" ;;
esac
exit 0
