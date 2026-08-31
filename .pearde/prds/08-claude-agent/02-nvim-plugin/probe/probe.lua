-- Probe pass one for 08-claude-agent/02-nvim-plugin. Runs against the
-- sandbox config (XDG redirected); prints one line per check.
local out = function(s) io.write(s .. "\n") end

-- 1. cmd stubs exist before any load
for _, c in ipairs({ "ClaudeCode", "ClaudeCodeFocus", "ClaudeCodeSelectModel",
  "ClaudeCodeAdd", "ClaudeCodeSend", "ClaudeCodeTreeAdd", "ClaudeCodeStatus",
  "ClaudeCodeDiffAccept", "ClaudeCodeDiffDeny", "ClaudeCodeCloseAllDiffs" }) do
  out(("CMD %s=%d"):format(c, vim.fn.exists(":" .. c)))
end

-- 2. lazy stub keymaps registered globally from startup
local want = { "<leader>ac", "<leader>af", "<leader>ar", "<leader>aC",
  "<leader>am", "<leader>ab", "<leader>as", "<leader>aa", "<leader>ad" }
local have = {}
for _, m in ipairs(vim.api.nvim_get_keymap("n")) do have[vim.fn.keytrans(m.lhs)] = m.desc end
for _, m in ipairs(vim.api.nvim_get_keymap("v")) do have[vim.fn.keytrans(m.lhs)] = (m.desc or "") .. " [v]" end
for _, k in ipairs(want) do out(("MAP %s=%s"):format(k, have[k] or "MISSING")) end
out("PREFIX <leader>a=" .. tostring(have["<leader>a"]))

-- 3. plugin load state before trigger
local ok_loaded, _ = pcall(require, "claudecode")
out("PRELOAD-CLAUDECODE-PRESENT=" .. tostring(ok_loaded))

-- 4. claude-tmux module resolvable and is_available answers (outside tmux)
local okt, ct = pcall(require, "claude-tmux")
out("CLAUDE-TMUX-MODULE=" .. tostring(okt))
if okt then
  local okload = pcall(function() return ct.get_config() end)
  out("CLAUDE-TMUX-LOADABLE=" .. tostring(okload))
  out("IS-AVAILABLE(outside-tmux)=" .. tostring(ct.is_available()))
end

-- 5. full load path: fire the lazy handler for :ClaudeCode (loads plugins,
--    runs config()). This is the moment the provider wiring runs.
local okfire, err = pcall(function()
  require("lazy.core.loader").load({ { name = "claudecode.nvim" } }, { cmd = "ClaudeCode" }, "cmd")
end)
out("FIRE=" .. tostring(okfire) .. (okfire and "" or (" ERR=" .. tostring(err))))
local okcc, cc = pcall(require, "claudecode")
out("AFTERLOAD-CLAUDECODE=" .. tostring(okcc))
if okcc then
  local cfg = require("claudecode.config")
  out("PROVIDER=" .. vim.inspect(cfg.config.terminal.provider):gsub("%s+", " "):sub(1, 120))
  out("AUTOSTART=" .. tostring(cfg.config.auto_start))
  out("SPLITW=" .. tostring(cfg.config.terminal.split_width_percentage))
end
-- which-key sees the a-group?
out("VIM-HEALTHY=done")