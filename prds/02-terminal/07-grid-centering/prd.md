---
state: done
claim: 
priority: 13
est: 2.5h
actual: 10m
task: T.8
mode: afk
needs:
  - 00-delivery/corrections/w0-2-terminal-respec
  - 02-terminal/01-appearance
verify: "bash tests/wezterm-grid-centering.sh"
---

# Dynamic grid centering

Parent: [Terminal epic](../prd.md) · C 8 · U 6 · source: Dynamic grid
centering

**Marker note.** The inventory entry carries a not-in-the-minimal-base marker,
and that marker is **withdrawn** by the answer to this re-spec's Q3
(2026-08-21, user): the feature is kept, as its own child, so it can still be
cut late without unpicking
[`01-appearance`](../01-appearance/prd.md). Following the D.1b precedent the
marker moves and the `C`/`U` numbers do not. Recorded here so a later reader
does not restore the marker from
[`capabilities-terminal.md`](../../../docs/capabilities-terminal.md), which
still shows it — the inventory's own text called it "a recommendation, not a
settled call… Flag it with D.1 for the human", and the human kept it.

Purpose: the cell grid is an integer number of cells and almost never divides
the window exactly, so the leftover sits as an uneven gap on the right and
bottom. This node measures the true cell size and pushes the sub-cell
remainder into symmetric padding, on every font size, DPI and resolution.
**This node is finding T-4** ("padding is zeroed and recomputed every tick by
`center_grid`; there is no platform-aware padding").

**Why it was kept, recorded so the question is not reopened cheaply.** Holding
it out of the minimal base is not free: `window_padding` is zeroed in the base
config *because* this feature owns padding at runtime
([`01-appearance`](../01-appearance/prd.md) R8), so dropping it without
replacing it leaves the remainder as an uneven gap — and any static
replacement is wrong again at the next font-size change, which is the problem
the feature exists to solve. The value is demonstrated rather than assumed:
the live config's own comment tells the reader to hand-tune font size "until
the bottom/right edge sits flush", which is the manual version of exactly
this. And each of its four non-obvious pieces is a bug already paid for.

**Numbering.** `07-` appends rather than re-sorting. The convention orders
prefixes by value ratio, but this epic already does not —
[`06-launchd-path`](../06-launchd-path/prd.md) is the best ratio in it and
sits last — and renumbering would churn every dependency string in
`plan.json` and both README lists for no gain.

## Requirements

- [x] **R1** — **Measure the cell from the grid's own rendered area.**
      `mux_tab:get_size()` returns `{cols, rows, pixel_width, pixel_height}`,
      so `cell = pixels / count` is exact. Recompute how many whole cells fit
      the window and push the sub-cell remainder into symmetric
      `window_padding` overrides — symmetric to within R4's over-reserve on
      the vertical axis, which measured 0-2 px across the font sizes in Q4.
- [x] **R2** — **Constraint 1: reach the tab through the mux window.**
      `mux_window():active_tab()`, **not** `active_pane():tab()`, because an
      overlay (debug, char-select, launcher) makes the active pane a detached
      one whose `:tab()` is nil — which crashed centering mid-flight and left
      stale padding in place.
- [x] **R3** — **Constraint 2: measure, do not reconstruct.** Do not derive
      the cell size from window-minus-padding: that reads stale padding under
      fractional DPI and during the multi-frame settle after a zoom, and
      produced a wrong cell size.
- [x] **R4** — **Constraint 3: reserve the tab bar, do not measure it.**
      `mux_tab:get_size()` reports the **pty** size, which is exactly
      `rows * cell_h`, so the live chrome derivation
      `win.pixel_height - tab.pixel_height - pad.top - pad.bottom` measures
      the bar *plus* the vertical remainder, `avail_h` reduces to
      `rows * cell_h`, and `gap_y` is zero by construction — the live vertical
      arm is inert at every font size, measured against
      `wezterm 20240203-110809-5046fc22`. What lands instead reserves the bar
      rather than measuring it: `avail_h = win.pixel_height -
      (math.ceil(cell_h) + 1)`. Settled by A4, which retires this
      requirement's earlier claim that "the arithmetic is right; only its
      comment is stale" — that claim was false. The constant is empirical: it
      carries a comment naming the build it was measured against, and needs
      re-measuring if the build moves. It errs in the safe direction.
      Over-reserving by *d* px costs *d* px of top/bottom asymmetry, plus one
      row wherever `(win_h - bar) mod cell_h < d` — the default-sized `f12`
      and `f17` geometries, where 24 rows become 23; stable, one tick, never
      flickering, and it does not occur in the shape `gui-startup` produces.
      Under-reserving over-pads, drops a row and parks a whole extra cell at
      the bottom — R5's flicker in its stable form. The live comment calling
      the bar height "zero whenever the tab bar is hidden (the usual case
      here)" is always false: the nine-tab floor means the bar is always
      shown.
