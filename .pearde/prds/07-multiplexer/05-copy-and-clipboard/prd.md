---
state: done           # open|analyzing|refine|question|specced|claimed|blocked|done|failed
origin: requested  # requested = the user asked | derived = the board found it
# from:            # derived only — the PRD whose work surfaced this one
priority: 20        # higher first
complexity: 29      # analyst, at spec time — 1-100. THE WEIGHT the board schedules by
blast-radius: mid
repo:              # the sub-repo the code lands in; delete if n/a
# workflow:        # OPTIONAL — how this kind of job is done: a slug in
#                  #   prds/workflows/. @references/workflow.md.
#                  #   Absent = the brief alone, as before workflows
time:              # OPTIONAL. See @references/parts/order.md
  est:             # the weight, only when complexity is absent. Not a duration
  actual:          # a record. Nothing reads it
  # claim: <worker> <started>   # orchestrator-only, present while a worker holds this PRD
needs:
  - 01-session-and-windows
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

# 05-copy-and-clipboard — Copy mode on `copy-mode-vi`: `Ctrl+Shift+X` enters with the selection and the per-pane toggle cleared, `c` cycles cell→word→line per pane, `y` copies (Q6). The sink is pbcopy when the pane is on this machine and OSC 52 when it is not (Q14), which is the only arrangement where copying works both at this desk and over ssh. Terminal.app ignores OSC 52 and will fail silently there; say so in the manual entry rather than papering over it.

Copy mode on `copy-mode-vi`: `Ctrl+Shift+X` enters with the selection and the per-pane toggle cleared, `c` cycles cell→word→line per pane, `y` copies (Q6). The sink is pbcopy when the pane is on this machine and OSC 52 when it is not (Q14), which is the only arrangement where copying works both at this desk and over ssh. Terminal.app ignores OSC 52 and will fail silently there; say so in the manual entry rather than papering over it.

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

## Corrected 2026-09-01 — the entry key, and the sink that was never wired

Two defects, both live from the cutover until 2026-09-01, both in this node's
scope:

- **`Ctrl+Shift+X` never worked.** This node's own probe (`probe/notes.md` C2)
  measured the cause and filed the fix as a one-line WezTerm shim on
  `08-wezterm-reduction`; that node shipped without it. The obligation is now
  **withdrawn**, not overdue — the shim would have been a WezTerm binding
  rescuing this epic's headline key, which [**I1**](../prd.md) forbids.
  `bind -n F4 copy-mode` replaces it and the `C-S-x` binding is deleted.
- **The sink was chosen and never used.** `@copy-sink pbcopy` was read by the
  `y` binding alone. Every other copy path — `Enter`, the mouse drag-release,
  double- and triple-click — ran stock `copy-pipe-and-cancel` with no command,
  which fills tmux's paste buffer and stops; under `set-clipboard off` that is
  the end of the line. Selecting text and pressing anything but `y` left the
  system clipboard untouched. The sink is now an option every path names,
  expanded with `send -FX` (plain `-X` does not expand formats and would pipe
  to the literal `#{@copy-pipe}`), and `Ctrl+C` in `copy-mode-vi` copies on
  `#{selection_present}` instead of the stock bare `cancel`.

Both arms are now driven rather than reasoned about: with `pbcopy` on `PATH`
the selection reaches `pbpaste`; on a server started with no `pbcopy`, no
`infocmp` and no `nu`, the same `y` puts base64 on an attached client's tty as
OSC 52. The fixture is in `manual → internals/tmux`.
