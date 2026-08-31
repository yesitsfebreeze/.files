# spec02 — Withdraw the `DEFER` verdict in the two inventories

est: 0.75h

## Goal

Three inventory entries carry a `DEFER` marker that this decision withdraws,
and two of them say so in their own text: `capabilities-terminal.md`'s F6
entry reads "Deferred with tinty itself, pending decision D.1", and its
per-pane OSC retint entry reads "if D.1 drops tinty, this has no cause". D.1b
has now answered. Left as they are, the inventories say the palette owner is
out of the minimal base while the backlog says it is in — and
`capabilities-terminal.md` is the **input** `w0-2-terminal-respec` rewrites
`02-terminal/*` from, so a stale deferral there propagates straight into the
re-specced terminal PRDs. This is where T.1's reconciliation actually lands
(see spec01, "Why T.1 is not edited in place").

**No `C`/`U` number changes anywhere in this spec.** The ratings measure how
intricate a thing is and how much daily value it delivers; the marker records
whether it is in the minimal base. The human overrode the *marker*, not the
measurements. Keeping the numbers also keeps every value ratio identical,
which means **the sorted order of both files is untouched** — important,
because `w0-4-s2-corrections/docs-inventories` (W0.4a) R3 is separately fixing
sort-order violations in `capabilities-nushell.md`, and a re-sort here would
collide with it head-on.

## Files touched

- `.mi/docs/capabilities-nushell.md` — one entry (`## Theme switcher (tinty +
  television)`).
- `.mi/docs/capabilities-terminal.md` — two entries (`## F6 theme toggle`,
  `## Per-pane OSC retint`).

### Ownership hazards, read before writing

- **W0.4a owns `capabilities-nushell.md`** (it is in that task's `files`
  list) and is `state: open`. Its R3 touches the theme entry's *position*
  (the "opacity below theme" sort violation) and its R7 sweeps for
  source-vs-deployed errors. Nothing here moves the entry or changes a number,
  so the two edits commute — but if W0.4a has already landed, re-read the
  entry and edit whatever text it left, do not restore this spec's assumed
  wording.
- **`capabilities-terminal.md` is W0.1's file**, and W0.1 is `state: done`, so
  it is free. Note for the conductor: W0.4a's **R7 names
  `capabilities-terminal.md` in its text but that path is absent from W0.4a's
  `files` list in `.mi/gantt/plan.json`** — an ownership gap that predates
  this ticket and should be closed one way or the other.
- **Flagged, not fixed — a rating mismatch this spec makes visible.**
  `04-shell/09-theme-switcher` (created 2026-08-21) carries `C 5 · U 7` in its
  header and names this inventory entry as its source, while the entry reads
  `C 8` / `U 5`. The contract requires a PRD header's C/U to match its
  inventory entry, single numbers. This spec deliberately does **not** move
  the inventory numbers (see the Goal), and it does not touch another
  ticket's PRD, so the two sides still disagree after it runs. Reported to the
  conductor: one side has to move, and the decision was explicitly about the
  marker rather than the measurements.
- Do **not** touch `.mi/docs/capabilities.md`. It is user-authored and W0.4a's
  R1 blocks edits until the author confirms.
- Do **not** touch `.mi/docs/capabilities-provisioning.md`, whose tinty
  mention ("tinty state + artifacts") is about the managed-config surface and
  is W0.4a's R6/R7 business.

## What to write

### 1. `capabilities-nushell.md` — the theme switcher entry

Change the marker on the heading from `DEFER` to `SIMPLIFY`, and replace the
verdict sentence "Works, but is a large surface for a cosmetic concern — not
part of the minimal base." with a record of the decision and of the reduced
version. `SIMPLIFY` rather than an unmarked take-over because the entry
bundles the palette-owning core with a background-override surface that the
decision does not rescue; the contract says a `SIMPLIFY` entry's PRD states
what gets dropped, and this text states it until that PRD exists.

Keep the description of what it does, keep `- 8` / `- 5`, keep the entry where
it is, and write:

