# Feature: Tab content-state coloring

Parent: [Terminal epic](00-epic.md) · C 4 · U 7 · source: net-new

## Summary

Tabs whose panes are all freshly initialized (nothing running yet) render in a
dim "empty" color; any tab with at least one pane running a command renders in
a lit "occupied" color. The distinction is computed at spawn time and rechecked
on every pane state change, so a tab that was empty and then ran `htop`
flips to occupied without a keystroke.

## Requirements

1. **Spawn-time classification.** When a tab or pane is created, classify it
   immediately: a pane whose shell has not yet emitted a prompt (no command
   has run) is `empty`; a pane that has emitted a first prompt or received
   input is `occupied`. The tab's color is the OR of its panes — occupied if
   any pane is occupied, empty only when every pane is empty.
2. **Recheck triggers.** Reclassify on: pane creation, pane exit, the first
   prompt emission from a shell, and any keystroke sent into a pane. A tab
   whose last empty pane runs a command must flip to occupied before the
   command finishes.
3. **Color mapping.** Two tab-bar colors, derived from the active scheme
   (never hardcoded hex):
   - `empty`   — the inactive-tab color already used for background tabs.
   - `occupied` — a distinct tint (e.g. the scheme's selection/active color at
     reduced alpha) so an occupied tab is legible against the bar but does
     not outshine the focused tab.
   The focused tab keeps its own color; occupied/inactive is a separate
   signal from focused/inactive.
4. **No shell-side dependency.** The classification must not require the shell
   to cooperate — WezTerm cannot rely on nushell emitting a marker, because
   the same config runs with any `$SHELL`. Detect prompt emission via the
   terminal stream, not via a shell hook.
5. **Stale-state safety.** A pane that dies without WezTerm learning about it
   (crash, `kill -9`) must not keep its tab lit forever. The periodic
   `update-status` tick reclassifies every tab against the live pane set, so
   a dead pane's occupancy decays within one tick interval.

## Acceptance criteria

- Launching WezTerm: all nine tabs render in the `empty` color (no command
  has run in any of them yet).
- Pressing Enter in tab 3 (which types into its shell) flips tab 3 to
  `occupied` before the prompt redraw completes.
- Splitting a tab and running a command in the new pane flips the *tab* to
  occupied even though the sibling pane is still empty.
- Killing a pane's process from outside WezTerm (`kill -9` on the shell
  PID) flips the tab back to `empty` within one `status_update_interval`.
- Switching the active theme (`tinty apply`) recolors both states with no
  edit to this feature's code.