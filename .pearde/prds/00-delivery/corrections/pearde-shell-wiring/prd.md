---
state: done        # open|analyzing|refine|question|specced|claimed|blocked|done|failed
origin: requested  # requested = the user asked | derived = the board found it
# from:            # derived only — the PRD whose work surfaced this one
priority: 0        # higher first
complexity: 8      # analyst, at spec time — 1-100. THE WEIGHT the board schedules by
blast-radius: mid
repo:              # the sub-repo the code lands in; delete if n/a
# workflow:        # OPTIONAL — how this kind of job is done: a slug in
#                  #   .pearde/workflows/. @references/workflow.md.
#                  #   Absent = the brief alone, as before workflows
time:              # OPTIONAL. See @references/parts/order.md
  est:             # the weight, only when complexity is absent. Not a duration
  actual: 0.36h
  # claim: <worker> <started>   # orchestrator-only, present while a worker holds this PRD
workflow: wire-a-tool-into-the-shell
commit: d1e993c
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
     or counting above `specs-above` (both in .pearde/settings.md, default 40 and
     6) make the analyst's verdict REFINE, and `pearde refine` lands the split
     under `## Children` here — the contract above it stays as written.

     A derived PRD states, in the body, which requested PRD it would otherwise
     get wrong. If it cannot, it is filed `state: deferred` — and if fixing it
     would change only how loudly the board notices, it is a memo, not a PRD.
     See @references/parts/derived.md. -->

# pearde-shell-wiring

Parent: [Corrections backlog](../prd.md) · net-new

Purpose: `pearde install --apply` builds the skill symlinks and then **prints
two lines for you to add to your shell yourself** — it writes no shell file.
Neither line was in this configuration, so the board could only be driven by
typing `PEARDE_AS=engineer python3 <repo>/resources/pearde.py` in full, and
every transition command refused with `persona: …` until the variable was set
by hand. This node puts both lines into the nushell configuration in
nushell's own form, and gives the new alias the manual entry this shell's
drift check requires of any alias.

**The contract on this heading was reconstructed on 2026-09-02, after the
work, and that is worth saying plainly.** The body was still the unfilled
template when the node was built and proven — it would have closed as the only
node on this board with no contract in the place the board designates for it,
which is the adjacent failure to the `[x]`-you-did-not-prove that
[`AGENTS.md`](../../../../../AGENTS.md) warns about: a proven box against a
contract nobody wrote. It is recovered from two independent sources that both
predate the build — `resources/install.sh:216-218`, which prints both lines
verbatim, and `references/install.md`, which documents them — never from the
implementation's own account of itself. Every box below carries the check that
closed it.

## Requirements

- [x] **R1** — `env.nu` exports `$env.PEARDE_AS`, with a comment saying what
      reads the variable and what happens when it is unset. Without it every
      transition command refuses. Proof: `env.nu:55`
      `$env.PEARDE_AS = "engineer"` under twelve lines of comment naming the
      refusal; re-measured independently — with `config.nu` loaded and
      `env.nu` not, `pearde sweep --dry` answers `refused — persona: …`, so
      the variable is doing work rather than decorating.
- [x] **R2** — `config.nu` aliases `pearde` at the **source repo**
      `~/dev/infra/pearde`, in the ALIASES anchor — never at the
      `.claude/skills/pearde` symlink inside this project. Every install on
      this machine is symlinks into that one repo, so a project-local path
      gives a `pearde` that answers only while you stand in this directory.
      Proof: `config.nu:88`
      `alias pearde = python3 ~/dev/infra/pearde/resources/pearde.py`.
- [x] **R3** — Both lines live in the chezmoi source under `home/` and are
      deployed, so the change survives the next apply. Proof: `chezmoi
      source-path` → `/Users/feb/dev/dotfiles/home`; the same two lines in
      `~/.config/nushell/{env,config}.nu`; scoped `chezmoi diff` returns zero
      bytes, rc 0.
- [x] **R4** — The alias carries a manual entry, because `help --check` fails
      on any alias without one — so the entry is part of this change, not a
      follow-up. It is **documented, not allowlisted**. Proof:
      `shell.nuon:643` with `verify: [{kind: "alias", name: "pearde"}]`;
      `help --check` unpiped exits 0 with `undocumented: 0`; `HC_ALLOW.alias`
      still reads `["core-help" "core-ls"]`. The check is not vacuous —
      `help-check.nu:93` enumerates `scope aliases | get name`, which contains
      `pearde` in a config-loaded shell, and line 437 diffs that against the
      documented targets, so deleting the entry produces a finding.
