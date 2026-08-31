#!/bin/bash
# P6 — against the REAL conf: (a) no byte leaks from a mistyped letter,
# (b) F5 F5 and F4 F4 put a literal key on the wire, (c) F6 forwards nothing.
set -u
CONF="$(cd "$(dirname "$0")/../../../.." && pwd)/home/dot_config/tmux/tmux.conf"
IN=p6-in; OUT=p6-out
D=$(mktemp -d); trap 'tmux -L $OUT kill-server 2>/dev/null; tmux -L $IN kill-server 2>/dev/null' EXIT
tmux -L $IN kill-server 2>/dev/null
# the pane runs `cat`, so every byte reaching the pty is on disk
tmux -L $IN -f "$CONF" new-session -d -s main -c "$D" "cat > $D/typed"
tmux -L $OUT kill-server 2>/dev/null
tmux -L $OUT new-session -d -s outer -c "$D" "tmux -L $IN attach"
sleep 1.2
k() { tmux -L $OUT send-keys -t outer "$@"; sleep 0.45; }

echo "=== (a) mistyped letters and Escape leak nothing"
for key in z q w Escape 0; do k F5; k "$key"; done
k F4; k z
k Enter; sleep 0.8
echo "  pane received:"; od -c "$D/typed" | head -2

echo "=== (b) the double-taps"
: > "$D/typed2"; tmux -L $IN kill-server 2>/dev/null; tmux -L $OUT kill-server 2>/dev/null; sleep 0.3
tmux -L $IN -f "$CONF" new-session -d -s main -c "$D" "cat > $D/typed2"
tmux -L $OUT new-session -d -s outer -c "$D" "tmux -L $IN attach"; sleep 1.2
k F5; k F5; k F4; k F4; k Enter; sleep 0.8
echo "  pane received (expect ESC[15~ then ESC[14~):"; od -c "$D/typed2" | head -2

echo "=== (c) F6 is bound in root and appears in no pushed table, and nothing sends it"
tmux -L $IN list-keys -T root  | grep -c 'F6' | sed 's/^/  root F6 binds: /'
tmux -L $IN list-keys -T jump  | grep -c 'F6' | sed 's/^/  jump F6 binds: /'
tmux -L $IN list-keys -T split | grep -c 'F6' | sed 's/^/  split F6 binds: /'
tmux -L $IN list-keys | grep -c 'send-keys F6' | sed 's/^/  send-keys F6 anywhere: /'
echo "D=$D"