- [x] **R5** — **Constraint 4: floor the total gap before halving.**
      Over-padding by even a sub-pixel shrinks the usable area below
      `cols * cell`, dropping a column that the next tick adds back — a 1 Hz
      flicker. Under-padding by less than a pixel is invisible and stable.
- [x] **R6** — **The idempotency guard.** `set_config_overrides` **re-fires
      the event that called it**, so write only when the computed padding
      actually changed. Without the guard it is a feedback loop; with it,
      idle ticks are nearly free.
- [x] **R7** — **The three triggers, and why the tick is one of them.**
      `window-resized` (including dragging between differently-sized
      monitors), `window-config-reloaded` (config or font-size edits), and
      `update-status` — because **interactive font zoom fires neither of the
      first two**. That is the whole reason the 5 s tick appears in this
      node's requirements as well as in
      [`02-startup-layout`](../02-startup-layout/prd.md)'s.
- [x] **R8** — **The padding is computed absolutely, on both axes.** It is
      derived from the constant window and never folds the current padding
      back in, so a given font always yields the same padding regardless of
      zoom history and the grid cannot ratchet smaller over time. R4's
      reserve is what makes this true vertically: the live `avail_h` fed the
      current padding straight back in, so before A4 this requirement held on
      the horizontal axis only.
- [x] **R9** — **This node owns `window_padding` at runtime.**
      [`01-appearance`](../01-appearance/prd.md) R8 zeroes all four sides and
      names this node as the runtime owner; this node names that as its
      reason for existing. One fact, two links, no duplication.

## Acceptance

The first five boxes need a human at a GUI: `center_grid` only fires on a
live window, and `window:set_config_overrides` on a real session is exactly
the disruption a gate must not cause. Each is written up as a `**T.8**` row
in [`gates/manual/wave3.md`](../../../gates/manual/wave3.md), with its own
PASS and FAIL condition and the requirement a failure would indict. They
stay `[ ]` until that checklist is run.

- [ ] Changing font size with the zoom keys leaves no gap wider than one cell
      on any edge, within one `status_update_interval`.
      (Manual: the "font zoom recentres" T.8 row.)
- [ ] Opening the debug overlay changes no padding and raises no Lua error.
      (Manual: the "an overlay changes nothing" T.8 row.)
- [ ] Padding is unchanged across two consecutive idle ticks — the
      idempotency guard holds and there is no 1 Hz flicker.
      (Manual: the "no flicker at the tick" T.8 row.)
- [ ] Zooming the font up and back down returns the same padding as before
      the round trip, so nothing has ratcheted.
      (Manual: the "no ratchet" T.8 row.)
- [ ] Dragging the window to a monitor with a different pixel density
      recentres it without a restart.
      (Manual: the "a denser monitor recentres" T.8 row.)
- [x] The vertical arm is live, not inert: at a maximized window on font size
      21 the bottom band is split into top and bottom padding rather than
      left whole. Q4 measured 40 px of unsplit band there while acceptance
      box 1 still passed, because the band was one cell minus a pixel — so
      box 1 alone cannot fail for this.
      Checked by running the arithmetic itself, on the geometry Q4 measured:
      `bash tests/wezterm-grid-centering.sh --math` reports
      `PASS math: f21-max: exact padding — got 8/9 x 20/20, expected 8/9 x
      20/20` at 2992x1756 with a 25x49 cell, where the live block computes
      `0 / 0` top and bottom. The same stage carries a named regression
      check, `the vertical arm is ALIVE — top = N > 0`, for all four
      maximized geometries (top = 6, 3, 20, 13), and its FAIL path was
      exercised: reverting the reserve to the live chrome derivation turned
      exactly those four red while the horizontal arm still produced `8/9`
      and `11/11`.

