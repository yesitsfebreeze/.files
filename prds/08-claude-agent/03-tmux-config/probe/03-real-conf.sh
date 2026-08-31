#!/usr/bin/env bash
# The shipped conf, with the docs' two lines appended, in the load fixture:
# does the extension load stderr-clean, read back as set, and leave the
# C2/C1 behaviour (decode unconditional, plain C-x untouched) as measured?
set -u
D=$(mktemp -d)
OUT=rc_out; IN=rc_in
trap 'tmux -L $OUT kill-server 2>/dev/null; tmux -L $IN kill-server 2>/dev/null; rm -rf "$D"' EXIT
CONF=/Users/feb/dev/dotfiles/home/dot_config/tmux/tmux.conf
cp "$CONF" "$D/with.conf"
cat >> "$D/with.conf" <<'EOF'

# ── 08-claude-agent/03-tmux-config: Claude Code inside tmux ───────────────
# probe/03-real-conf.sh: the docs' two lines, appended.
set -s extended-keys on
set -as terminal-features 'xterm*:extkeys'
EOF
tmux -L $IN -f "$D/with.conf" new-session -d -s main -x 80 -y 24 2> "$D/err"
echo "load rc=$?  stderr=[$(cat "$D/err")]"
for opt in extended-keys default-terminal escape-time focus-events allow-passthrough base-index renumber-windows; do
  printf '  %-20s = %s\n' "$opt" "$(tmux -L $IN show -s -g "$opt" 2>/dev/null)"
done
tmux -L $IN show -s -g terminal-features | sed 's/^/  terminal-features /'
# plain C-x still reaches the pane (C3)
tmux -L $IN new-window -d -t main -n cap 'exec dd bs=1 of='"$D"'/raw 2>/dev/null'
tmux -L $IN list-windows -t main | sed 's/^/  win: /'
W=$(tmux -L $IN list-windows -t main -F '#{window_name}' | grep cap)
tmux -L $IN send-keys -t "$W" C-x
sleep 0.4
echo "  after C-x, collector holds: [$(od -c "$D/raw" 2>/dev/null | head -2 | tr -s ' ')]"
# C-S-x decode still unconditional (C2) -- raw CSI u into a client
tmux -L $OUT -f /dev/null new-session -d -s o -x 80 -y 24 2>/dev/null
cat > "$D/in2.conf" <<EOF
set -s extended-keys on
set -g remain-on-exit on
bind -n C-S-x run-shell "echo CSX >> $D/hits"
bind -n C-x   run-shell "echo PLAIN-CX >> $D/hits"
EOF
tmux -L $IN kill-server 2>/dev/null
tmux -L $IN -f "$D/in2.conf" new-session -d -s main -x 80 -y 24
tmux -L $OUT -f /dev/null new-session -d -s o2 -x 80 -y 24 "tmux -L $IN attach"
sleep 0.8
tmux -L $OUT send-keys -t o2 -H 1b 5b 31 32 30 3b 36 75
sleep 0.6
echo "  CSI 120;6u into a client of an extended-keys-on server: [$(tr '\n' ' ' < "$D/hits" 2>/dev/null)]"
tmux -L $OUT kill-server 2>/dev/null; tmux -L $IN kill-server 2>/dev/null
