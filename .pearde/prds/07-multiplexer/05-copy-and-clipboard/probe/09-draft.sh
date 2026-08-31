#!/usr/bin/env bash
# Drive the draft conf through REAL key dispatch (F14/F15 nested fixture):
# the outer tmux's pane runs the inner client, so send-keys to the outer
# pane is a keystroke into the inner tmux's key tables.
set -u
IN=d_in; OUT=d_out
D=$(mktemp -d)
CONF=$(cd "$(dirname "$0")" && pwd)/copy.conf.draft
trap 'tmux -L $OUT kill-server 2>/dev/null; tmux -L $IN kill-server 2>/dev/null; rm -rf "$D"' EXIT
tmux -L $OUT kill-server 2>/dev/null; tmux -L $IN kill-server 2>/dev/null; sleep 0.3

# a fake pbcopy so the local arm is provable without touching the real one
mkdir -p "$D/bin"
cat > "$D/bin/pbcopy" <<EOF
#!/bin/sh
cat > "$D/pbcopy.out"
EOF
chmod +x "$D/bin/pbcopy"

{ cat "$CONF"; echo 'set -g remain-on-exit on'; } > "$D/in.conf"
echo "== conf parse =="
PATH="$D/bin:$PATH" tmux -L $IN -f "$D/in.conf" new-session -d -s main -x 80 -y 12 'cat'
echo "  rc=$?  sink=[$(tmux -L $IN show -gv @copy-sink)]  clip=[$(tmux -L $IN show -sv set-clipboard)] mode-keys=[$(tmux -L $IN show -gwv mode-keys)]"
tmux -L $IN list-keys -T root | grep -c 'C-S-x' | sed 's/^/  root C-S-x binds: /'
tmux -L $IN list-keys -T copy-mode-vi | grep -E '^bind-key +-T copy-mode-vi (c|y) ' | sed 's/^/  /' | cut -c1-100

tmux -L $OUT -f /dev/null new-session -d -s o -x 80 -y 14 "tmux -L $IN attach"
sleep 1.0
tmux -L $OUT pipe-pane -O -t o "cat >> $D/wire"
tmux -L $IN send-keys -t main 'alpha beta gamma delta' Enter
sleep 0.5

key()  { tmux -L $OUT send-keys -t o "$@"; sleep 0.35; }
raw()  { tmux -L $OUT send-keys -t o -H "$@"; sleep 0.35; }
state() {
  rm -f "$D/sel"
  tmux -L $IN send-keys -t main -X copy-pipe-no-clear "cat > $D/sel" 2>/dev/null
  sleep 0.25
  printf '  %-26s mode=[%-9s] cyc=[%-4s] sel=[%s]\n' "$1" \
    "$(tmux -L $IN display -p -t main '#{pane_mode}')" \
    "$(tmux -L $IN display -p -t main '#{@copy-cycle}')" \
    "$(tr -d '\n' < "$D/sel" 2>/dev/null)"
}

echo "== C-S-x via a real keystroke =="
state "before"
# CSI 120;6u -- what a CSI-u capable terminal sends for ctrl+shift+x
raw 1b 5b 31 32 30 3b 36 75
state "after C-S-x"

echo "== navigate to 'beta', then the c-cycle by real keys =="
key g; key j; key 0; key l; key l; key l; key l; key l; key l
state "cursor on beta"
key c ; state "c 1"
key c ; state "c 2"
key c ; state "c 3"
key c ; state "c 4 (wrap)"
key c ; state "c 5"

echo "== y copies through the pbcopy arm =="
key c   # back to cell? -> line at 5, so 6 = cell
key c   # word
state "before y (word)"
key y
sleep 0.6
printf '  after y: mode=[%s] cyc=[%s] pbcopy.out=[%s] osc52=[%s]\n' \
  "$(tmux -L $IN display -p -t main '#{pane_mode}')" \
  "$(tmux -L $IN display -p -t main '#{@copy-cycle}')" \
  "$(tr -d '\n' < "$D/pbcopy.out" 2>/dev/null)" \
  "$(LC_ALL=C grep -a -o ']52;[a-zA-Z0-9;+/=]*' "$D/wire" | head -1)"
