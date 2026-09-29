---
kind: knowledge
description: tmux has no margins, so zen mode fills an empty side with a spacer pane and builds its strip as one JSON `select-layout` — refit from a `window-layout-changed` hook that must be a fixed point, and focus bounced by `after-select-pane`, because `pane-focus-in` cannot move it
read_when: "touching tmux-zen, the cockpit's `w z` row, the process chip, or any hook that resizes panes"
---

# zen-centres-one-column-with-spacer-panes

**tmux has no margins.** The only way to put blank space beside a pane is
another pane, so zen mode (`F5 w z`, `tmux-zen`, one global switch for every window) fills an empty side of the
strip with a full-height spacer pane running `sleep`, marked with the pane
option `@zen_spacer` and an empty `pane-border-format`. Everything that
counts or walks panes has to skip them: the bar's process chip is
`tmux-zen procs` (a format inside that `#()` is expanded twice through
`E:@procs`, and its comma split the `#{?…}` around it), and an
`after-select-pane` hook sends focus back with `select-pane -l`. On the
frames build a popup — F5 itself — is a floating pane in the window
(`pane_floating_flag`) and fires the layout hook, so every listing filters
spacers and floating panes together.

The strip — active pane centred, the panes before it stacked on the left,
those after it on the right — is one `select-layout` of the frames build's
JSON layout (`"V":2`): a leaf's `i` places any pane in any cell, `a` sets
the active pane and `l` keeps the last-pane order in the same call, and
floating panes must be carried over (`z`) or the parser refuses. `tmux-zen
apply` compares leaf geometry first and applies only a change, so it is a
fixed point for the hooks that fire on its own call.

Three things measured on next-3.9 while building it:

- `pane-focus-in` fires on `select-pane` but a `select-pane -l` inside it
  does nothing; the same command in `after-select-pane` moves focus, and the
  hook firing again for its own `-l` lands on a real pane and stops there.
- One `kill-pane` fires `window-layout-changed` several times at
  once, and a check-then-set pid in a window option let four runs build
  spacers side by side (26/18/12/8 columns of them); the lock is an atomic
  `mkdir`, and a run that loses it waits its turn — up to ten seconds, not
  one: at load average 40 a tmux command takes a second, and a run that
  gives up leaves the spacers beside two panes.
- `split-window -f` takes a second spacer's width from the **whole
  window**, so sizing spacers one by one shrank the first (49 became 36);
  the layout string sizes them all at once.

A lone pane's border goes with `pane-active-border-style hidden` on the
pane itself: the seam to a spacer is drawn in the active pane's style, and
`hidden` is the SGR 8 that already blanks inactive seams, so the `nohidden`
header is all that shows.

Known ceiling: tmux-resurrect restores a spacer as a shell; `F5 w z` off and
on rebuilds them. See [[evening-out-panes-is-a-per-level-sweep]] for the
other layout verb and why its sweep is idempotent too.
