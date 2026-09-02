#!/usr/bin/env bash
# R3 live: lualine theme="tinted" is group-name based, so the statusline
# follows a scheme change with no restart and no ColorScheme autocmd. Two
# scheme changes are made INSIDE the running nvim (the machine's own tinty
# scheme is never touched). Read from the live process; nvim is not quit here.
set -u
OUT=$(mktemp -d); S="slprobe$$"
trap 'tmux -L "$S" kill-server 2>/dev/null; rm -rf "$OUT"' EXIT
tmux -L "$S" -f /dev/null new-session -d -x 160 -y 40 \
  "TERM=xterm-256color nvim --cmd 'set noswapfile'"
sleep 7
tmux -L "$S" send-keys ':lua local f=io.open("'"$OUT"'/r","w") local function grab(tag) vim.cmd("redrawstatus") local h=vim.api.nvim_get_hl(0,{name="lualine_a_normal"}) f:write(tag.."  bg="..string.format("#%06x",h.bg or 0).." fg="..string.format("#%06x",h.fg or 0).."  colorscheme="..(vim.g.colors_name or "?").."\n") end grab("start ") vim.cmd.colorscheme("base16-gruvbox-light-hard") grab("apply1") vim.cmd.colorscheme("base16-nord") grab("apply2") f:write("lualine_theme_after_two="..tostring(require("lualine").get_config().options.theme).."\n") f:flush() f:close()' Enter
sleep 5
cat "$OUT/r" 2>/dev/null || echo "NO READ"
