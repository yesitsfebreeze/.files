---
state: done
priority: 31
est: 8.2h
task: W0.2
mode: afk
needs:
  - 00-delivery/corrections/w0-1-terminal-inventory
  - 00-delivery/corrections/w0-4-s2-corrections
  - 00-delivery/corrections/w0-6-live-bugs
verify: ""
origin: derived
from: 00-delivery/corrections
---

# Re-spec the terminal epic from the inventory

Purpose: Rewrite every 02-terminal PRD from `capabilities-terminal.md` rather
than adjusting the existing text, which the audit found wrong on font,
palette, keys and model.

## Requirements
- [x] **R1** — Rewrite each terminal PRD from the inventory, not from the
      current file.
- [x] **R2** — The self-healing nine-tab floor is the tab/pane model. burrito
      is deleted, so the two-competing-models problem is gone; remove every
      burrito reference from the epic.
- [x] **R3** — Correct the confirmed errors: font, palette ownership, the
      non-existent `Cmd+N` and `gui-attached` (T-5, T-7), and the F5 letter
      set with its split-creation ordering via `tab:panes()` rather than
      geometry (T-8).
- [x] **R4** — Record that `PaneSelect` must not be used: a Lua modal cannot
      be dismissed across a tab switch. That is a documented failure, and the
      reason is the expensive part.
- [x] **R5** — Give the ~230 uncovered lines a home in some PRD, or record
      them as dropped with a reason. They currently sit in an audit note with
      no requirements.
- [x] **R6** — Update the epic and `README.md` together: children go from five
      to six (tab-content-state and launchd-path).

## Acceptance
- [x] No terminal PRD asserts a capability `capabilities-terminal.md` does not
      show.
- [x] Each of T-1 through T-11 is either fixed or recorded as accepted with a
      reason.
- [x] The README tree, the README build order and this epic agree on the child
      count.

## Out of scope
- Implementing any of it. The T nodes build; this one specifies.

## Inbox

*Filed 2026-08-21 by the orchestrator, from W0.3's implementer.*

`.mi/prds/02-terminal/04-copy-mode/prd.md` carries a stray editor artifact left
by an earlier session — a line reading ``- Added to terminal epic via `:w
.../02-terminal/04-copy-mode.md` ``. It is out of every current ticket's
footprint and this node owns those files, so it is recorded here rather than
fixed in place. Remove it as part of the re-spec.

*Filed 2026-08-21 by the orchestrator, from D.1d's analyst.*

This node's escalation §5 asserts that `decisions/wallpaper-opacity` decides
`window_background_opacity` and the base00 tint. **It does not, and no answer
is owed there** — do not stall waiting for one. Those belong to the
*Appearance baseline* inventory entry (C 2 / U 7, take over as-is), which is a
different capability from both the `Ctrl+Shift+B` wallpaper pipeline
(`DO NOT PORT`, C 8 / U 3) and the OSC-1337 opacity toggle. The wallpaper
decision covers only the latter two. The distinction is recorded as item 5(d)
in [`the corrections backlog`](../prd.md).

Also for this node: T.1's current R1–R4 and acceptance say nothing about
wallpaper or opacity at all, so there is no "drop those requirements" edit to
make — the re-spec writes T.1's real requirements from the inventory.

*Filed 2026-08-21 by the orchestrator, from W0.4a's and H.1's analysts.*

Two defects in `.mi/docs/capabilities-terminal.md` have **no owner**, and this
node rewrites the terminal PRDs from that file, so they land here:

- **`capabilities-terminal.md:208-209`** claims copy mode keeps "searches".
  WezTerm copy mode has **no `/` search key** — verified by `06-help/01`'s
  readers against 55 live key rows, one of which is this config's own `c`.
  Re-speccing from an inventory line that describes a key that does not exist
  reproduces the `02-terminal` failure exactly.
- **W0.4a R7's terminal half is unreachable.** R7's text names
  `capabilities-terminal.md`, but that path is absent from W0.4a's `files` list
  in `.mi/gantt/plan.json`, so that lane cannot touch it either way.

Also relevant to this node's re-spec: `capabilities.md`'s legacy WezTerm block
is only partly marked. The user confirmed `DO NOT PORT` on
`WezTerm terminal configuration`, but `Nine-tab maximized startup windows` and
`F5 one-shot jump mode` stay unmarked, though the audit found them equally
wrong (T-5, T-7, T-8). Whether that block should be marked entry-by-entry is a
**new question** and belongs with this re-spec, not with the inventory sweep.

## Questions

