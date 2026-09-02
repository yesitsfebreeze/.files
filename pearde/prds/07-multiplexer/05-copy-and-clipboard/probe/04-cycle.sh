#!/usr/bin/env bash
# The c-cycle mechanics: what cell / word / line selection actually yields,
# whether a pane user option is readable from a format, and whether
# re-entering copy mode carries a stale selection.
set -u
L=cyc
D=$(mktemp -d)
trap 'tmux -L $L kill-server 2>/dev/null; rm -rf "$D"' EXIT
tmux -L $L kill-server 2>/dev/null; sleep 0.2

tmux -L $L -f /dev/null new-session -d -s s -x 80 -y 10 'cat'
tmux -L $L set -g mode-keys vi
sleep 0.3
# Known content. printf into the pane's pty via the running `cat`.
tmux -L $L send-keys -t s 'alpha beta gamma delta' Enter
sleep 0.4

sel() { # dump the current selection without clearing it
  rm -f "$D/sel"
  tmux -L $L send-keys -t s -X copy-pipe-no-clear "cat > $D/sel"
  sleep 0.3
  printf '  %-28s sel=[%s] active=[%s] present=[%s]\n' "$1" \
     "$(tr -d '\n' < "$D/sel" 2>/dev/null)" \
     "$(tmux -L $L display -p -t s '#{selection_active}')" \
     "$(tmux -L $L display -p -t s '#{selection_present}')"
}

echo "== enter copy mode, put the cursor on 'beta' =="
tmux -L $L copy-mode -t s
tmux -L $L send-keys -t s -X history-top
tmux -L $L send-keys -t s -X cursor-down   # line 1 = the echoed command line
tmux -L $L send-keys -t s -X start-of-line
for i in 1 2 3 4 5 6; do tmux -L $L send-keys -t s -X cursor-right; done
echo "  pane_mode=[$(tmux -L $L display -p -t s '#{pane_mode}')]"

sel "no selection yet"
tmux -L $L send-keys -t s -X begin-selection ; sel "after begin-selection"
tmux -L $L send-keys -t s -X select-word     ; sel "after select-word"
tmux -L $L send-keys -t s -X select-line     ; sel "after select-line"
tmux -L $L send-keys -t s -X select-word     ; sel "word again after line"
tmux -L $L send-keys -t s -X clear-selection ; sel "after clear-selection"
tmux -L $L send-keys -t s -X begin-selection ; sel "begin again (cell)"

echo "== does exiting and re-entering carry the selection? =="
tmux -L $L send-keys -t s -X select-line
tmux -L $L send-keys -t s -X cancel
sleep 0.2
echo "  after cancel: pane_mode=[$(tmux -L $L display -p -t s '#{pane_mode}')]"
tmux -L $L copy-mode -t s
sleep 0.2
sel "fresh copy-mode entry"

echo "== pane user option readable from a format? =="
tmux -L $L set -p -t s @ccyc 2
tmux -L $L display -p -t s '  @ccyc=[#{@ccyc}]  eq2=[#{==:#{@ccyc},2}]  unset=[#{@nope}]'
tmux -L $L set -pu -t s @ccyc 2>/dev/null
tmux -L $L display -p -t s '  after unset: @ccyc=[#{@ccyc}] eq0=[#{==:#{@ccyc},0}]'

tmux -L $L kill-server 2>/dev/null
