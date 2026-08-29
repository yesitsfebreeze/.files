---
state: open        # open|analyzing|refine|question|specced|claimed|blocked|done|failed
origin: requested  # requested = the user asked | derived = the board found it
# from:            # derived only — the PRD whose work surfaced this one
priority: 20        # higher first
complexity: 0      # analyst, at spec time — 1-100. THE WEIGHT the board schedules by
blast-radius:      # analyst, at spec time — high|mid|low. What breaks if this is wrong
repo:              # the sub-repo the code lands in; delete if n/a
# workflow:        # OPTIONAL — how this kind of job is done: a slug in
#                  #   prds/workflows/. @references/workflow.md.
#                  #   Absent = the brief alone, as before workflows
time:              # OPTIONAL. See @references/parts/order.md
  est:             # the weight, only when complexity is absent. Not a duration
  actual:          # a record. Nothing reads it
  # claim: <worker> <started>   # orchestrator-only, present while a worker holds this PRD
needs:
  - 02-key-tables
  - 03-status-bar
  - 04-palette-delivery
  - 05-copy-and-clipboard
---
<!-- Ordering reads three axes and no clock: dependency (needs + footprint),
     vision importance (priority), and complexity/blast-radius. Add your own
     keys freely, at any nesting. Nothing outside state, origin, from,
     priority, complexity, blast-radius, claim, repo, workflow, needs and
     footprint is read, and nothing you add is ever dropped.
       needs:     — PRD dir names this one depends on. A hard gate in `plan`
       footprint: — paths this PRD touches. The overlap check
       workflow:  — the route a worker is handed, expanded into its brief

     One sitting is the limit: specs summing `complexity` above `split-above`
     or counting above `specs-above` (both in prds/settings.md, default 40 and
     6) make the analyst's verdict REFINE, and `pearde refine` lands the split
     under `## Children` here — the contract above it stays as written.

     A derived PRD states, in the body, which requested PRD it would otherwise
     get wrong. If it cannot, it is filed `state: deferred` — and if fixing it
     would change only how loudly the board notices, it is a memo, not a PRD.
     See @references/parts/derived.md. -->

# 08-wezterm-reduction — The cutover, in one change (Q8): `default_prog` attaches tmux, `enable_tab_bar = false`, F5 and F6 unbound, and roughly 470 lines go — the `reconcile_tabs` floor, the occupied/empty tint, the F5 table, the derived tab bar and the clock. What stays is the local chrome: font, grid centering, opacity and blur, the launchd PATH seeding, the capsule `SendString` keys. Three tests retire and `wezterm-launchd-path.sh` keeps everything but its `default_prog` assertions. I5 still binds what remains, and `gates/wezterm-config-fields.sh` keeps running. Also lands the cross-cutting edits: I1 and I2 amended in `02-terminal`, the six children marked superseded or amended, and `prds/README.md` and `AGENTS.md` brought in line — the 2026-08-20 shell-side multiplexer stays excluded, for a reason that now needs restating rather than repeating.

The cutover, in one change (Q8): `default_prog` attaches tmux, `enable_tab_bar = false`, F5 and F6 unbound, and roughly 470 lines go — the `reconcile_tabs` floor, the occupied/empty tint, the F5 table, the derived tab bar and the clock. What stays is the local chrome: font, grid centering, opacity and blur, the launchd PATH seeding, the capsule `SendString` keys. Three tests retire and `wezterm-launchd-path.sh` keeps everything but its `default_prog` assertions. I5 still binds what remains, and `gates/wezterm-config-fields.sh` keeps running. Also lands the cross-cutting edits: I1 and I2 amended in `02-terminal`, the six children marked superseded or amended, and `prds/README.md` and `AGENTS.md` brought in line — the 2026-08-20 shell-side multiplexer stays excluded, for a reason that now needs restating rather than repeating.

## Constraint — the two capsule keys are named, not implied

`Ctrl+Shift+S` and `Ctrl+Shift+O` survive this reduction. They are the capsule
recents picker, and the prose clause "the capsule `SendString` keys" above is
not enough to hold them, because what rests on those two keys is specific and
already `done`:

- [`01-capsule/04-recent-workspaces`](../../01-capsule/04-recent-workspaces/prd.md)
  R2 and R3, and three of its acceptance boxes.
- The five C.4 rows in `gates/manual/wave4.md`, ticked on real hardware on
  2026-08-29.
- `tests/capsule-recents-gui.sh`, which drives both keys through a real GUI
  WezTerm (35 run, 35 passed).
- `tests/capsule-recents.sh --keys`, which asserts the **compiled** WezTerm key
  table verbatim and goes red the moment either key moves.

So the implementer of this node deletes F5, F6 and the tab machinery and leaves
those two bindings exactly where they are, and `tests/capsule-recents.sh --keys`
staying green is a check on this node, not a coincidence. Recorded 2026-08-29
after the session holding `01-capsule` raised it: the dependency is real and is
deliberately **not** in this node's `needs:` — `04-recent-workspaces` is already
`done`, so a `needs:` edge would gate nothing. A named constraint is what a
finished-but-load-bearing sibling gets instead.

<!-- Three more headings exist, and none of them is a slot to copy down. Each
     is a claim about the state of this PRD, so an empty copy of it is a false
     one: an empty `## Questions` stops the board on nothing, an empty
     `## Answers` reads as answered, an empty `## Failure` reads as a failed
     attempt. Write the heading when it has content; until then it is absent,
     which is the honest state. @resources/questions.py reports the empty
     ones, and `doctor`'s `questions` row runs it. -->

<!-- `## Questions` — analyst-only, when blocked on the user: one round in the
     format of drill.md — `### Q1: <title>`, the fork in 1-3 sentences ending
     in "?", then exactly three prepared answers, each a complete decision,
     one `(recommended)`. Only real forks the user must settle (naming, scope,
     cost) — never facts a worker could look up, never the PRD restated. A PRD
     parked on the user with no such round never says what it is asking. -->

<!-- `## Answers` — orchestrator-only (or the view), written after asking the
     user: `**Q1** — <the picked answer verbatim, or the user's own words>`,
     numbers matching the round above it. Analysts read these before speccing.
     An `## Answers` with no `## Questions` above it answers nothing. -->

<!-- `## Failure` — implementer-only, after a FAILED attempt: what broke, what
     was tried. `retry` moves this into the body as history and reopens the
     PRD. -->
