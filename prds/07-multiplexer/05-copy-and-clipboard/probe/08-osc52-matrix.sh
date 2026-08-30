#!/usr/bin/env bash
# What does it take for tmux to put an OSC 52 on the wire?
# Capture: the OUTER tmux's `pipe-pane -O` on the pane running the inner
# client records every byte the inner tmux writes to its terminal.
# (`script` was tried first and logs nothing usable here -- it buffers and
# the buffer dies with the pane.)
set -u
IN=m_in; OUT=m_out
D=$(mktemp -d)
trap 'tmux -L $OUT kill-server 2>/dev/null; tmux -L $IN kill-server 2>/dev/null; rm -rf "$D"' EXIT

run() { # $1 label  $2 inner conf lines  $3 client TERM  $4 copy command
  tmux -L $OUT kill-server 2>/dev/null; tmux -L $IN kill-server 2>/dev/null; sleep 0.3
  rm -f "$D/log"; : > "$D/log"
  { echo 'set -g mode-keys vi'; echo 'set -g remain-on-exit on'; echo "$2"; } > "$D/in.conf"
  tmux -L $IN -f "$D/in.conf" new-session -d -s main -x 80 -y 10 'cat'
  tmux -L $OUT -f /dev/null new-session -d -s o -x 80 -y 12 "env TERM=$3 tmux -L $IN attach"
  sleep 1.0
  tmux -L $OUT pipe-pane -O -t o "cat >> $D/log"
  sleep 0.3
  tmux -L $IN send-keys -t main 'MARKER-alpha-beta' Enter; sleep 0.5
  tmux -L $IN copy-mode -t main; sleep 0.2
  tmux -L $IN send-keys -t main -X history-top
  tmux -L $IN send-keys -t main -X cursor-down
  tmux -L $IN send-keys -t main -X select-line
  eval "tmux -L $IN send-keys -t main -X $4"
  sleep 0.8
  printf '%-52s TERM=%-16s osc52=[%s] buf=[%s]\n' "$1" "$3" \
    "$(LC_ALL=C grep -a -o ']52;[a-zA-Z0-9;+/=]*' "$D/log" | head -1)" \
    "$(tmux -L $IN show-buffer 2>/dev/null | tr -d '\n' | cut -c1-20)"
  tmux -L $OUT kill-server 2>/dev/null; sleep 0.2
  tmux -L $IN kill-server 2>/dev/null; sleep 0.3
}

CLIP='set -as terminal-features ",*:clipboard"'
run "clipboard=external (tmux default)" 'set -s set-clipboard external' xterm-256color   copy-selection-and-cancel
run "clipboard=off"                     'set -s set-clipboard off'      xterm-256color   copy-selection-and-cancel
run "clipboard=on"                      'set -s set-clipboard on'       xterm-256color   copy-selection-and-cancel
run "clipboard=on, TERM=screen-256color" 'set -s set-clipboard on'      screen-256color  copy-selection-and-cancel
run "clipboard=on + *:clipboard, screen" "set -s set-clipboard on
$CLIP"                                                                  screen-256color  copy-selection-and-cancel
run "clipboard=on, TERM=vt100"          'set -s set-clipboard on'       vt100            copy-selection-and-cancel
run "clipboard=on + *:clipboard, vt100" "set -s set-clipboard on
$CLIP"                                                                  vt100            copy-selection-and-cancel
run "clipboard=on, copy-pipe to a command" 'set -s set-clipboard on'    xterm-256color   "copy-pipe-and-cancel 'cat >/dev/null'"
