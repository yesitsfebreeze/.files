---
state: analyzing        # open|analyzing|refine|question|specced|claimed|blocked|done|failed
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
claim: analyst-nvim-plugin 2026-08-31 13:00
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

# 02-nvim-plugin — claudecode.nvim + claude-tmux.nvim

The editor half: Claude Code inside nvim. `coder/claudecode.nvim` brings the
IDE integration — buffer management, inline diff accept/deny, send-selection —
and `mr55p-dev/claude-tmux.nvim` runs the Claude Code terminal in a tmux
split instead of nvim's built-in terminal, which is exactly the
07-multiplexer invariant (tmux owns the panes). A new `lua/plugins/claude.lua`
in the lazy.nvim stack, with `folke/snacks.nvim` as a dependency.

## Constraints

- **The plugin bypasses the `cc` profile picker.** claudecode.nvim launches
  `claude` directly; the nvim-launched instance uses the default profile.
  Accepted, not fixed (epic constraint).
- **`help --check` binds.** The `<leader>a*` keymaps and the claude-tmux
  `<C-j>` toggle need `06-help` entries (04-help-entries).
- **Lockfile discipline.** The lazy-lock.json delta commits with the spec
  (03-editor E.5+ convention).

## Non-goals

- No changes to the `cc`/`cr` launchers or the profile model.
- No changes to the tmux key tables (F4/F5/F6 stay as shipped).

## Pointers

- `home/dot_config/nvim/lua/plugins/` — the plugin stack; `claude.lua` lands
  here.
- `home/dot_config/nvim/lua/config/lazy.lua` — the bootstrap and lockfile
  policy.
- coder/claudecode.nvim README — the keymaps, commands and snacks.nvim
  dependency.
- mr55p-dev/claude-tmux.nvim README — the tmux provider setup and the
  `<C-j>` toggle.
