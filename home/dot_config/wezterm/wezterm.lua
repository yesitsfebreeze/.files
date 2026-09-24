-- macOS and Omarchy (Linux). `mac` gates the few macOS-only settings.
local wezterm = require("wezterm")
local config = wezterm.config_builder()
local act = wezterm.action

local home = os.getenv("HOME") or ""
local mac = wezterm.target_triple:find("darwin") ~= nil
local default_font = mac and "CaskaydiaCove Nerd Font" or "DepartureMono Nerd Font"

config.default_prog = { home .. "/.local/bin/tmux-main" }

config.set_environment_variables = {
	XDG_CONFIG_HOME = home .. "/.config",
	PATH = "/opt/homebrew/bin:/opt/homebrew/sbin:" .. home .. "/.local/bin:" .. home .. "/.cargo/bin:" .. (os.getenv(
		"PATH"
	) or ""),
}

config.color_scheme = "Gruvbox Material (Gogh)"
-- Omarchy: the current Omarchy theme, rendered as base16 by the omarchy repo's
-- tinty-scheme.yaml.tpl on every `omarchy theme set`; watched so a theme
-- change repaints open windows.
local omarchy_scheme = home .. "/.local/state/omarchy/current/theme/tinty-scheme.yaml"
if not mac and io.open(omarchy_scheme) then
	config.color_scheme = nil
	config.colors = wezterm.color.load_base16_scheme(omarchy_scheme)
	wezterm.add_to_config_reload_watch_list(omarchy_scheme)
end
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
	o.font = value ~= "" and wezterm.font_with_fallback({ value, default_font, "Menlo" }) or nil
	window:set_config_overrides(o)
end)

config.font = wezterm.font_with_fallback({
	family ~= "" and family or default_font,
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
-- macOS only: on Hyprland the compositor tiles the window.
-- manual → internals/wezterm.
config.native_macos_fullscreen_mode = false
local function fill(window)
	if not mac or (wezterm.GLOBAL.windowed or {})[tostring(window:window_id())] then
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
-- On Hyprland the compositor applies Omarchy's window opacity and blur.
config.window_background_opacity = mac and 0.9 or 1.0
config.macos_window_background_blur = 30
config.audible_bell = "Disabled"
-- Zero padding anchors the grid top-left; the sub-cell remainder sits at the
-- right and bottom edges, so the grid never shifts on fullscreen or resize.
config.window_padding = { left = 0, right = 0, top = 0, bottom = 0 }
config.adjust_window_size_when_changing_font_size = false
-- Linux: WebGpu over Vulkan, and no eased cursor-blink animation — on the
-- Omarchy laptop's Intel iGPU, OpenGL plus 60 fps blink redraws lagged.
config.front_end = mac and "OpenGL" or "WebGpu"
config.webgpu_power_preference = "LowPower"
config.max_fps = 60
config.animation_fps = mac and 60 or 1
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
	-- Omarchy's universal Super+C / Super+V arrive as Ctrl+Insert / Shift+Insert.
	{ key = "Insert", mods = "CTRL", action = act.CopyTo("Clipboard") },
	{ key = "Insert", mods = "SHIFT", action = act.PasteFrom("Clipboard") },
}
-- Alt+Enter: leaving fullscreen opts this window out of `fill`; entering opts
-- back in. macOS only: on Hyprland, WezTerm's own fullscreen toggle crashed the
-- window; the compositor's fullscreen binding owns it there.
if mac then
	table.insert(config.keys, {
		key = "Enter",
		mods = "ALT",
		action = wezterm.action_callback(function(window)
			local windowed, id = wezterm.GLOBAL.windowed or {}, tostring(window:window_id())
			windowed[id] = window:get_dimensions().is_full_screen or nil
			wezterm.GLOBAL.windowed = windowed
			window:toggle_fullscreen()
		end),
	})
end

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
