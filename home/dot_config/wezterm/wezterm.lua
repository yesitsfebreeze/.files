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
    -- Windows is a thin host: launch into WSL. A login (-l) bash sets PATH so `nu`
    -- resolves, then immediately execs it; `|| exec bash` keeps the terminal usable
    -- if nu isn't installed yet. NOT interactive (-i): that sources ~/.bashrc (nvm,
    -- etc.) — ~1-2s of work for a bash we replace instantly. -l alone is ~0.04s.
    config.default_prog = { "wsl.exe", "-d", "Ubuntu", "--cd", "~", "-e", "bash", "-lc", "exec nu || exec bash" }
else
    config.default_prog = { "nu", "--config", nu_config, "--env-config", nu_env }
end

config.set_environment_variables = {
    XDG_CONFIG_HOME = home .. "/.config",
}

-- A GUI-launched WezTerm inherits launchd's minimal PATH (/usr/bin:/bin:/usr/sbin:
-- /sbin), which lacks Homebrew — so the bare `nu` in default_prog above can't be
-- found and the window dies with "No viable candidates found in PATH". Seed the
-- Homebrew + user bin dirs here so the nu binary resolves at spawn time; env.nu
-- then owns PATH inside the shell. macOS only — Linux/WSL already have nu on PATH.
if is_mac then
    config.set_environment_variables.PATH =
        "/opt/homebrew/bin:/opt/homebrew/sbin:"
        .. home .. "/.local/bin:" .. home .. "/.cargo/bin:"
        .. (os.getenv("PATH") or "")
end

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
-- Capture the theme background; the background overlay layer (below) uses it as the
-- 75% wash over the blurred image, and the no-image fallback paints it solid.
local tinty_bg = (ok and type(tinty_colors) == "table") and tinty_colors.background or nil
if ok and type(tinty_colors) == "table" then
    -- Keep tinty's background: the layered background model below is opaque (no
    -- see-through canvas to protect), so the terminal cells should paint the real
    -- theme bg for text legibility over the image/overlay. The ANSI/fg/cursor
    -- palette retints live as before.
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

-- Layered window background (ctrl+shift+b sets it from a URL): when a baked
-- background.png exists it's the bottom layer (sized to cover) with the active
-- theme bg washed over it at 75% so text stays legible; with no image the window
-- is just the solid theme bg. Either way the window is fully opaque — no
-- see-through desktop. The centered padding (center_grid) frames the grid.
config.window_decorations = "RESIZE"
config.window_padding = { left = 0, right = 0, top = 0, bottom = 0 }

-- Background overlay color: the live tinty theme bg, falling back to gruvbox dark
-- hard base00 (NOT pure black, which diverges from the scheme) before any theme.
local overlay = tinty_bg or "#1d2021"
local bg_file = wezterm.config_dir .. "/background.png"
local bg_exists = false
do
    local f = io.open(bg_file, "r")
    if f then
        f:close()
        bg_exists = true
    end
end
if bg_exists then
    config.background = {
        {
            source = { File = bg_file },
            width = "100%",
            height = "100%",
            horizontal_align = "Center",
            vertical_align = "Middle",
            repeat_x = "NoRepeat",
            repeat_y = "NoRepeat",
        },
        {
            source = { Color = overlay },
            width = "100%",
            height = "100%",
            opacity = 0.75,
        },
    }
else
    -- No image: single source of truth for the solid case is the cell background.
    config.colors = config.colors or {}
    config.colors.background = overlay
end
config.inactive_pane_hsb = { saturation = 0.85, brightness = 0.7 }
config.scrollback_lines = 10000
config.audible_bell = "Disabled"

