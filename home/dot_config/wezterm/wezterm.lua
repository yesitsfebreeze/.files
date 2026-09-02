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

-- No tab bar (enable_tab_bar = false below) — nothing to reserve height for.
local function grid_padding(win_w, win_h, cell_w, cell_h)
	local avail_w = win_w
	local avail_h = win_h

	local cols = math.floor(avail_w / cell_w)
	local rows = math.floor(avail_h / cell_h)

	local tot_x = math.floor(avail_w - cols * cell_w)
	local tot_y = math.floor(avail_h - rows * cell_h)

	return {
		left = math.floor(tot_x / 2),
		right = tot_x - math.floor(tot_x / 2),
		top = math.floor(tot_y / 2),
		bottom = tot_y - math.floor(tot_y / 2),
	}
end

local function center_grid(window)
	local mux_win = window:mux_window()
	if not mux_win then
		return
	end
	local mux_tab = mux_win:active_tab()
	if not mux_tab then
		return
	end

	local win = window:get_dimensions()
	local tab = mux_tab:get_size()
	if not win or not tab or tab.cols == 0 or tab.rows == 0 or tab.pixel_width == 0 or tab.pixel_height == 0 then
		return
	end
	local cell_w = tab.pixel_width / tab.cols
	local cell_h = tab.pixel_height / tab.rows
	if cell_w <= 0 or cell_h <= 0 then
		return
	end

	local overrides = window:get_config_overrides() or {}
	local pad = overrides.window_padding or { left = 0, right = 0, top = 0, bottom = 0 }

	local new_pad = grid_padding(win.pixel_width, win.pixel_height, cell_w, cell_h)

	if
		new_pad.left ~= pad.left
		or new_pad.right ~= pad.right
		or new_pad.top ~= pad.top
		or new_pad.bottom ~= pad.bottom
	then
		overrides.window_padding = new_pad
		window:set_config_overrides(overrides)
	end
end

wezterm.on("window-resized", center_grid)
wezterm.on("window-config-reloaded", center_grid)
wezterm.on("update-status", center_grid)

config.color_scheme = "Gruvbox dark, hard (base16)"
config.enable_tab_bar = false

config.font = wezterm.font_with_fallback({
	"CaskaydiaCove Nerd Font",
	"CaskaydiaCove NF",
	"JetBrainsMono Nerd Font",
	"Cascadia Code",
	"Menlo",
})
config.font_size = 14.0
config.line_height = 1.0
config.font_dirs = { home .. "/Library/Fonts" }

config.window_decorations = "RESIZE"
config.default_cursor_style = "BlinkingBlock"
config.window_background_opacity = 0.95
config.macos_window_background_blur = 30
config.audible_bell = "Disabled"
config.window_padding = { left = 0, right = 0, top = 0, bottom = 0 }
config.adjust_window_size_when_changing_font_size = false
config.front_end = "OpenGL"
config.max_fps = 60
config.animation_fps = 60
config.enable_kitty_keyboard = false
config.status_update_interval = 5000
config.disable_default_key_bindings = true

config.keys = {
	{ key = "Enter", mods = "ALT", action = act.ToggleFullScreen },
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
