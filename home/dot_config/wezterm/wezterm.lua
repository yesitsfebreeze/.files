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

-- Nine terminals, always ready. F5 + a digit jumps straight to a slot (see the
-- tabjump key table below), so the set is a fixed floor rather than something grown
-- on demand: a digit always lands on the same slot, and there is no "tab 7 doesn't
-- exist yet" case.
local TAB_COUNT = 9

-- Self-healing tab set. WezTerm emits no "a tab closed" event, so rather than trying
-- to intercept every way a terminal can go away -- CloseCurrentTab, `exit` in a
-- tab's last pane, a crashed shell, `wezterm cli kill-pane` -- we reconcile: compare
-- the live tab list against the slot map we keep per window and rebuild what's
-- missing. Closing a pane in a SPLIT tab needs nothing: the tab survives, and only
-- when its last pane goes does the tab disappear and a slot open up here.
--
-- Position is restored, not just the count. When slot 3 dies WezTerm shifts tabs 4-9
-- down one, so a plain spawn_tab (which appends) would land the replacement at the
-- end and silently renumber everything after the hole -- F5+4 would then reach what
-- used to be tab 5. So we spawn, then MoveTab the fresh tab into the dead slot's
-- index, which puts every other tab back where it started.
--
-- Slots are tracked by tab_id, not by index, because indices are exactly what shifts
-- when a tab dies.
--
-- The floor applies to the STARTUP window ONLY, which is what `tab_primary_window`
-- records. It must not apply to every window: closing the last tab is exactly how a
-- window closes, so refilling made any second window (ctrl+shift+n, `wezterm cli
-- spawn --new-window`) impossible to close -- and with window_decorations = "RESIZE"
-- there is no titlebar close button to fall back on either. Other windows are
-- therefore left as ordinary WezTerm windows.
--
-- Both this and the slot list live in wezterm.GLOBAL, NOT in plain module-local
-- tables: WezTerm evaluates this config into more than one Lua context and runs event
-- callbacks in whichever one is free, so a module-local is empty as often as not. A
-- local `slots` table read back as nil on every single event here, which made each
-- pass re-adopt the current tab order as gospel -- exactly the state that has to
-- survive to know WHICH slot died. GLOBAL is the documented cross-context store;
-- values must stay JSON-shaped, so the slot list is a plain array of integer tab ids
-- (holes are derived against the live list each pass, never stored).
local function primary_wid()
    return wezterm.GLOBAL.tab_primary_window
end

local function get_slots()
    return wezterm.GLOBAL.tab_slots
end

local function set_slots(ids)
    wezterm.GLOBAL.tab_slots = ids
end

-- Per-window re-entrancy guard. spawn_tab and perform_action pump the event loop,
-- which re-fires pane-focus-changed and calls us again in the middle of a repair. A
-- nested pass sees a half-built window -- two tabs, say -- concludes seven slots are
-- missing, and fills them while the outer pass is still filling its own: startup
-- produced 16 tabs instead of 9 before this guard. This one is deliberately a
-- module-local, not GLOBAL: it only has to hold across a synchronous re-entry, which
-- by definition happens in the same Lua context. A single flag, not a per-window
-- table, since only the primary window is ever rebuilt.
local repairing = false

