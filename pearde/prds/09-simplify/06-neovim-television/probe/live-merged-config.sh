#!/usr/bin/env bash
# Read the MERGED state out of a live nvim running in a real pty (tmux), not
# the source files. Per land-an-answered-fork step 3: nvim never quits inside
# the probe body -- the tmux server is killed after the measurement, so the
# window layout is still listable when we read it.
set -u
OUT=$(mktemp -d)
S="nvimprobe$$"
trap 'tmux -L "$S" kill-server 2>/dev/null; rm -rf "$OUT"' EXIT

tmux -L "$S" -f /dev/null new-session -d -x 200 -y 50 \
  "nvim --cmd 'set noswapfile' /tmp/probe-scratch.lua"
sleep 6

tmux -L "$S" send-keys ':lua local f=io.open("'"$OUT"'/merged.txt","w") f:write("keymodel="..vim.o.keymodel.."\n") f:write("termguicolors="..tostring(vim.o.termguicolors).."\n") f:write("mouse="..vim.o.mouse.."\n") f:write("completeopt="..vim.o.completeopt.."\n") f:write("lualine_theme="..tostring(require("lualine").get_config().options.theme).."\n") f:write("grn="..tostring(vim.fn.maparg("grn","n")~="").."\n") f:write("gra="..tostring(vim.fn.maparg("gra","n")~="").."\n") f:write("leader_xc="..vim.fn.maparg("<leader>xc","n").."\n") f:write("claude_termcmd="..tostring((package.loaded["claudecode"] or {}).state and package.loaded["claudecode"].state.config.terminal_cmd or "unloaded").."\n") f:close()' Enter
sleep 4
tmux -L "$S" list-panes -a -F 'pane #{pane_index} #{pane_width}x#{pane_height}' > "$OUT/panes.txt"

echo "--- merged state read out of the running nvim ---"
cat "$OUT/merged.txt" 2>/dev/null || echo "NO MERGED FILE WRITTEN"
echo "--- live panes (read before teardown) ---"
cat "$OUT/panes.txt"
