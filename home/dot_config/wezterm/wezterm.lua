-- WezTerm: a plain cross-platform host terminal. Multiplexing lives in the shell
-- via burrito, not here, so the setup is portable to any terminal. Colors come
-- from WezTerm's builtin "Gruvbox dark, hard (base16)" scheme.

local wezterm = require("wezterm")
local act = wezterm.action
local config = wezterm.config_builder()

local triple = wezterm.target_triple
local is_mac = triple:find("darwin") ~= nil

local home = os.getenv("HOME") or ""

-- Explicit config dir so the same ~/.config/nushell files are used on every OS.
local nu_config = home .. "/.config/nushell/config.nu"
local nu_env = home .. "/.config/nushell/env.nu"

config.default_prog = { "nu", "--config", nu_config, "--env-config", nu_env }

config.set_environment_variables = {
    XDG_CONFIG_HOME = home .. "/.config",
}

-- A GUI-launched WezTerm inherits launchd's minimal PATH (/usr/bin:/bin:/usr/sbin:
-- /sbin), which lacks Homebrew — so the bare `nu` in default_prog above can't be
-- found and the window dies with "No viable candidates found in PATH". Seed the
-- Homebrew + user bin dirs here so the nu binary resolves at spawn time; env.nu
-- then owns PATH inside the shell. macOS only — Linux already have nu on PATH.
if is_mac then
    config.set_environment_variables.PATH =
        "/opt/homebrew/bin:/opt/homebrew/sbin:"
        .. home .. "/.local/bin:" .. home .. "/.cargo/bin:"
        .. (os.getenv("PATH") or "")
end

