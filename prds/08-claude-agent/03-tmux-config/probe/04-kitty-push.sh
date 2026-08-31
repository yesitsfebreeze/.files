#!/usr/bin/env bash
# Probe 01's kitty arm pushed CSI >1u (flags 1) and tmux still sent legacy
# bytes. Does tmux track the kitty protocol per pane at all, or only
# modifyOtherKeys? Send each enable to /dev/tty of a LIVE pane -- a heredoc
# mangled the \033 on the new-session argv -- then press Shift+Enter.
set -u
OUT=ek4_out; IN=ek4_in
tmux -L $OUT kill-server 2>/dev/null 2>&1
tmux -L $IN kill-server 2>/dev/null 2>&1
D=$(mktemp -d)
trap 'tmux -L $OUT kill-server 2>/dev/null 2>&1; tmux -L $IN kill-server 2>/dev/null 2>&1; rm -rf "$D"' EXIT

run() {  # $1 = enable as printf %b   $2 = label
  tmux -L $OUT kill-server 2>/dev/null 2>&1; tmux -L $IN kill-server 2>/dev/null 2>&1; sleep 0.3
  cat > "$D/inner.conf" <<EOF
set -s extended-keys on
set -g remain-on-exit on
EOF
  : > "$D/raw"
  tmux -L $IN -f "$D/inner.conf" new-session -d -s main -x 80 -y 24
  tmux -L $OUT -f /dev/null new-session -d -s o -x 80 -y 24 "env TERM=xterm-256color tmux -L $IN attach"
  sleep 0.8
  P=$(tmux -L $IN list-panes -F '#{pane_id}')
  tmux -L $IN respawn-pane -k -t "$P" "printf '$1' > /dev/tty; stty raw -echo; exec dd bs=1 of=$D/raw 2>/dev/null"
  sleep 0.5
  tmux -L $OUT send-keys -t o -H 1b 5b 32 37 3b 32 3b 31 33 7e   # shift+enter, modifyOtherKeys spelling
  sleep 0.4
  printf '%-26s -> pane got: ' "$2"
  od -c "$D/raw" | head -2
  tmux -L $OUT kill-server 2>/dev/null 2>&1; sleep 0.2
  tmux -L $IN kill-server 2>/dev/null 2>&1; sleep 0.3
}

run '\033[>4;2m'   'modifyOtherKeys mode 2'
run '\033[>4;1m'   'modifyOtherKeys mode 1 (again)'
run '\033[>1u'     'kitty push flags 1'
run '\033[>15u'    'kitty push flags 15'
run '\033[=15;1u'  'kitty set flags 15'