## Out of scope
- The appearance baseline itself, including the zeroed `window_padding`
  declaration, which is [`01-appearance`](../01-appearance/prd.md) R7 and R8.
- Anything this node's Requirements do not name. The epic
  ([`../prd.md`](../prd.md)) owns the shared invariants.

## Questions

Analyst round, 2026-08-22. Numbering continues past the re-spec's Q3,
which the marker note above cites.

Question *Q4*: **The vertical arm of `center_grid` is inert. Fix it, or
ship the horizontal half only?**

R4 says of the chrome subtraction: "The arithmetic is right; only its
comment is stale." Measured on the pinned build, the arithmetic is wrong.
It cannot produce a non-zero `top` or `bottom`. The live feature centres
the grid horizontally and leaves the entire vertical remainder as a band
along the bottom edge.

Why it collapses. `mux_tab:get_size()` reports the **pty** size, which is
exactly `rows * cell_h` — not the pixel region WezTerm allotted the grid.
So `chrome_h = win.pixel_height - tab.pixel_height - pad.top - pad.bottom`
measures the tab bar **plus the vertical remainder**, and
`avail_h = win.pixel_height - chrome_h` reduces to
`tab.pixel_height + pad.top + pad.bottom`. With padding at zero that is
`rows * cell_h`, so `gap_y` is zero by construction, the padding stays
zero, and zero is a fixed point. The horizontal arm has no such defect:
`avail_w` is `win.pixel_width` outright, independent of the padding, so
`gap_x` is the true remainder. This also makes **R8 false on the vertical
axis** — `avail_h` folds the current padding back in, which `avail_w`
never does.

Measured with probe configs against `wezterm 20240203-110809-5046fc22`,
dpi 144, CaskaydiaCove, `line_height = 1.0`, retro tab bar shown. The
80x24 rows are the default-sized window, where WezTerm sizes the frame to
whole cells, so the vertical remainder is zero and `win − tab` reads the
true bar height:

| font | cell (w×h) | window | grid | true bar height |
|---|---|---|---|---|
| 9  | 11×21 | 880×526   | 880×504   | 22 = cell_h + 1 |
| 12 | 14×28 | 1120×700  | 1120×672  | 28 = cell_h |
| 14 | 16×33 | 1280×826  | 1280×792  | 34 = cell_h + 1 |
| 17 | 20×40 | 1600×1000 | 1600×960  | 40 = cell_h |
| 21 | 25×49 | 2000×1226 | 2000×1176 | 50 = cell_h + 1 |

The same probe at a maximized window, where the remainder is non-zero —
`live pad` is what `center_grid` computes there, iterated to its fixed
point:

| font | window | grid | vertical remainder | live pad top/bottom | live pad left/right |
|---|---|---|---|---|---|
| 9  | 2992×1756 | 2992×1722 | 12 | 0 / 0 | 0 / 0 |
| 14 | 2992×1756 | 2992×1716 | 6  | 0 / 0 | 0 / 0 |
| 21 | 2992×1756 | 2975×1666 | 40 | 0 / 0 | 8 / 9 |
| 21 | 2472×1694 | 2450×1617 | 27 | 0 / 0 | 11 / 11 |

