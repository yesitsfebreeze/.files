# The committed set — the ~20 boxes that unblock nodes

Written 2026-08-28 from the [finish-line](../../prds/00-delivery/finish-line/prd.md)
drill round, answer 2. Eighty-four boxes are open across `wave0`–`wave6`
(eighty-eight when this file was written; the five decision rows came off the
checklists later the same day — see below). **These are the ones the user
committed to running.** The rest stay open as honest debt: not dropped, not
ticked, just not scheduled.

Run them in `gates/manual/wave4.md` itself — tick the box there, not here.
This file is the worklist, not a second place for results.

## What each group unblocks

| group | boxes | unblocks |
|---|---|---|
| **C.4** — capsule recents | 5 | `01-capsule/04-recent-workspaces`, the last open child of `01-capsule` |
| **T.4** — copy mode | 6 | `02-terminal` epic |
| **T.6** — tab content state | 5 | `02-terminal` epic |
| **T.7** — GUI launch as nine nushell prompts | 1 | `02-terminal/06-launchd-path` |
| **E.14** — shift-select under real keyboard timing | 1 | `03-editor` epic |

Roughly eighteen boxes. Two of them need a *second* agent as an adversary
rather than only a human: the S.4 bare-word rows and E.14 both say
"adversarial verify", and that half can be dispatched.

## The order that wastes least of your time

1. **T.7 first** — launch WezTerm from the Dock and type
   `$nu.default-config-dir` in three tabs. If this fails, several other rows
   are unreachable anyway, so it is the cheapest thing to learn first.
2. **T.6** — all five rows are the same session: launch, watch the bar, run
   `sleep 120` in a tab, split a pane, `kill -9` from elsewhere, press `F6`.
   One sitting.
3. **T.4** — six rows, one WezTerm window, mostly keystrokes.
4. **C.4** — five rows needing a live tv screen and a restart.
5. **E.14** — last, because it is the one that wants fast typing and a fresh
   pair of eyes.

## Not in the committed set

`wave0` G.1; all of `wave2`, `wave3`, `wave5`, `wave6`; and the S.4 rows in
`wave4`. `wave6`'s H.4 rows are additionally gated on
[`06-help/04-drift-check`](../../prds/06-help/04-drift-check/prd.md) shipping,
which answer 1 of the same round narrowed to two surfaces.

**The decision rows are no longer boxes at all.** D.1b (tinty), D.1c (fzf),
D.1d (wallpaper/opacity), D.2 (odin toolchain) and D.3 (shift-select scope)
came off `wave0`, `wave2` and `wave4` on 2026-08-28 by
[`d3-tick-breaks-unticked-rule`](../../prds/00-delivery/corrections/d3-tick-breaks-unticked-rule/prd.md),
answer A. Every one of them is a document to read rather than a screen to
watch, and each one's closure now lives in its own PRD under
[`00-delivery/decisions/`](../../prds/00-delivery/decisions/prd.md).
`gates/manual-coverage.sh` asserts they stay off these pages, so nothing here
is waiting on that node any more.
