verify: `bash -c 'cd "$(git rev-parse --show-toplevel)"; f=prds/02-terminal/07-grid-centering/prd.md; rc=0; [ -f "$f" ] || { echo "FAIL: the node does not exist: $f"; exit 1; }; T="$(tr "\n" " " < "$f" | tr -s " ")"; has() { echo "$T" | grep -qF "$1" || { echo "FAIL: missing: $1"; rc=1; }; }; has "C 8"; has "U 6"; has "Dynamic grid centering"; has "get_size"; has "active_tab"; has "chrome"; has "floor"; has "set_config_overrides"; has "window-resized"; has "update-status"; has "T-4"; has "01-appearance"; head -12 "$f" | grep -q "^state:" || { echo "FAIL: no frontmatter state"; rc=1; }; head -12 "$f" | grep -q "^verify:" || { echo "FAIL: no frontmatter verify field"; rc=1; }; head -12 "$f" | grep -q "^deps:" || { echo "FAIL: no frontmatter deps"; rc=1; }; A=$(awk "/^## Acceptance/{f=1;next} /^## /{f=0} f" "$f" | grep -c "^- \["); [ "$A" -ge 3 ] || { echo "FAIL: Acceptance has $A boxes, want >=3"; rc=1; }; echo "$T" | grep -qiF "DEFER" && { echo "FAIL: the node still carries the DEFER marker Q3 withdrew"; rc=1; }; [ $rc -eq 0 ] && echo OK; exit $rc'`

est: 45m

# spec07 — `07-grid-centering`: the seventh child, created by Q3

Goal: create the node Q3's answer requires. Grid centering is **kept**, and
kept as its own child so it can still be cut late without unpicking
`01-appearance`. This is a **new file**, and the only new file in the task.

Files: `.mi/prds/02-terminal/07-grid-centering/prd.md` — created.

**Proved RED 2026-08-21 — 1 failure**, and it is the only one the verify can
reach: the path does not exist, so it exits before every other assertion. All
eleven boxes below are unreachable until the file is created, which is the
correct shape for a create-a-node spec.

**Numbering.** `07-` appends rather than re-sorting. The convention orders
prefixes by value ratio, but `02-terminal` already does not (`06-launchd-path`
is the best ratio in the epic at V 8 and sits last), and renumbering would
churn every dep string in `plan.json` and both README lists for no gain.

**Rating: C 8 / U 6**, source `Dynamic grid centering`. The inventory's
`DEFER` is **withdrawn by Q3** — it was explicitly "a recommendation, not a
settled call… Flag it with D.1 for the human", and the human kept it. Same
handling as spec03: the marker moves, the numbers do not.

**Why it was kept, recorded so the `DEFER` is not restored.** Deferring is
not free. `window_padding` is zeroed in the base config *because*
`center_grid` owns padding at runtime, so dropping the centering without
replacing it leaves the sub-cell remainder as an uneven gap on the right and
bottom — and any static replacement is wrong again at the next font-size
change, which is the problem the feature exists to solve. The value is also
demonstrated rather than assumed: the live config's own comment tells the
reader to hand-tune font size "until the bottom/right edge sits flush", which
is the manual version of exactly this. This node **is** finding **T-4**.

## Boxes

- [x] **B1 — frontmatter.** `state: open`, `mode: afk`, `verify: ""`,
      `deps: [02-terminal/01-appearance]` — it overrides the padding that
      node zeroes — and `task: T.8`, which the conductor created on
      2026-08-21 with deps `W0.2, T.1` and Q3's reasoning recorded. Match the
      plan row exactly; do not invent an id.
- [x] **B2 — the measurement.** Measure the true cell size from the grid's
      own rendered area — `mux_tab:get_size()` gives `{cols, rows,
      pixel_width, pixel_height}`, so `cell = pixels / count` is exact.
      Recompute how many whole cells fit the window and push the sub-cell
      remainder into symmetric `window_padding` overrides. Adapts to any font
      size, DPI or resolution.
- [x] **B3 — constraint 1: reach the tab through the mux window.**
      `mux_window():active_tab()`, **not** `active_pane():tab()`, because an
      overlay (debug, char-select, launcher) makes the active pane a detached
      one whose `:tab()` is nil — which crashed centering mid-flight and left
      stale padding in place.
- [x] **B4 — constraint 2: measure, do not reconstruct.** Do not derive the
      cell size from window-minus-padding: that reads stale padding under
      fractional DPI and during the multi-frame settle after a zoom, and
      produced a wrong cell size.
- [x] **B5 — constraint 3: subtract the tab-bar chrome**, so the grid centres
      *below* the bar rather than drifting down by its height. Note that the
      live comment calling this "zero whenever the tab bar is hidden (the
      usual case here — burrito owns multiplexing, so there's a single tab)"
      is **now always false**: nine tabs means the bar is always shown. The
      arithmetic is right; only its comment is stale.
- [x] **B6 — constraint 4: floor the total gap before halving.**
      Over-padding by even a sub-pixel shrinks the usable area below
      `cols*cell`, dropping a column that the next tick adds back — a 1 Hz
      flicker. Under-padding by <1px is invisible and stable.
- [x] **B7 — the idempotency guard.** `set_config_overrides` **re-fires the
      event that called it**, so write only when the computed padding
      actually changed. Without the guard it is a feedback loop; with it,
      idle ticks are nearly free.
- [x] **B8 — the three triggers, and why the tick is one of them.**
      `window-resized` (including dragging between differently-sized
      monitors), `window-config-reloaded` (config or font-size edits), and
      `update-status` — because **interactive font zoom fires neither of the
      first two**. That is the whole reason the 5 s tick is in this node's
      requirements as well as spec03's.
- [x] **B9 — the absolute-computation requirement.** The padding is computed
      from the constant window and never folds the current padding back in,
      so a given font always yields the same padding regardless of zoom
      history and the grid cannot ratchet smaller over time.
- [x] **B10 — Acceptance, at least three boxes, observable.** For example:
      changing font size with the zoom keys leaves no gap wider than one cell
      on any edge within one `status_update_interval`; opening the debug
      overlay does not change the padding or raise; and padding is unchanged
      across two consecutive idle ticks (the guard holds).
- [x] **B11 — cross-link `01-appearance`.** Its B8 zeroes `window_padding`
      and names this node as the runtime owner; this node names that as its
      reason for existing. One fact, two links, no duplication.
