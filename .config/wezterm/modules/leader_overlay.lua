-- modules/leader_overlay.lua: Inline leader key hints in the status bar.
-- • When leader is active, displays all available bindings inline.
-- • When inside a sub-menu, shows only that sub-menu's bindings.
-- • The trigger key letter is highlighted inverted (cursor color).
-- • No background — follows the theme's tab bar styling.
-- • Pre-builds format elements; only re-resolves colors on scheme change.

local wezterm = require("wezterm")

local M = {}

--- Look up colors from the active color scheme.
--- Shares the tiny per-scheme cache in wezterm.GLOBAL._scheme_colors
--- (populated on first use by theme.lua or here).
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

-- Build format elements for a single binding.
-- The inverted-highlight colors are filled in with placeholders that
-- get patched when the color scheme is known.
local function format_binding(key, desc)
  local parts = {}  -- { type = "text"/"inv_start"/"inv_end", text = ... }
  local lower_key = key:lower()

  local match_pos = nil
  for i = 1, #desc do
    if desc:sub(i, i):lower() == lower_key then
      match_pos = i
      break
    end
  end

  if match_pos then
    local before = match_pos > 1 and desc:sub(1, match_pos - 1) or ""
    local letter = desc:sub(match_pos, match_pos)
    local after = match_pos < #desc and desc:sub(match_pos + 1) or ""
    table.insert(parts, { t = "text", s = " " .. before })
    table.insert(parts, { t = "inv", s = letter })
    table.insert(parts, { t = "text", s = after .. " │" })
  else
    table.insert(parts, { t = "text", s = " " })
    table.insert(parts, { t = "inv", s = key })
    table.insert(parts, { t = "text", s = " " .. desc .. " │" })
  end
  return parts
end

-- Convert pre-built parts into wezterm format elements using resolved colors.
local function render_parts(parts, colors, elements)
  for _, p in ipairs(parts) do
    if p.t == "inv" then
      table.insert(elements, { Foreground = { Color = colors.bg } })
      table.insert(elements, { Background = { Color = colors.cursor } })
      table.insert(elements, { Attribute = { Intensity = "Bold" } })
      table.insert(elements, { Text = p.s })
      table.insert(elements, "ResetAttributes")
    else
      table.insert(elements, { Text = p.s })
    end
  end
end

function M.apply(config, globals)
  local followers = globals.followers or {}

  -- ── Pre-build binding parts at config time ─────────────────────
  local top_parts = {}
  for _, entry in ipairs(followers) do
    local desc = entry.desc or entry.action or ""
    table.insert(top_parts, format_binding(entry.key, desc))
  end

  local sub_parts = {}
  local table_descs = {}
  for _, entry in ipairs(followers) do
    if entry.children then
      local name = "leader_" .. entry.key
      table_descs[name] = entry.desc or entry.key
      sub_parts[name] = {}
      for _, child in ipairs(entry.children) do
        table.insert(sub_parts[name], format_binding(
          child.key, child.desc or child.action or ""
        ))
      end
    end
  end

  -- ── Status bar ─────────────────────────────────────────────────
  wezterm.on("update-right-status", function(window, _pane)
    local kt = window:active_key_table()
    local leader = window:leader_is_active()

    if not kt and not leader then
      window:set_right_status("")
      return
    end

    local colors = get_scheme_colors(window:effective_config().color_scheme)
    local binding_parts, badge_text

    if kt and sub_parts[kt] then
      binding_parts = sub_parts[kt]
      badge_text = " LEADER → " .. (table_descs[kt] or kt) .. " "
    else
      binding_parts = top_parts
      badge_text = " LEADER "
    end

    local elements = {}
    for _, parts in ipairs(binding_parts) do
      render_parts(parts, colors, elements)
    end

    -- Badge at the end (rightmost)
    table.insert(elements, { Text = " " })
    table.insert(elements, { Foreground = { Color = colors.bg } })
    table.insert(elements, { Background = { Color = colors.cursor } })
    table.insert(elements, { Attribute = { Intensity = "Bold" } })
    table.insert(elements, { Text = badge_text })
    table.insert(elements, "ResetAttributes")

    window:set_right_status(wezterm.format(elements))
  end)
end

return M
