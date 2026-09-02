-- fire :ClaudeCode from a real nvim that loaded ~/.config/nvim, inside a real tmux pane
local out = {}
local function say(...) out[#out+1] = table.concat({...}, " ") end
say("TMUX", tostring(vim.env.TMUX))
local ok, err = pcall(vim.cmd, "ClaudeCode")
say("FIRE-ClaudeCode", tostring(ok), ok and "" or tostring(err):gsub("%s+"," "))
local cc = require("claudecode")
local cfg = cc.state and cc.state.config
say("TERMINAL-CMD", tostring(cfg and cfg.terminal_cmd))
local p = cfg and cfg.terminal and cfg.terminal.provider
say("PROVIDER-TYPE", type(p))
local ct = require("claude-tmux")
say("CT-AVAILABLE", tostring(ct.is_available()))
local okg, g = pcall(ct.get_config)
say("CT-CONFIG", tostring(okg), okg and (vim.inspect(g):gsub("%s+"," ")) or "")
vim.fn.writefile(out, vim.env.PROBE_OUT)
vim.cmd("qa!")
