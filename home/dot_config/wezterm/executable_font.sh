#!/bin/bash
# The `font` channel of the F8 overlay. WezTerm owns the font; this tells it
# which. manual → internals/wezterm, Font.
#
#   font.sh --list       monospace families, the current one first (tv source)
#   font.sh --preview F  show F in every attached window, unrecorded (tv preview)
#   font.sh --apply F    record F — wezterm.lua reads it on its reload watch
#   font.sh              drop the preview (Esc)
#
# The preview is OSC 1337 SetUserVar sent as tmux passthrough via each
# client's active pane (allow-passthrough in tmux.conf); wezterm.lua turns it into a
# per-window override. An empty value clears the override.

STATE="$HOME/.local/state/wezterm/font.txt"
cur=""
[[ -f "$STATE" ]] && read -r cur < "$STATE"

uservar() {
    local sock=() v tty
    v=$(printf '%s' "$1" | base64)
    [[ -n "${TMUX:-}" ]] && sock=(-S "${TMUX%%,*}")
    while IFS= read -r tty; do
        [[ "$tty" == /dev/* && -w "$tty" ]] &&
            printf '\033Ptmux;\033\033]1337;SetUserVar=font=%s\007\033\\' "$v" > "$tty" 2>/dev/null
    done < <(tmux "${sock[@]}" list-clients -F '#{pane_tty}' 2>/dev/null | sort -u)
}

id="${2:-}"
id="${id%% (current)}"
case "${1:-}" in
--list)
    [[ -n "$cur" ]] && echo "$cur (current)"
    fc-list :spacing=mono family | while IFS=, read -r f _; do
        [[ "$f" == .* || "$f" == *Emoji* || "$f" == "$cur" ]] || echo "$f"
    done | sort -u ;;
--preview)
    uservar "$id"
    printf '%s\n\n' "$id"
    printf '%s\n' 'The quick brown fox jumps over the lazy dog' \
        '0O o 1lI| {}[]() <= >= != -> => :: ~/ --' \
        'fn main() { let x = vec![1, 2, 3]; }' \
        '         ' ;;
--apply)
    mkdir -p "${STATE%/*}"
    printf '%s\n' "$id" > "$STATE"
    uservar "" ;;
*)
    uservar "" ;;
esac
exit 0