-- Launch fullscreen. The grid is an integer number of cells that rarely divides
-- the screen exactly; the leftover sub-cell pixels are split into symmetric
-- padding by center_grid (below).
wezterm.on("gui-startup", function(cmd)
    local _, _, window = wezterm.mux.spawn_window(cmd or {})
    if window then
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

-- Static theme: Gruvbox Dark Hard (base16), WezTerm's builtin scheme.
config.color_scheme = "Gruvbox dark, hard (base16)"
config.default_cursor_style = "BlinkingBlock"

-- Font: CaskaydiaCove Nerd Font (installed by install.sh); the rest are fallbacks.
config.font = wezterm.font_with_fallback({
    "CaskaydiaCove Nerd Font",
    "CaskaydiaCove NF",
    "JetBrainsMono Nerd Font",
    "Cascadia Code",
    "Menlo",
})
-- Larger size for fullscreen WQHD (2560x1440). Fine-tune live with Ctrl/Cmd +/-
-- until the bottom/right edge sits flush, then read rows*cols from the title.
config.font_size = is_mac and 14.0 or 9.0
config.line_height = 1.0

-- Keep the fullscreen window fixed when zooming the font. By default WezTerm
-- resizes the OS window to land on a whole number of cells; fullscreen can't
-- grow, so it instead leaves a large gap (padding above/below) and the window
-- appears to change size. Off = window stays put, the grid just reflows and
-- center_grid only absorbs the sub-cell residual.
config.adjust_window_size_when_changing_font_size = false

-- Search a per-user font dir so a freshly-installed font resolves before the system
-- font cache refreshes.
if is_mac then
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

-- The translucent tint is gruvbox dark hard base00 (NOT pure black, which
-- diverges from the scheme).
local overlay = "#1d2021"
config.colors = config.colors or {}
config.colors.background = overlay

-- Use the terminal background color for the opacity: the cell bg above goes
-- translucent at this alpha so the blurred desktop shows through it on every OS.
local window_opacity = 0.95
config.window_background_opacity = window_opacity
-- Blur: macOS frosts the desktop behind the window directly. Linux has no reliable
-- per-window blur from WezTerm — but the wallpaper we set below is ALREADY
-- gaussian-blurred, so plain transparency shows a blurred backdrop regardless;
-- only macOS gets the extra live frosting.
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
-- backend sensitivity the old layered background did. fps is capped at 60: uncapping
-- to 255 let WezTerm present every redraw at up to 255 Hz, which combined with the
-- periodic status repaint and cursor blink kept the GPU/CPU churning for no visible
-- benefit. 60 is smooth and idle-cheap.
config.front_end = "OpenGL"
config.max_fps = 60
config.animation_fps = 60

-- Kitty keyboard protocol: stays OFF, matching nushell's `use_kitty_protocol =
-- false` in config.nu. The two are a matched pair — with it on, reedline fires the
-- kitty support query at startup and the pty returns the reply too late to consume,
-- so it leaks as `^[[?...u` and garbles the prompt before it's visible. Enabling
-- only the WezTerm half reproduces that leak without buying anything, since the
-- shell never opts in. WezTerm defaults this to false, so the matched-off state
-- needs no line; kept explicit as a marker.
config.enable_kitty_keyboard = false

config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = true
config.tab_bar_at_bottom = false
config.show_new_tab_button_in_tab_bar = false

-- Shell-driven copy mode: a nu command prints an OSC 1337 SetUserVar `copymode` sequence to
-- stdout, WezTerm parses it off the pty and drops the GUI
-- into copy mode here (the value is ignored).
-- `opacity` (the nu command / ctrl+space tv channel) arrives the same way: the value is a
-- percentage 0–100, applied as a per-window override — live, nothing persisted.
wezterm.on("user-var-changed", function(window, pane, name, value)
    if name == "copymode" then
        enter_copy_mode(window, pane)
    elseif name == "opacity" then
        local pct = tonumber(value)
        if pct then
            local alpha = math.max(0, math.min(100, pct)) / 100
            local overrides = window:get_config_overrides() or {}
            if overrides.window_background_opacity ~= alpha then
                overrides.window_background_opacity = alpha
                window:set_config_overrides(overrides)
            end
        end
    end
end)

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
            local home = os.getenv("HOME") or ""
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

-- ctrl+shift+b background pipeline. Runs in a shell to download/copy an image,
-- blur it to 16px gaussian, write the result as background.png next to this config
-- (so WezTerm's auto-reload picks it up), and set the blurred copy as the OS desktop
-- wallpaper. set -e is on, so every command-sub that can fail is guarded.
-- The input is single-quoted in only after Lua-side validation (below) already
-- rejected control chars and single quotes.
local function run_bg_script(script)
    local argv = { "sh", "-lc", script }
    return wezterm.run_child_process(argv)
end

-- Single POSIX script: derive the dest dir in-shell, obtain the image (download an
-- http(s) URL, or copy a local file -- a file:// URL, ~ path, or POSIX path), then
-- write the 16px gaussian BLUR (background.png) to both the committed chezmoi source
-- AND the live dir, then apply that blurred copy as the OS desktop wallpaper.
local function set_background(input)
    local script = table.concat({
        "set -e",
        "input='" .. input .. "'",
        'tmp="$(mktemp)"',
        -- FIX E: GUI-launched wezterm inherits launchd's minimal PATH on macOS, so
        -- sh -lc won't find brew's magick/curl; seed Homebrew up front (no-op on
        -- linux where bash -lc already has /usr/bin).
        'export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"',
        -- FIX C: clean the temp on any exit/interrupt, not just the success path.
        'blurred="$tmp.blur"',
        "trap 'rm -f \"$tmp\" \"$blurred\"' EXIT INT TERM",
        'src_dir="$(chezmoi source-path "$HOME/.config/wezterm" 2>/dev/null)" || exit 1',
        '[ -n "$src_dir" ] || exit 1',
        'mkdir -p "$src_dir"',
        'live_dir="$HOME/.config/wezterm"',
        'mkdir -p "$live_dir"',
        -- Obtain the source image into $tmp: download http(s) URLs, else treat the
        -- input as a local file -- strip a file:// prefix, expand a leading ~.
        -- A missing local file aborts before any dest write.
        'case "$input" in '
        .. 'http://*|https://*) curl -fsSL "$input" -o "$tmp" ;; '
        .. '*) src="${input#file://}"; '
        .. 'case "$src" in "~/"*) src="$HOME/${src#\\~/}" ;; esac; '
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
        -- macOS via osascript, otherwise GNOME via gsettings. Best-effort per OS.
        'wp="$live_dir/background.png"',
        'if [ "$(uname)" = "Darwin" ]; then '
        ..
        'osascript -e "tell application \\"System Events\\" to tell every desktop to set picture to \\"$wp\\"" >/dev/null 2>&1 || true; '
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
-- committed source, then reload to fall back to the solid theme bg.
local function clear_background()
    local script = table.concat({
        'src_dir="$(chezmoi source-path "$HOME/.config/wezterm" 2>/dev/null)"',
        '[ -n "$src_dir" ] && rm -f "$src_dir/background.png"',
        'rm -f "$HOME/.config/wezterm/background.png"',
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
    -- CTRL-V: native paste. Sends the clipboard as a bracketed paste, which is
    -- how text reaches both the shell and a running program (Claude, nvim). Fast, no
    -- subprocess -- and it's what makes Wispr dictation (clipboard + paste) land here.
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

-- CTRL-ALT-SUPER + left-drag moves the whole OS window. window_decorations is
-- "RESIZE" (no titlebar to grab), so StartWindowDrag is the only handle for
-- repositioning; the heavy modifier combo keeps it from stealing ordinary clicks
-- or selection. SUPER is the Windows/Cmd key.
config.mouse_bindings = {
    {
        event = { Down = { streak = 1, button = "Left" } },
        mods = "CTRL|ALT|SUPER",
        action = act.StartWindowDrag,
    },
    -- CTRL + left-click opens the hyperlink under the cursor. mouse_reporting=true
    -- keeps it working while an app (burrito enables DECSET 1002/1006 on the outer
    -- terminal) is capturing the mouse — without it WezTerm forwards the click to
    -- the app and no one opens the URL. Plain clicks still reach burrito/nvim.
    {
        event = { Up = { streak = 1, button = "Left" } },
        mods = "CTRL",
        mouse_reporting = true,
        action = act.OpenLinkAtMouseCursor,
    },
}

return config
