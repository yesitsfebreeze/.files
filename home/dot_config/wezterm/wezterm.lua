-- macOS host only (repo scope decision) — no is_mac branch, no Linux fonts.
local wezterm = require("wezterm")
local config = wezterm.config_builder()
local act = wezterm.action

local home = os.getenv("HOME") or ""

config.default_prog = { home .. "/.local/bin/tmux-main" }

config.set_environment_variables = {
	XDG_CONFIG_HOME = home .. "/.config",
	PATH = "/opt/homebrew/bin:/opt/homebrew/sbin:"
		.. home
		.. "/.local/bin:"
		.. home
		.. "/.cargo/bin:"
		.. (os.getenv("PATH") or ""),
}

config.color_scheme = "Gruvbox Material (Gogh)"
config.enable_tab_bar = false

-- The F8 `font` channel (font.sh) records its pick here, and the reload
-- watch applies it to every window. Its live preview arrives as a user var
-- and becomes a per-window override; an empty value drops the override.
local font_file = home .. "/.local/state/wezterm/font.txt"
wezterm.add_to_config_reload_watch_list(font_file)
local picked = io.open(font_file)
local family = picked and picked:read("l") or ""
if picked then
	picked:close()
end
-- The F1 cockpit's `wezterm` group (cockpit.tsv) names one of these actions.
local cockpit = {
	window = act.SpawnWindow,
	bigger = act.IncreaseFontSize,
	smaller = act.DecreaseFontSize,
	reset = act.ResetFontSize,
}
wezterm.on("user-var-changed", function(window, pane, name, value)
	if name == "wez" and cockpit[value] then
		return window:perform_action(cockpit[value], pane)
	end
	if name ~= "font" then
		return
	end
	local o = window:get_config_overrides() or {}
	o.font = value ~= "" and wezterm.font_with_fallback({ value, "CaskaydiaCove Nerd Font", "Menlo" }) or nil
	window:set_config_overrides(o)
end)

config.font = wezterm.font_with_fallback({
	family ~= "" and family or "CaskaydiaCove Nerd Font",
	"CaskaydiaCove Nerd Font",
	"CaskaydiaCove NF",
	"JetBrainsMono Nerd Font",
	"Cascadia Code",
	"Menlo",
})
config.font_size = 14.0
config.line_height = 1.0
config.font_dirs = { home .. "/Library/Fonts" }

-- Every window is fullscreen, always, and non-native: macOS's native mode
-- gives each window its own Space, so switching windows or monitors animates
-- a Space change and re-lays the grid mid-slide. Non-native just fills the
-- screen the window is on — but a display change (resolution, arrangement)
-- can shove that frame half off-screen while the state still says
-- fullscreen, hiding tmux's bottom bar. So every resize re-checks: a window
-- that is not fullscreen, or whose size matches no screen, is re-filled.
-- The 2 s throttle stops a screen that never matches from toggling forever.
config.native_macos_fullscreen_mode = false
local function fill(window)
	local d = window:get_dimensions()
	if not d.is_full_screen then
		return window:toggle_fullscreen()
	end
	for _, s in pairs(wezterm.gui.screens().by_name) do
		if s.width == d.pixel_width and s.height == d.pixel_height then
			return
		end
	end
	local refit = wezterm.GLOBAL.refit or {}
	local id, now = tostring(window:window_id()), os.time()
	if now - (refit[id] or 0) < 2 then
		return
	end
	refit[id] = now
	wezterm.GLOBAL.refit = refit
	window:toggle_fullscreen()
end
wezterm.on("window-config-reloaded", fill)
wezterm.on("window-resized", fill)

config.window_decorations = "RESIZE"
config.default_cursor_style = "BlinkingBlock"
config.window_background_opacity = 0.95
config.macos_window_background_blur = 30
config.audible_bell = "Disabled"
-- Zero padding anchors the grid top-left; the sub-cell remainder sits at the
-- right and bottom edges, so the grid never shifts on fullscreen or resize.
config.window_padding = { left = 0, right = 0, top = 0, bottom = 0 }
config.adjust_window_size_when_changing_font_size = false
config.front_end = "OpenGL"
config.max_fps = 60
config.animation_fps = 60
config.enable_kitty_keyboard = false
config.disable_default_key_bindings = true

config.keys = {
	{ key = "=", mods = "SUPER", action = act.IncreaseFontSize },
	{ key = "-", mods = "SUPER", action = act.DecreaseFontSize },
	{ key = "0", mods = "SUPER", action = act.ResetFontSize },
	{ key = "c", mods = "SUPER", action = act.CopyTo("Clipboard") },
	{ key = "v", mods = "SUPER", action = act.PasteFrom("Clipboard") },
	{ key = "q", mods = "SUPER", action = act.QuitApplication },
	-- tmux owns tabs now — a WezTerm window is one tab running the tmux
	-- client, so closing the tab closes the window; the session detaches.
	{ key = "q", mods = "CTRL|SHIFT", action = act.CloseCurrentTab({ confirm = false }) },
	{ key = "n", mods = "SUPER", action = act.SpawnWindow },

	{ key = "v", mods = "CTRL", action = act.PasteFrom("Clipboard") },
	-- Mouse ownership moved to tmux (`mouse on`); its own copy-mode Ctrl+C
	-- handles select-then-copy now, so this just passes the key through.
	{ key = "c", mods = "CTRL", action = act.SendKey({ key = "c", mods = "CTRL" }) },
}

-- SHIFT + click opens the link under the cursor, in tmux/nvim (mouse reporting
-- on) and in the plain shell alike — one binding per reporting state.
-- Three measured facts pin this shape:
-- 1. mouse_reporting defaulting to false means a plain binding NEVER matches
--    while an app tracks the mouse; only the duplicated mouse_reporting=true
--    binding fires there (mouse.html, "will only be considered if the current
--    pane's mouse reporting state matches").
-- 2. SHIFT is WezTerm's default `bypass_mouse_reporting_modifiers`: the bypass
--    strips the modifier before matching (wezterm#4536), so with the default
--    in place a SHIFT binding can never fire under mouse reporting. The bypass
--    therefore moves to ALT — the cost is ALT+click bypassing to a block
--    selection under mouse reporting, a dead modifier here anyway.
-- 3. Binding only the Up event still sends the DOWN stroke to the running
--    program (mouse.html, "Gotcha on binding an 'Up' event only"). tmux takes
--    the press, a jittered click becomes a drag, and its copy-mode selection
--    eats the click — the "stuck in selection" failure. The two Nop Down
--    bindings stop that: both halves of SHIFT+click are consumed by WezTerm
--    in both reporting states.
config.bypass_mouse_reporting_modifiers = "ALT"

config.mouse_bindings = {
	{
		event = { Down = { streak = 1, button = "Left" } },
		mods = "CTRL|ALT|SUPER",
		action = act.StartWindowDrag,
	},
	{
		event = { Up = { streak = 1, button = "Left" } },
		mods = "SHIFT",
		action = act.OpenLinkAtMouseCursor,
	},
	{
		event = { Up = { streak = 1, button = "Left" } },
		mods = "SHIFT",
		mouse_reporting = true,
		action = act.OpenLinkAtMouseCursor,
	},
	-- With no Down binding the press reaches tmux (see fact 3 above) and the
	-- click turns into a selection. Nop consumes it instead, in both states.
	{
		event = { Down = { streak = 1, button = "Left" } },
		mods = "SHIFT",
		action = act.Nop,
	},
	{
		event = { Down = { streak = 1, button = "Left" } },
		mods = "SHIFT",
		mouse_reporting = true,
		action = act.Nop,
	},
}

return config
