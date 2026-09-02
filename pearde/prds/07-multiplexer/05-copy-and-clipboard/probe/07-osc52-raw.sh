#!/usr/bin/env bash
# Does the inner tmux WRITE an OSC 52 to its client's tty?
# The client runs under `script`, so every byte tmux sends to the terminal
# is on disk. (F17: stdin stays /dev/null and remain-on-exit absorbs the ^D.)
set -u
IN=osc2_in; OUT=osc2_out
D=$(mktemp -d)
trap 'tmux -L $OUT kill-server 2>/dev/null; tmux -L $IN kill-server 2>/dev/null; rm -rf "$D"' EXIT

run() { # $1 label  $2 inner conf lines  $3 outer set-clipboard
  tmux -L $OUT kill-server 2>/dev/null; tmux -L $IN kill-server 2>/dev/null; sleep 0.3
  rm -f "$D/log"
  { echo 'set -g mode-keys vi'; echo 'set -g remain-on-exit on'; echo "$2"; } > "$D/in.conf"
  tmux -L $IN -f "$D/in.conf" new-session -d -s main -x 80 -y 10 'cat'
  printf 'set -s set-clipboard %s\nset -g remain-on-exit on\n' "$3" > "$D/out.conf"
  tmux -L $OUT -f "$D/out.conf" new-session -d -s o -x 80 -y 12 \
      "script -q $D/log tmux -L $IN attach < /dev/null"
  sleep 1.0
  tmux -L $IN send-keys -t main 'MARKER-alpha-beta' Enter
  sleep 0.4
  tmux -L $IN copy-mode -t main
  tmux -L $IN send-keys -t main -X history-top
  tmux -L $IN send-keys -t main -X cursor-down
  tmux -L $IN send-keys -t main -X start-of-line
  tmux -L $IN send-keys -t main -X select-line
  tmux -L $IN send-keys -t main -X copy-selection-and-cancel
  sleep 0.8
  printf '%-44s osc52-on-wire=[%s] OUTER-buf=[%s]\n' "$1" \
    "$(LC_ALL=C grep -a -o $'\033]52;[^\a\033]*' "$D/log" 2>/dev/null | head -1 | cat -v)" \
    "$(tmux -L $OUT show-buffer 2>/dev/null | tr -d '\n' | cut -c1-24)"
  tmux -L $OUT kill-server 2>/dev/null; sleep 0.2
  tmux -L $IN kill-server 2>/dev/null; sleep 0.3
}

run "inner clipboard=off"                    'set -s set-clipboard off' on
run "inner clipboard=on"                     'set -s set-clipboard on'  on
run "inner clipboard=on + *:clipboard"       'set -s set-clipboard on
set -as terminal-features ",*:clipboard"'                               on
run "inner on + clipboard, outer external"   'set -s set-clipboard on
set -as terminal-features ",*:clipboard"'                               external
