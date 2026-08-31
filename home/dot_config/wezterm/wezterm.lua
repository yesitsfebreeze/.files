local wezterm = require("wezterm")
local config = wezterm.config_builder()
local act = wezterm.action

local triple = wezterm.target_triple
local is_mac = triple:find("darwin") ~= nil

local home = os.getenv("HOME") or ""

local nu_config = home .. "/.config/nushell/config.nu"
local nu_env = home .. "/.config/nushell/env.nu"

config.default_prog = { home .. "/.local/bin/tmux-main" }

config.set_environment_variables = {
	XDG_CONFIG_HOME = home .. "/.config",
}

if is_mac then
	config.set_environment_variables.PATH = "/opt/homebrew/bin:/opt/homebrew/sbin:"
		.. home
		.. "/.local/bin:"
		.. home
		.. "/.cargo/bin:"
		.. (os.getenv("PATH") or "")
end

local TAB_BAR_RESERVE = 0

local function grid_padding(win_w, win_h, cell_w, cell_h)
	local bar_h = TAB_BAR_RESERVE or (math.ceil(cell_h) + 1)

	local avail_w = win_w
	local avail_h = win_h - bar_h

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
-- <<< grid-padding

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
config.font_size = is_mac and 14.0 or 9.0
config.line_height = 1.0

if is_mac then
	config.font_dirs = { home .. "/Library/Fonts" }
else
	config.font_dirs = { home .. "/.local/share/fonts" }
end

config.window_decorations = "RESIZE"
config.default_cursor_style = "BlinkingBlock"
config.window_background_opacity = 0.95
config.macos_window_background_blur = 30
config.inactive_pane_hsb = { saturation = 0.85, brightness = 0.7 }
config.scrollback_lines = 10000
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
	{ key = "n", mods = "SUPER", action = act.SpawnWindow },

	{ key = "d", mods = "CTRL|SHIFT", action = act.SendString("capsule\r") },
	{ key = "b", mods = "CTRL|SHIFT", action = act.SendString("capsule --rebuild\r") },
	{ key = "s", mods = "CTRL|SHIFT", action = act.SendString("capsule recent\r") },
	{
		key = "o",
		mods = "CTRL|SHIFT",
		action = act.SpawnCommandInNewWindow({
			args = { "nu", "--config", nu_config, "--env-config", nu_env, "--execute", "capsule recent" },
		}),
	},
	{ key = "v", mods = "CTRL", action = act.PasteFrom("Clipboard") },
	{
		key = "c",
		mods = "CTRL",
		action = wezterm.action_callback(function(window, pane)
			local sel = window:get_selection_text_for_pane(pane)
			if sel and sel ~= "" then
				window:perform_action(act.CopyTo("ClipboardAndPrimarySelection"), pane)
				window:perform_action(act.ClearSelection, pane)
			else
				window:perform_action(act.SendKey({ key = "c", mods = "CTRL" }), pane)
			end
		end),
	},
}

config.mouse_bindings = {
	{
		event = { Down = { streak = 1, button = "Left" } },
		mods = "CTRL|ALT|SUPER",
		action = act.StartWindowDrag,
	},
	{
		event = { Up = { streak = 1, button = "Left" } },
		mods = "CTRL",
		mouse_reporting = true,
		action = act.OpenLinkAtMouseCursor,
	},
}

return config
