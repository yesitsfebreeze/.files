-- WezTerm — Minimal config (workspace-focused)

local wezterm = require("wezterm")
local config = wezterm.config_builder and wezterm.config_builder() or {}
local globals = dofile(wezterm.config_dir .. "/globals.lua")
local modules = require("modules")

-- ── Base appearance (inline, no module needed) ──────────────────
local is_windows = wezterm.target_triple:find("windows") ~= nil

config.term = "xterm-256color"
config.window_close_confirmation = "NeverPrompt"
config.window_decorations = "RESIZE"

-- ── Windows: enable IME so speech-to-text / external input agents work ──
if is_windows then
  config.use_ime = true
  config.allow_win32_input_mode = false
end
config.enable_scroll_bar = false
config.default_cursor_style = "BlinkingBlock"
config.animation_fps = 1
config.cursor_blink_rate = 0
config.audible_bell = "Disabled"
config.scrollback_lines = 3500

config.font = wezterm.font(globals.font_family or "DepartureMono Nerd Font Mono")
config.font_size = globals.font_size or 13
config.line_height = globals.line_height or 1.01

config.window_padding = {
  left = 4,
  right = 0,
  top = 0,
  bottom = 0,
}

config.enable_tab_bar = true
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = false
config.hide_tab_bar_if_only_one_tab = false

-- ── Modules ─────────────────────────────────────────────────────
modules.apply_all(config, globals, {
  "theme",            -- color scheme + tab bar theming
  "layout",           -- startup pane splits + Ctrl+Shift+/ cycle
  "projects",         -- Leader+h/o — project tracking + pane reset
  "finder",           -- full-screen finder overlay (Leader+f+f/g/Space)
  "keys",             -- leader key bindings
  "leader_overlay",   -- LEADER indicator + ? help overlay
  "workspaces",       -- Ctrl+Shift+Alt+W/S — workspace manager
})

return config
