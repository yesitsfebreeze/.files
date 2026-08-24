-- WezTerm appearance: font, palette reader, derived tab bar, baseline, clock,
-- F6 theme toggle — prds/02-terminal/01-appearance owns that scope. The
-- self-healing nine-tab floor below is prds/02-terminal/02-startup-layout's;
-- later terminal nodes (F5, copy mode, grid centering) extend this file.
--
-- The launch environment — default_prog, set_environment_variables and the
-- macOS PATH prefix — is prds/02-terminal/06-launchd-path's, and it sits
-- immediately below: a GUI-launched WezTerm inherits launchd's environment,
-- so nushell has to be named and its PATH seeded before the spawn.

local wezterm = require("wezterm")
local config = wezterm.config_builder()
local act = wezterm.action

local triple = wezterm.target_triple
-- The only platform surface WezTerm offers.
local is_mac = triple:find("darwin") ~= nil

local home = os.getenv("HOME") or ""

-- ── 06-launchd-path: the launch environment ─────────────────────────────────

-- Nushell, with both config files named absolutely (R6). A GUI-launched
-- WezTerm gets no default_prog for free and WezTerm then falls back to the
-- passwd login shell. Measured 2026-08-23 on this machine: `dscl . -read
-- /Users/feb UserShell` is /bin/zsh, launchd's GUI environment exports no
-- SHELL (only SSH_AUTH_SOCK -- see the foreground-process comment further
-- down), and a wezterm-mux-server started under `env -i` with no
-- default_prog spawns `-zsh`. So without this line the terminal never starts
-- nushell at all: no aliases, no keybindings, no `help`.
--
-- Both files are named rather than left to discovery, because the config
-- directory nushell would discover is not the managed one -- see the
-- XDG_CONFIG_HOME comment below, which is the other half of the same fact.
local nu_config = home .. "/.config/nushell/config.nu"
local nu_env = home .. "/.config/nushell/env.nu"
config.default_prog = { "nu", "--config", nu_config, "--env-config", nu_env }

-- XDG_CONFIG_HOME is exported at LAUNCH, and that is the whole point (R7).
-- $nu.default-config-dir is a launch-time CONSTANT, so env.nu's own
-- assignment runs too late to move it and everything nushell derives from it
-- drifts out of the managed tree. Measured 2026-08-23 on nushell 0.114.1:
-- with --config/--env-config but no export, $nu.default-config-dir is
-- ~/Library/Application Support/nushell and $nu.history-path is the
-- history.sqlite3 under it -- and reedline really does create it there, so
-- the shell history silently leaves ~/.config. history.nu's header records
-- the same lesson for that path; this line is what makes it come out right.
-- Not inside the is_mac branch: it is correct on every platform.
config.set_environment_variables = {
    XDG_CONFIG_HOME = home .. "/.config",
}

-- PATH seeding, macOS only (R2, R3). default_prog above is spawned by
-- WezTerm itself -- execvp against the process PATH, never through a login
-- shell -- and a GUI launch inherits launchd's PATH. Measured 2026-08-23:
-- `launchctl getenv PATH` is unset, so that is the hardcoded
-- /usr/bin:/bin:/usr/sbin:/sbin, with no Homebrew in it. Without this prefix
-- the spawn fails with `No viable candidates found in PATH` and the pane
-- STAYS OPEN carrying that message plus "didn't exit cleanly" -- WezTerm's
-- default exit_behavior is CloseOnCleanExit, so the failure is a terminal
-- you cannot type into rather than a window that disappears.
--
-- Four DIRECTORIES, fixed, not a list computed from the installed package
-- set: it seeds directories, so adding a package to the provisioning set
-- needs no change here. Not seeded on Linux -- this is a macOS-host-only
-- configuration and nu is on PATH there already.
--
-- Getting the binary spawned is all this does; env.nu owns PATH inside the
-- shell, and it wins by construction (R5). env.nu `prepend`s ~/.cargo/bin
-- and ~/.local/bin, `append`s the Homebrew and system dirs and `uniq`s, so
-- the duplicates this prefix creates collapse and the shell's resolution
-- order is env.nu's under either launch shape. Measured both ways on
-- 0.114.1: the repaired PATH is
-- .cargo/bin:.local/bin:/opt/homebrew/bin:... whether the launch PATH was
-- this prefix or a terminal's inherited one.
if is_mac then
    config.set_environment_variables.PATH =
        "/opt/homebrew/bin:/opt/homebrew/sbin:"
        .. home .. "/.local/bin:" .. home .. "/.cargo/bin:"
        .. (os.getenv("PATH") or "")
end

-- ── 02-startup-layout: the self-healing nine-tab floor ──────────────────────

-- Nine terminals, always ready. F5 + a digit
-- (prds/02-terminal/03-f5-jump-mode) jumps straight to a slot, so the set is
-- a fixed floor rather than something grown on demand: a digit always lands
-- on the same slot, and there is no "tab 7 doesn't exist yet" case.
local TAB_COUNT = 9

-- Self-healing tab set. WezTerm emits no "a tab closed" event, so rather
-- than trying to intercept every way a terminal can go away --
-- CloseCurrentTab, `exit` in a tab's last pane, a crashed shell,
-- `wezterm cli kill-pane` -- we reconcile: compare the live tab list against
-- the slot map we keep per window and rebuild what's missing. Closing a pane
-- in a SPLIT tab needs nothing: the tab survives, and only when its last
-- pane goes does the tab disappear and a slot open up here.
--
-- Position is restored, not just the count. When slot 3 dies WezTerm shifts
-- tabs 4-9 down one, so a plain spawn_tab (which appends) would land the
-- replacement at the end and silently renumber everything after the hole --
-- F5+4 would then reach what used to be tab 5. So we spawn, then MoveTab the
-- fresh tab into the dead slot's index, which puts every other tab back
-- where it started.
--
-- Slots are tracked by tab_id, not by index, because indices are exactly
-- what shifts when a tab dies.
--
-- The floor applies to EVERY window, however opened. No new-window binding
-- exists in this file: Cmd+N and Ctrl+Shift+N are WezTerm DEFAULTS resolving
-- to SpawnWindow (wezterm show-keys --lua), and `wezterm cli spawn
-- --new-window` opens one too -- all of them come up with the full set of
-- nine because window-config-reloaded fires once per newly created window,
-- not because any key is intercepted.
--
-- That needs an escape hatch, which is what ctrl+shift+q is. Closing the
-- last tab is exactly how a window closes, so a window whose tabs keep
-- refilling can never be closed that way -- and with window_decorations =
-- "RESIZE" there is no titlebar close button to fall back on either.
-- ctrl+shift+q marks the window as closing (the floor stops applying to it)
-- and then closes its tabs.
--
-- Both the closing marks and the slot lists live in wezterm.GLOBAL, NOT in
-- plain module-local tables, and the reason is LIFETIME rather than context
-- count. Every evaluation of this file creates fresh Lua contexts (measured:
-- 2 per evaluation) and a module-local starts nil in each, so a local slots
-- table is wiped by every config reload -- and every `tinty apply` is one,
-- because colors.lua is on the reload watch list further down. An emptied
-- slot map made each pass re-adopt the current tab order as gospel --
-- exactly the state that has to survive to know WHICH slot died.
-- What this comment used to claim, and what does NOT happen: callbacks do
-- not land "in whichever context is free". Measured 2026-08-24 on 20240203
-- against an instrumented copy of this file in two isolated GUIs -- 16
-- evaluations, 9 event kinds, 2770 fires -- exactly one context served
-- events at a time, dispatch never returned to an older one, and a
-- module-local read back nil 5 times, every one of them that context's
-- FIRST fire (0 of 2765 later fires). GLOBAL is still the documented
-- cross-context store; values must stay JSON-shaped, so the slot list is a
-- plain array of integer tab ids (holes are derived against the live list
-- each pass, never stored).
-- One slot list PER WINDOW, keyed by window id as a string (GLOBAL has to
-- stay JSON-shaped, so the key cannot be an integer). A single shared list
-- had two windows reading each other's tab ids as dead slots and refilling
-- forever.
local function get_slots(wid)
    local all = wezterm.GLOBAL.tab_slots
    return all and all[tostring(wid)]
