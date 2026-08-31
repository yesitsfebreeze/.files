#!/usr/bin/env bash
# The other direction: when a client attaches, does `extended-keys on` make
# tmux ASK the client terminal for extended keys (an enable sequence on the
# wire, WezTerm's side of the pairing)? And is the `xterm*:extkeys`
# terminal-feature line load-bearing for that?
#
# Wire capture is 05-copy-and-clipboard C8's: `pipe-pane -O` on the OUTER
# pane that carries the inner client records every byte the inner tmux
# writes to its terminal.
set -u
OUT=ek2_out
IN=ek2_in
D=$(mktemp -d)
trap 'tmux -L $OUT kill-server 2>/dev/null; tmux -L $IN kill-server 2>/dev/null; rm -rf "$D"' EXIT

run() {  # $1=extended-keys  $2=extkeys feature 0/1  $3=client TERM
  tmux -L $OUT kill-server 2>/dev/null; tmux -L $IN kill-server 2>/dev/null; sleep 0.3
  {
    echo "set -s extended-keys $1"
    [ "$2" = 1 ] && echo "set -as terminal-features 'xterm*:extkeys'"
  } > "$D/inner.conf"
  : > "$D/wire"
  tmux -L $OUT -f /dev/null new-session -d -s o -x 80 -y 24
  tmux -L $OUT pipe-pane -o -t o 'cat >> '"$D"'/wire'
  sleep 0.2
  tmux -L $IN -f "$D/inner.conf" new-session -d -s main -x 80 -y 24
  # client TERM on argv: the outer pane's env would otherwise be tmux-256color
  tmux -L $OUT send-keys -t o "env TERM=$3 tmux -L $IN attach" Enter
  sleep 1.2
  printf '%s\n' "── ek=$1 extkeys=$2 client-TERM=$3 -- enable/request bytes on the CLIENT wire:"
  # only the escape-prefixed probes matter; strip the attach screen noise
  LC_ALL=C tr -d '\r' < "$D/wire" | LC_ALL=C grep -o $'\033\\[[^a-zA-Z]*[a-zA-Z]' \
      | LC_ALL=C sort -u | sed 's/^/    /' | head -20
  # and say plainly whether an extended-keys request went out
  if LC_ALL=C grep -q $'\033\\[>4' "$D/wire"; then
    echo "    YES modifyOtherKeys enable (CSI >4;..) on the wire"
  else
    echo "    no modifyOtherKeys enable on the wire"
  fi
  if LC_ALL=C grep -q $'\033\\[?u' "$D/wire"; then
    echo "    YES kitty protocol query (CSI ?u) on the wire"
  else
    echo "    no kitty protocol query on the wire"
  fi
  tmux -L $OUT kill-server 2>/dev/null; sleep 0.2
  tmux -L $IN kill-server 2>/dev/null; sleep 0.3
}

run off 0 xterm-256color
run on  0 xterm-256color
run on  1 xterm-256color
run on  1 screen-256color