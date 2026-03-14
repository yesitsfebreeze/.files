-- modules/pickers/theme.lua: Fuzzy theme switcher using native InputSelector
-- Keybinding: CTRL+SHIFT+T → opens native WezTerm overlay picker

local wezterm = require("wezterm")
local act = wezterm.action

local M = {}

function M.apply(config, globals)
  config.keys = config.keys or {}

  table.insert(config.keys, {
    key = "T",
    mods = "CTRL|SHIFT",
    action = wezterm.action_callback(function(window, pane)
      local schemes = wezterm.color.get_builtin_schemes()
      local names = {}
      for name in pairs(schemes) do
        table.insert(names, name)
      end
      table.sort(names)

      local current = globals.color_scheme or "Jellybeans"
      local choices = {}
      for _, name in ipairs(names) do
        table.insert(choices, {
          id = name,
          label = name,
        })
      end

      window:perform_action(
        act.InputSelector {
          action = wezterm.action_callback(function(win, pan, id, label)
            if id then
              local globals_path = wezterm.config_dir .. "/globals.lua"
              local f = io.open(globals_path, "r")
              if f then
                local content = f:read("*a")
                f:close()
                local updated = content:gsub(
                  '(color_scheme%s*=%s*)"[^"]*"',
                  '%1"' .. id .. '"'
                )
                local fw = io.open(globals_path, "w")
                if fw then
                  fw:write(updated)
                  fw:close()
                end
              end
            end
          end),
          title = "Theme Picker",
          description = "Select theme (Enter=apply, Esc=cancel)",
          choices = choices,
          fuzzy = true,
          fuzzy_description = "Filter: ",
          initial_selection = function()
            for i, c in ipairs(choices) do
              if c.id == current then
                return i - 1
              end
            end
            return 0
          end,
        },
        pane
      )
    end),
  })
end

return M
