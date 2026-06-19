-- WezTerm: a plain cross-platform host terminal. Multiplexing lives in the shell
-- via burrito, not here, so the setup is portable to any terminal. Colors come
-- from WezTerm's builtin "Gruvbox dark, hard (base16)" scheme as the base; the
-- shell's tinty `theme` switcher retints the ANSI palette live on top via
-- tinted-shell OSC sequences, so WezTerm follows your pick without templating.

local wezterm = require("wezterm")
local act = wezterm.action
local config = wezterm.config_builder()

local triple = wezterm.target_triple
local is_windows = triple:find("windows") ~= nil
local is_mac = triple:find("darwin") ~= nil

local home = os.getenv("HOME") or os.getenv("USERPROFILE") or ""

-- Explicit config dir so the same ~/.config/nushell files are used on every OS.
local nu_config = home .. "/.config/nushell/config.nu"
local nu_env = home .. "/.config/nushell/env.nu"

if is_windows then
    -- Windows is a thin host: launch into WSL. The login shell (-lic) sets PATH
    -- so `nu` resolves; `|| exec bash` keeps the terminal usable if nu isn't
    -- installed in WSL yet.
    config.default_prog = { "wsl.exe", "-d", "Ubuntu", "--cd", "~", "-e", "bash", "-lic", "exec nu || exec bash" }
else
    config.default_prog = { "nu", "--config", nu_config, "--env-config", nu_env }
end

config.set_environment_variables = {
    XDG_CONFIG_HOME = home .. "/.config",
}

-- Always launch fullscreen. WezTerm renders an integer grid of cells and never
-- stretches glyphs, so the grid almost never divides the screen exactly; the
-- leftover sub-cell pixels would sit as an uneven gap on the right/bottom. We
-- center the grid by splitting that leftover into symmetric padding (see below).
wezterm.on("gui-startup", function(cmd)
    local _, _, window = wezterm.mux.spawn_window(cmd or {})
    window:gui_window():toggle_fullscreen()
end)

