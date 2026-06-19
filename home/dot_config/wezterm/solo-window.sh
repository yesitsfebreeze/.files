#!/usr/bin/env bash
# Solo the terminal on Linux: minimize every window except the focused one
# (WezTerm — the keybinding only fires while it has focus). Invoked by the WezTerm
# CTRL+SHIFT+M binding via background_child_process.
set -euo pipefail

if [ -n "${WAYLAND_DISPLAY:-}" ]; then
    # Wayland's security model forbids a client from minimizing OTHER clients, so
    # there is no portable path — it is compositor-specific and often impossible.
    if command -v hyprctl >/dev/null 2>&1; then
        # Hyprland has no real "minimize"; approximate it by stashing every other
        # window in a hidden special workspace. Bring them back with:
        #   hyprctl dispatch togglespecialworkspace minimized
        active=$(hyprctl -j activewindow | grep -om1 '0x[0-9a-f]*')
        hyprctl -j clients | grep -o '"address": *"0x[0-9a-f]*"' | grep -o '0x[0-9a-f]*' \
            | while read -r addr; do
                [ "$addr" = "$active" ] && continue
                hyprctl dispatch movetoworkspacesilent "special:minimized,address:$addr" >/dev/null
            done
        exit 0
    fi
    echo "solo-window: this Wayland compositor has no supported minimize-others path" >&2
    exit 0
fi

# X11: minimize every managed window except the active one.
if ! command -v xdotool >/dev/null 2>&1 || ! command -v wmctrl >/dev/null 2>&1; then
    echo "solo-window: X11 path needs both xdotool and wmctrl installed" >&2
    exit 1
fi
active=$(xdotool getactivewindow)
# wmctrl -l lists managed top-level windows as hex ids; $((hex)) → decimal lets us
# compare numerically against xdotool's decimal id without leading-zero pitfalls.
wmctrl -l | awk '{print $1}' | while read -r wid; do
    [ "$((wid))" = "$active" ] && continue
    xdotool windowminimize "$((wid))" 2>/dev/null || true
done