*Raised 2026-08-21 by this node's analyst. Evidence is the deployed
`~/.config/wezterm/wezterm.lua` (1149 lines), `wezterm show-keys --lua` on
build `20240203-110809-5046fc22` (263 effective key rows), and
`wezterm cli list` against the running GUI. `colors.lua` was sha256-checked
before and after — unchanged, nothing was written.*

Four forks gate the rewrite. Three of them are the `SIMPLIFY`/`DEFER`
markers in [`capabilities-terminal.md`(../../../../../docs/capabilities-terminal.md)
that the inventory itself hands to this node or to the human, and they
between them decide three of the four backlog rows routed here **unresolved**
(T-4, T-6, T-9). Everything else in this node's remit is answerable from the
inventory and the live config and is listed under "Not blocked" below, so
these are the whole of what is owed.

### Q1 — The nine-tab floor: full reconciler, or a cheaper shape?

`Self-healing nine-tab floor` is C 10 / U 7 `SIMPLIFY`, and the inventory
says "the re-spec must choose knowingly". Three shapes:

- **(a) as live** — per-window slot maps in `wezterm.GLOBAL`, `MoveTab`
  repositioning into the dead slot's index, a re-entrancy guard, `pcall`
  around the repair, focus re-asserted by tab id, healing on the 5 s tick.
  ~150 lines, the most intricate block in the config.
- **(b) spawn nine once** at `gui-startup`, no reconciler. ~10 lines. A
  closed tab stays closed and every digit past the hole shifts.
- **(c) reconcile count only**, no `MoveTab`. Nine tabs always exist, but a
  replacement appends, so digits past the hole shift until the next close.

**What it decides beyond itself.** `Ctrl+Shift+Q` exists *only* to serve the
floor — closing tabs one at a time can never empty a window whose slots
refill, and `window_decorations = "RESIZE"` leaves no titlebar close button.
Pick (b) or (c) and the escape hatch is dead weight, which is how **T-6**
(`mark_closing()` before `confirm = false`) gets disposed either way.

**Recommendation: (a).** The capability being ported is not "nine tabs", it
is "a digit is a stable address" — and both cheaper shapes keep the tabs
while deleting the address, so they buy complexity back by removing the
thing the complexity was for. F5's digit half is the highest-value binding in
the epic (`F5 jump-select`, U 8) and it is worth exactly as much as that
guarantee. The live evidence is that the floor is doing real work rather than
theoretical work: `wezterm cli list` today shows one window with exactly nine
tabs whose ids are `22, 24, 26, 28, 29, 30, 34, 36, 37` — nine live tabs
scattered across a 16-wide id range, i.e. tabs have died and been refilled
*and repositioned* repeatedly in this session alone. Finally, the C 10 rates
code that is already written and already debugged upstream: the five failure
modes the inventory names (16 tabs at startup, the `1,0,2,3` ordering bug,
two windows refilling each other, the latched guard, snap-to-blank focus) are
paid for, and re-deriving them later costs more than porting them now.

### Q2 — F5: keep the self-painted pane-letter overlay, or digits only?

`F5 jump-select` is C 9 / U 8 `SIMPLIFY`, and the inventory says the overlay
"is the bulk of the complexity and is worth its own decision in the
re-spec". The two halves are cleanly severable:

- **(a) as live** — digits `1`–`9` to tabs *plus* `asdfghjkl` indexed against
  `tab:panes()` in split-creation order, with reverse-video labels
  `inject_output`-ed into each pane, the covered cells saved to and restored
  from `GLOBAL`, and an `update-right-status` janitor for the two exits that
  run no callback (timeout, `until_unknown`).
- **(b) digits only** — a handful of lines. The tab bar already prints each
  tab's digit (`format-tab-title` returns nothing else), so the digit half
  needs no overlay at all. Pane switching falls back to WezTerm's own
  defaults, which are present and unshadowed: `Ctrl+Shift+`arrow →
  `ActivatePaneDirection` (rows 137–143 of `show-keys`).

**What it decides beyond itself.** **T-9** ("the JUMP status hint was
deliberately removed; discoverability is a reverse-video letter painted into
each pane") is disposed differently by each: under (a) the pane label is the
discoverability channel and the removal is recorded as intended; under (b)
there is no letter to discover and T-9 becomes moot. Live bug **L-11** (a
mistyped jump letter rings BEL into a config with `audible_bell = "Disabled"`
and no `visual_bell`, so a miss is silent and indistinguishable from the key
table having failed to open) is likewise only reachable through the letter
half.

**Recommendation: (b), digits only** — with the caveat that this is the one
question here where I am reading usage rather than code. On this machine the
letter half is currently inert: `paint_labels` returns early on `#panes < 2`,
and both live samples show one pane per tab — nine tabs / nine panes today,
and the same shape when W0.1 measured on 2026-08-20. Two samples a day apart
with zero splits is evidence, not proof; if you split panes regularly, answer
(a) and I will spec the overlay with its constraints intact. If (a) is
chosen, L-11 is mine to close and I will spec a `visual_bell` fade for the
miss path, since `audible_bell = "Disabled"` is deliberate and silence is not
an acceptable failure signal.

### Q3 — Dynamic grid centering: keep it, or defer it?

`Dynamic grid centering` is C 8 / U 6 `DEFER`, and the inventory is explicit
that this is "a recommendation, not a settled call… Flag it with D.1 for the
human". It is also the whole of **T-4** ("padding is zeroed and recomputed
every tick by `center_grid`; there is no platform-aware padding"), which
cannot be disposed without an answer.

**Deferring is not free.** `config.window_padding` is zeroed in the base
config *because* `center_grid` owns padding at runtime. Drop the centering
and the re-spec must name a static padding instead — and any static number is
wrong again at the next font-size change, which is the exact problem the
feature exists to solve.

**Recommendation: keep it, as its own child node** so it can still be cut
late without unpicking anything else. Two reasons. The value is demonstrated
rather than assumed: the live config's own comment tells the reader to
hand-tune font size "until the bottom/right edge sits flush" — that is the
manual version of precisely this feature. And each of its four non-obvious
pieces is a bug already paid for (reaching the tab through
`mux_window():active_tab()` because an overlay makes the active pane's
`:tab()` nil; measuring the cell from `tab:get_size()` rather than
reconstructing it from window-minus-padding, which read stale padding under
fractional DPI; subtracting tab-bar chrome so the grid centres *below* the
bar; flooring the total gap before halving, because over-padding by a
sub-pixel drops a column the next tick adds back — a 1 Hz flicker).

### Q4 — Mark `capabilities.md`'s two remaining legacy WezTerm entries?

You confirmed `DO NOT PORT` on `WezTerm terminal configuration`
(`capabilities.md:28`). Two entries beside it are still unmarked, and
unmarked means "take over as-is":

- `Nine-tab maximized startup windows` (C 3 / U 7, `capabilities.md:58`) —
  describes `gui-attached` hooks, `maximize()`, and `Cmd+N` / `Ctrl+Shift+N`
  as bindings that "spawn more of the same". None of that is the live
  mechanism (findings T-5 and T-7).
- `F5 one-shot jump mode` (C 6 / U 8, `capabilities.md:83`) — describes
  letters activating panes "left-to-right", which is geometry ordering; live
  is `asdfghjkl` against `tab:panes()` in split-creation order (T-8).

These two entries are the sources the invalid PRDs were written from, and
they are superseded entry-for-entry by `capabilities-terminal.md`.

**Recommendation: mark both `DO NOT PORT`**, with the reason recorded as
"superseded by `capabilities-terminal.md`", on the same footing as the
third. **Mechanics you should know before answering:** even a "yes"
is not this node's edit to make — `.mi/docs/capabilities.md` is not in W0.2's
`files` in `plan.json` (which lists only the six terminal PRDs, the epic and
`.mi/prds/README.md`), so landing it needs either a footprint amendment here
or a row on the inventory-sweep lane.

## Verified while raising these

Recorded so the spec pass does not re-derive them, and because two correct
existing findings and one inventory line are wrong in detail.

- **The Inbox's copy-mode defect is confirmed, and is worse than filed.**
  `capabilities-terminal.md:208-209` says the default `copy_mode` table's
  "55 builtin motions and searches survive". Measured: the effective
  `copy_mode` table has **55 rows in total, one of which is this config's own
  `c`** — so 54 are builtin, not 55. And it contains **no search facility at
  all**: not `/`, and not `NextMatch`/`PriorMatch`/`ClearPattern`/
  `CycleMatchType` either. Every one of those lives in a *separate*
  `search_mode` table (10 rows), reachable only from normal mode via
  WezTerm's default `Ctrl+Shift+F` / `Cmd+F`. The re-spec must say "all 54
  builtin **motions**", and must not promise search from inside copy mode.
- **T-7 is right in conclusion, wrong in mechanism, and the difference
  matters.** `config.keys` binds no new-window key — but the *effective* key
  set does contain `Cmd+N` and `Ctrl+Shift+N` → `SpawnWindow`, as WezTerm
  **defaults** (`show-keys` rows 111–112). So T.2's R2 ("`Cmd+N` spawns
  another identically shaped window") is accidentally true in behaviour and
  false in cause: the nine-tab shape comes from `reconcile_tabs` firing on
  `window-config-reloaded`, which is emitted once per newly created window.
  Re-specced as "any new window, however opened, comes up at the floor",
  which also covers `wezterm cli spawn --new-window`.
- **Do not carry a scheme name into any PRD.** The inventory names
  `base16-everforest-dark-hard` as live; `colors.lua` today is
  `base16-caroline`. Both are correct — the scheme is user state that tinty
  rewrites, so the requirement is the *mechanism* (`dofile` under `pcall`
  with an essential-key check plus `add_to_config_reload_watch_list`), never
  a scheme or a hex.
- **`jump_mode` and the alphabet check out exactly as filed** — 36 rows
  (`Escape`, `1`–`9`, all 26 letters), `PANE_ALPHABET = "asdfghjkl"`, indexed
  against `tab:panes()`.
- **T.6's R4 is unbuildable as written, and this node fixes it without
  asking.** It requires detecting prompt emission "via the terminal stream,
  not via a shell hook", while
  [`04-shell/01-core-config`](../../../04-shell/01-core-config/prd.md) R5
  turns OSC 133/633 **off** on purpose (the phantom-blank-line fix for the
  starship two-line prompt under WezTerm). OSC 133 *is* the terminal-stream
  prompt marker, so R4 asks for a signal the shell is deliberately not
  emitting. The re-spec rewrites it against the foreground process instead of
  prompt markers, and owes a live check that the accessor exists on
  `20240203` before it becomes a requirement — the same build where
  `pane:get_current_working_directory()` is nil.
- **Footprint gap for the conductor.** W0.2's `files` in `plan.json` omits
  `.mi/prds/02-terminal/06-launchd-path/prd.md`, yet R6 names launchd-path as
  one of the two children the count moves to six and the node already exists.
  Separately, `plan.json`'s T.7 row points `spec` at
  `.mi/prds/02-terminal/prd.md` rather than at that node's own `prd.md`.
- **Already-known, still true:** the stray editor artifact at the foot of
  `04-copy-mode/prd.md`, and T.1's textual damage (a stray `]` closing
  nothing, `capabilities-terminal.md\"appearance"’dictated`). Both are
  rewrite fodder, not edits.

## Not blocked by the above

Listed so the cost of waiting is visible. Answerable today from the inventory
and the live config, needing no decision: the epic rewrite and every burrito
removal (R2); T-1 font and T-2's font/palette requirements; T-5
(`toggle_fullscreen()`, no `gui-attached`); T-7 as corrected above; the
appearance baseline including the static `window_background_opacity`, its
base00 tint and `macos_window_background_blur` (per the Inbox — no answer is
owed there); copy mode as corrected; `Ctrl+V` / `Ctrl+C` / the two mouse
bindings; the launchd PATH seeding; placing the F6 theme toggle (R5); the
`PaneSelect`-is-impossible constraint (R4); and the README tree, build order
and child-count reconciliation (R6). That is roughly two thirds of the
rewrite. The third that is blocked — T.2, the letter half of T.3, and the
centering half of T.4 — is the third that carries the code.

## Answers

*Answered 2026-08-21 by the user. All four of the analyst's recommendations
were taken.*

1. **Nine-tab floor: the full reconciler.** Keep the self-healing behaviour —
   nine tabs always exist **and** each digit maps to a stable position. The two
   cheaper shapes keep the tabs while deleting the "digit is a stable address"
   guarantee, which is precisely what F5's U 8 digit half is worth. This
   disposes **T-6**, and settles that `Ctrl+Shift+Q` exists.
2. **F5: digits only — the pane-letter overlay is dropped.** The analyst was
   right to flag this as the one usage-based call it could not make: `paint_labels`
   returns early below two panes, and both live samples show one pane per tab,
   so the letter half is inert on this machine. WezTerm's default
   `Ctrl+Shift+`arrow already covers pane movement unshadowed. This disposes
   **T-9**, and makes **L-11** (the silent miss) unreachable rather than a bug
   needing a fix — record it that way, not as "fixed".
3. **Dynamic grid centering: kept, as its own child node.** Deferring is not
   free — `window_padding` is zeroed in the live config *precisely because*
   `center_grid` owns padding at runtime, so dropping one without the other
   leaves the terminal visually wrong. A child node keeps the appearance
   baseline shippable while centering is built. This disposes **T-4**.
4. **`capabilities.md`'s two remaining legacy WezTerm entries** —
   `Nine-tab maximized startup windows` and `F5 one-shot jump mode` — are marked
   **`DO NOT PORT`, superseded by `capabilities-terminal.md`**. That inventory
   was built by W0.1 from the live config for exactly this purpose. Leaving them
   unmarked is how this epic went wrong the first time: an agent re-specced from
   a legacy entry nobody had ruled on. **W0.2's footprint is widened to include
   `.mi/docs/capabilities.md` for these two markers only** — the file is
   user-authored and the author has now confirmed this specific edit, as R1 of
   `docs-inventories` requires.

*Orchestrator note on Q4's blast radius:* `docs-inventories`' landed
`specs/spec04.md` pins `capabilities.md` at **30 entries** with an exact ratio
sequence and asserts the take-over-as-is set is exactly six named entries.
Markers are not a sort key and adding two changes no rating, so the ratio guard
should stay green — **verify that rather than assuming it**, and if the
six-entry assertion is affected, report it rather than editing another ticket's
spec.

## Closing note

*Closed 2026-08-21 by the orchestrator.* **The largest ticket of the session.**
All 82 spec boxes ticked, nine verifies `OK` exit 0, R1–R6 and all three
acceptance boxes closed. Re-verified independently: `tests/live-bugs.sh` 159
PASS / 0 FAIL, `gates/audit-findings.sh` 101 PASS / 0 FAIL and 49 findings 0
undisposed, `capabilities-terminal.md` still **550 lines** with line **220**
`## Appearance baseline` and `Live bug L-11` untouched at 406,
`capabilities.md` still 30 entries / 172 lines, and `02-terminal` now has seven
children. `colors.lua` sha256 identical before and after — the live config was
never written.

`02-terminal` was invalid in almost every requirement, specced entirely from
the legacy inventory. It has been rewritten from `capabilities-terminal.md` and
the live config, and nine `T-` backlog rows can now be disposed.

**The save.** spec04 B3 became R2: all 26 letters stay bound in jump mode as a
bare cancel, because `until_unknown` pops the key table **without eating the
keystroke** — an unbound letter falls through and types itself into whatever is
running. The user's "digits only" answer removes the *action* behind each
letter, not the *need to bind* it. Implemented literally it would have leaked a
character on every mistyped jump, traceable straight back to a decision made on
the orchestrator's framing. `L-11` is recorded **unreachable, not fixed**.

**Three landed guards went red, all reported rather than edited, and all
repointed by the orchestrator:**
1. `docs-inventories` spec04 — **exactly the two assertions predicted** (marker
   count 24 → 26, and the six-entry take-over-as-is set), entry count and ratio
   sequence untouched. Repointed.
2. `decisions/tinty` spec01 — `T.1 lost its escalation section`. **Not flagged
   in any spec beforehand**: the escalation's removal *is* spec02 B12, and
   spec02's own verify forbids `## Escalation`, so the two requirements were in
   direct contradiction. Repointed at what that lane actually cares about — T.1
   still naming tinty as palette owner. Verified: zero occurrences of "terminal
   owns the palette" survive.
3. `decisions/wallpaper-opacity` spec02 — the inventory guard and the T.1 sha
   pin, both broken by work Q4 explicitly authorised. Narrowed and repinned.

All three green again, each recorded in the ticket that owned it.

**Guard over-broadness worth keeping in mind.** spec04's "no JUMP" check uses
`grep -qiF`, forbidding the substring `jump` in any case — so the node could not
keep the word at all. Its title is now "F5 one-shot tab select" and it cites its
inventory entry **by description** rather than by name, because the entry's own
name contains the forbidden token. The spec's intent (no status legend) is fully
met; the naming is the guard's doing, and the implementer said so rather than
quietly renaming things.

R6's text says the epic's children "go from five to six"; Q3 took it to seven.
The box is met and exceeded, and the epic, README tree and README build order
all agree on seven — the wording predates the answer and was correctly not
edited. `.mi/SYSTEM.md`'s epic table (6 → 7) and node total (80 → 84) were the
orchestrator's to fix and are done.

`gates/tree-links.sh` reports 104 broken links repo-wide, **none in any file
this ticket touched** — all pre-existing inside other tickets' `specs/`,
quoting relative paths from the wrong base. That is a convention problem, not a
link problem, and it is growing as each new analyst repeats it.
