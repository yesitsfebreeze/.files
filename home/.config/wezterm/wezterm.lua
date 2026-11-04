local wezterm = require("wezterm")
local config = wezterm.config_builder()
local act = wezterm.action

local home = os.getenv("HOME") or ""
local default_font = "CaskaydiaCove Nerd Font"

config.default_prog = { home .. "/.local/bin/tmux-main" }

config.set_environment_variables = {
	XDG_CONFIG_HOME = home .. "/.config",
	-- ~/.local/bin FIRST, as env.nu and dotfiles.sh order it: tmux-main runs
	-- `tmux` from this PATH, and brew-first starts stock tmux over tmux-next.
	PATH = home .. "/.local/bin:" .. home .. "/.cargo/bin:/opt/homebrew/bin:/opt/homebrew/sbin:" .. (os.getenv(
		"PATH"
	) or ""),
}

config.color_scheme = "Gruvbox Material (Gogh)"
config.enable_tab_bar = false

-- The F5 s c font pick and its live preview. manual → internals/wezterm, "Font".
local font_file = home .. "/.local/state/wezterm/font.txt"
wezterm.add_to_config_reload_watch_list(font_file)
local picked = io.open(font_file)
local family = picked and picked:read("l") or ""
if picked then
	picked:close()
end
-- The F5 cockpit's `wezterm` group (cockpit.json) names one of these actions.
local cockpit = {
	bigger = act.IncreaseFontSize,
	smaller = act.DecreaseFontSize,
	reset = act.ResetFontSize,
	close = act.CloseCurrentTab({ confirm = false }),
}
-- The wallpaper tint's live colour. theme.sh sends base00 as the `bg` user
-- var on every paint; it becomes a window override (no config reload, which
-- took ~700 ms). The override pins whole layers, so a reload (wezterm-bg
-- changed image, dark or tint) rebuilds it: bg_key names what it was built
-- from, wezterm.GLOBAL keeps the colour and what each window got.
-- tinted (base00, locked to layers) is nil while no image is on. Locked, the
-- only layer is wezterm-bg's cached unblurred render (background.lock) as
-- is: no darkness, no tint. That is what the `lock` user var from tmux-lock shows.
local tinted, bg_key, seed_bg
local function retint(window)
	local o = window:get_config_overrides() or {}
	local locked = wezterm.GLOBAL.locked
	local id, want = tostring(window:window_id()), tinted and bg_key .. (wezterm.GLOBAL.bg or "") .. (locked and " locked" or "")
	local got = wezterm.GLOBAL.tinted or {}
	if got[id] == want and (want or not o.background) then
		return
	end
	got[id] = want
	wezterm.GLOBAL.tinted = got
	o.background = want and tinted(wezterm.GLOBAL.bg or seed_bg, locked) or nil
	window:set_config_overrides(o)
