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

-- Launch fullscreen — EXCEPT on Windows, where GlazeWM tiles the window: a native
-- fullscreen toggle there fights the tiler (the window gets sized into its pane,
-- then snaps back to borderless fullscreen), so we let GlazeWM own the geometry and
-- center_grid still centers the grid inside whatever tile it's given. On mac/Linux
-- there's no GlazeWM, so keep the self-fullscreen. The grid is an integer number of
-- cells that rarely divides the screen exactly; the leftover sub-cell pixels are
-- split into symmetric padding by center_grid (below).
wezterm.on("gui-startup", function(cmd)
    local _, _, window = wezterm.mux.spawn_window(cmd or {})
    if not is_windows then
        window:gui_window():toggle_fullscreen()
    end
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

-- Search a per-user font dir so a freshly-installed font resolves before the system
-- font cache refreshes. NOT on Windows: there that dir is the OS per-user font
-- INSTALL location (here 2.1 GB / 525 Nerd Fonts), and WezTerm parses every file in
-- font_dirs at startup — scanning it dominated launch time. Windows registers those
-- fonts with DirectWrite, which WezTerm already queries, so they still resolve.
if is_mac then
    config.font_dirs = { home .. "/Library/Fonts" }
elseif not is_windows then
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
-- The retro tab bar reuses this exact value (baked into its rgba bg below) so the
-- bar reads as the same translucent surface as the cells, not a separate shade.
local window_opacity = 0.821
config.window_background_opacity = window_opacity
-- Blur: macOS frosts the desktop behind the window directly. Windows and Linux
-- have no reliable per-window blur from WezTerm — the Acrylic backdrop renders a
-- flat gray fallback whenever the window is unfocused or transparency effects are
-- off, and Linux blur is the compositor's job. But the wallpaper we set below is
-- ALREADY gaussian-blurred, so plain transparency shows a blurred backdrop on
-- every OS regardless; only macOS gets the extra live frosting.
config.macos_window_background_blur = 30
config.inactive_pane_hsb = { saturation = 0.85, brightness = 0.7 }
config.scrollback_lines = 10000
config.audible_bell = "Disabled"

-- Slow tick: the status interval drives BOTH update-status (→ center_grid, to catch
-- interactive font zoom, which fires no resize/reload event) AND update-right-status
-- (the workspace label). At 1s that repainted the tab bar every second forever — a
-- constant titlebar refresh for a label that almost never changes. 5s still recenters
-- a font zoom within a few seconds, and the padding guard keeps idle ticks near-free.
config.status_update_interval = 5000

-- OpenGL, not WebGpu: window transparency + the OS backdrop blur have the same
-- backend sensitivity the old layered background did — WebGpu on the Windows/D3D12
-- backend (this config's host: WSL launches into the Windows wezterm.exe)
-- mis-composites translucent windows, so OpenGL is the safe choice and is still
-- GPU-accelerated. fps is capped at 60: uncapping to 255 let WezTerm present every
-- redraw at up to 255 Hz, which combined with the periodic status repaint and cursor
-- blink kept the GPU/CPU churning for no visible benefit. 60 is smooth and idle-cheap.
config.front_end = "OpenGL"
config.max_fps = 60
config.animation_fps = 60

-- Kitty keyboard protocol: stays OFF, matching nushell's `use_kitty_protocol =
-- false` in config.nu. The two are a matched pair — with it on, reedline fires the
-- kitty support query at startup and the WSL2<->WezTerm pty returns the reply too
-- late to consume, so it leaks as `^[[?...u` and garbles the prompt before it's
-- visible. Enabling only the WezTerm half (the state this was left in) reproduces
-- that leak without buying anything, since the shell never opts in. WezTerm defaults
-- this to false, so the matched-off state needs no line; kept explicit as a marker.
config.enable_kitty_keyboard = false

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
    -- Tint a #RRGGBB translucently as an rgba() string (a in 0..1). WezTerm rejects
    -- #RRGGBBAA hex for tab-bar colors, but accepts rgba(r, g, b, a).
    local function with_alpha(hex, a)
        local r, g, b = (hex or ""):match("^#(%x%x)(%x%x)(%x%x)$")
        if not r then
            return hex
        end
        return string.format("rgba(%d, %d, %d, %s)", tonumber(r, 16), tonumber(g, 16), tonumber(b, 16), a)
    end
    -- The theme green (base0B = ansi slot 3), same accent as the GlazeWM outline.
    local green = (p.ansi and p.ansi[3]) or br[3] or p.selection_bg
    -- The translucent window surface: an explicit opaque hex paints the bar solid (it
    -- does NOT honor window_background_opacity), so bake the theme bg + window_opacity
    -- into an rgba — identical surface to the cells.
    local surface = with_alpha(p.background, window_opacity)
    -- Active tab is FILLED with the green accent, with the bg color as text so it
    -- stays readable on the accent. Inactive/new tabs sit on the same translucent
    -- surface as the strip with green text, so the active tab reads as inverted.
    p.tab_bar = {
        background = surface,
        active_tab = { bg_color = green, fg_color = p.background },
        inactive_tab = { bg_color = surface, fg_color = green },
        inactive_tab_hover = { bg_color = with_alpha(br[4] or p.selection_bg, "0.5"), fg_color = green, italic = false },
        new_tab = { bg_color = surface, fg_color = green },
        new_tab_hover = { bg_color = with_alpha(br[4] or p.selection_bg, "0.5"), fg_color = green },
    }
end

wezterm.on("update-right-status", function(window, pane)
    -- Show the pane's current working directory instead of the workspace name
    -- ("default", which never changes here — burrito owns multiplexing). Needs the
    -- shell to emit OSC 7; get_current_working_directory() returns nil otherwise, so
    -- fall back to the workspace name. $HOME is abbreviated to ~.
    local label = window:active_workspace()
    local cwd = pane:get_current_working_directory()
    if cwd then
        local path = type(cwd) == "userdata" and (cwd.file_path or cwd.path)
            or tostring(cwd):gsub("^file://[^/]*", "")
        if path and path ~= "" then
            local home = os.getenv("HOME") or os.getenv("USERPROFILE") or ""
            if home ~= "" and path:sub(1, #home) == home then
                path = "~" .. path:sub(#home + 1)
            end
            label = path
        end
    end
    window:set_right_status(wezterm.format({
        { Foreground = { AnsiColor = "Blue" } },
        { Text = "  " .. label .. "  " },
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

-- Copy mode: ctrl+shift+x freezes the scrollback and drops a movable cursor
-- (arrows/hjkl, plus all of WezTerm's default copy-mode motions + search). One
-- key drives the whole select-and-copy cycle: first `c` anchors a cell selection
-- at the cursor, you move to extend the highlight, second `c` copies the range to
-- the clipboard and leaves copy mode. We track the toggle per-pane rather than
-- reading the selection text back, because a selection that begins over blank
-- cells reads as empty and would desync the toggle. State is reset on entry, so a
-- copy mode exited any other way (q/Esc/y) can't leave it stale.
local copy_selecting = {}

-- Enter copy mode on a pane from a clean state: clear any stale selection and the
-- per-pane toggle flag so the first `c` always starts (never finishes) a selection.
-- Shared by the ctrl+shift+x keybind and the user-var trigger below.
local function enter_copy_mode(window, pane)
    copy_selecting[pane:pane_id()] = nil
    window:perform_action(act.ClearSelection, pane)
    window:perform_action(act.ActivateCopyMode, pane)
end

-- CTRL-Space toggles a native scratchpad pane, entirely inside WezTerm (no external
-- window manager). WezTerm has no floating panes (issue #3851) or pane-size animation, so we
-- fake a quake-style drop-down: the scratch is a TOP pane split off as a thin strip, then its
-- split boundary is stepped downward over a few frames so it slides in from the top edge, and
-- settles into a real zoom (full-window overlay) on the last frame. Hiding reverses the slide
-- and zooms the work pane back; the scratch shell keeps running underneath the whole time.
-- Caught at the GUI layer so CTRL-Space never reaches the pty. Windows-only, matching the old
-- GlazeWM float's scope; elsewhere CTRL-Space falls through to reedline.
--
-- The scratch shell is nu with SCRATCH_FLOAT=1, which runs dispatch.nu's `scratch_dispatch`:
-- an inline command line that reads ONE command and signals back over OSC 1337 user-vars
-- (handled below) so we either insert its result into the work pane, scrape a quick
-- program's output, or auto-promote a TUI into a split. Defined here (above the
-- user-var-changed handler) because that handler drives the same state.

-- Scrape markers: must match dispatch.nu. dispatch.nu brackets an external command's output
-- with these lines so we can slice it out of the pane's text.
local SCRATCH_MARK_BEGIN = "«scratch-out»"
local SCRATCH_MARK_END = "«/scratch-out»"

-- tab_id -> scratch pane_id (find the scratch again across toggles), and tab_id -> token
-- (a monotonically-bumped guard that cancels a running TUI watch when the command finishes).
local scratch_pane_for_tab = {}
local scratch_run_token = {}

local function find_pane(panes, id)
    if not id then
        return nil
    end
    for _, info in ipairs(panes) do
        if info.pane:pane_id() == id then
            return info
        end
    end
    return nil
end

-- Zoom a specific pane. The zoom flag tracks the active pane, so we can't re-point it at a
-- new target directly: unzoom first, activate the target, then zoom it.
local function zoom_pane(tab, pane)
    tab:set_zoomed(false)
    pane:activate()
    tab:set_zoomed(true)
end

-- The work pane of a tab = the one that isn't the scratch overlay.
local function work_pane(tab, scratch_id)
    for _, info in ipairs(tab:panes_with_info()) do
        if info.pane:pane_id() ~= scratch_id then
            return info.pane
        end
    end
    return nil
end

-- Quake-style slide: WezTerm has no floating panes or pane-size animation, so we fake the
-- drop-down by stepping the scratch pane's split boundary over a handful of frames. The
-- scratch is the TOP pane; growing it downward reads as a terminal sliding in from the top
-- edge. We settle into a real zoom on the last frame so the rest of the overlay machinery
-- (dispatch markers, dismiss, promote) keeps operating on a clean full-window pane.
local SCRATCH_SLIDE_FRAMES = 8
local SCRATCH_SLIDE_DT = 0.012

-- Grow the (top) scratch pane from its small split size to full over SCRATCH_SLIDE_FRAMES,
-- then zoom it for an exact full-window finish. `total_rows` is the window height in cells,
-- used only to size each step; overshoot is harmless (AdjustPaneSize clamps at the max).
local function slide_in(window, tab, scratch_pane, total_rows)
    local tid = tab:tab_id()
    local step = math.max(2, math.ceil(total_rows / SCRATCH_SLIDE_FRAMES))
    tab:set_zoomed(false)
    scratch_pane:activate()
    local i = 0
    local function frame()
        if scratch_pane_for_tab[tid] ~= scratch_pane:pane_id() then
            return -- closed or superseded mid-slide
        end
        i = i + 1
        if i >= SCRATCH_SLIDE_FRAMES then
            zoom_pane(tab, scratch_pane)
            return
        end
        window:perform_action(act.AdjustPaneSize({ "Down", step }), scratch_pane)
        wezterm.time.call_after(SCRATCH_SLIDE_DT, frame)
    end
    frame()
end

-- Reverse of slide_in: unzoom and shrink the scratch back up to a thin strip, then run
-- `finalize` (zoom the work pane to fully hide it, and for a dismiss also close + untrack).
-- The pane stays tracked through the whole slide so the frame guard doesn't abort early.
local function slide_out(window, tab, scratch_pane, finalize)
    local rows = scratch_pane:get_dimensions().viewport_rows
    local step = math.max(2, math.ceil(rows / SCRATCH_SLIDE_FRAMES))
    tab:set_zoomed(false)
    scratch_pane:activate()
    local i = 0
    local function frame()
        i = i + 1
        if i >= SCRATCH_SLIDE_FRAMES then
            finalize()
            return
        end
        window:perform_action(act.AdjustPaneSize({ "Up", step }), scratch_pane)
        wezterm.time.call_after(SCRATCH_SLIDE_DT, frame)
    end
    frame()
end

-- SpawnCommand for the scratch shell: the same nu as default_prog but with SCRATCH_FLOAT=1.
-- On the WSL→Windows host the var must be set INSIDE the bash -lc string (WSL doesn't inherit
-- Windows env without WSLENV); native hosts pass it via the env table.
local function scratch_spawn()
    if is_windows then
        return { args = { "wsl.exe", "-d", WSL_DISTRO, "--cd", "~", "-e", "bash", "-lc",
            "SCRATCH_FLOAT=1 exec nu --config ~/.config/nushell/config.nu"
            .. " --env-config ~/.config/nushell/env.nu || exec bash" } }
    end
    return {
        args = { "nu", "--config", nu_config, "--env-config", nu_env },
        set_environment_variables = { SCRATCH_FLOAT = "1" },
    }
end

-- Dismiss the overlay after its one command: optionally drop `text` at the work pane's prompt
-- (un-executed), hide the overlay by zooming the work pane, then close the scratch pane (its
-- nu has finished) and untrack so the next CTRL-Space spawns fresh.
local function dismiss_scratch(window, tab, scratch_pane, text)
    local tid = tab:tab_id()
    local work = work_pane(tab, scratch_pane:pane_id())
    -- Paste into the (still-hidden) work pane first, then slide the overlay back up; on the
    -- last frame zoom the work pane to fully reveal the result and close the spent scratch.
    if work and text and text ~= "" then
        -- Wrap in bracketed paste so the result lands as literal text at the prompt,
        -- un-executed even if it spans multiple lines — the user presses Enter.
        work:send_text("\x1b[200~" .. text .. "\x1b[201~")
    end
    slide_out(window, tab, scratch_pane, function()
        if work then
            zoom_pane(tab, work)
        end
        scratch_pane_for_tab[tid] = nil
        scratch_run_token[tid] = (scratch_run_token[tid] or 0) + 1
        window:perform_action(act.CloseCurrentPane({ confirm = false }), scratch_pane)
    end)
end

-- Pull a quick program's output out of the scratch pane: the text between the markers that
-- dispatch.nu printed around the run. "" if the markers aren't both present (e.g. a TUI that
-- was promoted instead). Plain (non-pattern) finds — the markers are literal byte strings.
local function scrape_between_markers(pane)
    local txt = pane:get_lines_as_text()
    local b = txt:find(SCRATCH_MARK_BEGIN, 1, true)
    if not b then
        return ""
    end
    local body_start = txt:find("\n", b, true)
    if not body_start then
        return ""
    end
    local e = txt:find(SCRATCH_MARK_END, body_start, true)
    if not e then
        return ""
    end
    local out = txt:sub(body_start + 1, e - 1)
    return (out:gsub("^%s+", ""):gsub("%s+$", ""))
end

-- Promote the overlay into a normal split (the running TUI keeps going in it). Reuses the
-- unzoom-and-activate move and untracks it, graduating it out of the overlay; bumps the token
-- so any in-flight TUI watch stops.
local function promote_scratch_pane(tab, scratch_pane)
    local tid = tab:tab_id()
    tab:set_zoomed(false)
    scratch_pane:activate()
    scratch_pane_for_tab[tid] = nil
    scratch_run_token[tid] = (scratch_run_token[tid] or 0) + 1
end

-- After an external command starts (scratch_running), watch the scratch pane for ~600ms: a
-- TUI flips alt-screen (parsed off the pty, so it works through WSL) -> promote to a split;
-- a TUI that never uses alt-screen (e.g. fzf --height) is caught by the fallback timeout. The
-- per-tab token cancels the watch the moment the command finishes (scratch_scrape) or it was
-- already promoted.
local SCRATCH_TUI_FALLBACK_MS = 600
local function watch_scratch_tui(window, tid, scratch_pane, token)
    local elapsed = 0
    local function poll()
        if scratch_run_token[tid] ~= token then
            return -- finished or superseded
        end
        if scratch_pane_for_tab[tid] ~= scratch_pane:pane_id() then
            return -- gone or already promoted
        end
        local ok, alt = pcall(function()
            return scratch_pane:is_alt_screen_active()
        end)
        local tab = window:mux_window():active_tab()
        if (ok and alt) or elapsed >= SCRATCH_TUI_FALLBACK_MS then
            if tab then
                promote_scratch_pane(tab, scratch_pane)
            end
            return
        end
        elapsed = elapsed + 50
        wezterm.time.call_after(0.05, poll)
    end
    wezterm.time.call_after(0.05, poll)
end

-- Shell-driven entry: a nu command prints an OSC 1337 SetUserVar sequence to stdout, WezTerm
-- parses it off the pty (even through the WSL→Windows host) and fires user-var-changed here.
--   copymode        -> drop the GUI into copy mode (value ignored).
--   scratch_running -> an external command just started in the overlay; arm the TUI watch.
--   scratch_result  -> a captured nu result; insert `value` at the work pane + dismiss.
--   scratch_scrape  -> a quick external finished; scrape its output + dismiss.
--   scratch_done    -> nothing to insert (empty line); just dismiss.
-- The scratch_* signals are no-ops once the pane has been promoted (it's a normal split then).
wezterm.on("user-var-changed", function(window, pane, name, value)
    if name == "copymode" then
        enter_copy_mode(window, pane)
        return
    end
    if name == "scratch_running" or name == "scratch_result"
        or name == "scratch_scrape" or name == "scratch_done" then
        local tab = window:mux_window():active_tab()
        if not tab then
            return
        end
        local tid = tab:tab_id()
        if scratch_pane_for_tab[tid] ~= pane:pane_id() then
            return -- promoted/stale: ignore
        end
        if name == "scratch_running" then
            local token = (scratch_run_token[tid] or 0) + 1
            scratch_run_token[tid] = token
            watch_scratch_tui(window, tid, pane, token)
        elseif name == "scratch_result" then
            dismiss_scratch(window, tab, pane, value or "")
        elseif name == "scratch_scrape" then
            dismiss_scratch(window, tab, pane, scrape_between_markers(pane))
        elseif name == "scratch_done" then
            dismiss_scratch(window, tab, pane, "")
        end
    end
end)

-- Extend the DEFAULT copy_mode table so every builtin motion/search key survives;
-- we only add the plain-`c` toggle on top.
local copy_mode = wezterm.gui.default_key_tables().copy_mode
table.insert(copy_mode, {
    key = "c",
    mods = "NONE",
    action = wezterm.action_callback(function(window, pane)
        local id = pane:pane_id()
        if copy_selecting[id] then
            copy_selecting[id] = nil
            window:perform_action(
                act.Multiple({
                    act.CopyTo("ClipboardAndPrimarySelection"),
                    act.CopyMode("Close"),
                }),
                pane
            )
        else
            copy_selecting[id] = true
            window:perform_action(act.CopyMode({ SetSelectionMode = "Cell" }), pane)
        end
    end),
})
config.key_tables = { copy_mode = copy_mode }

config.keys = {
    {
        key = "x",
        mods = "CTRL|SHIFT",
        action = wezterm.action_callback(enter_copy_mode),
    },
    -- CTRL-V: native paste. Sends the Windows clipboard as a bracketed paste, which is
    -- how text reaches both the shell and a running program (Claude, nvim). Fast, no
    -- subprocess -- and it's what makes Wispr dictation (clipboard + paste) land here.
    { key = "v", mods = "CTRL", action = act.PasteFrom("Clipboard") },
    -- CTRL-SHIFT-V: paste an IMAGE into the running program. Claude's own Ctrl-V is
    -- image-only (it probes the clipboard), and on WSL it reads the Wayland clipboard
    -- while a copied Windows image only crosses as bmp, which Claude rejects. So we
    -- re-encode the Windows clipboard image to PNG on the Wayland clipboard, then
    -- forward Ctrl-V so Claude's probe finds it. Costs a PowerShell launch -- image only.
    {
        key = "v",
        mods = "CTRL|SHIFT",
        action = wezterm.action_callback(function(window, pane)
            if is_windows then
                pcall(wezterm.run_child_process, {
                    "wsl.exe", "-d", WSL_DISTRO, "-e", "bash", "-c",
                    '"$HOME/.config/wezterm/wsl-clip-prime.sh"',
                })
            end
            window:perform_action(act.SendKey({ key = "v", mods = "CTRL" }), pane)
        end),
    },
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

-- CTRL-ALT-SUPER + left-drag moves the whole OS window. window_decorations is
-- "RESIZE" (no titlebar to grab), so StartWindowDrag is the only handle for
-- repositioning; the heavy modifier combo keeps it from stealing ordinary clicks,
-- selection, or the scratch overlay. SUPER is the Windows/Cmd key.
config.mouse_bindings = {
    {
        event = { Down = { streak = 1, button = "Left" } },
        mods = "CTRL|ALT|SUPER",
        action = act.StartWindowDrag,
    },
}

-- CTRL-Space toggles the scratch overlay (state + helpers are defined above, next to the
-- user-var-changed handler that the inline dispatch drives). Showing slides the scratch down
-- from the top into a full-window overlay; hiding slides it back up and zooms the work pane.
-- Windows-only, matching the old GlazeWM float's scope.
local function toggle_scratch(window)
    local tab = window:mux_window():active_tab()
    if not tab then
        return
    end
    local tid = tab:tab_id()
    local panes = tab:panes_with_info()
    local scratch = find_pane(panes, scratch_pane_for_tab[tid])

    -- No scratch yet (first toggle, or it was closed): split a thin strip off the TOP and
    -- slide it down into a full overlay.
    if not scratch then
        local active = tab:active_pane()
        local total_rows = active:get_dimensions().viewport_rows
        local cmd = scratch_spawn()
        cmd.direction = "Top"
        cmd.size = 0.08
        local new = active:split(cmd)
        scratch_pane_for_tab[tid] = new:pane_id()
        slide_in(window, tab, new, total_rows)
        return
    end

    if scratch.is_active then
        -- Scratch is showing -> slide it back up, then zoom the work pane to fully hide it
        -- (the scratch pane is parked at a thin strip behind it, ready to slide back in).
        local work = work_pane(tab, scratch.pane:pane_id())
        slide_out(window, tab, scratch.pane, function()
            if work then
                zoom_pane(tab, work)
            end
        end)
    else
        -- Scratch is parked behind the zoomed work pane, so its own height is just the strip;
        -- measure the full-size work pane to size the slide steps.
        local work = work_pane(tab, scratch.pane:pane_id())
        local total_rows = work and work:get_dimensions().viewport_rows
            or scratch.pane:get_dimensions().viewport_rows
        slide_in(window, tab, scratch.pane, total_rows)
    end
end

-- CTRL-SHIFT-TAB promotes the scratch: unzoom it so it stops being an overlay and
-- becomes a normal pane beside the active terminal — graduating whatever you did in
-- it into your live layout. It's then untracked, so the next CTRL-Space spawns a
-- fresh scratch. Works regardless of what the work pane runs (plain shell or a
-- burrito-multiplexed session) — at the WezTerm layer it's a single pane either way.
local function promote_scratch(window)
    local tab = window:mux_window():active_tab()
    if not tab then
        return
    end
    local tid = tab:tab_id()
    local scratch = find_pane(tab:panes_with_info(), scratch_pane_for_tab[tid])
    if not scratch then
        return
    end
    promote_scratch_pane(tab, scratch.pane)
end

if is_windows then
    table.insert(config.keys, {
        key = "Space",
        mods = "CTRL",
        action = wezterm.action_callback(toggle_scratch),
    })
    table.insert(config.keys, {
        key = "Tab",
        mods = "CTRL|SHIFT",
        action = wezterm.action_callback(promote_scratch),
    })
end

return config
