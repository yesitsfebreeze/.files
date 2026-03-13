-- modules/init.lua: Module loader
-- Loads and applies feature modules based on the enabled list.
--
-- Usage in wezterm.lua:
--   require("modules").apply_all(config, {
--     "appearance",
--     "tabs",
--     "keys",
--     "theme_picker",
--     "font_picker",
--     "workspaces",
--     "panes",
--     "status_bar",
--   })

local M = {}

--- Apply a single module by name.
--- Each module must export an `apply(config, globals)` function.
function M.apply(config, globals, name)
  local ok, mod = pcall(require, "modules." .. name)
  if not ok then
    local wezterm = require("wezterm")
    wezterm.log_warn("Module '" .. name .. "' failed to load: " .. tostring(mod))
    return
  end
  if type(mod.apply) == "function" then
    mod.apply(config, globals)
  end
end

--- Apply all modules in order.
function M.apply_all(config, globals, module_names)
  for _, name in ipairs(module_names) do
    M.apply(config, globals, name)
  end
end

return M
