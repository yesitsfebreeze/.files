#!/usr/bin/env bash
# R5 live: keymodel=startsel,stopsel in a REAL pty (tmux). One fresh nvim per
# case; state is captured by a timer armed BEFORE the keys, so insert/visual
# mode is read without leaving it. nvim is never quit inside the probe body --
# the tmux server is killed after the read (land-an-answered-fork step 3).
set -u
SDOWN='1b 5b 31 3b 32 42'   # CSI 1;2B = <S-Down>

case_run() { # case_run <name> <keyscript>
  local name="$1" keys="$2"
  local OUT S F
  OUT=$(mktemp -d); S="ss${name}$$"; F="$OUT/scratch.txt"
  printf 'one\ntwo\nthree\nfour\nfive\nsix\nseven\n' > "$F"
  tmux -L "$S" -f /dev/null new-session -d -x 120 -y 40 \
    "TERM=xterm-256color nvim --cmd 'set noswapfile' $F"
  sleep 6
  tmux -L "$S" send-keys ':lua vim.defer_fn(function() local f=io.open("'"$OUT"'/r","w") f:write(vim.fn.mode(1).."|"..vim.fn.line(".").."|"..vim.fn.line("v")) f:flush() f:close() end, 8000)' Enter
  sleep 1
  eval "$keys"
  sleep 9
  printf '%-26s %s\n' "$name" "$(cat "$OUT/r" 2>/dev/null || echo NOFILE)"
  tmux -L "$S" kill-server 2>/dev/null
  rm -rf "$OUT"
}
sd() { tmux -L "$S" send-keys -H $SDOWN; sleep 0.4; }

echo "                           mode|cursor|anchor   (start line 1)"
case_run normal_shiftdown_x3 'sd; sd; sd'
case_run then_bare_down      'sd; sd; sd; tmux -L "$S" send-keys Down; sleep 0.5'
case_run insert_shiftdown_x2 'tmux -L "$S" send-keys i; sleep 0.5; sd; sd'
case_run visual_v_then_hjkl  'tmux -L "$S" send-keys v; sleep 0.5; tmux -L "$S" send-keys j; sleep 0.5; tmux -L "$S" send-keys j; sleep 0.5'
