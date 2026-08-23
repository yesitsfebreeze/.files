# spec01 — the reconciler, `gui-startup`, and `Ctrl+Shift+Q` in `wezterm.lua`

Extends T.1's `home/dot_config/wezterm/wezterm.lua` with the self-healing
nine-tab floor: the per-window slot machinery, `reconcile_tabs`, the
`gui-startup` handler, the four repair triggers, and the `Ctrl+Shift+Q`
close-window key. Covers all of R1–R14. The source to port is the deployed
`~/.config/wezterm/wezterm.lua` (epic I4), read-only — the machinery is its
`TAB_COUNT` block through the event registrations, plus its `ctrl+shift+q`
key entry. Port the mechanism and the reason-comments verbatim in substance;
the deviations are named below.

**Est:** 2.5h

**Footprint:** `home/dot_config/wezterm/wezterm.lua` (extend — T.1 creates
it; this spec lands only after T.1 is `done`, never concurrently)

## Anchors, not line numbers

T.1's file ends state is not pinned to line counts. Anchor on content:

- Insert the whole floor block **after the head locals** (the line
  `local home = os.getenv("HOME") or ""`) and **before the
  `config.keys = {` assignment**. Everything in the block is
  self-contained; the only external names it uses are `wezterm`, `act`,
  and `config`, all defined in T.1's head.
- The `Ctrl+Shift+Q` entry is **appended inside the existing
  `config.keys = { … }` table**, beside T.1's F6 entry. T.1's spec says
  later waves append to this table; do that, do not create a second table
  or a second assignment.

## The floor block, piece by piece

Port each piece from the deployed file. Comments carrying a constraint's
reason are part of the port — the PRD makes each reason a requirement.

### Constants (R1)

`local TAB_COUNT = 9`, with the purpose comment: nine terminals always
ready; a digit is a stable address; the set is a fixed floor, not grown on
demand, so there is no "tab 7 doesn't exist yet" case.

### Slot maps (R4, R5, R6)

- `get_slots(wid)`: read `wezterm.GLOBAL.tab_slots[tostring(wid)]`.
- `set_slots(wid, ids)`: rebuild the whole map as a plain table, keep only
  keys whose window is in `wezterm.mux.all_windows()`, deep-copy each kept
  list, assign the new list, write the map back to
  `wezterm.GLOBAL.tab_slots`.
- Comments to carry: `wezterm.GLOBAL` not a module-local, because WezTerm
  evaluates the config into more than one Lua context and a local `slots`
  read back `nil` — every pass then re-adopted the current tab order as
  gospel. Per-window keys as **strings** (GLOBAL stays JSON-shaped), because
  a single shared list had two windows reading each other's ids as dead
  slots and refilling forever. Rebuilt-not-mutated, because a value read out
  of GLOBAL is a copy and assigning into it does not write through. Dropping
  dead windows' entries is the only thing keeping the map from growing for
  the life of the session.

### Closing marks (R14 support)

`is_closing(wid)` / `mark_closing(wid)` over `wezterm.GLOBAL.tab_closing`,
a list of window-id strings, rebuilt on append. Comment: the floor must
stop applying to a window being closed on purpose, or the refill races the
close and the window can never go away.

### Re-entrancy guard (R7)

`local repairing = false` — **module-local, not GLOBAL**, with the comment:
`spawn_tab` and `perform_action` pump the event loop; a nested pass saw a
half-built window, concluded seven slots were missing, and filled them
while the outer pass was still filling its own — startup produced 16 tabs
instead of 9. Module-local because it only has to hold across a
synchronous re-entry, which happens in the same Lua context by definition.

### Helpers

`live_tab_ids(mux_win)` (walk `mux_win:tabs()`, collect `tab:tab_id()`)
and `index_of(list, want_id)`.

### `reconcile_tabs(window)` (R1–R3, R8–R11)

Port the deployed function whole. Its shape, so the port can be checked:

1. Resolve `window:mux_window()`; return if nil, if `is_closing(wid)`, or
   if `repairing`.
