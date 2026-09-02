---
state: done        # open|analyzing|refine|question|specced|claimed|blocked|done|failed
origin: requested  # requested = the user asked | derived = the board found it
# from:            # derived only — the PRD whose work surfaced this one
priority: 15        # higher first
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
  - 02-nvim-plugin
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

# 04-help-entries — the manual entries for the new bindings

The `06-help` entries for everything this epic binds, so `help --check`
passes. The `<leader>a*` keymaps and the claude-tmux `<C-j>` toggle are new
bindings; the manual documents them with what they do and how to use them,
per the 06-help content model.

## Constraints

- **`help --check` must pass.** An undocumented binding is a failed check.
- **The right surface.** nvim keymaps go on the nvim surface (`nvim.nuon`,
  `kind: "nvim-map"`); anything tmux stays on the existing `terminal` surface
  — `help` gains no fifth `--mode` (07-multiplexer constraint).

## Non-goals

- No changes to the `help` command itself.

## Pointers

- `home/dot_config/nushell/help/nvim.nuon` — the nvim surface and its
  `nvim-map` verify kind.
- `home/dot_config/nushell/help/terminal.nuon` — the terminal surface.
- `prds/06-help/01-content-model/prd.md` — the surfaces and verify kinds.

## Closed 2026-08-31 in passing

The claude entries this node owed — the `<leader>a` group and the nine
`<leader>a*` maps — were written into `nvim.nuon` the same day, from the live
`claude.lua` descs, while the markdown-manual work
([06-help/06](../../06-help/06-manual-markdown/prd.md)) was landing; the
`02-nvim-plugin` code itself was already deployed. `help --check` now reports
**stale 0 · mismatched 0 · undocumented 0**; the three `unresolved` are the
known buffer-local maps and are not findings. What is NOT done, and stays with
[`02-nvim-plugin`](../02-nvim-plugin/prd.md): the plugin's own spec-time work
(`analyzing`) — the entries here document keys that already work, nothing more.
No `use-review`/`why-review` rows exist for the ten new entries; the gate that
enforced them was deleted with `tests/` on 2026-08-31, so a reader who did not
write them still owes that reading.
