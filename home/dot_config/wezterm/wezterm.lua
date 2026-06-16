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

-- Flip to true to log the raw geometry to the WezTerm log (Help > Show Debug
-- Overlay, or the GUI log file). Use this if the grid still looks off: it prints
-- the window pixels, grid cols/rows, recovered cell size and the leftover it
-- couldn't account for. A nonzero residual there means the cell isn't a whole
-- number of pixels (usually fractional display scaling), which no integer
-- padding can perfectly center.
local CENTER_DEBUG = false

-- Keep the grid centered. WezTerm exposes no cell-pixel API and renders an
-- integer grid of whole-pixel cells, so we recover the cell size from the window
-- pixels and the column/row counts, then push the leftover sub-cell pixels into
-- symmetric padding. Adapts to any font size, DPI or resolution automatically.
local function center_grid(window)
    local pane = window:active_pane()
    if not pane then
        return
    end
    local win = window:get_dimensions()
    local grid = pane:get_dimensions()
    if not win or grid.cols == 0 or grid.viewport_rows == 0 then
        return
    end

    local overrides = window:get_config_overrides() or {}
    local pad = overrides.window_padding
        or { left = 0, right = 0, top = 0, bottom = 0 }

    -- Pixels currently handed to the grid = window minus the padding we already
    -- added. usable / count rounds down to the exact integer cell size, because
    -- for real terminal geometries the remainder is far smaller than the count.
    local usable_w = win.pixel_width - pad.left - pad.right
    local usable_h = win.pixel_height - pad.top - pad.bottom
    local cell_w = math.floor(usable_w / grid.cols)
    local cell_h = math.floor(usable_h / grid.viewport_rows)
    if cell_w <= 0 or cell_h <= 0 then
        return
    end

    -- The grid tiles cols*cell_w pixels and leaves `usable % cell` unfilled on
    -- one edge. The total empty space is that residual PLUS the padding we have
    -- already applied; splitting that whole amount evenly is what centers the
    -- grid. This is self-correcting: once the padding absorbs the residual the
    -- usable size is an exact multiple of the cell, the residual is 0, and the
    -- padding stops changing -- so it converges instead of just looking right by
    -- coincidence (the old `win.pixel_width % cell_w` ignored the padding offset
    -- and only matched at steady state).
    local gap_x = pad.left + pad.right + (usable_w % cell_w)
    local gap_y = pad.top + pad.bottom + (usable_h % cell_h)
    local new_pad = {
        left = math.floor(gap_x / 2),
        right = math.ceil(gap_x / 2),
        top = math.floor(gap_y / 2),
        bottom = math.ceil(gap_y / 2),
    }

    if CENTER_DEBUG then
        wezterm.log_info(string.format(
            "center_grid: win=%dx%d grid=%dx%d cell=%dx%d residual=%d,%d pad=%d/%d,%d/%d",
            win.pixel_width, win.pixel_height, grid.cols, grid.viewport_rows,
            cell_w, cell_h, usable_w % cell_w, usable_h % cell_h,
            new_pad.left, new_pad.right, new_pad.top, new_pad.bottom))
    end

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

-- Appearance — builtin base16 gruvbox base; tinty retints ANSI live on top.
config.color_scheme = "Gruvbox dark, hard (base16)"
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
config.font_size = is_mac and 18.0 or 16.0
config.line_height = 1.0

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
config.window_background_opacity = 0.875
config.macos_window_background_blur = 20
config.window_decorations = "RESIZE"
config.window_padding = { left = 0, right = 0, top = 0, bottom = 0 }
config.inactive_pane_hsb = { saturation = 0.85, brightness = 0.7 }
config.scrollback_lines = 10000
config.audible_bell = "Disabled"

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
}

return config
