#!/usr/bin/env bash
# What does tmux SEND a pane program, under the two lines Claude Code's docs
# require -- and does it disturb a program that never asked (nushell)?
#
# Nested fixture (the F14/F15 shape of 07-multiplexer/05): an OUTER tmux pane
# runs the INNER client, `send-keys -H` to the outer pane writes raw bytes to
# the inner CLIENT's stdin -- exactly what a terminal emulator does. The inner
# pane's program is a collector that (optionally) first enables an extended
# key protocol, then dumps every byte it receives to a file.
set -u
OUT=ek_out
IN=ek_in
D=$(mktemp -d)
trap 'tmux -L $OUT kill-server 2>/dev/null; tmux -L $IN kill-server 2>/dev/null; rm -rf "$D"' EXIT

# the collector: $1 = mode (none|mok|kitty), $2 = output file
cat > "$D/cap.sh" <<'EOF'
#!/bin/sh
case "$1" in
  mok)   printf '\033[>4;1m' ;;   # xterm modifyOtherKeys level 1 enable
  kitty) printf '\033[>1u'  ;;   # kitty keyboard protocol push, flags 1
esac
# raw: no ICRNL (CR must not read back as NL), no canonical line buffering
# (would swallow every byte after the last \n when the pane is killed)
stty raw -echo 2>/dev/null
# dd with bs=1 writes every byte as it is read -- cat's stdio buffer would
# be lost to the SIGKILL when the server dies
exec dd bs=1 of="$2" 2>/dev/null
EOF
chmod +x "$D/cap.sh"

# send one key spelling, given as hex pairs, into the inner client
keys() {  # hex bytes on argv
  tmux -L $OUT send-keys -t o -H "$@"
  sleep 0.25
}

run() {  # $1=extended-keys  $2=extkeys feature 0/1  $3=pane request mode  $4=client TERM
  tmux -L $OUT kill-server 2>/dev/null; tmux -L $IN kill-server 2>/dev/null; sleep 0.3
  {
    echo "set -s extended-keys $1"
    [ "$2" = 1 ] && echo "set -as terminal-features 'xterm*:extkeys'"
    echo "set -g remain-on-exit on"
  } > "$D/inner.conf"
  : > "$D/raw"
  tmux -L $IN -f "$D/inner.conf" new-session -d -s main -x 80 -y 24 "$D/cap.sh" "$3" "$D/raw"
  tmux -L $OUT -f /dev/null new-session -d -s o -x 80 -y 24 "env TERM=$4 tmux -L $IN attach"
  sleep 0.8

  # the inputs: plain enter, shift+enter both spellings, ctrl+x, up-arrow
  keys 0d                        # Enter, legacy \r
  keys 1b 5b 32 37 3b 32 3b 31 33 7e   # Shift+Enter as CSI 27;2;13~ (modifyOtherKeys)
  keys 1b 5b 31 33 3b 32 75            # Shift+Enter as CSI 13;2u (kitty/CSI-u)
  keys 18                        # Ctrl+X, legacy
  keys 1b 5b 41                  # arrow up, legacy
  sleep 0.5
  printf '%s\n' "── ek=$1 extkeys=$2 request=$3 client-TERM=$4"
  od -c "$D/raw" | sed 's/^/    /'
  tmux -L $OUT kill-server 2>/dev/null; sleep 0.2
  tmux -L $IN kill-server 2>/dev/null; sleep 0.3
}

for EK in off on; do
  for FEAT in 0 1; do
    for REQ in none mok kitty; do
      run "$EK" "$FEAT" "$REQ" xterm-256color
    done
  done
done