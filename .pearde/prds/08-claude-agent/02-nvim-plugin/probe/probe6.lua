-- After load, claudecode.state.config holds the merged config
local cc = require("claudecode")
local st = cc.state
local cfg = st and st.config
print("STATE-CONFIG", type(cfg))
if cfg then
  print("PROVIDER", type(cfg.terminal) == "table" and type(cfg.terminal.provider))
  local p = cfg.terminal and cfg.terminal.provider
  print("PROVIDER-VAL", p == nil and "nil" or (type(p) == "string" and p or type(p)))
  if type(p) == "table" and p.name then print("PROVIDER-NAME", tostring(p.name)) end
  print("AUTOSTART", tostring(cfg.auto_start))
  print("SPLITW", tostring(cfg.terminal and cfg.terminal.split_width_percentage))
  print("DIFF-LAYOUT", tostring(cfg.diff_opts and cfg.diff_opts.layout))
end
-- claude-tmux get_config after setup
local ct = require("claude-tmux")
local okg, g = pcall(ct.get_config)
print("CT-CONFIG", okg, okg and vim.inspect(g):gsub("%s+", " ") or "")