local function live_tab_ids(mux_win)
    local ids = {}
    for _, tab in ipairs(mux_win:tabs()) do
        ids[#ids + 1] = tab:tab_id()
    end
    return ids
end

local function index_of(list, want_id)
    for i, id in ipairs(list) do
        if id == want_id then
            return i
        end
    end
    return nil
end

local function reconcile_tabs(window)
    local mux_win = window:mux_window()
    if not mux_win then
        return
    end
    -- Not the startup window (or a session whose primary was never recorded, e.g. a
    -- config reload into an older run): leave it completely alone, tabs and all.
    if primary_wid() == nil or mux_win:window_id() ~= primary_wid() then
        return
    end
    if repairing then
        return
    end

    local live = live_tab_ids(mux_win)
    local alive = {}
    for _, id in ipairs(live) do
        alive[id] = true
    end

    -- Target order: every still-living slot in its original place, `false` marking
    -- each one to refill, then any tabs opened by hand (ctrl+shift+t, `wezterm cli
    -- spawn`) appended -- TAB_COUNT is a floor, so extra tabs are adopted, never
    -- closed. A dead slot PAST the floor is simply dropped rather than refilled.
    local map = get_slots() or live
    local known = {}
    local want = {}
    for _, id in ipairs(map) do
        known[id] = true
        if alive[id] then
            want[#want + 1] = id
        elseif #want < TAB_COUNT then
            want[#want + 1] = false
        end
    end
    for _, id in ipairs(live) do
        if not known[id] then
            want[#want + 1] = id
        end
    end
    while #want < TAB_COUNT do
        want[#want + 1] = false
    end

    -- Nothing to rebuild: record the (possibly re-ordered) map and leave focus alone.
    -- This is the path every status tick takes, so it stays a tab-list walk.
    local holes = false
    for _, id in ipairs(want) do
        if id == false then
            holes = true
            break
        end
    end
    if not holes then
        set_slots(want)
        return
    end

    -- Focus: WezTerm has already moved it to a neighbour by the time we run, and
    -- that is the right place to leave it -- closing a tab should move you on, not
    -- snap you back onto a blank replacement. So we re-assert that tab by id after
    -- the rebuild (the spawns below steal focus as they go) and only fall back to the
    -- fresh tab if the one we were on is dead too.
    local active = mux_win:active_tab()
    local active_alive = (active and alive[active:tab_id()]) and true or false

    repairing = true
    -- pcall so a spawn failure (out of ptys, bad default_prog) can't leave the guard
    -- latched -- that would silently disable healing for the rest of the session. A
    -- `false` left in the map is harmless: the next pass reads it as a dead slot and
    -- retries the refill.
    local done, err = pcall(function()
        local first_new = nil
        -- Left to right, one hole at a time. Slots before `pos` are settled and the
        -- tabs after it keep their relative order, so pos-1 is exactly where the
        -- fresh tab belongs -- no arithmetic across multiple insertions.
        for pos, id in ipairs(want) do
            if id == false then
                local tab, pane = mux_win:spawn_tab({})
                want[pos] = tab:tab_id()
                first_new = first_new or tab
                -- spawn_tab appends, so when the slot being filled IS the end of the
                -- list the tab is already home and no move is needed. Skipping that
                -- no-op is not just an optimization: MoveTab acts on whatever the GUI
                -- currently believes is the active tab, and right after a spawn that
                -- belief can still be the PREVIOUS tab -- so a "harmless" no-op move
                -- actually shoved the old tab one slot along (startup came out
                -- 1,0,2,3... instead of 0,1,2,3...). Activate explicitly before any
                -- real move so the action can only ever apply to the new tab.
                if index_of(live_tab_ids(mux_win), tab:tab_id()) ~= pos then
                    tab:activate()
                    window:perform_action(act.MoveTab(pos - 1), pane)
                end
            end
        end
        if active_alive then
            active:activate()
        elseif first_new then
            first_new:activate()
        end
    end)
    repairing = false
    set_slots(want)
    if not done then
        wezterm.log_error("tab reconcile failed: " .. tostring(err))
    end
end

-- Launch fullscreen with the full set of tabs. reconcile_tabs fills slots 2-9 (it
-- pads any window up to the floor), so the startup path and the repair path are the
-- same code. The grid is an integer number of cells that rarely divides the screen
-- exactly; the leftover sub-cell pixels are split into symmetric padding by
-- center_grid (below).
wezterm.on("gui-startup", function(cmd)
    -- cmd goes to the FIRST tab only (the CLI's `wezterm start -- prog`, if any);
    -- the rest are plain default_prog shells, so `wezterm start -- nvim foo` doesn't
    -- open nine editors.
    local _, _, mux_win = wezterm.mux.spawn_window(cmd or {})
    if not mux_win then
        return
    end
    -- Claim this window as the one the floor applies to, BEFORE reconciling -- the
    -- reconciler refuses to touch any window that is not the recorded primary.
    wezterm.GLOBAL.tab_primary_window = mux_win:window_id()
    wezterm.GLOBAL.tab_slots = nil
    local window = mux_win:gui_window()
    reconcile_tabs(window)
    -- Start on slot 1 regardless of where the fill left focus.
    mux_win:tabs()[1]:activate()
    window:toggle_fullscreen()
end)

-- Repair triggers. There is no close event, so: pane-focus-changed fires the instant
-- a closed tab hands focus to another one (the common case, so the slot is back
-- before you see the gap), and the periodic update-status tick catches a BACKGROUND
-- tab whose shell exited without any focus change -- within status_update_interval
-- (5s below). The no-hole path is just a tab-list walk, so idle ticks stay cheap.
wezterm.on("pane-focus-changed", reconcile_tabs)
wezterm.on("window-focus-changed", reconcile_tabs)
wezterm.on("update-status", reconcile_tabs)

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
-- (the cwd label + HH:MM clock). At 1s that repainted the tab bar every second forever
-- — a constant titlebar refresh for a label that almost never changes, and the clock
-- only needs minute resolution (5s worst-case lag on the rollover). 5s still recenters
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

-- Number every tab and nothing else: the label IS the digit you press after F5, so
-- the bar doubles as the keymap legend. Nine process titles would not fit legibly
-- anyway, and the active pane's cwd already shows in the right status.
wezterm.on("format-tab-title", function(tab)
    return string.format("  %d  ", tab.tab_index + 1)
end)

config.use_fancy_tab_bar = false
-- Kept for completeness -- with TAB_COUNT = 9 the bar is always shown, but a window
-- opened by other means (e.g. `wezterm cli spawn --new-window`) has one tab.
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
    -- Clock at the far right, after the cwd. HH:MM only: seconds would be wrong
    -- most of the time anyway, since the 5s status tick is what repaints this.
    window:set_right_status(wezterm.format({
        { Foreground = { AnsiColor = "Blue" } },
        { Text = "  " .. label .. "  " },
        { Foreground = { AnsiColor = "Silver" } },
        { Text = wezterm.strftime("%H:%M") .. "  " },
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
-- F5 listen mode: F5 pushes a ONE-SHOT key table, so WezTerm swallows exactly the
-- next keypress and resolves it here -- 1..9 activates that tab. one_shot pops the
-- table after that single key; until_unknown pops it for any key we did NOT bind
-- (which is then handled normally), so a mistyped key can never leave the terminal
-- stuck swallowing input. No timeout: it waits as long as you take. Escape is bound
-- explicitly to back out without doing anything.
local tabjump = {}
for i = 1, TAB_COUNT do
    table.insert(tabjump, {
        key = tostring(i),
        mods = "NONE",
        action = act.ActivateTab(i - 1),
    })
end
table.insert(tabjump, { key = "Escape", mods = "NONE", action = act.PopKeyTable })

config.key_tables = { copy_mode = copy_mode, tabjump = tabjump }

config.keys = {
    -- F5: enter tab-jump listen mode (see the tabjump table above). Binding it here
    -- means F5 no longer reaches the shell or a running app -- nothing in this setup
    -- uses it, but that is the trade.
    {
        key = "F5",
        mods = "NONE",
        action = act.ActivateKeyTable({
            name = "tabjump",
            one_shot = true,
            until_unknown = true,
        }),
    },
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
