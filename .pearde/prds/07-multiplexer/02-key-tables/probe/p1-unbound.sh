#!/bin/bash
# P1 — in a custom key table entered by `switch-client -T`, what happens to a
# key that is NOT bound in that table? Does it leak into the pane?
# Needs REAL key dispatch, so: outer tmux whose pane runs `tmux -L in attach`.
set -u
IN=p1-in; OUT=p1-out
D=$(mktemp -d); trap 'tmux -L $OUT kill-server 2>/dev/null; tmux -L $IN kill-server 2>/dev/null; ' EXIT
CONF=$D/conf
cat > "$CONF" <<'C'
set -g base-index 1
set -gw pane-base-index 1
set -g status off
bind -n F5 switch-client -T jump
bind -T jump 1 select-window -t :1
C
tmux -L $IN kill-server 2>/dev/null
tmux -L $IN -f "$CONF" new-session -d -s main -c "$D" 'cat > '"$D"'/typed'
tmux -L $OUT kill-server 2>/dev/null
tmux -L $OUT new-session -d -s outer -c "$D" "tmux -L $IN attach"
sleep 1

# press F5 then `z` (unbound in the jump table)
tmux -L $OUT send-keys -t outer F5
sleep 0.4
tmux -L $OUT send-keys -t outer z
sleep 0.8
tmux -L $OUT send-keys -t outer Enter
sleep 0.8
echo "--- after F5 z : pane received:"; od -c "$D/typed" 2>/dev/null | head -3
echo "--- inner key-table now: $(tmux -L $IN display -p '#{client_key_table}' 2>/dev/null)"

# control: plain `z` with no F5
tmux -L $OUT send-keys -t outer y
sleep 0.8
tmux -L $OUT send-keys -t outer Enter
sleep 0.8
echo "--- control, plain y : pane received:"; od -c "$D/typed" 2>/dev/null | head -3
echo "D=$D"
