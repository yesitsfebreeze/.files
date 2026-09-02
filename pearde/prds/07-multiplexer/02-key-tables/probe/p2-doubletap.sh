#!/bin/bash
# P2 — Q10. Does `bind -T jump F5 send-keys F5` forward a literal F5 inward?
# And WITHOUT that bind, does F5 F5 fall back to the root table's F5 bind
# (re-pushing jump) or get dropped?
set -u
IN=p2-in; OUT=p2-out
D=$(mktemp -d); trap 'tmux -L $OUT kill-server 2>/dev/null; tmux -L $IN kill-server 2>/dev/null' EXIT

run() { # $1 = conf body, $2 = keys after the first F5, $3 = label
  local conf=$D/conf.$3
  { echo 'set -g status off'; echo 'set -g base-index 1'; printf '%s\n' "$1"; } > "$conf"
  tmux -L $IN kill-server 2>/dev/null; tmux -L $OUT kill-server 2>/dev/null
  : > "$D/typed.$3"
  tmux -L $IN -f "$conf" new-session -d -s main -c "$D" "cat > $D/typed.$3"
  tmux -L $OUT new-session -d -s outer -c "$D" "tmux -L $IN attach"
  sleep 1
  tmux -L $OUT send-keys -t outer F5; sleep 0.4
  tmux -L $OUT send-keys -t outer $2; sleep 0.6; tmux -L $OUT send-keys -t outer Enter; sleep 1
  echo "[$3] key-table after: $(tmux -L $IN display -p '#{client_key_table}')"
  echo "[$3] pane received:"; od -c "$D/typed.$3" | head -3
  tmux -L $OUT kill-server 2>/dev/null; tmux -L $IN kill-server 2>/dev/null; sleep 0.3
}

echo "=== A: with the forwarding bind, F5 F5 ==="
run 'bind -n F5 switch-client -T jump
bind -T jump 1 select-window -t :1
bind -T jump F5 send-keys F5' F5 A

echo "=== B: WITHOUT the forwarding bind, F5 F5 ==="
run 'bind -n F5 switch-client -T jump
bind -T jump 1 select-window -t :1' F5 B

echo "=== C: control, a bare F5 with NO table at all reaches the pane ==="
run 'bind -T jump 1 select-window -t :1' F5 C
