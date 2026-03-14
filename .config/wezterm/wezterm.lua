-- WezTerm — Clean single-terminal config with tabs

local wezterm = require("wezterm")
local config = wezterm.config_builder and wezterm.config_builder() or {}

-- ── Appearance ──────────────────────────────────────────────────

config.term = "xterm-256color"
config.window_close_confirmation = "NeverPrompt"
config.window_decorations = "RESIZE"
config.enable_scroll_bar = false
config.default_cursor_style = "BlinkingBlock"
config.animation_fps = 1
config.cursor_blink_rate = 0
config.audible_bell = "Disabled"
config.scrollback_lines = 3500
config.canonicalize_pasted_newlines = "LineFeed"

-- ── Font ────────────────────────────────────────────────────────

config.font_dirs = { wezterm.config_dir .. "/fonts" }
config.font = wezterm.font("DepartureMono Nerd Font Mono")
config.font_size = 13
config.line_height = 1.01

-- ── Window ──────────────────────────────────────────────────────

config.window_padding = { left = 4, right = 0, top = 0, bottom = 0 }

-- ── Tab bar ─────────────────────────────────────────────────────

config.enable_tab_bar = true
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = false
config.hide_tab_bar_if_only_one_tab = false

-- ── Color scheme + tab styling ──────────────────────────────────

local THEME_FILE = wezterm.config_dir .. "/.theme"
local function read_theme()
  local f = io.open(THEME_FILE, "r")
  if not f then return "Belafonte Night (Gogh)" end
  local name = f:read("*l")
  f:close()
  return (name and #name > 0) and name or "Belafonte Night (Gogh)"
end

local SCHEME_NAME = read_theme()
config.color_scheme = SCHEME_NAME

local function get_scheme_colors(name)
  local schemes = wezterm.color.get_builtin_schemes()
  local scheme = schemes[name]
  if not scheme then
    return { cursor = "#c0c0c0", fg = "#c0c0c0", bg = "#1a1a1a" }
  end
  return {
    cursor = scheme.cursor_bg or scheme.foreground or "#c0c0c0",
    fg = scheme.foreground or "#c0c0c0",
    bg = scheme.background or "#1a1a1a",
  }
end

local colors = get_scheme_colors(SCHEME_NAME)

config.background = {
  { width = "100%", height = "100%", opacity = 0.725, source = { Color = colors.bg } },
}

config.colors = {
  tab_bar = {
    background = "transparent",
    active_tab = { bg_color = colors.cursor, fg_color = colors.bg, intensity = "Bold" },
    inactive_tab = { bg_color = "transparent", fg_color = "#606060" },
    inactive_tab_hover = { bg_color = "transparent", fg_color = colors.cursor },
    new_tab = { bg_color = "transparent", fg_color = "#606060" },
    new_tab_hover = { bg_color = "transparent", fg_color = colors.cursor },
  },
}

wezterm.on("format-tab-title", function(tab)
  local title = tab.tab_title
  if not title or #title == 0 then
    title = tab.active_pane.title
  end
  if title and #title > 24 then
    title = title:sub(1, 22) .. "…"
  end
  return " " .. (tab.tab_index + 1) .. ": " .. title .. " "
end)

-- ── Maximize on startup ─────────────────────────────────────────

wezterm.on("gui-attached", function()
  local window = wezterm.mux.all_windows()[1]
  if window then
    window:gui_window():maximize()
  end
end)

-- ── Start tmux ─────────────────────────────────────────────────

local function get_default_prog()
  local target = wezterm.target_triple
  if target:match("windows") then
    return nil
  end
  return { "/bin/zsh", "-c", "command -v zsh >/dev/null 2>&1 && tmux new-session -A -s main || :" }
end

config.default_prog = get_default_prog()

-- ── Theme picker ────────────────────────────────────────────────

local act = wezterm.action

local open_theme_picker = wezterm.action_callback(function(_, pane)
  local all = wezterm.color.get_builtin_schemes()
  local names = {}
  for name in pairs(all) do
    table.insert(names, name)
  end
  table.sort(names)

  local list_file = wezterm.config_dir .. "/.theme_list"
  local f = io.open(list_file, "w")
  if f then
    f:write(table.concat(names, "\n"))
    f:close()
  end

  local theme_esc = THEME_FILE:gsub("'", "'\\''")
  local list_esc = list_file:gsub("'", "'\\''")

  -- Save current theme so we can restore on cancel
  local orig = read_theme()
  local orig_file = wezterm.config_dir .. "/.theme_orig"
  local of = io.open(orig_file, "w")
  if of then of:write(orig); of:close() end

  local orig_esc = orig_file:gsub("'", "'\\''")

  local cmd = string.format(
    "export PATH=\"/opt/homebrew/bin:$PATH\"; "
    .. "selected=$(cat '%s' | fzf --prompt='Theme > ' --layout=reverse --no-info "
    .. "--bind 'focus:execute-silent(printf %%s {}" .. " > " .. "'%s'" .. ")') ; "
    .. "if [ -n \"$selected\" ]; then "
    .. "  printf '%%s' \"$selected\" > '%s'; "
    .. "else "
    .. "  cp '%s' '%s'; "
    .. "fi; "
    .. "rm -f '%s' '%s'",
    list_esc, theme_esc,
    theme_esc,
    orig_esc, theme_esc,
    list_esc, orig_esc
  )

  pane:split({
    direction = "Right",
    size = 0.20,
    args = { "/bin/zsh", "-c", cmd },
  })
end)

-- ── Keys ────────────────────────────────────────────────────────

config.keys = {
  -- New tab
  { key = "t", mods = "CMD", action = act.SpawnTab("CurrentPaneDomain") },

  -- Close tab
  { key = "w", mods = "CMD", action = act.CloseCurrentTab({ confirm = false }) },

  -- Switch to tabs 1–6
  { key = "1", mods = "CMD", action = act.ActivateTab(0) },
  { key = "2", mods = "CMD", action = act.ActivateTab(1) },
  { key = "3", mods = "CMD", action = act.ActivateTab(2) },
  { key = "4", mods = "CMD", action = act.ActivateTab(3) },
  { key = "5", mods = "CMD", action = act.ActivateTab(4) },
  { key = "6", mods = "CMD", action = act.ActivateTab(5) },

  -- Next/prev tab
  { key = "}", mods = "CMD|SHIFT", action = act.ActivateTabRelative(1) },
  { key = "{", mods = "CMD|SHIFT", action = act.ActivateTabRelative(-1) },

  -- Clipboard
  { key = "c", mods = "CMD", action = act.CopyTo("Clipboard") },
  { key = "v", mods = "CMD", action = act.PasteFrom("Clipboard") },
  { key = "v", mods = "CTRL", action = act.PasteFrom("Clipboard") },

  -- Theme picker
  { key = "t", mods = "CMD|SHIFT", action = open_theme_picker },
}

return config
