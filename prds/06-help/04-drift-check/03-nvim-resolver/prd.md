---
state: done        # open|analyzing|refine|question|specced|claimed|blocked|done|failed
origin: requested  # requested = the user asked | derived = the board found it
# from:            # derived only — the PRD whose work surfaced this one
priority: 8        # higher first
complexity: 18      # analyst, at spec time — 1-100. THE WEIGHT the board schedules by
blast-radius: mid
repo:              # the sub-repo the code lands in; delete if n/a
# workflow:        # OPTIONAL — how this kind of job is done: a slug in
#                  #   prds/workflows/. @references/workflow.md.
#                  #   Absent = the brief alone, as before workflows
time:              # OPTIONAL. See @references/parts/order.md
  est:             # the weight, only when complexity is absent. Not a duration
  actual: 0.05h
  # claim: <worker> <started>   # orchestrator-only, present while a worker holds this PRD
needs:
  - 01-check-plumbing
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

# 03-nvim-resolver — R2 for global maps: one headless spawn that never installs plugins and raises on a missing config, the seven normalization rules, the three-state `desc

R2 for global maps: one headless spawn that never installs plugins and raises on a missing config, the seven normalization rules, the three-state `desc

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

## Report

spec01: exit 0
7:-- HELP_CHECK=1 — the drift check's read-only spawn (06-help/04-drift-check).
26:local checking = vim.env.HELP_CHECK == "1"
33:    io.stderr:write("HELP_CHECK: lazy.nvim is not installed at " .. lazypath .. "\n")
62:  -- under HELP_CHECK and unchanged otherwise.
plugin-manager rc=0
plugin-manager FAILs: 0 (expect 0)
PASS  R6: install.missing = true on an ordinary launch
PASS  HELP_CHECK=1: install.missing = false (the spawn cannot install)
PASS  HELP_CHECK=1: checker.enabled = false (the spawn cannot poll)
PASS  HELP_CHECK=1: install.colorscheme is otherwise untouched
PASS  counterfactual: guard removed -> HELP_CHECK no longer stops installing
colorscheme rc=0
colorscheme FAILs: 0 (expect 0)
live 217 · targets 61 · raw 30 · normalized 61
114:| `<space>` | `" "` — and so `<leader><space>` returns two spaces |
degraded rc=1 store       23 ->       23
noguard rc=1 store       23 ->       24 (expect it to GROW: the guard is what stops the clone)
PASS  M0 baseline, no mutation — no nvim finding, as required
PASS  M1 explicit desc drifts — mismatched <leader>w and <leader>q — <leader>w: live 'Write the file' vs manual 'Save'
PASS  M2 the documented map is deleted — stale <leader>w and <leader>q — n <leader>w -> looked up as ' w', not in the live dump
PASS  M3 desc absent -> compared against the title — mismatched <C-h> <C-j> <C-k> <C-l> — <C-l>: live 'Go to right window' vs manual 'Move between windows'
PASS  M4 desc null + drifted live desc — no nvim finding, as required
mutations rc=0
help --check rc=1 (expect 1 — the corpus has known shell drift)
documented 147 · prose-only 16 · allowlisted 10 · live nvim maps 217
stale: 4
  [shell/command] z <query> — z
  [shell/command] zi — zi
  [shell/command] zz — zz
  [shell/command] pass <tab> — pass
mismatched: 0
undocumented: 173
