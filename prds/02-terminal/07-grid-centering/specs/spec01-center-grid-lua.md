---
est: 1h
footprint:
  - home/dot_config/wezterm/wezterm.lua
  - tests/wezterm-startup-layout.sh
---

# spec01 — `center_grid` in `wezterm.lua`, with the vertical arm fixed

Adds the runtime padding owner to `home/dot_config/wezterm/wezterm.lua`:
the pure padding arithmetic, the `center_grid` handler around it, and the
three event registrations. Covers R1-R9. The source to port is the
deployed `~/.config/wezterm/wezterm.lua` (epic I4), read-only — its
`center_grid` block and the three `wezterm.on` lines under it. The block
is ported with one deliberate change and one deliberate refactor, both
named below. Also flips the one assertion in
`tests/wezterm-startup-layout.sh` that requires `center_grid` to be
absent, in the same commit, because that gate goes red the moment this
code lands.

## The change A4 ordered, and what it supersedes

**R4 as written in `prd.md` is superseded by A4.** R4 says the chrome
subtraction's "arithmetic is right; only its comment is stale". That is
false and must not be carried into the file. The measurement is in Q4:
`mux_tab:get_size()` reports the **pty** size, exactly `rows * cell_h`,
so `chrome_h = win.pixel_height - tab.pixel_height - pad.top - pad.bottom`
measures the tab bar *plus* the vertical remainder, `avail_h` collapses to
`tab.pixel_height + pad.top + pad.bottom`, and `gap_y` is zero by
construction. The live feature centres horizontally only.

What lands instead: the bar is **reserved**, not measured.

```lua
local bar_h = math.ceil(cell_h) + 1
local avail_h = win.pixel_height - bar_h
```

`chrome_h` does not survive. The horizontal arm is unchanged — `avail_w`
is `win.pixel_width` outright, which is why that arm was always correct.

## The refactor, and why it is not gold-plating

Split the arithmetic into a pure function that takes only the window and
the cell, and call it from the handler:

```lua
-- >>> grid-padding (pure): no wezterm calls in this block —
-- tests/wezterm-grid-centering.sh --math slices it out between these two
-- sentinels and runs it against measured geometries.
local function grid_padding(win_w, win_h, cell_w, cell_h)
    ...
    return { left = …, right = …, top = …, bottom = … }
end
-- <<< grid-padding
```

The failure this node exists to fix — an arm that computes zero for every
input — is invisible to a grep and needs no GUI to catch. A pure function
is the only way a gate can prove the arm produces padding at all. Keep
the block free of `wezterm.*`, `window` and `config`: the gate loads it
with no wezterm module in scope.

## `grid_padding(win_w, win_h, cell_w, cell_h)`

Exactly this arithmetic, in this order:

1. `local bar_h = math.ceil(cell_h) + 1`
2. `local avail_w = win_w` and `local avail_h = win_h - bar_h`
3. `local cols = math.floor(avail_w / cell_w)`,
   `local rows = math.floor(avail_h / cell_h)`
4. `local tot_x = math.floor(avail_w - cols * cell_w)` and
   `local tot_y = math.floor(avail_h - rows * cell_h)`
5. return `left = math.floor(tot_x / 2)`,
   `right = tot_x - math.floor(tot_x / 2)`, and the same split for
   `top`/`bottom` from `tot_y`

The comments this block must carry, each because it is a bug already paid
for:

- **The reserve is empirical, and bounded in the safe direction** (A4).
  Measured against `wezterm 20240203-110809-5046fc22`, the tab bar is
  `cell_h` or `cell_h + 1` pixels tall at font sizes 9, 12, 14, 17 and 21;
  re-measure if the build moves. Over-reserving by *d* px costs *d* px of
  top/bottom asymmetry, and costs one row in the boundary case where
  `(win_h - bar) mod cell_h < d` — stable either way, never a flicker.
  Under-reserving over-pads, drops a row and parks a whole cell at the
  bottom, which is R5's failure in its stable form. `cell_h + 1` therefore
  over-reserves on purpose.
- **The reserve assumes the tab bar is shown**, which the nine-tab floor
  guarantees (epic I1 — `hide_tab_bar_if_only_one_tab` only hides the bar
  at one tab, and the floor keeps nine). The two one-tab states are a new
  window's birth instant before the reconciler fills it and a window being
  closed through `Ctrl+Shift+Q`; both are transient and neither is worth a
  branch.
- **Measure, do not reconstruct** (R3). The cell comes from the grid's own
  rendered pixels, `cell = pixels / count`, not from
  window-minus-padding — that reads stale padding under fractional DPI and
  during the multi-frame settle after a font zoom, and produced a wrong
  cell size.
