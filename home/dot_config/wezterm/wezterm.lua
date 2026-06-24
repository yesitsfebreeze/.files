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

-- The WSL distro the Windows host launches into; shared by default_prog and the
-- background script's wsl.exe spawn so the two can't drift.
local WSL_DISTRO = "Ubuntu"

local home = os.getenv("HOME") or os.getenv("USERPROFILE") or ""

-- Explicit config dir so the same ~/.config/nushell files are used on every OS.
local nu_config = home .. "/.config/nushell/config.nu"
local nu_env = home .. "/.config/nushell/env.nu"

if is_windows then
    -- Windows is a thin host: launch into WSL. A login (-l) bash sets PATH so `nu`
    -- resolves, then immediately execs it; `|| exec bash` keeps the terminal usable
    -- if nu isn't installed yet. NOT interactive (-i): that sources ~/.bashrc (nvm,
    -- etc.) — ~1-2s of work for a bash we replace instantly. -l alone is ~0.04s.
    config.default_prog = { "wsl.exe", "-d", WSL_DISTRO, "--cd", "~", "-e", "bash", "-lc", "exec nu || exec bash" }
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
-- Interactive font zoom fires neither of the above, so a slow update-status tick
-- catches it within ~1s. center_grid only writes overrides when the computed padding
-- actually changes, so these idle ticks are nearly free.
wezterm.on("update-status", center_grid)

-- Colors from the active tinty theme, written by wezterm-colors.sh whenever the
-- theme changes. Falls back to the builtin gruvbox scheme if the file is absent
-- (e.g. first run before any theme has been picked).
local ok, tinty_colors = pcall(dofile, wezterm.config_dir .. "/colors.lua")
-- Live preview: the tinty `theme` switcher rewrites colors.lua on every focus, so
-- watch it and let WezTerm auto-reload. That refreshes the bits only the config can
-- set — window background / overlay wash, cursor, selection — across the whole
-- window (the ANSI palette already retints live via tinted-shell OSC). On the
-- WSL→Windows host config_dir is the Windows profile copy, which wezterm-colors.sh
-- mirrors to, so the running wezterm.exe reloads too.
wezterm.add_to_config_reload_watch_list(wezterm.config_dir .. "/colors.lua")
-- Capture the theme background; the background overlay layer (below) uses it as the
-- heavy wash over the blurred image, and the no-image fallback paints it solid.
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

-- Transparent, blurred window: there's no wezterm image layer anymore. The theme
-- bg is painted as the translucent cell color and the OS composites a blur behind
-- it, so the desktop wallpaper (set by ctrl+shift+b, below) reads through softly.
-- The centered padding (center_grid) frames the grid.
config.window_decorations = "RESIZE"
config.window_padding = { left = 0, right = 0, top = 0, bottom = 0 }

-- The translucent tint is the live tinty theme bg, falling back to gruvbox dark
-- hard base00 (NOT pure black, which diverges from the scheme) before any theme.
local overlay = tinty_bg or "#1d2021"
config.colors = config.colors or {}
config.colors.background = overlay

-- Use the terminal background color for the opacity: the cell bg above goes
-- translucent at this alpha so the blurred desktop shows through it on every OS.
config.window_background_opacity = 0.618
-- Per-OS blur behind the translucent window. macOS and KDE expose it directly;
-- Windows uses the Acrylic system backdrop (its own blur + translucency).
config.macos_window_background_blur = 30
config.kde_window_background_blur = true
if is_windows then
    config.win32_system_backdrop = "Acrylic"
end
config.inactive_pane_hsb = { saturation = 0.85, brightness = 0.7 }
config.scrollback_lines = 10000
config.audible_bell = "Disabled"

-- Slow tick: update-status now only exists to catch interactive font zoom for
-- center_grid (registered above), which fires no resize/reload event. 1s is plenty,
-- and the padding guard keeps the idle ticks nearly free.
config.status_update_interval = 1000