end
wezterm.on("window-config-reloaded", retint)
wezterm.on("user-var-changed", function(window, pane, name, value)
	if name == "wez" and cockpit[value] then
		return window:perform_action(cockpit[value], pane)
	end
	if name == "bg" then
		wezterm.GLOBAL.bg = value
		return retint(window)
	end
	if name == "lock" then
		wezterm.GLOBAL.locked = value == "1" or nil
		return retint(window)
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
-- off-screen while it still reports fullscreen, hiding the frame's bottom edge, so
-- every resize re-fills a window whose width matches no screen (throttled 2 s),
-- unless Alt+Enter took that window out of fullscreen.
-- The frame extends behind the MacBook notch (full panel height; the band
-- beside the notch holds the top text row). Width only in `fill`: a frame
-- macOS pushes down out of the notch keeps its size, so height is no signal.
-- manual → internals/wezterm.
config.native_macos_fullscreen_mode = false
config.macos_fullscreen_extend_behind_notch = true
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

-- An opaque macOS window gets a shadow and a light 1 px frame line; drop both.
config.window_decorations = "RESIZE|MACOS_FORCE_DISABLE_SHADOW"
config.default_cursor_style = "BlinkingBlock"
-- The background image `wezterm-bg` renders (blur baked in) and its darkness.
-- manual → internals/wezterm, "Background".
local bg_dir = home .. "/.local/state/wezterm/"
wezterm.add_to_config_reload_watch_list(bg_dir .. "background.txt")
wezterm.add_to_config_reload_watch_list(bg_dir .. "background")
local bg_state = io.open(bg_dir .. "background.txt")
local bg_img = io.open(bg_dir .. "background")
if bg_state and bg_img then
	-- The source is on the watch too: replacing that file re-renders it
	-- (only when it is newer than the render, so the reload this causes stops).
	local src = bg_state:read("l")
	bg_key = (src or "") .. " " .. (bg_state:read("a") or "") .. " "
	bg_state:seek("set")
	bg_state:read("l")
	wezterm.add_to_config_reload_watch_list(src)
	-- WezTerm's own env lacks magick; hand it the PATH panes get.
	wezterm.background_child_process({
		"env", "PATH=" .. config.set_environment_variables.PATH,
		"sh", "-c", '[ "$1" -nt "$2" ] && exec wezterm-bg "$1"', "_", src, bg_dir .. "background",
	})
	bg_state:read("l")
	local dark = tonumber(bg_state:read("l")) or 60
	local tint = math.min(tonumber(bg_state:read("l")) or 0, 100)
	config.background = {
		{
			source = { File = bg_dir .. "background" },
			width = "Cover",
			height = "Cover",
			-- Cover crops from the top left unless told to centre.
			horizontal_align = "Center",
			vertical_align = "Middle",
			repeat_x = "NoRepeat",
			repeat_y = "NoRepeat",
			-- Every 20 halves the brightness: the image nears black as dark grows
			-- but never gets there, so the last stretch stays fine-tunable.
			hsb = { brightness = 0.5 ^ (dark / 20) },
		},
	}
	-- Tint: the theme's background (base00) laid over the image at tint %,
	-- 100 = only the colour. theme.sh's `bg` user var recolours open windows
	-- through tinted(); theme-bg (on the watch) seeds new ones. Not tinty's
	-- current_scheme: a symlink into artifacts/ a theme pick never repainted.
	local image = config.background[1]
	-- The lock image falls back to the source until wezterm-bg has rendered it.
	local lf = io.open(bg_dir .. "background.lock")
	local sharp = { source = { File = lf and bg_dir .. "background.lock" or src }, width = "Cover", height = "Cover", horizontal_align = "Center", vertical_align = "Middle", repeat_x = "NoRepeat", repeat_y = "NoRepeat" }
	if lf then
		lf:close()
	end
	tinted = function(base00, locked)
		if locked then
			return { sharp }
		end
		if not (base00 and base00:match("^#%x%x%x%x%x%x$")) or tint <= 0 then
			return { image }
		end
		return { image, { source = { Color = base00 }, width = "100%", height = "100%", opacity = tint / 100 } }
	end
	wezterm.add_to_config_reload_watch_list(bg_dir .. "theme-bg")
	local tf = io.open(bg_dir .. "theme-bg")
	seed_bg = tf and tf:read("l")
	config.background = tinted(seed_bg)
	if tf then
		tf:close()
	end
end
if bg_state then
	bg_state:close()
end
if bg_img then
	bg_img:close()
end
config.audible_bell = "Disabled"
-- Zero padding anchors the grid top-left; the sub-cell remainder sits at the
-- right and bottom edges, so the grid never shifts on fullscreen or resize.
config.window_padding = { left = 0, right = 0, top = 0, bottom = 0 }
config.adjust_window_size_when_changing_font_size = false
config.front_end = "WebGpu"
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
	-- Cmd+←/→ step through tmux's windows. WezTerm only relays a key no
	-- program here binds (Ctrl+Alt+Shift+arrow); tmux.conf maps it.
	{ key = "LeftArrow", mods = "SUPER", action = act.SendKey({ key = "LeftArrow", mods = "CTRL|ALT|SHIFT" }) },
	{ key = "RightArrow", mods = "SUPER", action = act.SendKey({ key = "RightArrow", mods = "CTRL|ALT|SHIFT" }) },
	{ key = "v", mods = "CTRL", action = act.PasteFrom("Clipboard") },
	-- Mouse ownership moved to tmux (`mouse on`); its own copy-mode Ctrl+C
	-- handles select-then-copy now, so this just passes the key through.
	{ key = "c", mods = "CTRL", action = act.SendKey({ key = "c", mods = "CTRL" }) },
}
-- Alt+Enter: leaving fullscreen opts this window out of `fill`; entering opts
-- back in.
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
