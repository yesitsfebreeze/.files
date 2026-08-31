---
est: 1.5h
footprint:
  - tests/wezterm-grid-centering.sh
  - gates/waves.tsv
  - gates/manual/wave3.md
---

# spec02 — the grid-centering gate, its wave-3 row, and the manual checks

The gate that proves spec01 statically, arithmetically and by load probe,
its registration in the wave-3 gates cell, and the interactive checks only
a human at a GUI can run. Lands after spec01, never before: every stage
reads the file spec01 writes.

The middle stage is the point of this gate. The defect A4 settled — a
vertical arm that computes zero for every input — passes any grep and any
config-load probe. Only running the arithmetic against measured
geometries catches it, which is why spec01 leaves `grid_padding` pure and
sentinel-marked.

## The script

House pattern, inherited from `tests/wezterm-startup-layout.sh` and not
re-derived: `set -u`, source `gates/lib.sh`, `GREP=/usr/bin/grep` (`grep`
in this environment is a shell function over ugrep), scratch `HOME` from
`gates_tmpdir`, the live `~/.config` never written, `chk_ok`/`chk_fail`
for every assertion with a message naming what failed. Registered
`external`. `SRC="$REPO/home/dot_config/wezterm/wezterm.lua"`.

Stage flags `--static`, `--math`, `--probe`; no argument runs all three.

### `--static` — greps over the source file

- `local function center_grid(window)` present; so are
  `local function grid_padding(`, the `-- >>> grid-padding` and
  `-- <<< grid-padding` sentinels (R1).
- `mux_win:active_tab()` present and `active_pane():tab()` absent (R2).
- `tab.pixel_width / tab.cols` and `tab.pixel_height / tab.rows` present
  (R1, R3).
- `chrome_h` absent — the derivation A4 removed.
- `math.ceil(cell_h) + 1` present, and `20240203-110809-5046fc22` present
  in the file (the empirical-constant note A4 requires).
- `pad.left`, `pad.right`, `pad.top`, `pad.bottom` each occur exactly once
  (R8: neither axis folds current padding into its arithmetic; the one
  occurrence each is the change comparison).
- `math.floor(` occurs on the `tot_x`/`tot_y` lines — the total gap is
  floored before halving (R5).
- `set_config_overrides` occurs exactly once, and the line before it is
  inside a comparison against `pad` (R6).
- Exactly 3 hits of `, center_grid)`, and one line each registering
  `"window-resized"`, `"window-config-reloaded"` and `"update-status"` on
  it (R7).