end

-- Rebuilt as a plain Lua table rather than mutated in place: a value read
-- back out of wezterm.GLOBAL is a copy, so assigning into it does not write
-- through. Entries for windows that no longer exist are dropped on the way
-- past, which is the only thing that keeps the map from growing for the life
-- of the session.
local function set_slots(wid, ids)
    local live_wins = {}
    for _, w in ipairs(wezterm.mux.all_windows()) do
        live_wins[tostring(w:window_id())] = true
    end
    local out = {}
    local all = wezterm.GLOBAL.tab_slots
    if all then
        for k, v in pairs(all) do
            if live_wins[k] then
                local copy = {}
                for i, id in ipairs(v) do
                    copy[i] = id
                end
                out[k] = copy
            end
        end
    end
    out[tostring(wid)] = ids
    wezterm.GLOBAL.tab_slots = out
end

-- Windows with an explicit close in progress (ctrl+shift+q, below). The
-- floor must stop applying to a window being closed on purpose, or the
-- refill races the close and the window can never go away.
local function is_closing(wid)
    local list = wezterm.GLOBAL.tab_closing
    if not list then
        return false
    end
    for _, id in ipairs(list) do
        if id == tostring(wid) then
            return true
        end
    end
    return false
end

local function mark_closing(wid)
    local out = {}
    local list = wezterm.GLOBAL.tab_closing
    if list then
        for _, id in ipairs(list) do
            out[#out + 1] = id
        end
    end
    out[#out + 1] = tostring(wid)
    wezterm.GLOBAL.tab_closing = out
end

-- Re-entrancy guard. spawn_tab and perform_action pump the event loop, which
-- re-fires the repair triggers and calls us again in the middle of a repair.
-- A nested pass saw a half-built window -- two tabs, say -- concluded seven
-- slots were missing, and filled them while the outer pass was still filling
-- its own: startup produced 16 tabs instead of 9 before this guard. This one
-- is deliberately a module-local, not GLOBAL, for two reasons. It only has
-- to hold across a synchronous re-entry, which by definition happens in the
-- same Lua context. And GLOBAL survives a config reload (see the theme
-- block) while a local does not, so a guard parked in GLOBAL would outlive
-- the one event measured to clear a stuck one -- see the pcall below.
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
    local wid = mux_win:window_id()
    -- A window being closed on purpose is the one case where the floor must
    -- not apply; everything else -- the startup window, a SpawnWindow
    -- default, `wezterm cli spawn --new-window` -- gets the full set.
    if is_closing(wid) then
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

    -- Target order: every still-living slot in its original place, `false`
    -- marking each one to refill, then any tabs opened by hand appended --
    -- TAB_COUNT is a floor, so extra tabs are adopted, never closed. A dead
    -- slot PAST the floor is simply dropped rather than refilled.
    local map = get_slots(wid) or live
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

    -- Nothing to rebuild: record the (possibly re-ordered) map and leave
    -- focus alone. This is the path every status tick takes, so it stays a
    -- tab-list walk.
    local holes = false
    for _, id in ipairs(want) do
        if id == false then
            holes = true
            break
        end
    end
    if not holes then
        set_slots(wid, want)
        return
    end

    -- Focus: WezTerm has already moved it to a neighbour by the time we run,
    -- and that is the right place to leave it -- closing a tab should move
    -- you on, not snap you back onto a blank replacement. So we re-assert
    -- that tab by id after the rebuild (the spawns below steal focus as they
    -- go) and only fall back to the fresh tab if the one we were on is dead
    -- too.
    local active = mux_win:active_tab()
    local active_alive = (active and alive[active:tab_id()]) and true or false

    repairing = true
    -- pcall so a spawn failure (out of ptys, bad default_prog) can't leave
    -- the guard latched. Measured 2026-08-23 on 20240203 with a probe
    -- config in an isolated GUI: one evaluation of this file creates 2 Lua
    -- contexts (4 with three windows), and exactly one of them serves every
    -- trigger of that generation -- 0 of 268 fires reached a sibling, even
    -- with an 800 ms busy-wait held inside update-status. So a latched local
    -- is read as latched by every later fire, in every window, including
    -- windows opened after it latched, and only a re-evaluation of this file
    -- clears it: a reload does (every tinty apply is one, via the colors.lua
    -- watch), and a config that fails to parse does not, because the body
    -- never runs. A `false` left in the map is harmless: the next pass reads
    -- it as a dead slot and retries the refill.
    local done, err = pcall(function()
        local first_new = nil
        -- Left to right, one hole at a time. Slots before `pos` are settled
        -- and the tabs after it keep their relative order, so pos-1 is
        -- exactly where the fresh tab belongs -- no arithmetic across
        -- multiple insertions.
        for pos, id in ipairs(want) do
            if id == false then
                local tab, pane = mux_win:spawn_tab({})
                want[pos] = tab:tab_id()
                first_new = first_new or tab
                -- spawn_tab appends, so when the slot being filled IS the
                -- end of the list the tab is already home and no move is
                -- needed. Skipping that no-op is not just an optimization:
                -- MoveTab acts on whatever the GUI currently believes is the
                -- active tab, and right after a spawn that belief can still
                -- be the PREVIOUS tab -- so a "harmless" no-op move actually
                -- shoved the old tab one slot along (startup came out
                -- 1,0,2,3... instead of 0,1,2,3...). Activate explicitly
                -- before any real move so the action can only ever apply to
                -- the new tab.
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
    set_slots(wid, want)
    if not done then
        wezterm.log_error("tab reconcile failed: " .. tostring(err))
    end
end

-- Launch fullscreen (finding T-5 — fullscreen, not maximized) with the full
-- set of tabs. reconcile_tabs fills slots 2-9 (it pads any window up to the
-- floor), so the startup path and the repair path are the same code. There
-- is no attach-time GUI hook and no window-enlarging call: neither exists in
-- the live config or in this build's event set.
wezterm.on("gui-startup", function(cmd)
    -- cmd goes to the FIRST tab only (the CLI's `wezterm start -- prog`, if
    -- any); the rest are plain default_prog shells, so `wezterm start --
    -- nvim foo` doesn't open nine editors.
    local _, _, mux_win = wezterm.mux.spawn_window(cmd or {})
    if not mux_win then
        return
    end
    -- Start from a clean slot map: a config reload re-runs this file but
    -- GLOBAL survives, and stale tab ids from a previous run would read as
    -- dead slots.
    wezterm.GLOBAL.tab_slots = nil
    wezterm.GLOBAL.tab_closing = nil
    local window = mux_win:gui_window()
    reconcile_tabs(window)
    -- Start on slot 1 regardless of where the fill left focus.
    mux_win:tabs()[1]:activate()
    window:toggle_fullscreen()
end)

-- Repair triggers. There is no tab-close event, so the periodic
-- update-status tick (status_update_interval = 5000, below) is what actually
-- heals: a dead slot is rebuilt within one interval, whether the tab was
-- focused or sitting in the background. The no-hole path is just a tab-list
-- walk, so idle ticks stay cheap.
--
-- pane-focus-changed would make the common case instant, and it is
-- registered for that reason -- but it is INERT on wezterm 20240203
-- (verified: switching panes never fires it). Left in place because it costs
-- nothing and starts working by itself on a build that emits it; the 5s tick
-- is the guarantee until then.
wezterm.on("pane-focus-changed", reconcile_tabs)
wezterm.on("window-focus-changed", reconcile_tabs)
wezterm.on("update-status", reconcile_tabs)
-- Fires once for each newly created window (and again on every config
-- reload), which is what fills ANY new window at birth instead of up to 5s
-- later on the tick -- the mechanism behind "however opened" above.
-- Registered on the same event as retint_all_panes below: wezterm.on
-- accumulates handlers.
wezterm.on("window-config-reloaded", reconcile_tabs)

-- ── 07-grid-centering: the runtime owner of window_padding ──────────────────

-- Keep the grid centered. The grid is an integer number of cells, so it
-- almost never divides the window exactly, and the sub-cell remainder would
-- sit as an uneven gap on the right and bottom. center_grid measures the true
-- cell size, recomputes how many whole cells fit, and pushes the leftover
-- into padding -- so it adapts to any font size, DPI or resolution by itself
-- (resize, interactive zoom, monitor swap). The left/right split is exactly
-- symmetric; the top/bottom split is symmetric to within the tab-bar
-- over-reserve explained below, which measured 0-2 px across the font sizes
-- checked.
--
-- This pair is the RUNTIME OWNER of window_padding. That is why
-- config.window_padding further down the file is declared as four zeroes
-- (prds/02-terminal/01-appearance R8): the declaration is only the neutral
-- starting point, and every value after the first tick comes from here.

-- >>> grid-padding (pure): no wezterm calls in this block --
-- tests/wezterm-grid-centering.sh --math slices it out between these two
-- sentinels and runs it against measured geometries. The failure this node
-- exists to fix -- an axis that computes zero for every input -- is invisible
-- to a grep and needs no GUI to catch, so the arithmetic is kept pure and the
-- gate proves it produces padding at all.
local function grid_padding(win_w, win_h, cell_w, cell_h)
    -- RESERVE the tab bar, do not measure it. mux_tab:get_size() reports the
    -- PTY size, which is exactly rows * cell_h and therefore carries no
    -- information about the vertical remainder: deriving the chrome as
    -- height - grid_height - pad_top - pad_bottom measures the bar PLUS the
    -- remainder, the available height collapses back to rows * cell_h, and
    -- the vertical gap comes out zero by construction at every font size.
    -- Measured, not assumed: that is why this reserves the bar instead.
    --
    -- The constant is EMPIRICAL. Measured against
    -- wezterm 20240203-110809-5046fc22 (dpi 144, CaskaydiaCove,
    -- line_height = 1.0, retro tab bar shown), the bar is cell_h or
    -- cell_h + 1 pixels tall at font sizes 9, 12, 14, 17 and 21.
    -- RE-MEASURE IT IF THE WEZTERM BUILD MOVES.
    --
    -- It over-reserves on purpose, because the error is safe in one direction
    -- only. Over-reserving by d px costs d px of top/bottom asymmetry, plus
    -- one row in the boundary case where (win_h - bar) mod cell_h < d --
    -- stable, reached in one tick, never flickering. UNDER-reserving
    -- over-pads, drops a row and parks a whole extra cell at the bottom,
    -- which is the flicker failure described further down in its stable form.
    --
    -- The reserve assumes the tab bar is SHOWN, and the nine-tab floor above
    -- is what guarantees it: hide_tab_bar_if_only_one_tab hides the bar at
    -- one tab only, and the floor keeps nine. The two one-tab states -- a new
    -- window's birth instant before the reconciler fills it, and a window on
    -- its way out through ctrl+shift+q -- are transient, and neither is worth
    -- a branch.
    local bar_h = math.ceil(cell_h) + 1

    -- ABSOLUTE, never incremental. Both axes are derived from the constant
    -- window and the cell only; the padding in force is not an input to this
    -- function on either axis, so a given font always yields the same padding
    -- regardless of zoom history and the grid cannot ratchet smaller over
    -- time.
    local avail_w = win_w
    local avail_h = win_h - bar_h

    -- Fit as many whole cells as the available space allows; the gap is
    -- whatever those cells leave over, which is in [0, cell).
    local cols = math.floor(avail_w / cell_w)
    local rows = math.floor(avail_h / cell_h)

    -- floor() the TOTAL gap before halving it, so the padding applied is
    -- never larger than the true gap. Over-padding by even a sub-pixel
    -- (possible whenever the cell is not a whole pixel, i.e. fractional DPI)
    -- shrinks the usable area below cols * cell and drops a column that the
    -- next tick adds back -- a flicker at the tick rate. Under-padding by
    -- less than a pixel is invisible and stable.
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
    -- Reach the tab through the MUX WINDOW, not through the active pane and
    -- its own tab accessor: an overlay (debug overlay, char select, launcher)
    -- makes the active pane a detached one whose tab is nil, which crashed
    -- centering mid-flight and left the stale padding in place.
    -- mux_window():active_tab() always resolves the real underlying tab, so
    -- update-status keeps centering even while an overlay is up.
    local mux_win = window:mux_window()
    if not mux_win then
        return
    end
    local mux_tab = mux_win:active_tab()
    if not mux_tab then
        return
    end

    -- MEASURE, do not reconstruct. get_size() reports
    -- {cols, rows, pixel_width, pixel_height} for the grid's own rendered
    -- area, so cell = pixels / count is exact and independent of the padding
    -- in force -- which is what matters under fractional DPI (the cell is not
    -- a whole pixel) and during the multi-frame settle after a font zoom,
    -- where reconstructing the cell from window-minus-padding read stale
    -- padding and produced a wrong cell size.
    local win = window:get_dimensions()
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

    -- The padding in force is read for the change comparison at the bottom
    -- and for nothing else. It must never reach the arithmetic.
    local overrides = window:get_config_overrides() or {}
    local pad = overrides.window_padding
        or { left = 0, right = 0, top = 0, bottom = 0 }

    local new_pad = grid_padding(win.pixel_width, win.pixel_height,
        cell_w, cell_h)

    -- Idempotency guard. Writing the config overrides RE-FIRES the event that
    -- called this handler, so writing unconditionally is a feedback loop;
    -- writing only on a real change makes idle ticks nearly free.
    if new_pad.left ~= pad.left or new_pad.right ~= pad.right
        or new_pad.top ~= pad.top or new_pad.bottom ~= pad.bottom then
        overrides.window_padding = new_pad
        window:set_config_overrides(overrides)
    end
end

-- Recenter on anything that can change the grid geometry: window or screen
-- size (window-resized, which also covers dragging between differently sized
-- monitors), and config or font-size edits (window-config-reloaded).
-- Registering window-config-reloaded a third time is fine -- reconcile_tabs
-- above and retint_all_panes below are on it too, and wezterm.on accumulates
-- handlers.
wezterm.on("window-resized", center_grid)
wezterm.on("window-config-reloaded", center_grid)
-- Interactive font zoom fires NEITHER of the two above. That is the whole
-- reason the periodic tick is a trigger here as well as in
-- prds/02-terminal/02-startup-layout: it catches a zoom within one
-- status_update_interval, which is 5 s (set further down). The guard above
-- keeps these ticks nearly free.
wezterm.on("update-status", center_grid)

-- ── 03-f5-jump-mode: the F5 one-shot tab select ─────────────────────────────

-- Every key bound in jump_mode exits the mode, so the timeout only matters
-- when F5 was a misfire and nothing at all is pressed after it.
local JUMP_TIMEOUT_MS = 5000

local jump_mode_keys = {
    { key = "Escape", mods = "NONE", action = act.Nop },
}

-- Digits over TAB_COUNT, not a literal 9: the digit set IS the floor's
-- address space (epic I1), and the two must not drift apart. The tab bar
-- already prints each tab's digit and nothing else (format-tab-title,
-- 01-appearance R5), so the addressing needs no overlay, no legend, and
-- nothing painted into a pane — the status legend existed and was removed
-- as noise, and the clock's corner is unconditional precisely so nothing
-- can displace it.
for i = 1, TAB_COUNT do
    table.insert(jump_mode_keys, {
        key = tostring(i),
        mods = "NONE",
        action = act.ActivateTab(i - 1),
    })
end

-- All 26 letters, bound as a bare cancel. until_unknown pops the key table
-- without eating the keystroke, so an unbound letter would fall through and
-- type itself into whatever is running — nvim, Claude. The letters do
-- nothing on purpose (the pane-letter half is dropped, Q2 2026-08-21); they
-- are bound so a mistyped letter cancels the mode instead of leaking a
-- character.
--
-- And no BEL on the miss path. Live bug L-11 — a missed letter rang BEL
-- into a disabled audible_bell with no visual_bell, so the miss was silent
-- and indistinguishable from the table having failed to open — only ever
-- rang on the letter path, and removing the ring makes it unreachable, not
-- fixed. Do not add a visual_bell, and audible_bell stays Disabled exactly
-- as 01-appearance R7 has it.
for i = 1, 26 do
    table.insert(jump_mode_keys, {
        key = string.char(96 + i),
        mods = "NONE",
        action = act.Nop,
    })
end

-- Pane switching is WezTerm's own unshadowed defaults — Ctrl+Shift+arrow →
-- ActivatePaneDirection; nothing here binds panes.

-- ── 04-copy-mode: the c-cycle on the extended default table ─────────────────

-- Copy mode: ctrl+shift+x freezes the scrollback and drops a movable
-- cursor. One key drives the whole select-and-copy cycle: first `c`
-- anchors a Cell selection at the cursor, second `c` copies the range and
-- leaves copy mode. The toggle is tracked per PANE ID rather than by
-- reading the selection text back, because a selection that begins over
-- blank cells reads as empty and would desync the toggle. State is reset
-- on ENTRY, so a copy mode exited any other way (q/Esc/y) cannot leave it
-- stale.
local copy_selecting = {}

-- Enter copy mode from a clean state: clear any stale selection and the
-- per-pane toggle flag, so the first `c` always starts (never finishes) a
-- selection. Shared by the ctrl+shift+x keybind and the user-var trigger.
local function enter_copy_mode(window, pane)
    copy_selecting[pane:pane_id()] = nil
    window:perform_action(act.ClearSelection, pane)
    window:perform_action(act.ActivateCopyMode, pane)
end

-- Shell-driven copy mode: a nushell command (copymode.nu) prints an OSC
-- 1337 SetUserVar named `copymode`; WezTerm parses it off the pty and
-- enters copy mode here, ignoring the value. That is how a shell command
-- reaches a GUI-only mode. This handler answers to ONE name: the live
-- config's sibling `opacity` user-var (the background-transparency
-- toggle) is refused by prds/00-delivery/decisions/wallpaper-opacity
-- (2026-08-21) and must not come back with a port of this handler.
wezterm.on("user-var-changed", function(window, pane, name, _value)
    if name == "copymode" then
        enter_copy_mode(window, pane)
    end
end)

-- Extend the DEFAULT copy_mode table so every builtin motion survives;
-- only the plain-`c` toggle is added on top. Extension, never
-- replacement.
--
-- The builtin table is 54 rows, and the count is measured, not the
-- printer's: `wezterm show-keys --lua` on a BARE config prints 62
-- copy_mode rows, because the printer shows eight uppercase+SHIFT
-- duplicates (F G H L M O T V) that wezterm.gui.default_key_tables()
-- folds away. The effective table here prints 55 — 54 builtin plus this
-- `c` — and shift+g still reaches `G`. Do not "fix" the count.
--
-- Copy mode has NO search: `/`, NextMatch, PriorMatch, ClearPattern and
-- CycleMatchType all live in the separate 10-row `search_mode` table,
-- reachable from normal mode via WezTerm's default Ctrl+Shift+F — which
-- this config neither sets nor shadows.
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

-- One assignment, both tables: a second `config.key_tables = …` would
-- clobber the first.
config.key_tables = { copy_mode = copy_mode, jump_mode = jump_mode_keys }

-- ── R1: font ────────────────────────────────────────────────────────────────

config.font = wezterm.font_with_fallback({
    "CaskaydiaCove Nerd Font",
    "CaskaydiaCove NF",
    "JetBrainsMono Nerd Font",
    "Cascadia Code",
    "Menlo",
})
config.font_size = is_mac and 14.0 or 9.0
config.line_height = 1.0

-- Search the per-user font dir so a freshly installed font resolves before
-- the system font cache refreshes.
if is_mac then
    config.font_dirs = { home .. "/Library/Fonts" }
else
    config.font_dirs = { home .. "/.local/share/fonts" }
end

-- ── R2, R3: the palette reader ──────────────────────────────────────────────

-- The one permitted scheme constant: the no-theme-picked fallback for a
-- checkout that has never applied a theme. Never the palette — the palette is
-- whatever tinty last wrote to colors.lua, and naming a scheme here as the
-- palette would be wrong within a day.
config.color_scheme = "Gruvbox dark, hard (base16)"

local colors_file = home .. "/.config/wezterm/colors.lua"

-- WezTerm's auto-reload only watches files it loaded, and the dofile below is
-- invisible to it — register colors.lua explicitly so tinty rewriting it
-- triggers a reload (and with it the retint of every pane) with no manual
-- step.
wezterm.add_to_config_reload_watch_list(colors_file)

-- dofile, not require: require caches by module name, so a second
-- `tinty apply` in the same GUI process would keep returning the FIRST
-- palette. pcall guards the half-written file a concurrent hook can leave
-- behind, and the essential-key check rejects a truncated table rather than
-- painting a half-empty theme.
local function load_theme()
    local ok, t = pcall(dofile, colors_file)
    if ok and type(t) == "table" and t.background and t.foreground and t.ansi then
        return t
    end
    return nil
end

local theme = load_theme()

-- ── R4: tab bar and window frame, derived from the same palette ─────────────

if theme then
    -- The retro tab bar (use_fancy_tab_bar = false, below) does NOT inherit
    -- the scheme: with colors.tab_bar unset WezTerm falls back to its own
    -- hardcoded dark greys, so the bar stayed near-black under a light
    -- scheme. Derive it from the same palette so the bar tracks every switch:
    --   bar background = base00, so it disappears into the window,
    --   active tab     = base02 (the selection tint) + base05 text, bold,
    --   inactive tabs  = base00 + base03, so digits stay readable but recede.
    -- brights[1] is base03: colors.lua carries no separate base03 key.
    local base03 = theme.brights and theme.brights[1] or theme.selection_bg
    local tab_bar = {
        background = theme.background,
        active_tab = {
            bg_color = theme.selection_bg,
            fg_color = theme.foreground,
            intensity = "Bold",
        },
        inactive_tab = {
            bg_color = theme.background,
            fg_color = base03,
        },
        inactive_tab_hover = {
            bg_color = theme.selection_bg,
            fg_color = theme.foreground,
            italic = false,
        },
        new_tab = {
            bg_color = theme.background,
            fg_color = base03,
        },
        new_tab_hover = {
            bg_color = theme.selection_bg,
            fg_color = theme.foreground,
            italic = false,
        },
    }

    config.colors = {
        foreground = theme.foreground,
        background = theme.background,
        cursor_bg = theme.cursor_bg,
        cursor_border = theme.cursor_border,
        cursor_fg = theme.cursor_fg,
        selection_bg = theme.selection_bg,
        selection_fg = theme.selection_fg,
        ansi = theme.ansi,
        brights = theme.brights,
        tab_bar = tab_bar,
    }

    -- The fancy tab bar ignores colors.tab_bar and reads window_frame
    -- instead. It is off here, but window_frame ALSO paints the resize
    -- border, so keep it on-scheme rather than leaving WezTerm's grey behind
    -- the window edge.
    config.window_frame = {
        active_titlebar_bg = theme.background,
        inactive_titlebar_bg = theme.background,
        button_fg = theme.foreground,
        button_bg = theme.background,
    }
end
-- When no theme loads, set no config.colors at all: the fallback color_scheme
-- above paints its own base00, which is the same value a hardcoded overlay
-- would carry — so no colour constant is needed, and none is permitted.

-- Tab bar chrome. use_fancy_tab_bar = false is what makes colors.tab_bar
-- apply at all.
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = false
config.show_new_tab_button_in_tab_bar = false
-- Vestigial while the nine-tab floor holds; kept for a window opened by other
-- means (e.g. `wezterm cli spawn --new-window`), which has one tab.
config.hide_tab_bar_if_only_one_tab = true

-- ── 05-tab-content-state: the occupied/empty tab tint ───────────────────────

-- A tab is `occupied` when at least one of its panes has something running,
-- and `empty` only when every pane sits at the program it was spawned with.
-- The test is the pane's FOREGROUND PROCESS, never a prompt marker: OSC
-- 133/633 is off on purpose (prds/04-shell/01-core-config R5 -- it
-- double-marks starship's two-line prompt under WezTerm and leaves a
-- phantom blank line), so a prompt signal is one the shell is deliberately
-- not sending. The foreground process needs no cooperation from any shell
-- at all, which is the requirement prompt markers were only approximating.
--
-- What counts as "the program it was spawned with" is LEARNED, never named.
-- The first foreground process WezTerm reports for a pane is what WezTerm
-- spawned into it; anything in the foreground later is a descendant. So no
-- shell name appears in this config, and the classification survives
-- prds/02-terminal/06-launchd-path landing default_prog and changing the
-- spawned program from the login shell to a different one. Reading the shell
-- out of the environment was not an option: measured 2026-08-23, launchd's
-- GUI environment on this machine exports SSH_AUTH_SOCK and nothing else, so
-- os.getenv("SHELL") is nil in a GUI-launched WezTerm. (Named here in a
-- COMMENT only, the way R10 records get_current_working_directory: the
-- measurement is the value, the code route is refused.)
--
-- The baselines live in wezterm.GLOBAL for the reason the slot map above
-- records, and it is a LIFETIME reason: a module-local starts nil in every
-- new Lua context, and every config reload makes new ones (every `tinty
-- apply` is a reload), so a baseline map parked in a local would be emptied
-- on each -- and an empty baseline map re-learns against whatever is running
-- RIGHT NOW, which would record a long-lived TUI as a pane's own program and
-- read that tab as empty for as long as it ran. Not "whichever context is
-- free": measured, one context serves at a time -- see the slot map comment.
-- JSON-shaped, as GLOBAL requires: pane id as a string key, the executable
-- path as the value.
local function pane_programs()
    return wezterm.GLOBAL.tab_pane_program or {}
end

-- Learn on the tick, paint on the repaint. The accessor below is called in
-- this one place and nowhere else, and only for a pane that has no
-- baseline yet -- WezTerm documents it as a relatively expensive call
-- (it walks the OS process table), so it is bounded to once per pane rather
-- than once per repaint. pcall for the same reason R6's retint wraps
-- inject_output: a pane can die mid-iteration.
local function learn_pane_programs()
    local known = pane_programs()
    -- Rebuilt rather than mutated: a value read back out of wezterm.GLOBAL
    -- is a copy, so assigning into it does not write through (the set_slots
    -- rule above). Rebuilding from the live pane set is also what drops
    -- entries for panes that are gone, which is the only thing that keeps
    -- the map from growing for the life of the session.
    local out = {}
    local changed = false
    -- wezterm.mux has no all_panes and no get_pane on this build (measured:
    -- its function list is get_active_workspace, get_workspace_names,
    -- set_active_workspace, get_window, get_tab, spawn_window, all_windows,
    -- get_domain, all_domains, set_default_domain). Panes are reached
    -- window -> tab -> pane, which is the only route there is.
    for _, w in ipairs(wezterm.mux.all_windows()) do
        for _, t in ipairs(w:tabs()) do
            for _, p in ipairs(t:panes()) do
                local key = tostring(p:pane_id())
                if known[key] then
                    out[key] = known[key]
                else
                    local ok, name = pcall(function()
                        return p:get_foreground_process_name()
                    end)
                    if ok and type(name) == "string" and name ~= "" then
                        out[key] = name
                        changed = true
                    end
                end
            end
        end
    end
    for k in pairs(known) do
        if out[k] == nil then
            changed = true
        end
    end
    if changed then
        wezterm.GLOBAL.tab_pane_program = out
    end
end

-- The trigger list reconcile_tabs carries, for the same reasons: this build
-- emits no pane-created and no pane-closed event, so the periodic
-- update-status tick (status_update_interval = 5000, below) is the guarantee
-- -- a pane that appears, exits, or is killed from outside WezTerm is
-- reflected within one interval, which is R6's stale-state decay.
-- pane-focus-changed is inert on 20240203 and is registered anyway because
-- it costs nothing and starts working by itself on a build that emits it.
wezterm.on("update-status", learn_pane_programs)
wezterm.on("window-config-reloaded", learn_pane_programs)
wezterm.on("pane-focus-changed", learn_pane_programs)
wezterm.on("window-focus-changed", learn_pane_programs)

-- Occupied when ANY pane's current foreground process differs from that
-- pane's own baseline; empty only when every one of them matches. Read from
-- the PaneInformation the tab bar already hands us, so the paint path calls
-- no mux method at all.
--
-- Three cases fail to EMPTY on purpose, and dim is the safe direction for
-- all three: a pane created since the last tick has no baseline yet and is
-- idle anyway; a pane whose foreground process cannot be read (it died, or
-- it is not a local pane) has nothing to compare; and a pane that is gone is
-- not in tab.panes at all, so no dead pane can keep a tab lit.
local function tab_is_occupied(tab)
    local known = pane_programs()
    for _, p in ipairs(tab.panes or {}) do
        local id = p.pane_id
        local fg = p.foreground_process_name
        if id ~= nil and type(fg) == "string" and fg ~= "" then
            local base = known[tostring(id)]
            if base ~= nil and fg ~= base then
                return true
            end
        end
    end
    return false
end

-- ── R5: the tab title is the digit and nothing else ─────────────────────────

-- The bar IS the F5 keymap legend (prds/02-terminal/03-f5-jump-mode leans on
-- this): nine process titles would not fit legibly, and the opposite corner
-- is the clock's. The label is still the digit and nothing else -- what the
-- block above adds is the digit's COLOUR, which carries occupancy
-- (prds/02-terminal/05-tab-content-state). colors.tab_bar has no occupancy
-- state -- its keys are focus and hover, and it is WezTerm-wide -- so the
-- value this handler returns is the only place a PER-TAB colour is reachable
-- from.
wezterm.on("format-tab-title", function(tab)
    local label = string.format("  %d  ", tab.tab_index + 1)
    -- The bare string leaves colors.tab_bar in charge, which is how both the
    -- focused tab and an empty one keep the colours R4 derived -- base02 +
    -- bold base05 for the focused tab, base03 for an inactive one. The
    -- focused tab is never repainted here: the tab BACKGROUND says which tab
    -- has focus and the tab FOREGROUND says which tabs are busy, so the two
    -- signals never compete for one channel.
    if tab.is_active or not tab_is_occupied(tab) then
        return label
    end
    -- `Silver` is ANSI 7, the slot colors.lua fills with base05 -- the
    -- palette's own foreground, and the same slot the clock uses. An ANSI
    -- NAME rather than a colour value is what makes tinty's next apply
    -- retint this with everything else: lit against the inactive tab's
    -- base03, without taking the focused tab's background or its bold.
    return wezterm.format({
        { Foreground = { AnsiColor = "Silver" } },
        { Text = label },
    })
end)

-- ── R6: per-pane OSC retint ─────────────────────────────────────────────────

-- A pane that already received tinted-shell's per-pane OSC escapes holds a
-- palette override that outranks config.colors, so a config reload alone
-- leaves it on the OLD scheme — the exact "only this pane changed" symptom.
-- inject_output writes the new palette into every live pane's terminal stream
-- as if the program had emitted it, which replaces those stale overrides.
-- OSC only: nothing is printed and the cursor never moves, so it is safe over
-- a full-screen TUI.
local function theme_osc(t)
    local slots = {}
    for i, c in ipairs(t.ansi or {}) do
        slots[#slots + 1] = string.format("%d;%s", i - 1, c)
    end
    for i, c in ipairs(t.brights or {}) do
        slots[#slots + 1] = string.format("%d;%s", i + 7, c)
    end
    local parts = {}
    if #slots > 0 then
        parts[#parts + 1] = "\27]4;" .. table.concat(slots, ";") .. "\27\\"
    end
    local function osc(code, value)
        if value then
            parts[#parts + 1] = "\27]" .. code .. ";" .. value .. "\27\\"
        end
    end
    osc(10, t.foreground)
    osc(11, t.background)
    osc(12, t.cursor_bg)
    osc(17, t.selection_bg)
    osc(19, t.selection_fg)
    return table.concat(parts)
end

-- window-config-reloaded fires per WINDOW, and a theme switch reloads all of
-- them — so dedupe on the payload in wezterm.GLOBAL (which survives the
-- reload that resets every local in this file) to inject exactly once per
-- actual palette change. Without it every font-size edit would re-blast every
-- pane.
local function retint_all_panes()
    if not theme then
        return
    end
    local osc = theme_osc(theme)
    if osc == "" or wezterm.GLOBAL.tinty_osc == osc then
        return
    end
    wezterm.GLOBAL.tinty_osc = osc
    -- Best-effort: inject_output is absent on older builds, and a pane can
    -- die mid-iteration. A failure just means that pane keeps its stale
    -- override until its next shell, which is strictly better than erroring
    -- out of the reload.
    pcall(function()
        for _, w in ipairs(wezterm.mux.all_windows()) do
            for _, t in ipairs(w:tabs()) do
                for _, p in ipairs(t:panes()) do
                    pcall(function()
                        p:inject_output(osc)
                    end)
                end
            end
        end
    end)
end

wezterm.on("window-config-reloaded", retint_all_panes)

-- ── R7, R8, R9: the appearance baseline ─────────────────────────────────────

config.window_decorations = "RESIZE"
config.default_cursor_style = "BlinkingBlock"

-- The translucent tint is the active scheme's base00 by construction:
-- config.colors.background (with a theme) or the fallback scheme's own
-- base00 (without) — never pure black, never a constant.
config.window_background_opacity = 0.95
-- macOS frosts the desktop directly behind the translucent cell colour;
-- there is no WezTerm image layer.
config.macos_window_background_blur = 30

config.inactive_pane_hsb = { saturation = 0.85, brightness = 0.7 }
config.scrollback_lines = 10000
config.audible_bell = "Disabled"

-- Zeroed BECAUSE prds/02-terminal/07-grid-centering owns padding at runtime
-- (finding T-4): the grid is an integer number of cells and the sub-cell
-- remainder is pushed into symmetric padding there. Until that node lands the
-- remainder sits as a gap on the right and bottom — expected, not a bug here.
config.window_padding = { left = 0, right = 0, top = 0, bottom = 0 }

-- By default WezTerm resizes the OS window to land on a whole number of
-- cells; a fullscreen window cannot grow, so it leaves a large gap instead
-- and appears to change size. Off = the window stays put and the grid
-- reflows.
config.adjust_window_size_when_changing_font_size = false

-- OpenGL, not WebGpu: transparency plus the OS backdrop blur have the same
-- backend sensitivity the old layered background had. fps capped at 60:
-- uncapping to 255 let WezTerm present every redraw at up to 255 Hz, which
-- with the status repaint and cursor blink kept the GPU churning for no
-- visible benefit.
config.front_end = "OpenGL"
config.max_fps = 60
config.animation_fps = 60

-- Matched pair with nushell's `use_kitty_protocol = false`
-- (prds/04-shell/01-core-config): with it on, reedline fires the kitty
-- support query at startup and the pty returns the reply too late to consume,
-- leaking `^[[?...u` over the prompt. Enabling only the WezTerm half
-- reproduces the leak and buys nothing.
config.enable_kitty_keyboard = false

-- The one tick that drives the tab reconcile, the grid centering and the
-- clock. At 1 s it repainted the bar every second for a minute-resolution
-- clock.
config.status_update_interval = 5000

-- ── R10: the top-right clock ────────────────────────────────────────────────

-- The tab bar is at the top, so the right status IS the top-right corner.
-- Painted unconditionally and last, so nothing can displace it. HH:MM only,
-- because the 5 s status tick is what repaints it.
--
-- What used to share the corner — an OSC 7 cwd label — is impossible on this
-- build: pane:get_current_working_directory() does not exist on wezterm
-- 20240203 and raised on every status tick, which is why the corner sat
-- empty. Re-checked for the re-spec: the string appears 0 times in the
-- binary.
wezterm.on("update-right-status", function(window)
    window:set_right_status(wezterm.format({
        { Foreground = { AnsiColor = "Silver" } },
        { Text = "  " .. wezterm.strftime("%H:%M") .. "  " },
    }))
end)

-- ── R11: F6 theme toggle ────────────────────────────────────────────────────

-- Created here with one entry; later terminal nodes append to this table.
config.keys = {
    -- F6 flips between the two theme slots theme.nu parks in the state dir
    -- (prds/04-shell/09-theme-switcher owns the shell half). Bound HERE
    -- rather than in the shell because a full-screen TUI would swallow a
    -- shell-level binding.
    --
    -- background_child_process, never the blocking spawn: `tinty apply` runs
    -- the whole hook chain and blocking the GUI thread would freeze every
    -- window for its duration. Nothing needs the exit status — the visible
    -- effect arrives when tinty rewrites colors.lua and the reload watch
    -- above fires.
    --
    -- The inline PATH seeding repeats the four directories
    -- prds/02-terminal/06-launchd-path seeds at launch, for a RELATED BUT
    -- DIFFERENT reason (that node's R4). What it earns here is NOT `nu`:
    -- `sh -lc` is a LOGIN shell, so /etc/profile runs path_helper, which
    -- reads /etc/paths.d/homebrew and puts /opt/homebrew/bin on PATH by
    -- itself. Measured 2026-08-23 --
    --   env -i HOME=$HOME PATH=/usr/bin:/bin:/usr/sbin:/sbin \
    --     /bin/sh -lc 'command -v nu; command -v tinty'
    -- answers /opt/homebrew/bin/nu, and `tinty: NOT FOUND`. So the prefix is
    -- load-bearing for ~/.local/bin (where tinty is installed) and
    -- ~/.cargo/bin, neither of which path_helper ever adds, plus
    -- /opt/homebrew/sbin -- /etc/paths.d/homebrew names only `bin`.
    --
    -- DO NOT "simplify" this away on the grounds that `nu` resolves without
    -- it. The toggle would then fail one layer further in, on `tinty`, where
    -- the cause is much harder to see than a missing shell.
    --
    -- One further live-machine trap, to guard against rather than rely on:
    -- this developer's ~/.profile sources ~/.cargo/env, which is what puts
    -- ~/.cargo/bin into a login shell's PATH HERE. This repo deploys no
    -- ~/.profile (`git ls-files home` has no dot_profile), so that is a local
    -- accident and nothing may depend on it.
    {
        key = "F6",
        mods = "NONE",
        action = wezterm.action_callback(function()
            wezterm.background_child_process({
                "sh", "-lc",
                'export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$HOME/.local/bin:$HOME/.cargo/bin:$PATH"; '
                .. 'exec nu -n -c "source $HOME/.config/nushell/theme.nu; _theme_toggle"',
            })
        end),
    },
    -- CTRL-SHIFT-Q: close this whole window. Needed because the nine-tab
    -- floor applies to every window (see the reconcile comment above):
    -- closing tabs one at a time can never empty a window whose slots
    -- refill, and window_decorations = "RESIZE" leaves no titlebar close
    -- button either. Marking the window as closing FIRST is what stops the
    -- reconciler from racing the close and refilling behind it.
    --
    -- CloseCurrentTab repeated once per live tab, not a single "close
    -- window" action: WezTerm exposes no such action, and the window goes
    -- away by itself when its last tab does. confirm = false because the
    -- prompt would appear once per tab.
    {
        key = "q",
        mods = "CTRL|SHIFT",
        action = wezterm.action_callback(function(window, pane)
            local mux_win = window:mux_window()
            if not mux_win then
                return
            end
            mark_closing(mux_win:window_id())
            local acts = {}
            for _ = 1, #mux_win:tabs() do
                acts[#acts + 1] = act.CloseCurrentTab({ confirm = false })
            end
            window:perform_action(act.Multiple(acts), pane)
        end),
    },
    -- prds/01-capsule/01-container-lifecycle R8: thin wrappers over the one
    -- capsule CLI. SendString, not a spawn, because the pane's cwd is
    -- unreadable from Lua on this build (pane:get_current_working_directory()
    -- is absent from wezterm 20240203 — see the R10 comment above): the
    -- command is delivered to the pane's shell, whose cwd IS the pane's
    -- directory. One code path by construction — the binding types exactly
    -- the invocation a hand would. \r, not \n: reedline submits on carriage
    -- return. Known and accepted: the string lands wherever the pane's input
    -- goes, so a non-empty prompt line or a running TUI receives it as
    -- keystrokes — that is the wrapper being thin, not a bug to guard.
    { key = "d", mods = "CTRL|SHIFT", action = act.SendString("capsule\r") },
    { key = "b", mods = "CTRL|SHIFT", action = act.SendString("capsule --rebuild\r") },
    -- prds/01-capsule/04-recent-workspaces R2: the recents picker, in this
    -- pane and in a new tab. Both keys are thin wrappers over the one CLI
    -- (the epic's one-entry-path acceptance); `capsule recent` owns the
    -- store, the picker screen and the mount.
    --
    -- Ctrl+Shift+S is the Ctrl+Shift+D shape: SendString into this pane,
    -- whose shell has the TTY tv needs.
    --
    -- Ctrl+Shift+O is SpawnCommandInNewTab, and deliberately NOT "spawn a
    -- tab, then send text into it": a pane that was created this instant has
    -- no shell reading its pty yet, so typed input would race the shell's
    -- startup. Making the picker the tab's PROGRAM removes the race. nushell
    -- --execute runs the command and then stays interactive, so an aborted
    -- pick leaves exactly the plain tab Ctrl+Shift+T would have given, and
    -- $nu.is-interactive is TRUE while --execute runs (measured on nushell
    -- 0.114.1, 2026-08-23; it is false under -c) so the picker's own TTY
    -- guard passes.
    --
    -- nu_config and nu_env are 06-launchd-path's locals, reused and not
    -- respelled: SpawnCommandInNewTab replaces default_prog, so both config
    -- paths have to be named a second time, and taking them from the one
    -- source is the difference between a reuse and two spellings that drift.
    -- The spawn resolves `nu` through config.set_environment_variables.PATH,
    -- the same seeding default_prog depends on under a GUI launch -- if that
    -- ever stops applying to a pane spawn, the symptom is the launchd-path
    -- one: "No viable candidates found in PATH" in a tab that stays open.
    --
    -- Ctrl+Shift+T keeps WezTerm's SpawnTab and the tab reconciler's manual
    -- new-tab path (finding C-1). Either key's extra tab is adopted by the
    -- nine-tab floor, never closed by it.
    { key = "s", mods = "CTRL|SHIFT", action = act.SendString("capsule recent\r") },
    {
        key = "o",
        mods = "CTRL|SHIFT",
        action = act.SpawnCommandInNewTab({
            args = { "nu", "--config", nu_config, "--env-config", nu_env, "--execute", "capsule recent" },
        }),
    },
    -- F5: push jump_mode (prds/02-terminal/03-f5-jump-mode). A direct
    -- action, not a callback — the live callback existed only to paint the
    -- pane overlay first, and there is no overlay. one_shot resolves the
    -- mode on the first bound key; until_unknown is the backstop for keys
    -- the table does not name (Enter, arrows, a ctrl combo) — the mode ends
    -- there too, it just cannot swallow the keystroke on the way out.
    -- Binding F5 means it no longer reaches the shell or a running app;
    -- nothing in this setup uses it, but that is the trade.
    {
        key = "F5",
        mods = "NONE",
        action = act.ActivateKeyTable({
            name = "jump_mode",
            one_shot = true,
            until_unknown = true,
            timeout_milliseconds = JUMP_TIMEOUT_MS,
        }),
    },
    -- CTRL-SHIFT-X: enter copy mode from a clean state (see enter_copy_mode
    -- above for why entry is where the reset lives).
    {
        key = "x",
        mods = "CTRL|SHIFT",
        action = wezterm.action_callback(enter_copy_mode),
    },
    -- CTRL-V: native paste. Sends the clipboard as a bracketed paste, which
    -- is how text reaches both the shell and a running program (Claude,
    -- nvim). No subprocess — and it is what makes clipboard-based dictation
    -- land in the terminal.
    { key = "v", mods = "CTRL", action = act.PasteFrom("Clipboard") },
    -- CTRL-C copies when a selection exists, otherwise falls through to the
    -- pty as a normal interrupt (SIGINT) so the key keeps its terminal
    -- meaning. The fallthrough is the point: the platform-native copy
    -- shortcut without ever costing an interrupt.
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

-- ── 04-copy-mode: the two mouse bindings ────────────────────────────────────

-- CTRL-ALT-SUPER + left-drag moves the whole OS window.
-- window_decorations is "RESIZE" (01-appearance), so StartWindowDrag is
-- the ONLY handle for repositioning; the deliberately heavy modifier
-- combo keeps it from stealing ordinary clicks and selection drags.
-- SUPER is the Cmd key.
config.mouse_bindings = {
    {
        event = { Down = { streak = 1, button = "Left" } },
        mods = "CTRL|ALT|SUPER",
        action = act.StartWindowDrag,
    },
    -- CTRL + left-click opens the hyperlink under the cursor.
    -- mouse_reporting = true keeps it working while an application is
    -- capturing the mouse (DECSET 1002/1006) — nvim and other
    -- full-screen TUIs do — because without the flag WezTerm forwards
    -- the click to the application and nobody opens the URL. Plain
    -- clicks still reach the application.
    {
        event = { Up = { streak = 1, button = "Left" } },
        mods = "CTRL",
        mouse_reporting = true,
        action = act.OpenLinkAtMouseCursor,
    },
}

return config