Forty pixels of unsplit bottom band at font size 21, against a horizontal
axis that splits its 17 correctly. Acceptance box 1 ("no gap wider than
one cell on any edge") passes only because the gap it leaves is exactly
one cell minus a pixel.

**Option A — reserve one cell for the bar instead of measuring the
chrome.** Replace the `chrome_h` derivation with
`avail_h = win.pixel_height - (math.ceil(cell_h) + 1)`. Nothing else
changes. The bar is one grid row plus at most one pixel of rounding at
every size in the first table, and the reserve becomes independent of the
current padding — which is what R8 already claims and what the horizontal
arm already has.

The direction of the error is what matters, and it is provable. Over-
reserving the bar by *d* pixels leaves the top/bottom split asymmetric by
*d* and costs nothing else, because WezTerm re-fits rows inside the padded
region. Under-reserving by *d* over-pads, drops a row, and puts a whole
extra cell at the bottom — R5's flicker failure, in its stable form.
`cell_h + 1` over-reserves by 0 or 1, so it is exact at font sizes 9, 14
and 21 and 2 px off at 12 and 17; simulated to its fixed point it settles
in one tick and holds, with no row lost at any size measured. `cell_h + 2`
is the more conservative constant if a future build's bar is `cell_h + 2`:
2 px of asymmetry everywhere, never a lost row.

Cost: the node carries an empirical renderer constant that has to be
re-measured if the WezTerm build moves, and R4, R8 and R1's word
"symmetric" get rewritten to describe what lands.

**Option B — port the horizontal arm only.** Delete the chrome
arithmetic and the `top`/`bottom` computation. State in R4's place that
`window_padding` top and bottom stay 0, with the reason: the pty size
carries no information about the vertical remainder on this build. R1
narrows to the horizontal axis. Cheaper, carries no renderer constant,
and the file makes no claim that is false — but the Purpose's "uneven gap
on the right and bottom" is then half addressed, and the bottom band
stays.

Refused without asking: porting the live arithmetic unchanged. It computes
a value that is provably always zero, and shipping it under R4's "the
arithmetic is right" would put a false claim in the file the next reader
trusts.

Recommendation: **A**, with `math.ceil(cell_h) + 1`. The node exists
because a static replacement is wrong at the next font-size change; an
arm that is always zero is a static replacement with extra steps. It is a
three-line change to the block being ported, it makes the vertical axis
obey R8 exactly as the horizontal one does, and the constant it introduces
is bounded in the safe direction by construction.

Neither option changes the spec plan or the estimate: two specs, 2.5 h —
the `wezterm.lua` block (1 h) and `tests/wezterm-grid-centering.sh` with
its wave-3 registration and `gates/manual/wave3.md` rows (1.5 h).

Two findings from the same round that need no decision, and land with
whichever option wins:

- The live block's comments say interactive font zoom is caught "within
  ~1 s" in two places. `status_update_interval` is 5000, so the port says
  5 s — the number this node's own acceptance already uses.
- `tests/wezterm-startup-layout.sh:115` asserts `center_grid` appears
  nowhere in `home/dot_config/wezterm/wezterm.lua`. Whatever lands must
  flip that assertion in the same commit, or T.2's gate goes red the
  moment this node's code arrives.

## Answers

Round of 2026-08-22, answered by the user.

**A4 (to Q4): keep the node, and take Option A** — replace the chrome
derivation with `avail_h = win.pixel_height - (math.ceil(cell_h) + 1)`.

The user reconsidered the node's existence first ("do we need this?"), heard
the measurement that the vertical arm is zero by construction, and kept it
knowingly. Keeping it therefore means keeping the axis that motivates it:
Option B ships an arm that is provably always zero, which is the static
replacement this node exists to avoid, so it was not what "keep it" bought.

Consequences to carry into the specs, all named by the analyst's own round:

- **R4 is rewritten.** Its present claim, "the arithmetic is right; only its
  comment is stale", is false and must not survive into the file. What replaces
  it: the pty size carries no information about the vertical remainder, so the
  bar is *reserved* as one cell plus a pixel rather than *measured*.
- **R8 becomes true on both axes.** The reserve is pad-independent, so neither
  axis folds current padding back in.
- **R1's word "symmetric" is qualified**: the top/bottom split is symmetric to
  within the over-reserve, 0–2 px at the font sizes measured.
- **The constant is empirical and bounded in the safe direction.** Over-
  reserving by *d* costs *d* px of asymmetry; under-reserving over-pads, drops
  a row and parks a whole cell at the bottom — R5's flicker in its stable form.
  It must carry a comment saying it was measured against
  `wezterm 20240203-110809-5046fc22` and needs re-measuring if the build moves.
- **`tests/wezterm-startup-layout.sh:115` asserts `center_grid` appears nowhere
  in `wezterm.lua`.** That assertion must flip in the same commit as the code,
  or T.2's gate goes red the moment this node lands.