- [x] **R5** — The probe left behind for the next run is **falsifiable on the
      one thing it exists to detect**: `probe/verify.sh` grades a missing
      alias as bad, and does not pass by default on a machine without tmux.
      As first written its arms matched `*"unknown command"*` and
      `*"executable was not found"*`, and nushell 0.115.1 emits neither for an
      unresolved alias, so a missing alias fell through to `*)` and graded
      **ok**. Found by review, reproduced against the live shell before
      anything was changed. Rewritten so grading is **positive** — only
      `*"sweep: "*` passes, `*)` is `bad`, and the no-tmux branch is `bad`
      rather than a skip — because enumerating failure strings and defaulting
      to success is the defect itself, not the missing string.

      Proof, with each measurement attributed to whoever actually made it.
      *By the implementer:* the real missing-alias error grades bad, real
      success grades ok, the persona refusal grades bad, unrecognised junk
      grades bad; the no-tmux path run against a shim PATH holding nu, chezmoi
      and git and genuinely no tmux gave `FAIL no tmux …` and a real exit 1,
      captured unpiped. *By the orchestrator, run rather than read off the
      report:* `bash probe/verify.sh` → 8 ok, `PROBE_RC=0`; and
      `nu -n -c 'pearde sweep --dry'` — no config loaded, so the alias is
      genuinely absent — answers ``Command `pearde` not found`` under a
      `nu::shell::external_command` banner, the shape the arms now grade
      `bad`.

## Constraints

- **`nu -c '<code>'` loads neither `env.nu` nor `config.nu`**, so it reports
  the alias as unknown and `PEARDE_AS` as absent even when both are correct
  and deployed. Worse, it *looks* like it loaded: `EDITOR` and
  `STARSHIP_SHELL` both answer under it, inherited from the parent process.
  Measured 2026-09-02. Test with both config paths named explicitly, or with a
  detached `tmux` session running bare `nu` — both forms are in
  `probe/verify.sh`.
- **`chezmoi apply` is scoped, never bare.** The working tree holds unrelated
  pending changes, including `run_after_*.sh` scripts that `chezmoi diff`
  renders as new files at `$HOME` root. Those are scripts chezmoi *executes*,
  not files it deploys — alarming, not a defect.
- **The manual pages under `manual/guide/` and `manual/reference/` are
  generated.** Add the entry to `help/shell.nuon` and run `just manual`; never
  hand-edit a generated page.

## What rides in this commit that is not this node's

Recorded because `collect` widened five pre-claim paths and three of them are
shared. Stated here rather than discovered later from a confusing `git show`.

- **Clean, wholly this node's**: `manual/guide/agents.md` (+15, the `pearde
  [cmd]` entry) and `manual/reference/agents.md` (+1, its table row) — both
  generated from `shell.nuon` by `just manual`, both containing nothing else.
  The seven files under `.pearde/workflows/` are also wholly this node's: its
  analyst drafted the route because the library was empty.
- **Shared, and swept in**: `env.nu`, `config.nu` and `help/shell.nuon`. Each
  carries this node's lines *and* the uncollected 2026-09-01 change that
  retired `Ctrl-Space` / `F1` / `Ctrl-T`, moved the finder to `F3` in
  `tmux.conf`, and moved R7's start-dir read out of `env.nu` for tmux. That
  work is **not** this node's and its attribution to this commit is an
  artifact of `--widen` taking whole files, not hunks. The 633 other dirty
  paths `collect` listed as *inherited, not added* were correctly left alone;
  these three could not be, because the two edits interleave inside them.

The separation was made by reading each diff, not by trusting the report:
`git diff` on the two `agents.md` pages shows only the `pearde` entry, while
`config.nu` shows the `tv_finder`/`tv_remote` removal and the `Ctrl-T` unbind
alongside the alias.

## Out of scope

- The behaviour of the board tool itself. This node wires an installed tool
  into the shell; it changes nothing about what the tool does.
- The dead-gate rows in `why-review.nuon` and `use-review.nuon`, which name
  the deleted `tests/help-content-model.nu`. Real, found by this work, and its
  own correction.
- The three `unresolved: 3` nvim buffer-local findings, which predate this
  change.

<!-- Three more headings exist, and none of them is a slot to copy down. Each
     is a claim about the state of this PRD, so an empty copy of it is a false
     one: an empty `## Questions` stops the board on nothing, an empty
     `## Answers` reads as answered, an empty `## Failure` reads as a failed
     attempt. Write the heading when it has content; until then it is absent,
     which is the honest state. @resources/questions.py reports the empty
     ones, and `doctor`'s `questions` row runs it. -->

<!-- `## Questions` — analyst-only, when blocked on the user: one round in the
     format of drill.md — `### Q1: <title>`, the fork in two sentences ending
     in "?", then exactly three prepared answers, each a complete decision,
     one `(recommended)`. Only real forks the user must settle (naming, scope,
     cost) — never facts a worker could look up, never the PRD restated. A PRD
     parked on the user with no such round never says what it is asking.
     Written in plain words for the person who asked, never for the board — no
     backtick, no path, no PRD name, no board word, 60 words in the fork and 25
     in an answer: the table in @references/drill.md is the whole rule, and
     @resources/questions.py refuses a round that breaks it. -->

<!-- `## Answers` — orchestrator-only (or the view), written after asking the
     user: `**Q1** — <the picked answer verbatim, or the user's own words>`,
     numbers matching the round above it. Analysts read these before speccing.
     An `## Answers` with no `## Questions` above it answers nothing. -->

<!-- `## Failure` — implementer-only, after a FAILED attempt: what broke, what
     was tried. `retry` moves this into the body as history and reopens the
     PRD. -->
