#!/usr/bin/env bash
set -u
OUT=$(mktemp -d); S="claudeprobe$$"
trap 'tmux -L "$S" kill-server 2>/dev/null; rm -rf "$OUT"' EXIT
tmux -L "$S" -f /dev/null new-session -d -x 200 -y 50 "nvim --cmd 'set noswapfile'"
sleep 6
tmux -L "$S" send-keys ':lua require("lazy").load({plugins={"claudecode.nvim"}}) local c=require("claudecode").state.config local f=io.open("'"$OUT"'/c.txt","w") f:write("terminal_cmd="..tostring(c.terminal_cmd).."\n") f:write("provider="..tostring(c.diff_opts and "" or "").."\n") f:close()' Enter
sleep 5
tmux -L "$S" send-keys ':lua local t=require("claudecode.terminal") local f=io.open("'"$OUT"'/t.txt","w") f:write("provider="..tostring((t.get_config and t.get_config().provider) or "n/a").."\n") f:close()' Enter
sleep 3
echo "--- claudecode merged state ---"; cat "$OUT/c.txt" "$OUT/t.txt" 2>/dev/null
