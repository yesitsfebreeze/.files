-- macOS host only (repo scope decision) — no is_mac branch, no Linux fonts.
local wezterm = require("wezterm")
local config = wezterm.config_builder()
local act = wezterm.action

local home = os.getenv("HOME") or ""

config.default_prog = { home .. "/.local/bin/tmux-main" }

config.set_environment_variables = {
	XDG_CONFIG_HOME = home .. "/.config",
	PATH = "/opt/homebrew/bin:/opt/homebrew/sbin:" .. home .. "/.local/bin:" .. home .. "/.cargo/bin:" .. (os.getenv(
		"PATH"
	) or ""),
}

config.color_scheme = "Gruvbox Material (Gogh)"
config.enable_tab_bar = false

-- The F8 font pick and its live preview. manual → internals/wezterm, "Font".
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
	close = act.CloseCurrentTab({ confirm = false }),
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

-- Always non-native fullscreen: a display change can shove the frame half
-- off-screen while it still reports fullscreen, hiding tmux's bottom bar, so
-- every resize re-fills a window whose width matches no screen (throttled 2 s),
-- unless Alt+Enter took that window out of fullscreen.
-- Width only: fullscreen stops below the MacBook notch, so height never matches.
-- manual → internals/wezterm.
config.native_macos_fullscreen_mode = false
local function fill(window)
	if (wezterm.GLOBAL.windowed or {})[tostring(window:window_id())] then
		return
	end
	local d = window:get_dimensions()
	if not d.is_full_screen then
		return window:toggle_fullscreen()
	end
	for _, s in pairs(wezterm.gui.screens().by_name) do
		if s.width == d.pixel_width then
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
config.window_background_opacity = 0.9
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
	-- Leaving fullscreen opts this window out of `fill`; entering opts back in.
	{
		key = "Enter",
		mods = "ALT",
		action = wezterm.action_callback(function(window)
			local windowed, id = wezterm.GLOBAL.windowed or {}, tostring(window:window_id())
			windowed[id] = window:get_dimensions().is_full_screen or nil
			wezterm.GLOBAL.windowed = windowed
			window:toggle_fullscreen()
		end),
	},

	{ key = "v", mods = "CTRL", action = act.PasteFrom("Clipboard") },
	-- Mouse ownership moved to tmux (`mouse on`); its own copy-mode Ctrl+C
	-- handles select-then-copy now, so this just passes the key through.
	{ key = "c", mods = "CTRL", action = act.SendKey({ key = "c", mods = "CTRL" }) },
}

-- SHIFT+click opens a link in both mouse-reporting states; the bypass moves
-- to ALT and the Down stroke is Nopped. manual → internals/wezterm.
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
