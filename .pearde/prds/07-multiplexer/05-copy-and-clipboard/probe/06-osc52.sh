#!/usr/bin/env bash
# Does tmux actually emit OSC 52 on copy, and what does it take?
# The OUTER tmux stands in for a terminal that honours OSC 52: it accepts
# the sequence from its pane and stores the text in its OWN paste buffer,
# so `tmux -L outer show-buffer` is a headless end-to-end assertion that
# the remote copy path works.
set -u
IN=osc_in; OUT=osc_out
D=$(mktemp -d)
trap 'tmux -L $OUT kill-server 2>/dev/null; tmux -L $IN kill-server 2>/dev/null; rm -rf "$D"' EXIT

run() { # $1 label  $2 extra inner conf lines  $3 copy command  $4 outer TERM
  tmux -L $OUT kill-server 2>/dev/null; tmux -L $IN kill-server 2>/dev/null; sleep 0.3
  { echo 'set -g mode-keys vi'; echo 'set -g remain-on-exit on'; echo "$2"; } > "$D/in.conf"
  tmux -L $IN -f "$D/in.conf" new-session -d -s main -x 80 -y 10 'cat'
  tmux -L $OUT -f /dev/null new-session -d -s o -x 80 -y 12 \
      "env TERM=$4 tmux -L $IN attach"
  sleep 0.8
  tmux -L $IN send-keys -t main 'MARKER-alpha-beta' Enter
  sleep 0.4
  tmux -L $IN copy-mode -t main
  tmux -L $IN send-keys -t main -X history-top
  tmux -L $IN send-keys -t main -X cursor-down
  tmux -L $IN send-keys -t main -X start-of-line
  tmux -L $IN send-keys -t main -X select-line
  tmux -L $IN send-keys -t main -X $3
  sleep 0.6
  printf '%-46s inner-buf=[%s] OUTER-buf=[%s] client-term=[%s] Ms=[%s]\n' "$1" \
    "$(tmux -L $IN show-buffer 2>/dev/null | tr -d '\n' | cut -c1-24)" \
    "$(tmux -L $OUT show-buffer 2>/dev/null | tr -d '\n' | cut -c1-24)" \
    "$(tmux -L $IN display -p -t main '#{client_termname}' 2>/dev/null)" \
    "$(tmux -L $IN display -p -t main '#{?#{client_control_mode},,}#{e|+|:0,0}' >/dev/null 2>&1; tmux -L $IN display -p '#{client_termfeatures}' 2>/dev/null)"
  tmux -L $OUT kill-server 2>/dev/null; sleep 0.2
  tmux -L $IN kill-server 2>/dev/null; sleep 0.3
}

echo "--- outer TERM=xterm-256color ---"
run "set-clipboard off, copy-selection"        'set -s set-clipboard off' copy-selection-and-cancel  xterm-256color
run "set-clipboard on,  copy-selection"        'set -s set-clipboard on'  copy-selection-and-cancel  xterm-256color
run "set-clipboard on + clipboard feature"     'set -s set-clipboard on
set -as terminal-features ",*:clipboard"'                                 copy-selection-and-cancel  xterm-256color
run "set-clipboard on + feature, copy-pipe /dev/null" 'set -s set-clipboard on
set -as terminal-features ",*:clipboard"'                  "copy-pipe-and-cancel 'cat >/dev/null'"  xterm-256color
echo "--- outer TERM=screen-256color (a minimal host) ---"
run "set-clipboard on + clipboard feature"     'set -s set-clipboard on
set -as terminal-features ",*:clipboard"'                                 copy-selection-and-cancel  screen-256color