2. Build `live` and the `alive` set.
3. Build `want`: every id from `get_slots(wid) or live` that is still
   alive keeps its position; a dead id becomes `false` **only while
   `#want < TAB_COUNT`** (a dead slot past the floor is dropped, R1); live
   ids not in the map are appended (hand-opened tabs are adopted, never
   closed, R1); pad with `false` up to `TAB_COUNT`.
4. No-hole fast path: `set_slots` and return — the path every idle tick
   takes, a plain tab-list walk (R11).
5. Capture the active tab and whether it is still alive (R10).
6. Set `repairing = true`; run the repair inside `pcall` — comment: a
   spawn failure (out of ptys, bad `default_prog`) must not latch the
   guard and silently disable healing; a `false` left in the map is
   harmless, the next pass reads it as a dead slot and retries (R8).
7. Repair loop, left to right: for each `false` slot, `spawn_tab({})`,
   record the new id in `want`, and **only when
   `index_of(live_tab_ids(mux_win), tab:tab_id()) ~= pos`**: activate the
   new tab, then `perform_action(act.MoveTab(pos - 1), pane)`. Comment
   both halves: skipping the no-op is not an optimization — `MoveTab` acts
   on whatever the GUI believes is active, which right after a spawn can
   still be the previous tab, so a "harmless" no-op move shoved the old
   tab along and startup came out `1,0,2,3…` (R9); spawn-then-move because
   a plain `spawn_tab` appends and would silently renumber everything
   after the hole — F5+4 would reach the old tab 5 (R3).
8. After the loop: re-activate the previously active tab **by id** when it
   survived, else the first fresh tab — closing a tab should move you on,
   not snap you onto a blank replacement (R10).
9. `repairing = false`, `set_slots(wid, want)`,
   `wezterm.log_error("tab reconcile failed: " .. tostring(err))` on a
   failed `pcall`.

Head comment for the function (R2): WezTerm emits **no tab-close event**,
so reconcile rather than intercept — comparing the live list against the
slot map covers `CloseCurrentTab`, `exit` in a tab's last pane, a crashed
shell and `wezterm cli kill-pane` with one mechanism; closing a pane in a
split tab needs nothing, the tab survives. Slots are tracked by `tab_id`,
never by index, because indices are exactly what shift when a tab dies
(R4).

### `gui-startup` (R12)

```lua
wezterm.on("gui-startup", function(cmd)
    local _, _, mux_win = wezterm.mux.spawn_window(cmd or {})
    if not mux_win then return end
    wezterm.GLOBAL.tab_slots = nil
    wezterm.GLOBAL.tab_closing = nil
    local window = mux_win:gui_window()
    reconcile_tabs(window)
    mux_win:tabs()[1]:activate()
    window:toggle_fullscreen()
end)
```

Comments: `cmd` reaches the **first tab only**, so `wezterm start -- nvim
foo` does not open nine editors; the GLOBAL clear is required because a
config reload re-runs this file while GLOBAL survives, and stale ids from
a previous run would read as dead slots. Fullscreen, not maximized
(finding T-5). Write **no** attach-time GUI hook and **no**
window-enlarging call — neither exists in the live config or in this
build's event set.

### The four triggers (R11, R13)

```lua
wezterm.on("pane-focus-changed", reconcile_tabs)
wezterm.on("window-focus-changed", reconcile_tabs)
wezterm.on("update-status", reconcile_tabs)
wezterm.on("window-config-reloaded", reconcile_tabs)
```

Comments to carry: `update-status` (T.1's
`status_update_interval = 5000`) is the guarantee — it heals whether or
not the tab is focused; `window-config-reloaded` fires once per newly
created window and again on every reload, which is what fills **any** new
window at birth — the startup window aside, `Cmd+N` and `Ctrl+Shift+N`
exist only as WezTerm **defaults** resolving to `SpawnWindow`
(`wezterm show-keys --lua`), and `wezterm cli spawn --new-window` comes up
at the floor the same way (R13 — the mechanism is the event, not a
binding); `pane-focus-changed` is **inert on 20240203** — verified never
to fire on a pane switch — kept because it costs nothing and starts
working by itself on a build that emits it.

Registering `window-config-reloaded` twice (T.1 registers
`retint_all_panes` on it) is fine: `wezterm.on` accumulates handlers.

### `Ctrl+Shift+Q` (R14)

Append to `config.keys`:

```lua
{
    key = "q",
    mods = "CTRL|SHIFT",
    action = wezterm.action_callback(function(window, pane)
        local mux_win = window:mux_window()
        if not mux_win then return end
        mark_closing(mux_win:window_id())
        local acts = {}
        for _ = 1, #mux_win:tabs() do
            acts[#acts + 1] = act.CloseCurrentTab({ confirm = false })
        end
        window:perform_action(act.Multiple(acts), pane)
    end),
},
```

Comment with all three reasons: `mark_closing` **first**, or the
reconciler races the close and refills behind it; one `CloseCurrentTab`
per live tab because WezTerm exposes no "close window" action and the
window goes away when its last tab does; `confirm = false` because the
prompt would appear once per tab. Needed at all because the floor applies
to every window — closing tabs one at a time can never empty a window
whose slots refill — and `window_decorations = "RESIZE"` leaves no
titlebar close button (finding T-6; kept alive by the Q1 answer that kept
the floor).

## Deviations from the deployed file, on purpose

- **No burrito.** The deployed head comment says multiplexing lives in the
  shell via burrito; that tool is refused (epic I1 — the floor is the only
  multiplexer). Carry no burrito mention into any comment.
- **No `center_grid`** and none of its registrations —
  [`07-grid-centering`](../../07-grid-centering/prd.md) (T.8) owns them.
- **No F5 / `jump_mode` / `PaneSelect`**, no copy mode, no `Ctrl+V`, no
  `Ctrl+C`, no mouse bindings, no wallpaper pipeline — other nodes or
  refused. Epic I3 stands: `PaneSelect` must appear nowhere.
- The deployed reconcile comment names `ctrl+shift+n` as if it were a
  binding of ours; write the R13 wording instead (WezTerm defaults, event
  is the mechanism).

## Acceptance

Ran 2026-08-22 (wezterm 20240203-110809-5046fc22): rc=0, config-field hits
0, `'Q'` rows 1, `gui-startup` 1, `reconcile_tabs)` 4, refused names 0, hex
0, census one line.

- [x] `env HOME=$SCRATCH wezterm --config-file
      home/dot_config/wezterm/wezterm.lua ls-fonts --list-system` exits 0
      with stderr free of `not a valid Config field` and of
      `Configuration Error`.
- [x] `env HOME=$SCRATCH wezterm --config-file … show-keys --lua` lists
      the `Q`/`CTRL` row (shift folds into the letter in show-keys output)
      and still lists `F6`.
- [x] The file contains exactly four `wezterm.on("…", reconcile_tabs)`
      registrations, for `pane-focus-changed`, `window-focus-changed`,
      `update-status`, `window-config-reloaded`; one `gui-startup` handler
      containing `toggle_fullscreen`; and no occurrence of `PaneSelect`,
      `center_grid`, or `burrito`.
- [x] `mark_closing` appears in the `q` key callback before the
      `CloseCurrentTab` loop, and `confirm = false` appears in that loop.
- [x] `/usr/bin/grep -cE '#[0-9a-fA-F]{6}'` on the file still returns 0,
      and `git ls-files home/dot_config/wezterm/` still prints exactly
      `home/dot_config/wezterm/wezterm.lua`.

## Verify

```sh
SRC=home/dot_config/wezterm/wezterm.lua
H="$(mktemp -d)"
env HOME="$H" wezterm --config-file "$SRC" ls-fonts --list-system \
  >/dev/null 2>"$H/err"; echo "rc=$?"
/usr/bin/grep -c 'not a valid Config field' "$H/err" || true    # want 0
env HOME="$H" wezterm --config-file "$SRC" show-keys --lua \
  | /usr/bin/grep -c "'Q'"                                      # want >=1
/usr/bin/grep -c 'wezterm.on("gui-startup"' "$SRC"              # want 1
/usr/bin/grep -c 'reconcile_tabs)' "$SRC"                       # want 4
/usr/bin/grep -cE 'PaneSelect|center_grid|burrito' "$SRC" || true  # want 0
/usr/bin/grep -cE '#[0-9a-fA-F]{6}' "$SRC" || true              # want 0
git ls-files home/dot_config/wezterm/                           # one line
```