-- Keep the grid centered. The grid is an integer number of cells, so it almost
-- never divides the window exactly; the sub-cell remainder would sit as an uneven
-- gap on the right/bottom. We measure the true cell size, recompute how many whole
-- cells fit the window, and push the leftover into symmetric padding. Adapts to
-- any font size, DPI or resolution automatically (resize, zoom, monitor swap).
local function center_grid(window)
    -- Reach the tab through the mux window, not window:active_pane():tab(): an
    -- overlay (debug overlay, char select, launcher) makes the active pane a
    -- detached one whose :tab() is nil, which crashed center_grid mid-flight and
    -- left the stale padding in place. mux_window():active_tab() always resolves
    -- the real underlying tab, so update-status keeps centering even over overlays.
    local mux_win = window:mux_window()
    if not mux_win then
        return
    end
    local mux_tab = mux_win:active_tab()
    if not mux_tab then
        return
    end
    local win = window:get_dimensions()
    -- Measure the cell size DIRECTLY from the grid's own rendered pixel area
    -- instead of reconstructing it from window-minus-padding. tab:get_size()
    -- reports {cols, rows, pixel_width, pixel_height} for the actual grid, so
    -- cell = pixels / count is exact and independent of the padding we set --
    -- which matters under fractional DPI (the cell isn't a whole pixel) and during
    -- the multi-frame settle after a font zoom, where the old reconstruction read
    -- stale padding and produced a wrong cell size.
    local tab = mux_tab:get_size()
    if not win or not tab or tab.cols == 0 or tab.rows == 0
        or tab.pixel_width == 0 or tab.pixel_height == 0 then
        return
    end
    local cell_w = tab.pixel_width / tab.cols
    local cell_h = tab.pixel_height / tab.rows
    if cell_w <= 0 or cell_h <= 0 then
        return
    end

    local overrides = window:get_config_overrides() or {}
    local pad = overrides.window_padding
        or { left = 0, right = 0, top = 0, bottom = 0 }

    -- Vertical chrome (the tab bar, when shown) lives outside the grid: it's the
    -- window height not accounted for by the grid plus the padding we set. Subtract
    -- it so the grid centers in the region BELOW the tab bar rather than drifting
    -- down by the bar's height. Zero whenever the tab bar is hidden (the usual case
    -- here -- burrito owns multiplexing, so there's a single tab).
    local chrome_h = win.pixel_height - tab.pixel_height - pad.top - pad.bottom
    if chrome_h < 0 then
        chrome_h = 0
    end
    local avail_w = win.pixel_width
    local avail_h = win.pixel_height - chrome_h

    -- Fit as many whole cells as the FULL available space allows, then the gap is
    -- whatever those cells leave over: gap = avail - count*cell, in [0, cell). This
    -- is absolute (computed from the constant window, never folding the current
    -- padding back in), so a given font always yields the same padding regardless
    -- of zoom history -- it can't ratchet the grid smaller over time.
    local cols = math.floor(avail_w / cell_w)
    local rows = math.floor(avail_h / cell_h)
    local gap_x = avail_w - cols * cell_w
    local gap_y = avail_h - rows * cell_h

    -- floor() the TOTAL gap before splitting so the padding we apply is never more
    -- than the true gap. Over-padding by even a sub-pixel (possible when the cell
    -- isn't a whole pixel) shrinks the usable area below cols*cell, dropping a
    -- column that the next tick adds back -- a 1Hz flicker. Under-padding by <1px
    -- is invisible and stable. With whole-pixel cells the gap is already integral,
    -- so this centers exactly.
    local tot_x = math.floor(gap_x)
    local tot_y = math.floor(gap_y)
    local new_pad = {
        left = math.floor(tot_x / 2),
        right = tot_x - math.floor(tot_x / 2),
        top = math.floor(tot_y / 2),
        bottom = tot_y - math.floor(tot_y / 2),
    }

    -- TEMP DEBUG: dump the live geometry so we can see why a gap survives. View it
    -- with the debug overlay (CTRL+SHIFT+L) and look for "CENTER_GRID" lines.
    wezterm.log_info(string.format(
        "CENTER_GRID win=%dx%d tab=%dx%d(%dc x %dr) cell=%.3fx%.3f chrome_h=%d availh=%d rows=%d gap=%.2fx%.2f pad{l=%d r=%d t=%d b=%d}",
        win.pixel_width, win.pixel_height,
        tab.pixel_width, tab.pixel_height, tab.cols, tab.rows,
        cell_w, cell_h, chrome_h, avail_h, rows, gap_x, gap_y,
        new_pad.left, new_pad.right, new_pad.top, new_pad.bottom))

    -- Idempotency guard: set_config_overrides re-fires this event, so only write
    -- when the padding actually changes to avoid a feedback loop.
    if new_pad.left ~= pad.left or new_pad.right ~= pad.right
        or new_pad.top ~= pad.top or new_pad.bottom ~= pad.bottom then
        overrides.window_padding = new_pad
        window:set_config_overrides(overrides)
    end
end

-- Recenter on anything that can change the grid geometry: window/screen size
-- (window-resized, including dragging between differently-sized monitors), config
-- or font-size edits (window-config-reloaded), and interactive font zoom — which
-- fires neither of those, so the periodic update-status catches it within ~1s.
-- The padding guard inside center_grid keeps these cheap (no write unless the
-- computed padding actually changes).
wezterm.on("window-resized", center_grid)
wezterm.on("window-config-reloaded", center_grid)
wezterm.on("update-status", center_grid)

-- Colors from the active tinty theme, written by wezterm-colors.sh whenever the
-- theme changes. Falls back to the builtin gruvbox scheme if the file is absent
-- (e.g. first run before any theme has been picked).
local ok, tinty_colors = pcall(dofile, wezterm.config_dir .. "/colors.lua")
if ok and type(tinty_colors) == "table" then
    config.colors = tinty_colors
else
    config.color_scheme = "Gruvbox dark, hard (base16)"
end
config.default_cursor_style = "BlinkingBlock"

-- Font: DepartureMono Nerd Font (installed via packages.yaml `nerd-font`);
-- the rest are fallbacks.
config.font = wezterm.font_with_fallback({
    "DepartureMono Nerd Font",
    "Departure Mono",
    "JetBrainsMono Nerd Font",
    "Cascadia Code",
    "Menlo",
})
-- Larger size for fullscreen WQHD (2560x1440). Fine-tune live with Ctrl/Cmd +/-
-- until the bottom/right edge sits flush, then read rows*cols from the title.
config.font_size = is_mac and 14.0 or 12.0
config.line_height = 1.0

-- Keep the fullscreen window fixed when zooming the font. By default WezTerm
-- resizes the OS window to land on a whole number of cells; fullscreen can't
-- grow, so it instead leaves a large gap (padding above/below) and the window
-- appears to change size. Off = window stays put, the grid just reflows and
-- center_grid only absorbs the sub-cell residual.
config.adjust_window_size_when_changing_font_size = false

-- Also search the installer's per-user font dir, so a freshly-downloaded font
-- resolves before the system font cache refreshes.
if is_windows then
    config.font_dirs = { (os.getenv("LOCALAPPDATA") or (home .. "/AppData/Local")) .. "/Microsoft/Windows/Fonts" }
elseif is_mac then
    config.font_dirs = { home .. "/Library/Fonts" }
else
    config.font_dirs = { home .. "/.local/share/fonts" }
end

-- Translucent window; the centered padding (set live by center_grid) becomes a
-- thin translucent border frame around the grid. Starts at 0 so center_grid has
-- a clean baseline to measure the cell size from on the first resize.
config.window_background_opacity = 0.0
config.window_decorations = "RESIZE"
config.window_padding = { left = 0, right = 0, top = 0, bottom = 0 }
config.inactive_pane_hsb = { saturation = 0.85, brightness = 0.7 }
config.scrollback_lines = 10000
config.audible_bell = "Disabled"

-- Kitty keyboard protocol: lets the shell see the FULL modifier set on a key, so
-- e.g. Ctrl+Shift+R arrives distinct from Ctrl+R (a legacy terminal collapses both
-- to ^R, dropping shift on ctrl+letter). Pairs with nushell's `use_kitty_protocol`
-- in config.nu, which keys local vs global history pickers off exactly that
-- distinction. Defaults to false in WezTerm, so it must be opted into here.
config.enable_kitty_keyboard = true

config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = true
config.tab_bar_at_bottom = false
config.show_new_tab_button_in_tab_bar = false

wezterm.on("update-right-status", function(window, _pane)
    window:set_right_status(wezterm.format({
        { Foreground = { AnsiColor = "Blue" } },
        { Text = "  " .. window:active_workspace() .. "  " },
    }))
end)

-- No WezTerm plugins, by design: resurrect.wezterm was removed because at config
-- load it shells out via os.execute(), and wezterm-gui has no console, so Windows
-- spawned a visible conhost window per call — flashing terminals on every launch.
-- Keybindings are terminal-level only; burrito owns the grid (its leader is
-- ctrl+space), so there's no leader or mux emulation here.
config.keys = {
    { key = "v", mods = "CTRL", action = act.PasteFrom("Clipboard") },
    -- CTRL-C copies when a selection exists, otherwise falls through to the
    -- shell as a normal interrupt (SIGINT) so it keeps its terminal meaning.
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
    -- Solo the terminal: minimize every OTHER window, keeping WezTerm focused.
    -- The binding only fires while WezTerm already has focus, so the foreground
    -- window IS this terminal; each platform minimizes all windows EXCEPT it, so
    -- WezTerm is never minimized and there's no fragile re-raise to time. The
    -- OS-level part can't be expressed in Lua, so we shell out to a per-OS helper
    -- that lives beside this config (the WSL run_after hook mirrors this dir into
    -- the Windows profile, so the .vbs/.ps1 are there too). Rebind the key freely.
    {
        key = "m",
        mods = "CTRL|SHIFT",
        action = wezterm.action_callback(function(window, _pane)
            local sep = is_windows and "\\" or "/"
            local dir = wezterm.config_dir
            if is_windows then
                -- wscript is a GUI-subsystem host: launching the .vbs allocates no
                -- console, so there's no conhost flash — the same reason os.execute
                -- is banned above. The .vbs in turn runs the P/Invoke .ps1 hidden.
                wezterm.background_child_process({ "wscript", dir .. sep .. "solo-window.vbs" })
            elseif is_mac then
                wezterm.background_child_process({ "osascript", dir .. sep .. "solo-window.applescript" })
            else
                wezterm.background_child_process({ "bash", dir .. sep .. "solo-window.sh" })
            end
            window:focus()
        end),
    },
}

return config
