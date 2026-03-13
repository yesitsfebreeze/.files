-- modules/theme_picker.lua: Fuzzy theme switcher in the active pane
-- Keybinding: CTRL+SHIFT+T  →  runs the TUI picker in the current pane.
-- The picker updates globals.lua on every cursor move so WezTerm hot-reloads
-- the theme across ALL panes in real time (live preview).
-- On cancel (Esc) the original theme is restored and the terminal state
-- is recovered via the alternate screen buffer.

local wezterm = require("wezterm")
local act = wezterm.action

local M = {}

--- Export all built-in scheme names to a file (one per line).
local function export_themes()
  local path = wezterm.config_dir .. "/.theme_list.txt"
  local schemes = wezterm.get_builtin_color_schemes()
  local names = {}
  for name in pairs(schemes) do
    table.insert(names, tostring(name))
  end
  table.sort(names)

  local f = io.open(path, "w")
  if not f then return nil end
  for _, name in ipairs(names) do
    f:write(name .. "\n")
  end
  f:close()
  return path
end

function M.apply(config, globals)
  config.keys = config.keys or {}

  table.insert(config.keys, {
    key = "T",
    mods = "CTRL|SHIFT",
    action = wezterm.action_callback(function(window, pane)
      local themes_file = export_themes()
      if not themes_file then
        wezterm.log_error("theme_picker: failed to write theme list")
        return
      end

      local globals_path = wezterm.config_dir .. "/globals.lua"
      local current = globals.color_scheme or "Jellybeans"
      local script = wezterm.config_dir .. "/theme_picker_tui.py"
      local python = "python"

      local cmd = string.format(
        '%s "%s" "%s" "%s" "%s"\r',
        python, script, themes_file, globals_path, current
      )
      window:perform_action(act.SendString(cmd), pane)
    end),
  })
end

return M
