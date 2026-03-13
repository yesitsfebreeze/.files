-- modules/theme.lua: Color scheme + tab bar theming
-- Sets the color scheme from globals and styles the tab bar using theme colors:
--   • Transparent tab bar background
--   • Active tab bg = cursor color from the scheme
--   • Inactive tabs = muted gray

local wezterm = require("wezterm")

local M = {}

--- Look up the cursor color from the active color scheme.
local function get_scheme_colors(scheme_name)
  local schemes = wezterm.color.get_builtin_schemes()
  local scheme = schemes[scheme_name]
  if not scheme then
    return { cursor = "#c0c0c0", fg = "#c0c0c0", bg = "#1a1a1a" }
  end
  return {
    cursor = scheme.cursor_bg or scheme.foreground or "#c0c0c0",
    fg = scheme.foreground or "#c0c0c0",
    bg = scheme.background or "#1a1a1a",
  }
end

function M.apply(config, globals)
  local scheme_name = globals.color_scheme or "Jellybeans"
  config.color_scheme = scheme_name

  local colors = get_scheme_colors(scheme_name)

  -- Background: use the theme's bg color with user opacity
  config.background = {
    {
      width = "100%",
      height = "100%",
      opacity = globals.opacity or 0.75,
      source = { Color = colors.bg },
    },
  }

  config.colors = config.colors or {}
  config.colors.tab_bar = {
    background = "transparent",
    active_tab = {
      bg_color = colors.cursor,
      fg_color = colors.bg,
      intensity = "Bold",
    },
    inactive_tab = {
      bg_color = "transparent",
      fg_color = "#606060",
    },
    inactive_tab_hover = {
      bg_color = "transparent",
      fg_color = colors.cursor,
    },
    new_tab = {
      bg_color = "transparent",
      fg_color = "#606060",
    },
    new_tab_hover = {
      bg_color = "transparent",
      fg_color = colors.cursor,
    },
  }

  -- Custom tab title: index + process name
  wezterm.on("format-tab-title", function(tab, _tabs, _panes, _cfg, _hover, _max)
    local title = tab.active_pane.title
    if title and #title > 24 then
      title = title:sub(1, 22) .. "…"
    end
    local index = tab.tab_index + 1
    return " " .. index .. ": " .. title .. " "
  end)
end

return M