-- OpenGL, not WebGpu: window transparency + the OS backdrop blur have the same
-- backend sensitivity the old layered background did — WebGpu on the Windows/D3D12
-- backend (this config's host: WSL launches into the Windows wezterm.exe)
-- mis-composites translucent windows, so OpenGL is the safe choice and is still
-- GPU-accelerated. max_fps is uncapped to 255 (WezTerm's ceiling) so frames present
-- as fast as produced, and animation_fps matches so cursor blink / smooth-scroll
-- never throttle below it.
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

-- Theme the retro tab bar from the active tinty palette so it tracks the live
-- scheme like the rest of the window (colors.lua is on the reload-watch list, so a
-- theme switch retints this on the next reload). Derived only from named palette
-- entries — never hardcoded — so it follows any scheme. Skipped on the builtin
-- gruvbox fallback, where WezTerm already derives a bar from the scheme itself.
if ok and type(tinty_colors) == "table" then
    local p = config.colors
    local br = p.brights or {}
    p.tab_bar = {
        background = p.background,
        active_tab = { bg_color = p.selection_bg or br[1], fg_color = br[8] or p.foreground },
        inactive_tab = { bg_color = p.background, fg_color = br[1] or p.foreground },
        inactive_tab_hover = { bg_color = br[4] or p.selection_bg, fg_color = p.foreground, italic = false },
        new_tab = { bg_color = p.background, fg_color = br[1] or p.foreground },
        new_tab_hover = { bg_color = br[4] or p.selection_bg, fg_color = p.foreground },
    }
end

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
        argv = { "wsl.exe", "-d", WSL_DISTRO, "-e", "bash", "-lc", script }
    else
        argv = { "sh", "-lc", script }
    end
    -- Login shell (-lc) so PATH resolves magick/convert/curl/wslpath/chezmoi.
    -- run_child_process is synchronous (returns success/stdout/stderr) so we can
    -- branch on failure; it briefly blocks the GUI thread during the download.
    return wezterm.run_child_process(argv)
end

-- Single POSIX script: derive both dest DIRS in-shell (no host paths hardcoded),
-- obtain the image (download an http(s) URL, or copy a local file -- a file:// URL,
-- ~ path, POSIX path, or a Windows path via wslpath), then write the 16px gaussian
-- BLUR (background.png) to BOTH the committed chezmoi source AND a live dir, then
-- apply that blurred copy as the OS desktop wallpaper. set -e is on, so every
-- command-sub that can fail is guarded.
-- The input is single-quoted in only after Lua-side validation (below) already
-- rejected control chars and single quotes.
--
-- WSL live-dir derivation is strict (FIX B): cmd.exe|tr exits 0 even when cmd.exe
-- fails, leaving $up empty, and `wslpath ""` returns "." (a valid dir) -- which
-- would silently write under wsl.exe's CWD. So require a drive letter on the raw
-- value AND an absolute wslpath result before trusting it.
local WIN_LIVE_DIR =
    'up="$(cmd.exe /c \'echo %USERPROFILE%\' 2>/dev/null | tr -d \'\\r\\n\')"; '
    .. 'case "$up" in [A-Za-z]:*) ;; *) exit 1 ;; esac; '
    .. 'winhome="$(wslpath -u "$up" 2>/dev/null)" || exit 1; '
    .. 'case "$winhome" in /*) ;; *) exit 1 ;; esac; '
    .. '[ -d "$winhome" ] || exit 1; '
    .. 'live_dir="$winhome/.config/wezterm"'

local function set_background(input)
    local script = table.concat({
        "set -e",
        "input='" .. input .. "'",
        'tmp="$(mktemp)"',
        -- FIX E: GUI-launched wezterm inherits launchd's minimal PATH on macOS, so
        -- sh -lc won't find brew's magick/curl; seed Homebrew up front (no-op on
        -- linux/WSL, where bash -lc already has /usr/bin).
        'export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"',
        -- FIX C: clean the temp on any exit/interrupt, not just the success path.
        'blurred="$tmp.blur"',
        "trap 'rm -f \"$tmp\" \"$blurred\"' EXIT INT TERM",
        'src_dir="$(chezmoi source-path "$HOME/.config/wezterm" 2>/dev/null)" || exit 1',
        '[ -n "$src_dir" ] || exit 1',
        'mkdir -p "$src_dir"',
        "if grep -qi microsoft /proc/version 2>/dev/null; then " .. WIN_LIVE_DIR .. "; "
            .. 'else live_dir="$HOME/.config/wezterm"; fi',
        'mkdir -p "$live_dir"',
        -- Obtain the source image into $tmp: download http(s) URLs, else treat the
        -- input as a local file -- strip a file:// prefix, expand a leading ~, and
        -- convert a Windows drive path via wslpath (WSL only). A missing local file
        -- aborts before any dest write.
        'case "$input" in '
            .. 'http://*|https://*) curl -fsSL "$input" -o "$tmp" ;; '
            .. '*) src="${input#file://}"; '
            .. 'case "$src" in "~/"*) src="$HOME/${src#\\~/}" ;; esac; '
            .. 'case "$src" in [A-Za-z]:[/\\\\]*) if command -v wslpath >/dev/null 2>&1; then src="$(wslpath -u "$src")"; fi ;; esac; '
            .. '[ -f "$src" ] || exit 1; cp "$src" "$tmp" ;; '
            .. "esac",
        "blur() { if command -v magick >/dev/null 2>&1; then magick \"$1\" -blur 0x16 \"$2\"; "
            .. 'else convert "$1" -blur 0x16 "$2"; fi; }',
        -- Blur into a temp FIRST: this doubles as image validation. A non-image input
        -- (e.g. an HTML page from a non-direct URL) makes magick/convert fail here, and
        -- set -e aborts before ANY dest file is written. Only once the blur succeeds do
        -- we publish to both dirs.
        'blur "$tmp" "$blurred"',
        'cp "$blurred" "$src_dir/background.png"',
        'cp "$blurred" "$live_dir/background.png"',
        -- Apply that blurred copy as the OS DESKTOP wallpaper (not a wezterm layer):
        -- Windows (from WSL) via reg + rundll32 on the wslpath -w form, macOS via
        -- osascript, otherwise GNOME via gsettings. Best-effort per OS.
        'wp="$live_dir/background.png"',
        'if grep -qi microsoft /proc/version 2>/dev/null; then '
            .. 'win_wp="$(wslpath -w "$wp")"; '
            .. 'reg.exe add "HKCU\\Control Panel\\Desktop" /v Wallpaper /t REG_SZ /d "$win_wp" /f >/dev/null 2>&1 || true; '
            .. 'reg.exe add "HKCU\\Control Panel\\Desktop" /v WallpaperStyle /t REG_SZ /d 10 /f >/dev/null 2>&1 || true; '
            .. 'rundll32.exe user32.dll,UpdatePerUserSystemParameters 1, True >/dev/null 2>&1 || true; '
        .. 'elif [ "$(uname)" = "Darwin" ]; then '
            .. 'osascript -e "tell application \\"System Events\\" to tell every desktop to set picture to \\"$wp\\"" >/dev/null 2>&1 || true; '
        .. 'else '
            .. 'gsettings set org.gnome.desktop.background picture-uri "file://$wp" >/dev/null 2>&1 || true; '
            .. 'gsettings set org.gnome.desktop.background picture-uri-dark "file://$wp" >/dev/null 2>&1 || true; '
        .. 'fi',
    }, "; ")
    local success, _, stderr = run_bg_script(script)
    if not success then
        wezterm.log_error("set wallpaper failed: " .. (stderr or ""))
    end
end

-- Empty-enter clear: remove the background image at both the live display dir and the
-- committed source, via the same single WSL/POSIX path so the running (Windows)
-- wezterm stops showing it, then reload to fall back to the solid theme bg.
local function clear_background()
    -- Best-effort, no set -e: remove the committed copies first (always reachable),
    -- then the live copies. The live derivation reuses the same strict WIN_LIVE_DIR
    -- guard (FIX B) so a failed cmd.exe can never resolve live_dir to a relative "."
    -- and delete under the wrong CWD; on that failure it exits before the live rm,
    -- which is acceptable (the committed copy is already gone and the next reload
    -- falls back to the solid bg anyway).
    local script = table.concat({
        'src_dir="$(chezmoi source-path "$HOME/.config/wezterm" 2>/dev/null)"',
        '[ -n "$src_dir" ] && rm -f "$src_dir/background.png"',
        "if grep -qi microsoft /proc/version 2>/dev/null; then " .. WIN_LIVE_DIR .. "; "
            .. 'else live_dir="$HOME/.config/wezterm"; fi',
        'rm -f "$live_dir/background.png"',
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
    -- CTRL-SHIFT-B: prompt for an image URL or local path, blur it, set as OS wallpaper.
    {
        key = "b",
        mods = "CTRL|SHIFT",
        action = act.PromptInputLine({
            description = wezterm.format({
                { Attribute = { Intensity = "Bold" } },
                { Foreground = { AnsiColor = "Fuchsia" } },
                { Text = "Paste image URL or path (empty to clear):" },
            }),
            action = wezterm.action_callback(function(_window, _pane, line)
                -- nil  -> ESC: do nothing.
                -- ""   -> empty enter: clear the background.
                -- else -> validate, then fetch/copy + blur + set.
                if line == nil then
                    return
                end
                if line == "" then
                    clear_background()
                    return
                end
                -- Validate in Lua before interpolating into the shell script: reject
                -- any control char (newline/CR) and single quotes (which would break
                -- the 'input=...' literal). The shell decides URL vs local path; a bad
                -- one fails the download/copy or the blur, leaving no dest file behind.
                if line:match("[%c]") or line:find("'", 1, true) then
                    wezterm.log_error("ignored invalid background input")
                    return
                end
                set_background(line)
            end),
        }),
    },
}

return config