> **Decided 2026-08-21 (user): tinty stays as palette owner and the `DEFER`
> "cosmetic" verdict is withdrawn** — see open decision 2 in
> [the corrections backlog](../../../corrections/prd.md). It is
> infrastructure: `tinty apply` is what writes both the WezTerm palette
> (`~/.config/wezterm/colors.lua`) and the tinted-shell artifact a new shell
> re-asserts, so dropping it would leave WezTerm, Neovim, tv and the shell
> with no palette source. Minimal base is the palette-owning core: `tinty
> apply`, its `current_scheme`, the tinted-shell re-assert at shell start
> (`04-shell/01-core-config` R10), the A/B slots with `_theme_toggle` behind
> F6, and the tv scheme picker — the node that builds it is
> `04-shell/09-theme-switcher` (S.9). **Dropped by the `SIMPLIFY`:** the background
> override ladder and its R/G/B tuner, and the liked/recency sets — those are
> the cosmetic part, and the background override overlaps the still-open
> `wallpaper-opacity` decision (D.1d). The ratio stays −3 and the entry stays
> where it is: the numbers were never wrong, the membership was.

The value ratio is deliberately left contradicting the verdict, and that is
worth understanding rather than fixing: a low ratio is an argument, not a
rule, and here it lost to the fact that four scheduled nodes inherit from
this one capability.

### 2. `capabilities-terminal.md` — `## F6 theme toggle`

Remove the ` DEFER` marker from the heading (no marker = take over as-is).
Replace the closing sentence "Deferred with tinty itself, pending decision
D.1 — the *reader* above is minimal base, this *switcher* is not." with:

> **D.1b answered 2026-08-21 (user): tinty stays as palette owner, so the
> switcher is minimal base alongside the reader.** The binding has no node
> yet — `w0-2-terminal-respec` R5 ("give the ~230 uncovered lines a home")
> owns placing it, and the `theme.nu` half it calls needs a new `04-shell`
> child. Keep the two constraints above with it: bound in WezTerm rather than
> the shell because a full-screen TUI swallows a shell-level binding, and
> `background_child_process` rather than `run_child_process` because
> `tinty apply` runs the whole hook chain and blocking the GUI thread freezes
> every window for its duration.

Keep `- 3` / `- 6`.

### 3. `capabilities-terminal.md` — `## Per-pane OSC retint`

Remove the ` DEFER` marker. Replace the closing sentence "**Contingent on
tinted-shell writing per-pane escapes at all** — if D.1 drops tinty, this has
no cause." with:

> **The contingency resolved in favour of keeping it (D.1b, 2026-08-21):**
> `config.nu` sources tinty's cached tinted-shell artifact at every
> interactive start, and that artifact writes the per-pane OSC escapes — so
> the override this broadcast exists to overrule is live, and without the
> broadcast a theme switch leaves already-open panes on the old scheme.

Keep `- 6` / `- 7`.

## Acceptance

- [ ] `capabilities-nushell.md`'s theme-switcher heading carries `SIMPLIFY`
      and no longer carries `DEFER`.
- [ ] Its entry records `Decided 2026-08-21 (user)`, names what the
      `SIMPLIFY` drops, and no longer contains the phrase
      `not part of the minimal base`.
- [ ] Its rating lines are still `- 8` then `- 5`, unchanged.
- [ ] The entry has not moved: `## Opacity picker` still follows it, and the
      entry order in the file is otherwise unchanged.
- [ ] `capabilities-terminal.md`'s `## F6 theme toggle` heading carries no
      verdict marker, and its text records the 2026-08-21 answer and names
      `w0-2-terminal-respec` as the node that must find the binding a home.
- [ ] `## Per-pane OSC retint` carries no verdict marker and no longer says
      `if D.1 drops tinty`.
- [ ] Neither terminal entry's `- <n>` rating lines changed (`3`/`6` and
      `6`/`7`).
- [ ] No occurrence of `pending decision D.1` remains in `.mi/docs/`.
- [ ] `.mi/docs/capabilities.md` still names tinty nowhere, and
      `.mi/docs/capabilities-provisioning.md` still names it exactly once (its
      managed-config line). Neither is touched. These are content guards, not
      `git diff` guards: `capabilities-provisioning.md` already carries
      uncommitted changes from another lane in this working tree.
- [ ] The two "hard-won why" constraints on the F6 entry
      (`background_child_process`, TUI-swallows-a-shell-binding) survive.

