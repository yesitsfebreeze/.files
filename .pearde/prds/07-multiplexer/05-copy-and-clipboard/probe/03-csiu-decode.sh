#!/usr/bin/env bash
# Can tmux DECODE an extended-key sequence into a C-S-x binding?
# We drive a real client over a pty and write raw bytes into its stdin,
# which is what a terminal emulator does. `send-keys -H` is not usable:
# it writes to the PANE, never to tmux's key dispatch.
set -u
L=csiu
D=$(mktemp -d)
trap 'tmux -L $L kill-server 2>/dev/null; rm -rf "$D"' EXIT

# The outer tmux is only a pty carrier here: its pane runs the inner client
# and `send-keys -H` writes the raw bytes to that pane, i.e. into the inner
# tmux CLIENT's stdin -- exactly where a terminal would put them.
OUT=csiu_out

try() { # $1 label  $2... hex bytes for send-keys -H
  local label="$1"; shift
  tmux -L $OUT kill-server 2>/dev/null; tmux -L $L kill-server 2>/dev/null; sleep 0.3
  cat > "$D/in.conf" <<EOF
set -s extended-keys $EK
set -g remain-on-exit on
bind -n C-S-x run-shell "echo CSX >> $D/hits"
bind -n C-x   run-shell "echo CX >> $D/hits"
bind -n S-x   run-shell "echo SX >> $D/hits"
EOF
  : > "$D/hits"
  tmux -L $L -f "$D/in.conf" new-session -d -s main -x 80 -y 24
  tmux -L $OUT -f /dev/null new-session -d -s o -x 80 -y 24 "tmux -L $L attach"
  sleep 0.8
  tmux -L $OUT send-keys -t o -H "$@"
  sleep 0.8
  printf '  ek=%-7s %-34s -> [%s]\n' "$EK" "$label" "$(tr '\n' ' ' < "$D/hits")"
  tmux -L $OUT kill-server 2>/dev/null; sleep 0.2
  tmux -L $L kill-server 2>/dev/null; sleep 0.3
}

for EK in off on always; do
  # CSI 120 ; 6 u   = kitty/CSI-u form, unshifted 'x' (120), mods 6 = ctrl+shift
  try "CSI 120;6u"  1b 5b 31 32 30 3b 36 75
  # CSI 27 ; 6 ; 120 ~  = xterm modifyOtherKeys form
  try "CSI 27;6;120~" 1b 5b 32 37 3b 36 3b 31 32 30 7e
done