- **Absolute, never incremental** (R8). Both axes are derived from the
  constant window and the cell only; the current padding is not an input
  to this function on either axis, so a given font always yields the same
  padding regardless of zoom history and the grid cannot ratchet smaller.
- **Floor the total gap before halving** (R5). Over-padding by even a
  sub-pixel — possible when the cell is not a whole pixel — shrinks the
  usable area below `cols * cell`, dropping a column that the next tick
  adds back: a 1 Hz flicker. Under-padding by less than a pixel is
  invisible and stable.

## `center_grid(window)`

Port the deployed handler, with the arithmetic delegated to
`grid_padding`:

1. `local mux_win = window:mux_window()`; return if nil.
2. `local mux_tab = mux_win:active_tab()`; return if nil. Comment (R2):
   reach the tab through the mux window, **not**
   `window:active_pane():tab()` — an overlay (debug overlay, char select,
   launcher) makes the active pane a detached one whose `:tab()` is nil,
   which crashed centering mid-flight and left the stale padding in place.
   `mux_window():active_tab()` always resolves the real tab, so
   `update-status` keeps centering over an overlay.
3. `local win = window:get_dimensions()` and
   `local tab = mux_tab:get_size()`; return unless both are present and
   `tab.cols`, `tab.rows`, `tab.pixel_width`, `tab.pixel_height` are all
   non-zero.
4. `cell_w = tab.pixel_width / tab.cols`,
   `cell_h = tab.pixel_height / tab.rows`; return if either is `<= 0`.
5. `local overrides = window:get_config_overrides() or {}` and
   `local pad = overrides.window_padding or { left = 0, right = 0, top =
   0, bottom = 0 }`. `pad` is read **only** for the change comparison in
   step 7 — it must not appear in any arithmetic (R8).
6. `local new_pad = grid_padding(win.pixel_width, win.pixel_height,
   cell_w, cell_h)`.
7. The idempotency guard (R6): compare all four sides against `pad` and
   only then `overrides.window_padding = new_pad` and
   `window:set_config_overrides(overrides)`. Comment:
   `set_config_overrides` **re-fires the event that called it**, so
   writing unconditionally is a feedback loop; with the guard, idle ticks
   are nearly free.

