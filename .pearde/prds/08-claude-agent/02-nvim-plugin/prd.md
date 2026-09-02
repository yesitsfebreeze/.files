---
state: claimed        # open|analyzing|refine|question|specced|claimed|blocked|done|failed
origin: requested  # requested = the user asked | derived = the board found it
# from:            # derived only — the PRD whose work surfaced this one
priority: 15        # higher first
complexity: 8      # analyst, at spec time — 1-100. THE WEIGHT the board schedules by
blast-radius: low
repo:              # the sub-repo the code lands in; delete if n/a
# workflow:        # OPTIONAL — how this kind of job is done: a slug in
#                  #   prds/workflows/. @references/workflow.md.
#                  #   Absent = the brief alone, as before workflows
time:              # OPTIONAL. See @references/parts/order.md
  est:             # the weight, only when complexity is absent. Not a duration
  actual:          # a record. Nothing reads it
  # claim: <worker> <started>   # orchestrator-only, present while a worker holds this PRD
needs:
workflow: land-an-answered-fork
claim: impl-nvim 2026-09-02 11:44
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

## History

**failed, retried 2026-09-02 11:17**

The spec set was written against a tree that had already changed underneath
it, so two of its boxes are not implementable as written. Recorded
2026-09-02 from the implementer's run; the work that *did* land is in the
tree, uncommitted, and is not lost.

**spec02 cannot start — its entire footprint was deleted.** Both files it
names, `tests/nvim-claude.sh` and `gates/nvim-seed-registry.sh`, went with
commit `ad3f1a6`, which retired `tests/` and `gates/` wholesale under
`.pearde/memos/tests-and-gates-retire-a-dev-setup-is-not-a-product.md`.
spec01's `## Verify and Proof` block calls the same three deleted scripts.
The specs were written hours *after* that retirement, from a probe pass that
predated it — so this is spec drift, not an implementation defect. 0 of 6
boxes closed, and none can be without the user settling whether the
retirement stands.

**spec01 box 4 cannot be met as written.** `claudecode.nvim` ends
`terminal.setup()` with `get_provider().setup(defaults)`, where
`defaults.split_side = "right"`, and claude-tmux force-merges that over its
own state. Measured twice inside real tmux with different inputs — first
`"bottom"`, then `"left"` — and both runs produced `split_side=right`, pane
`h=49 w=60`, a right split. `split_side` in `claude.lua` is therefore dead
configuration: whatever it is set to, the value is overwritten before it is
read. 4 of 5 spec01 boxes closed.

**What landed and stands.** `home/dot_config/nvim/lazy-lock.json` — exactly
3 insertions, 23 entries, sorted, no other line moved. Reproduced by the
orchestrator on collect: `git diff --stat` reports `1 file changed, 3
insertions(+)`.

The way back is `retry` once the two forks in `.pearde/.state/ask.md` are
answered; spec02 needs re-speccing against whatever the first answer
settles, and spec01 box 4 against the second.

## Questions

Transcribed by the orchestrator on 2026-09-02 from `.pearde/.state/ask.md`,
where the previous pass wrote this round and from which it was put to the
user. It is recorded here, not composed here: the round had no home in the
PRD because `failed` is reached from `claimed`, where `question` is not a
legal edge, and `pearde answer` needs the forks present to bind replies to.

### Q1: Do the planned checks get written?

A batch of checks for the editor's new Claude integration was planned before
this project deleted its whole test suite, on the grounds that a personal
setup is not a product. Writing those checks now would rebuild part of what
was just deliberately retired?

1. Skip them — the retirement stands, and the integration is proven by deploying it and using it. (recommended)
2. Write them anyway — this integration is intricate enough that it earns a check the rest of the setup does not.
3. Write one smoke check that it loads and opens, and leave the rest retired.

### Q2: What happens to the panel-side setting?

When Claude opens inside the editor, the plugin hosting it forces its panel
to the right, overriding whichever side the configuration asks for. Measured
twice with different settings and the panel came out on the right both times,
so the setting currently does nothing?

1. Accept the right-hand panel and remove the setting that has no effect, so nothing claims a choice that is not there. (recommended)
2. Force the side back after the host plugin loads, so the panel opens where the configuration asks.
3. Keep the setting as it is and record in the manual that it is inert.

## Answers

**Q1** *(answered 2026-09-02 11:17)* — Skip them — the retirement stands, and the integration is proven by deploying it and using it.

**Q2** *(answered 2026-09-02 11:17)* — Accept the right-hand panel and remove the setting that has no effect, so nothing claims a choice that is not there.