verify: ""

Proven RED against the current tree before being written here: it reports
`theme switcher not marked SIMPLIFY`, `theme switcher still DEFER`, the three
missing strings in the theme entry, `theme entry still argues the deferral`,
`F6 entry still carries a verdict marker`, the two missing strings in the F6
entry, `per-pane OSC entry still carries a verdict marker`, `per-pane OSC
entry still conditional on D.1`, `per-pane OSC entry records no dated answer`
and `a docs entry still waits on D.1`, exiting 1. The rating, sort-position
and untouched-file guards pass today and exist to catch overreach.

## Spent proof

Both assertions pin inventory text that later nodes rewrote: the entry after
`## Theme switcher` in `docs/capabilities-nushell.md` is `## Leader mode  DO
NOT PORT` rather than the `## Opacity picker` this expects, and
`docs/capabilities-provisioning.md` mentions `tinty` six times rather than
the one it pinned, the extra five being the chezmoi-management lapse and the
palette-ownership record added since.

Retired from `verify:` by
[`mi-rooted-verify-commands`](../../../corrections/mi-rooted-verify-commands/prd.md)
spec02. The command below is byte-identical to what spec01 left in this
file's `verify:`; it is kept because it is the execution record of a check
that once ran green.

```text
verify: `bash -c 'cd "$(git rev-parse --show-toplevel)"; rc=0; n=docs/capabilities-nushell.md; t=docs/capabilities-terminal.md; E() { awk -v h="$2" "index(\$0,h)==1{e=1;print;next} /^## /{e=0} e" "$1"; }; grep -q "^## Theme switcher (tinty + television)  SIMPLIFY$" "$n" || { echo "FAIL: theme switcher not marked SIMPLIFY"; rc=1; }; grep -q "^## Theme switcher.*DEFER" "$n" && { echo "FAIL: theme switcher still DEFER"; rc=1; }; TS() { E "$n" "## Theme switcher"; }; for s in "Decided 2026-08-21 (user)" "Dropped by the" "R10"; do TS | grep -qF "$s" || { echo "FAIL: theme entry lacks: $s"; rc=1; }; done; TS | grep -qF "not part of the minimal base" && { echo "FAIL: theme entry still argues the deferral"; rc=1; }; [ "$(TS | grep -c "^- 8$")" -eq 1 ] && [ "$(TS | grep -c "^- 5$")" -eq 1 ] || { echo "FAIL: theme entry C/U changed"; rc=1; }; grep -A2 "^## Theme switcher" "$n" >/dev/null; awk "/^## Theme switcher/{f=1} f&&/^## /&&!/^## Theme switcher/{print;exit}" "$n" | grep -q "^## Opacity picker" || { echo "FAIL: the theme entry moved in the sort order"; rc=1; }; grep -q "^## F6 theme toggle$" "$t" || { echo "FAIL: F6 entry still carries a verdict marker"; rc=1; }; F6() { E "$t" "## F6 theme toggle"; }; for s in "2026-08-21" "w0-2-terminal-respec" "background_child_process" "full-screen TUI"; do F6 | grep -qF "$s" || { echo "FAIL: F6 entry lacks: $s"; rc=1; }; done; grep -q "^## Per-pane OSC retint$" "$t" || { echo "FAIL: per-pane OSC entry still carries a verdict marker"; rc=1; }; OSC() { E "$t" "## Per-pane OSC retint"; }; OSC | grep -qF "if D.1 drops tinty" && { echo "FAIL: per-pane OSC entry still conditional on D.1"; rc=1; }; OSC | grep -qF "2026-08-21" || { echo "FAIL: per-pane OSC entry records no dated answer"; rc=1; }; grep -rqF "pending decision D.1" docs/ && { echo "FAIL: a docs entry still waits on D.1"; rc=1; }; grep -qi "tinty" docs/capabilities.md && { echo "FAIL: capabilities.md was edited (it names no tinty today and is author-confirmed only)"; rc=1; }; [ "$(grep -ci "tinty" docs/capabilities-provisioning.md)" -eq 1 ] || { echo "FAIL: capabilities-provisioning.md tinty mentions changed"; rc=1; }; [ $rc -eq 0 ] && echo OK; exit $rc'`
```
