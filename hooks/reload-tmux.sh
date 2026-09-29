#!/bin/sh
# deploy hook — a running tmux server keeps the config it started with, so a
# deploy that changed tmux.conf or cockpit.json reloads it; otherwise a new
# binding or cockpit row exists on disk and not on the keyboard. Reloaded
# every deploy (source-file is idempotent), which is the same guarantee the
# old chezmoi hash-trick bought.
tmux info >/dev/null 2>&1 || exit 0
tmux source-file "${XDG_CONFIG_HOME:-$HOME/.config}/tmux/tmux.conf"
# terminal-features apply only at attach: a client that attached before
# `sync` was set keeps repainting popups as erase-then-draw. Say so on it.
tmux list-clients -F '#{client_tty} ,#{client_termfeatures},' | grep -v ',sync,' |
    while read -r tty _; do tmux display -c "$tty" -d 5000 'no sync on this client, redraws flicker: tmux detach-client -E "tmux attach"'; done
