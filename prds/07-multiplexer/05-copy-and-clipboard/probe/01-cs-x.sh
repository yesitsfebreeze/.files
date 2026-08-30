#!/usr/bin/env bash
# Does Ctrl+Shift+X reach a tmux binding at all?
# Nested fixture (F14/F15): outer tmux pane runs `tmux -L inner attach`.
# send-keys C-S-x to the OUTER pane = a real keystroke into the INNER's
# key dispatch. The INNER must have extended-keys on BEFORE the client
# attaches, because that is when tmux emits the modifyOtherKeys / CSI-u
# request to its terminal.
set -u
IN=cs_in; OUT=cs_out
D=$(mktemp -d)
trap 'tmux -L $OUT kill-server 2>/dev/null; tmux -L $IN kill-server 2>/dev/null; rm -rf "$D"' EXIT

run() {  # $1 = inner extended-keys  $2 = inner extended-keys-format
  tmux -L $OUT kill-server 2>/dev/null; tmux -L $IN kill-server 2>/dev/null
  sleep 0.3
  cat > "$D/inner.conf" <<EOF
set -s extended-keys $1
set -s extended-keys-format $2
set -g remain-on-exit on
bind -n C-S-x run-shell "echo CSX >> $D/hits"
bind -n C-x   run-shell "echo PLAIN-CX >> $D/hits"
EOF
  : > "$D/hits"
  tmux -L $IN -f "$D/inner.conf" new-session -d -s main -x 80 -y 24
  tmux -L $OUT -f /dev/null new-session -d -s o -x 80 -y 24 "tmux -L $IN attach"
  sleep 0.8
  tmux -L $OUT send-keys -t o C-S-x
  sleep 0.8
  printf 'inner extended-keys=%-7s fmt=%-6s -> inner saw: [%s]\n' \
      "$1" "$2" "$(tr '\n' ' ' < "$D/hits")"
  tmux -L $OUT kill-server 2>/dev/null; sleep 0.2
  tmux -L $IN kill-server 2>/dev/null; sleep 0.3
}

run off    xterm
run on     xterm
run on     csi-u
run always xterm
run always csi-u
