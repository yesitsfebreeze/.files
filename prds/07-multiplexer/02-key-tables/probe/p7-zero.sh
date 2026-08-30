#!/bin/bash
set -u
CONF="$(cd "$(dirname "$0")/../../../.." && pwd)/home/dot_config/tmux/tmux.conf"
IN=p7-in; OUT=p7-out
D=$(mktemp -d); trap 'tmux -L $OUT kill-server 2>/dev/null; tmux -L $IN kill-server 2>/dev/null' EXIT
one() { # $1 second key, $2 tag
  tmux -L $IN kill-server 2>/dev/null; tmux -L $OUT kill-server 2>/dev/null; sleep 0.3
  : > "$D/t.$2"
  tmux -L $IN -f "$CONF" new-session -d -s main -c "$D" "cat > $D/t.$2"
  tmux -L $OUT new-session -d -s outer -c "$D" "tmux -L $IN attach"; sleep 1.2
  tmux -L $OUT send-keys -t outer F5; sleep 0.5
  tmux -L $OUT send-keys -t outer "$1"; sleep 0.6
  tmux -L $OUT send-keys -t outer Enter; sleep 0.8
  printf '  F5 %-8s table=%s pane=' "$1" "$(tmux -L $IN display -p '#{client_key_table}')"
  od -c "$D/t.$2" | head -1
}
one 0 zero
one z zed
one q que
one Escape esc
one Space spc
echo "--- is 0 bound anywhere?"; tmux -L $IN list-keys | grep -E '^bind-key +(-T root)? *0 ' || echo "  (no root 0 binding)"
tmux -L $IN list-keys -T root | head -20