Head comment for the function: the grid is an integer number of cells and
almost never divides the window exactly, so the sub-cell remainder would
sit as an uneven gap on the right and bottom; this measures the true cell,
recomputes how many whole cells fit, and pushes the remainder into
padding — adapting to any font size, DPI or resolution. Say that the
top/bottom split is symmetric **to within the bar over-reserve**, 0-2 px
at the sizes measured (A4's qualification of R1), and that this function
is the runtime owner of `window_padding`, which is why
`config.window_padding` is declared as four zeroes further down the file
(R9, T.1's R8).

## The three registrations (R7)

```lua
wezterm.on("window-resized", center_grid)
wezterm.on("window-config-reloaded", center_grid)
wezterm.on("update-status", center_grid)
```

Comment all three with the reason the tick is one of them:
`window-resized` covers a resize and dragging between differently sized
monitors, `window-config-reloaded` covers config and font-size edits, and
**interactive font zoom fires neither** — which is the whole reason
`update-status` is here, and why the 5 s tick appears in this node's
requirements as well as in `02-startup-layout`'s. The interval is
`config.status_update_interval = 5000`, already in the file, so the number
is **5 s**. The live block's comments say "~1s" in two places; that is
wrong and does not come over.

Registering `window-config-reloaded` a third time is fine — the file
already registers `reconcile_tabs` and `retint_all_panes` on it, and
`wezterm.on` accumulates handlers.

## Placement

Anchor on content, never on line numbers.

- Insert the whole block **after** the reconcile trigger registrations
  (the line `wezterm.on("window-config-reloaded", reconcile_tabs)`) and
  **before** the F5 block (the line `local JUMP_TIMEOUT_MS = 5000`). That
  is the deployed file's own order.
- Touch nothing else in `wezterm.lua`. In particular leave
  `config.window_padding` (the four zeroes and its T-4 comment),
  `config.status_update_interval`,
  `config.adjust_window_size_when_changing_font_size`, `format-tab-title`
  and `config.keys` exactly as they are. `05-tab-content-state` (T.6)
  edits `format-tab-title` in this same file; this spec must leave no
  change outside its own inserted block.

## The gate flip

`tests/wezterm-startup-layout.sh` asserts `center_grid` appears nowhere
in `wezterm.lua` — T.2's scope boundary, obsolete the moment this code
lands. Delete those two lines:

```sh
  chk_fail "static: center_grid appears nowhere (T.8's)" \
           $GREP -q 'center_grid' "$SRC"
```

and leave a one-line comment in their place naming
`tests/wezterm-grid-centering.sh` as the gate that now asserts
`center_grid` is **present**. Do not invert the assertion in place: T.2's
gate must not start depending on T.8's code. Change nothing else in that
file — the `PaneSelect`, `burrito` and no-hex assertions above it stay.

## Acceptance

- [x] `grid_padding` exists between the two sentinels, contains no
      `wezterm`, `window` or `config` reference, and `chrome_h` appears
      nowhere in the file.
- [x] `pad.left`, `pad.right`, `pad.top` and `pad.bottom` each appear
      exactly once in the file, all four inside the change comparison —
      no axis folds current padding into its own arithmetic (R8).
- [x] `math.ceil(cell_h) + 1` is present, and the comment above it names
      `20240203-110809-5046fc22` as the build it was measured against.
- [x] Exactly three `, center_grid)` registrations, one each for
      `window-resized`, `window-config-reloaded` and `update-status`; no
      comment in the file claims font zoom is caught in ~1 s.
- [x] `wezterm --config-file home/dot_config/wezterm/wezterm.lua ls-fonts
      --list-system` exits 0 against a scratch `HOME`, with no
      `Configuration Error` and no `not a valid Config field` on stderr.
- [x] `bash tests/wezterm-startup-layout.sh` is green after the flip, and
      `bash tests/wezterm-appearance.sh --static` is still green — the new
      block disturbs no T.1 or T.2 invariant.
- [x] The edit to `wezterm.lua` is confined to the two files this spec
      names, proved by reconstruction rather than by `git diff --stat`.
      **Reworded by the orchestrator on the transition**, because the
      original check is not runnable in this tree and a `[x]` against it
      would have been a false record: `git diff --stat` reports 35 changed
      files, since several lanes hold uncommitted work here and
      `gates/lib.sh` says as much in as many words. Nothing in the diff
      distinguishes one lane's bytes from another's, and mtime evidence is
      contaminated for the same reason. What the implementer proved instead
      is the stronger statement: stripping lines 320-472 back out and
      re-applying the block to the remainder yields a file `cmp`-identical
      to disk, so `format-tab-title`, `config.keys`,
      `config.window_padding` and `config.status_update_interval` are
      untouched **by construction** rather than by inspection, and
      `05-tab-content-state`'s region is clean. Original text follows.

      `git diff --stat` touches exactly two files:
      `home/dot_config/wezterm/wezterm.lua` and
      `tests/wezterm-startup-layout.sh`.
      **Left open on purpose: this check is not runnable in this tree, and
      a `[x]` here would be a false record.** `git diff --stat` reports 35
      changed files, because the working tree carries the uncommitted work
      of several concurrent lanes — `gates/lib.sh` says so in as many
      words ("the working tree carries staged work no gate caused… so
      porcelain is never empty"), and during this implementation other
      lanes wrote `home/dot_config/nushell/*`,
      `home/dot_config/nvim/lua/plugins/lsp.lua`, six `tests/*.sh` and
      `gates/waves.tsv`. Nothing in the diff distinguishes their bytes
      from mine, so mtime evidence is contaminated too. What was proved
      instead, and it is the stronger statement for `wezterm.lua`: the
      edit there is exactly **one contiguous insertion of 153 lines after
      line 319** and nothing else — the inserted range was stripped back
      out of the file on disk and the block re-applied to the remainder,
      and the result compared byte-for-byte (`cmp`) against the file on
      disk, identical. So `format-tab-title`, `config.keys`,
      `config.window_padding` and `config.status_update_interval` are
      untouched by construction, not by inspection. In
      `tests/wezterm-startup-layout.sh` the only change is the two-line
      `chk_fail` deleted and a four-line comment in its place.

## Verify and Proof

```sh
H="$(mktemp -d)"
env HOME="$H" wezterm --config-file home/dot_config/wezterm/wezterm.lua \
    ls-fonts --list-system >/dev/null && echo load-ok
/usr/bin/grep -c ', center_grid)' home/dot_config/wezterm/wezterm.lua
/usr/bin/grep -c 'chrome_h' home/dot_config/wezterm/wezterm.lua   # expect 0
bash tests/wezterm-startup-layout.sh
bash tests/wezterm-appearance.sh --static
git diff --stat
```