- `status_update_interval = 5000` still present; `~1s` and `~1 s` absent
  anywhere in the file (the stale live comment, A4's second finding).
- `window_padding = { left = 0, right = 0, top = 0, bottom = 0 }` still
  present — T.1's R8 declaration, which R9 names this node's reason for
  existing.
- `hide_tab_bar_if_only_one_tab = true` still present: the reserve assumes
  the bar is shown, and epic I1's floor is what guarantees it.
- No `#rrggbb` constant anywhere (epic acceptance), and
  `git ls-files home/dot_config/wezterm/` is exactly
  `home/dot_config/wezterm/wezterm.lua`.

### `--math` — the arithmetic against measured geometries

Precondition `chk`: `wezterm` on PATH; echo the version it ran against
(the epic pins `20240203-110809-5046fc22`). No separate Lua interpreter:
`wezterm --config-file <file>` executes arbitrary Lua and a config that
returns `{}` exits 0, so the pinned binary is the interpreter. `io.open`
and `os.getenv` are available inside it — verified 2026-08-23.

Build the probe in the scratch dir:

```sh
sed -n '/-- >>> grid-padding/,/-- <<< grid-padding/p' "$SRC" > "$P"
cat >> "$P" <<'DRIVER'
   … cases table, assertions, io.open(os.getenv("OUT"), "w") …
   return {}
DRIVER
env HOME="$SCRATCH" OUT="$SCRATCH/math.tsv" \
  "$WEZTERM" --config-file "$P" ls-fonts --list-system >/dev/null 2>&1
```

The driver writes one `PASS`/`FAIL` line per check to `$OUT` with a label;
the shell reads the file and feeds each line through `chk`. A missing or
empty `$OUT` is one FAIL saying the probe never ran — never a silent pass.

The cases, all measured on the pinned build at dpi 144, CaskaydiaCove,
`line_height = 1.0`, retro tab bar shown. Columns are the driver's
inputs plus the true bar height, which the driver needs to model what
WezTerm does with the padding it is handed:

| label | win w×h | cell w×h | true bar |
|---|---|---|---|
| f9-default  | 880×526   | 11×21 | 22 |
| f12-default | 1120×700  | 14×28 | 28 |
| f14-default | 1280×826  | 16×33 | 34 |
| f17-default | 1600×1000 | 20×40 | 40 |
| f21-default | 2000×1226 | 25×49 | 50 |
| f9-max      | 2992×1756 | 11×21 | 22 |
| f14-max     | 2992×1756 | 16×33 | 34 |
| f21-max     | 2992×1756 | 25×49 | 50 |
| f21-max2    | 2472×1694 | 25×49 | 50 |

Per case the driver computes `p = grid_padding(win_w, win_h, cell_w,
cell_h)`, plus `rows_assumed = floor((win_h - (ceil(cell_h)+1)) /
cell_h)`, `remaining = win_h - true_bar - p.top - p.bottom`,
`rows_after = floor(remaining / cell_h)` and
`rows_nopad = floor((win_h - true_bar) / cell_h)`. Checks:

- **No flicker, any case**: `remaining >= rows_assumed * cell_h`. This is
  R5's failure mode as an inequality — over-padding below the assumed grid
  is what drops a row the next tick adds back.
- **Pad-independent, any case**: a second call with the same arguments
  returns the same four numbers, and `grid_padding` takes no padding
  argument at all (R8).
- **Horizontal gap bounded, any case**: `p.left + p.right <
  ceil(cell_w)` and `|p.left - p.right| <= 1`.
- **Row-loss bound, any case**: `rows_nopad - rows_after <= 1`. One row is
  the documented cost of over-reserving the bar, and it is paid only where
  `(win_h - bar) mod cell_h` is smaller than the over-reserve — the two
  `f12`/`f17` default-sized rows below are exactly that case.
- **The maximized four lose no row**: `rows_after == rows_nopad` for
  `f9-max`, `f14-max`, `f21-max`, `f21-max2`. Fullscreen is the shape
  `gui-startup` actually produces.
- **The vertical arm is alive** — the regression check for the whole Q4
  finding: `p.top > 0` for `f9-max`, `f14-max`, `f21-max` and `f21-max2`.
  The ported-unchanged live arithmetic returns 0 for all four.
- **Exact expected padding**, so a wrong constant cannot pass the
  inequalities above:

| label | left/right | top/bottom |
|---|---|---|
| f9-default  | 0 / 0  | 0 / 0   |
| f12-default | 0 / 0  | 13 / 14 |
| f14-default | 0 / 0  | 0 / 0   |
| f17-default | 0 / 0  | 19 / 20 |
| f21-default | 0 / 0  | 0 / 0   |
| f9-max      | 0 / 0  | 6 / 6   |
| f14-max     | 0 / 0  | 3 / 3   |
| f21-max     | 8 / 9  | 20 / 20 |
| f21-max2    | 11 / 11| 13 / 14 |

The `f21-max` `8 / 9` and `f21-max2` `11 / 11` rows are the padding the
**live** feature computes on those geometries, recorded in Q4's second
table. They are the anchor that the fix left the working horizontal arm
alone.

### `--probe` — the real binary loads the real file

Precondition `chk`: `wezterm` on PATH. With `HOME` pointed at the scratch
dir, `wezterm --config-file "$SRC" ls-fonts --list-system` exits 0 and its
stderr is free of `not a valid Config field` and `Configuration Error` —
the new block must not break T.1's standalone-load guarantee.

No GUI is launched. `center_grid` only fires on a live window, and
`window:set_config_overrides` on a real session is the disruption the
manual rows exist to avoid.

## `gates/waves.tsv`

Append ` | external bash tests/wezterm-grid-centering.sh` to the
**wave-3** gates cell — the row whose tasks already include `T.8`. One
cell, one row, nothing else in the file. Shared file: land only when no
other lane holds it.

**Carved out of this implementer's footprint.** Three PRDs were appending
gate segments to this one file concurrently, so the orchestrator owns the
append and the evidence for it. The exact segment to add to the wave-3
gates cell, verbatim, is

```
 | external bash tests/wezterm-grid-centering.sh
```

and the rest of this spec landed without it.

## `gates/manual/wave3.md`

Add five `**T.8**` rows in the file's existing PASS/FAIL style, one per
PRD acceptance box, every box `[ ]` (`manual-coverage.sh` fails a
pre-ticked box, and T.8 must appear in no other wave file):

- **Font zoom recentres** — press the font-zoom keys up and down a few
  steps, wait one `status_update_interval` (5 s) after each.
  PASS: no edge gap wider than one cell. FAIL: a growing band on the
  right or bottom — `update-status` is not reaching `center_grid`, which
  is the only trigger interactive zoom fires.
- **An overlay changes nothing** — open the debug overlay
  (`Ctrl+Shift+L`) and close it.
  PASS: padding unchanged, and `wezterm` logs no Lua error. FAIL: the
  grid jumps, or the log carries an error — the active pane was reached
  through `:tab()` on a detached pane (R2).
- **No 1 Hz flicker** — sit idle for at least four ticks (≥20 s).
  PASS: the grid edges do not move; no column appears and disappears.
  FAIL: a column or row breathing once every tick — the total gap was not
  floored before halving (R5), or the idempotency guard is missing (R6).
- **No ratchet** — note the edge gaps, zoom the font up three steps, back
  down three, wait a tick.
  PASS: the gaps are what they were. FAIL: the grid has crept smaller —
  the padding folded the previous padding back in (R8).
- **A denser monitor recentres** — drag the window to a monitor of a
  different pixel density, wait a tick.
  PASS: recentred, no restart. FAIL: stale padding until WezTerm is
  restarted — `window-resized` is not wired (R7).

## Acceptance

- [x] `bash tests/wezterm-grid-centering.sh` is ALL PASS, and each stage
      also runs alone via `--static`, `--math`, `--probe`.
- [x] The `--math` stage reports one line per case per check, and its
      FAIL path is proved: temporarily reverting `math.ceil(cell_h) + 1`
      to the live `chrome_h` derivation turns the four "vertical arm is
      alive" checks red. Quote that run, then restore.
- [x] `bash gates/wave-status.sh` still parses the registry with the new
      wave-3 command in place. **Closed by the orchestrator on the
      transition**, which appended the segment and ran both halves:
      `bash gates/wave-status.sh` → `3  PENDING  5/12  7 registered` (six
      before), and `bash gates/wave-status.sh --run 3` → all seven wave-3
      commands PASS, the new one ending
      `wezterm-grid-centering gate: ALL PASS`.
      **The orchestrator's box, not this implementer's.** `gates/waves.tsv`
      was carved out of this footprint because three PRDs were appending
      to that one cell at once (see the `gates/waves.tsv` section above for
      the verbatim segment). What was checked here is the registry as it
      stands *without* the new command: `bash gates/wave-status.sh` parses
      it and prints the matrix (`3 PENDING 5/12 6 registered`), and
      `bash gates/wave-status.sh --run 3` is green on all six commands
      already in the cell. The seventh has to be appended before this box
      can be closed.
- [x] `bash gates/manual-coverage.sh` is green with the five new `T.8`
      rows in `gates/manual/wave3.md`, all boxes `[ ]`.
- [x] `bash tests/wezterm-startup-layout.sh` and
      `bash tests/wezterm-appearance.sh` stay green.
- [x] The script never names `$HOME/.config` and never writes outside
      `gates_tmpdir` — safety rule 1, checked by reading the script.

## Verify and Proof

```sh
bash tests/wezterm-grid-centering.sh
bash tests/wezterm-grid-centering.sh --static
bash tests/wezterm-grid-centering.sh --math
bash tests/wezterm-grid-centering.sh --probe
bash gates/wave-status.sh >/dev/null && echo registry-ok
bash gates/manual-coverage.sh
bash tests/wezterm-startup-layout.sh
bash tests/wezterm-appearance.sh
```
