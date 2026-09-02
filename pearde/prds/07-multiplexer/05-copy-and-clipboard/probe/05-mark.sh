#!/usr/bin/env bash
# select-line leaves the cursor at end-of-line, so a cycle that wraps back
# to cell/word selects the WRONG thing unless the anchor is restored.
# Measure set-mark / jump-to-mark as the restore idiom.
set -u
L=mrk
D=$(mktemp -d)
trap 'tmux -L $L kill-server 2>/dev/null; rm -rf "$D"' EXIT
tmux -L $L kill-server 2>/dev/null; sleep 0.2
tmux -L $L -f /dev/null new-session -d -s s -x 80 -y 10 'cat'
tmux -L $L set -g mode-keys vi
sleep 0.3
tmux -L $L send-keys -t s 'alpha beta gamma delta' Enter
sleep 0.4

pos() { tmux -L $L display -p -t s "x=#{copy_cursor_x} y=#{copy_cursor_y}"; }
sel() {
  rm -f "$D/sel"
  tmux -L $L send-keys -t s -X copy-pipe-no-clear "cat > $D/sel"
  sleep 0.25
  printf '  %-30s sel=[%s] %s\n' "$1" "$(tr -d '\n' < "$D/sel" 2>/dev/null)" "$(pos)"
}
x() { tmux -L $L send-keys -t s -X "$@"; }

tmux -L $L copy-mode -t s
x history-top; x cursor-down; x start-of-line
for i in 1 2 3 4 5 6; do x cursor-right; done
echo "anchor: $(pos)"

x set-mark
x begin-selection ;               sel "1 cell"
x select-word ;                   sel "2 word"
x select-line ;                   sel "3 line"
echo "-- restore idiom: jump-to-mark then set-mark --"
x jump-to-mark ;                  sel "   after jump-to-mark"
x set-mark
x clear-selection
x begin-selection ;               sel "4 cell (wrapped)"
x select-word ;                   sel "5 word"
x select-line ;                   sel "6 line"
x jump-to-mark; x set-mark; x clear-selection; x begin-selection ; sel "7 cell (wrapped again)"

echo "-- does jump-to-mark work with no mark set? --"
tmux -L $L send-keys -t s -X cancel; sleep 0.2
tmux -L $L copy-mode -t s; sleep 0.2
x history-top; x cursor-down; x start-of-line; for i in 1 2 3; do x cursor-right; done
echo "   before: $(pos)"
x jump-to-mark
echo "   after jump-to-mark with no mark: $(pos)"
tmux -L $L kill-server 2>/dev/null
