-- modules/pane_mode.lua: Single-pane command overlay
--
-- Runs a command in the current pane. When the command exits (fzf closes,
-- etc.), the pane returns to its shell automatically — no multi-pane
-- orchestration needed.
--
-- Usage:
--   local pm = require("modules.pane_mode")
--   pm.define("find_files", function(cwd) return "fzf ..." end)
--   -- in keys.lua:  action = pm.activate("find_files")

local wezterm = require("wezterm")

local M = {}

local modes = {}  -- name → function(cwd) -> cmd_string

--- Resolve the working directory from a pane, normalized for Windows.
local function resolve_cwd(pane)
  local cwd_url = pane:get_current_working_dir()
  local cwd = cwd_url and (cwd_url.file_path or tostring(cwd_url)) or wezterm.home_dir
  cwd = cwd:gsub("^file:///", "")
  cwd = cwd:gsub("^/(%a:)", "%1")  -- /C:/… → C:/… on Windows
  return cwd
end

--- Register a mode.
--- build_cmd: function(cwd) → string  (the shell command to run)
function M.define(name, build_cmd)
  modes[name] = build_cmd
end

--- Return a wezterm action that sends the mode's command into the current pane.
--- The command runs inline; when it exits the shell prompt returns.
function M.activate(name)
  return wezterm.action_callback(function(_window, pane)
    local build_cmd = modes[name]
    if not build_cmd then
      wezterm.log_warn("pane_mode: unknown mode '" .. name .. "'")
      return
    end
    local cwd = resolve_cwd(pane)
    local cmd = build_cmd(cwd)
    if cmd then
      -- Leading space keeps it out of shell history
      pane:send_text(" " .. cmd .. "\r")
    end
  end)
end

return M
