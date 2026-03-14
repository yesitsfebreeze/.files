-- modules/theme.lua: Color scheme + tab bar theming
-- Sets the color scheme from globals and styles the tab bar using theme colors:
--   • Transparent tab bar background
--   • Active tab bg = cursor color from the scheme
--   • Inactive tabs = muted gray

local wezterm = require("wezterm")

local M = {}

--- Look up the cursor color from the active color scheme.
--- Caches only the 3 colors we need per scheme in wezterm.GLOBAL (tiny).
--- The full builtin schemes table is transient and can be GC'd.
local function get_scheme_colors(scheme_name)
  if not wezterm.GLOBAL._scheme_colors then
    wezterm.GLOBAL._scheme_colors = {}
  end
  local cached = wezterm.GLOBAL._scheme_colors[scheme_name]
  if cached then return cached end

  local schemes = wezterm.color.get_builtin_schemes()
  local scheme = schemes[scheme_name]
  local colors
  if not scheme then
    colors = { cursor = "#c0c0c0", fg = "#c0c0c0", bg = "#1a1a1a" }
  else
    colors = {
      cursor = scheme.cursor_bg or scheme.foreground or "#c0c0c0",
      fg = scheme.foreground or "#c0c0c0",
      bg = scheme.background or "#1a1a1a",
    }
  end
  wezterm.GLOBAL._scheme_colors[scheme_name] = colors
  return colors
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

  -- Custom tab title: index + process name (or explicit tab title if set)
  wezterm.on("format-tab-title", function(tab, _tabs, _panes, _cfg, _hover, _max)
    local title = tab.tab_title
    if not title or #title == 0 then
      title = tab.active_pane.title
    end
    if title and #title > 24 then
      title = title:sub(1, 22) .. "…"
    end
    local index = tab.tab_index + 1
    return " " .. index .. ": " .. title .. " "
  end)
end

return M
