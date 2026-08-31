#!/bin/bash
# P5 — drive the REAL conf's F4/F5 through real key dispatch (nested tmux).
set -u
CONF="$(cd "$(dirname "$0")/../../../.." && pwd)/home/dot_config/tmux/tmux.conf"
IN=p5-in; OUT=p5-out
D=$(mktemp -d); trap 'tmux -L $OUT kill-server 2>/dev/null; tmux -L $IN kill-server 2>/dev/null' EXIT
mkdir -p "$D/sess" "$D/pane" "$D/client"
SESS=$(cd "$D/sess" && pwd -P); PANE=$(cd "$D/pane" && pwd -P); CLIENT=$(cd "$D/client" && pwd -P)

tmux -L $IN kill-server 2>/dev/null
tmux -L $IN -f "$CONF" new-session -d -s main -c "$SESS"
tmux -L $OUT kill-server 2>/dev/null
tmux -L $OUT new-session -d -s outer -c "$CLIENT" "tmux -L $IN attach"
sleep 1.2
k() { tmux -L $OUT send-keys -t outer "$@"; sleep 0.5; }

echo "=== F5 4 on an empty session: creates window 4"
k F5; k 4; sleep 0.5
echo "  windows: $(tmux -L $IN list-windows -F '#{window_index}' | tr '\n' ' ')"
echo "  active:  $(tmux -L $IN display -p '#{window_index}')"
echo "  cwd of 4: $(tmux -L $IN display -p -t :4 '#{pane_current_path}')   (session path is $SESS)"

echo "=== F5 4 again: SELECTS, does not create a second"
k F5; k 1; sleep 0.3; k F5; k 4; sleep 0.5
echo "  windows: $(tmux -L $IN list-windows -F '#{window_index}' | tr '\n' ' ')  active=$(tmux -L $IN display -p '#{window_index}')"

echo "=== F4 Right / Down: splits inheriting the ACTIVE PANE cwd"
tmux -L $IN send-keys -t :4 "cd $PANE" Enter; sleep 0.8
k F4; k Right; sleep 0.6
echo "  panes in w4: $(tmux -L $IN list-panes -t :4 -F '#{pane_index}:#{pane_current_path}' | tr '\n' ' ')"
echo "  active pane: $(tmux -L $IN display -p -t :4 '#{pane_index}')"
k F4; k Down; sleep 0.6
echo "  panes in w4: $(tmux -L $IN list-panes -t :4 -F '#{pane_index}' | tr '\n' ' ')"

echo "=== F5 a / F5 b: pane letters"
k F5; k a; echo "  after F5 a -> pane $(tmux -L $IN display -p '#{pane_index}')"
k F5; k b; echo "  after F5 b -> pane $(tmux -L $IN display -p '#{pane_index}')"
k F5; k c; echo "  after F5 c -> pane $(tmux -L $IN display -p '#{pane_index}')"
echo "=== F5 z (unbound letter): cancels, types nothing, pane unchanged"
k F5; k z; echo "  table=$(tmux -L $IN display -p '#{client_key_table}') pane=$(tmux -L $IN display -p '#{pane_index}')"
echo "=== F5 h (letter for a pane that does not exist)"
k F5; k h; echo "  table=$(tmux -L $IN display -p '#{client_key_table}') pane=$(tmux -L $IN display -p '#{pane_index}')"
echo "D=$D"