-- OpenGL, not WebGpu: the layered config.background (File image + Color overlay
-- with per-layer opacity) has the same backend sensitivity the old translucent
-- window did — WebGpu on the Windows/D3D12 backend (this config's host: WSL
-- launches into the Windows wezterm.exe) mis-composites layered/opacity
-- backgrounds, so OpenGL is the safe choice and is still GPU-accelerated. max_fps
-- is uncapped to 255 (WezTerm's ceiling) so frames present as fast as produced, and
-- animation_fps matches so cursor blink / smooth-scroll never throttle below it.
config.front_end = "OpenGL"
config.max_fps = 255
config.animation_fps = 255

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

-- ctrl+shift+b background pipeline. The keybind callback runs inside the active
-- wezterm binary; on the WSL→Windows host that's wezterm.exe, so we route the
-- ENTIRE download+blur+commit through a single `wsl.exe … bash -lc` call into the
-- same WSL distro the terminal uses — one POSIX code path everywhere, no
-- PowerShell, no conhost flash (wsl.exe runs windowless from wezterm-gui; see the
-- "No WezTerm plugins" note above on the os.execute conhost lesson). We pass argv,
-- never a shell string, and never os.execute.
local function run_bg_script(script)
    local argv
    if is_windows then
        argv = { "wsl.exe", "-d", "Ubuntu", "-e", "bash", "-lc", script }
    else
        argv = { "sh", "-lc", script }
    end
    -- Login shell (-lc) so PATH resolves magick/convert/curl/wslpath/chezmoi.
    -- run_child_process is synchronous (returns success/stdout/stderr) so we can
    -- branch on failure; it briefly blocks the GUI thread during the download.
    return wezterm.run_child_process(argv)
end

-- Single POSIX script: derive both dest paths in-shell (no host paths hardcoded),
-- download to a temp, bake a 16px gaussian blur, write to the committed chezmoi
-- source AND the live path the running wezterm reads. set -e is on, so every
-- command-substitution that can fail is guarded. The url is single-quoted in only
-- after Lua-side validation (below) already rejected control chars, quotes, and
-- anything not matching ^https?://[^%s]+$.
local function set_background_from_url(url)
    local script = table.concat({
        "set -e",
        "url='" .. url .. "'",
        'tmp="$(mktemp)"',
        'src_dir="$(chezmoi source-path "$HOME/.config/wezterm")"',
        '[ -n "$src_dir" ] || exit 1',
        'mkdir -p "$src_dir"',
        'committed="$src_dir/background.png"',
        "if grep -qi microsoft /proc/version 2>/dev/null; then "
            .. "winhome=\"$(wslpath \"$(cmd.exe /c 'echo %USERPROFILE%' 2>/dev/null | tr -d '\\r\\n')\" 2>/dev/null)\"; "
            .. '{ [ -n "$winhome" ] && [ -d "$winhome" ]; } || exit 1; '
            .. 'live="$winhome/.config/wezterm/background.png"; '
            .. 'else live="$HOME/.config/wezterm/background.png"; fi',
        'mkdir -p "$(dirname "$live")"',
        'curl -fsSL "$url" -o "$tmp"',
        "blur() { if command -v magick >/dev/null 2>&1; then magick \"$1\" -blur 0x16 \"$2\"; "
            .. 'else convert "$1" -blur 0x16 "$2"; fi; }',
        'blur "$tmp" "$committed"',
        'cp "$committed" "$live"',
        'rm -f "$tmp"',
    }, "; ")
    local success, _, stderr = run_bg_script(script)
    if success then
        wezterm.reload_configuration()
    else
        wezterm.log_error("set background failed: " .. (stderr or ""))
    end
end

-- Empty-enter clear: remove both the live display copy and the committed source,
-- via the same single WSL/POSIX path so the running (Windows) wezterm stops
-- showing it, then reload to fall back to the solid theme bg.
local function clear_background()
    local script = table.concat({
        'src_dir="$(chezmoi source-path "$HOME/.config/wezterm" 2>/dev/null)"',
        '[ -n "$src_dir" ] && rm -f "$src_dir/background.png"',
        "if grep -qi microsoft /proc/version 2>/dev/null; then "
            .. "winhome=\"$(wslpath \"$(cmd.exe /c 'echo %USERPROFILE%' 2>/dev/null | tr -d '\\r\\n')\" 2>/dev/null)\"; "
            .. '[ -n "$winhome" ] && rm -f "$winhome/.config/wezterm/background.png"; '
            .. 'else rm -f "$HOME/.config/wezterm/background.png"; fi',
        "true",
    }, "; ")
    run_bg_script(script)
    wezterm.reload_configuration()
end

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
    -- CTRL-SHIFT-B: prompt for an image URL, download + blur it, set as window bg.
    {
        key = "b",
        mods = "CTRL|SHIFT",
        action = act.PromptInputLine({
            description = wezterm.format({
                { Attribute = { Intensity = "Bold" } },
                { Foreground = { AnsiColor = "Fuchsia" } },
                { Text = "Paste image URL (empty to clear):" },
            }),
            action = wezterm.action_callback(function(_window, _pane, line)
                -- nil  -> ESC: do nothing.
                -- ""   -> empty enter: clear the background.
                -- else -> validate, then download+blur+set.
                if line == nil then
                    return
                end
                if line == "" then
                    clear_background()
                    return
                end
                -- Validate in Lua before interpolating into the shell script: reject
                -- any control char (newline/CR), require a full-line-anchored URL,
                -- and reject single quotes (which would break the 'url=...' literal).
                if line:match("[%c]") or line:find("'", 1, true)
                    or not line:match("^https?://[^%s]+$") then
                    wezterm.log_error("ignored invalid background URL")
                    return
                end
                set_background_from_url(line)
            end),
        }),
    },
}

return config
