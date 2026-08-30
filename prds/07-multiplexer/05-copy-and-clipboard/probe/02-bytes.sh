#!/usr/bin/env bash
# What bytes does tmux (acting as the terminal) send to a pane for C-S-x,
# with and without the pane having requested extended keys?
set -u
L=byt
D=$(mktemp -d); trap 'tmux -L $L kill-server 2>/dev/null; rm -rf "$D"' EXIT

probe() { # $1 label  $2 request-sequence (printf form, may be empty)
  tmux -L $L kill-server 2>/dev/null; sleep 0.3
  tmux -L $L -f /dev/null new-session -d -s s -x 80 -y 24 \
      "sh -c 'printf %b \"$2\"; stty raw -echo; cat -v > $D/out; :'"
  sleep 0.6
  tmux -L $L send-keys -t s C-S-x
  tmux -L $L send-keys -t s C-x
  tmux -L $L send-keys -t s M-S-x
  sleep 0.6
  tmux -L $L kill-server 2>/dev/null; sleep 0.3
  printf '%-24s -> %s\n' "$1" "$(cat -v "$D/out" 2>/dev/null | tr -d '\n')"
  : > "$D/out"
}

probe "no request"        ""
probe "modifyOtherKeys=2" "\\\\033[>4;2m"
probe "CSI-u (kitty >1u)" "\\\\033[>1u"
probe "DECSET 2027"       "\\\\033[?2027h"
