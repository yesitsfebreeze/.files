---
state: done
priority: 12
est: 7.5h
task: G.1
mode: afk
needs:
  - 05-platform/01-deploy-mechanism/repo-skeleton
verify: ""
---

# Verification gates

Parent: [Delivery epic](../prd.md) · net-new

Purpose: What must actually *run* before a wave counts as done. The tree's
acceptance criteria are already written as observable checks; this turns them
into gates that an agent can execute without a human watching.
**Scheduled first (priority 90, set 2026-08-21),** behind only the repo
skeleton it depends on. The drift sweep of 2026-08-21 found no gate runner
anywhere in this tree, which makes every "the wave gate passes" acceptance
box in the tree uncloseable until this node closes — the boxes are not wrong,
they simply name a thing that does not exist yet. Two nodes already record a
`[~]` stub standing in for a gate that was never built
(`00-delivery/corrections/w0-3-platform-rewrite`'s link-check box is one).
Building this converts those stubs into checks that can actually be run.

One scoping question this node must answer deliberately, raised by W0.3 and
recorded here so it is not rediscovered: does "tree link check" mean the board
only, or the whole `.mi/` directory? `.mi/workflows/refs/worker.md` and
`memo.md` carry 11 broken relative links into the mi framework's own source
repo, so the answer flips the gate red on day one. Also exclude
`.mi/gantt/scratch/`, which planning runs write into and which is git-ignored.


## Requirements
- [x] **R1** — **Definition of done, per task.** A task is done when: its
      PRD's acceptance criteria have been executed and passed; its `help`
      entries exist; and it introduced no regression in an earlier wave's
      gate. Reading the criteria is not executing them.
      *(a) — the definition is established and the board operates by it: the
      done nodes carry executed acceptance criteria with quoted runs, and the
      quiet-board sweep (2026-08-30) re-ran the whole suite to 5096 PASS /
      8 FAIL. The definition is the rule, not a work item.*
- [x] **R2** — **Headless checks where possible.** The three surfaces are all
      scriptable, which is what makes automated gates realistic:
  - [x] shell — `nu -c '<expr>'` for commands and pipelines;
        `$env.config.keybindings` for bindings. Note the constraint: a bare
        `nu -c` loads no config, so gate scripts must launch a *configured*
        shell.
  - [x] editor — `nvim --headless -c '<lua>' -c 'qa'`, plus `nvim_get_keymap`
        for maps and `:checkhealth` for plugin state. Also `:Lazy! sync` exit
        status for install integrity.
  - [x] terminal — `wezterm show-keys --lua`, diffed against the intended set.
- [x] **R3** — **Interactive checks, listed explicitly.** Some criteria
      genuinely need a human at a terminal: the F5 jump landing on the right
      pane, the smear of a cursor, whether the bare-word jump *feels* instant,
      the shift-select collapse under real keyboard timing. These are
      enumerated per wave as a short manual checklist rather than pretended to
      be automated.
- [x] **R4** — **Wave gates.** | Wave | Gate | |---|---| | 0 | Every audit
      finding is either fixed or recorded as accepted, with a reason. Tree
      link check passes. | | 1 | `chezmoi apply` on a scratch target succeeds
      and is idempotent (second apply is a no-op). `nvim --headless` starts
      with the new options and no error. | | 2 | Shell-init files are
      generated and non-empty; `nvim --headless '+Lazy! sync' +qa` exits 0;
      the dev image builds; WezTerm launches with the intended appearance. | |
      3 | A configured `nu` starts, `cd` funnels correctly (start dir
      written), and each Track E task's own criteria pass headlessly. Capsule
      mounts a directory and lands in `/workspace`. | | 4 | `tv` channels
      return data through `finder`; `git push` works inside a capsule
      (credential propagation); the editor's full acceptance sweep passes. | |
      5 | Directory-scoped history returns only this dir's commands; quicklist
      round-trips a pick; `help <topic>` renders. | | 6 | `help --check` exits
      0. `ls --help` still behaves. Full fresh-machine run: clone → apply →
      working daily driver. |
      *(a) — the wave gates are defined and runnable: `just gates`
      (2026-08-21) ran waves 0–6 to rc 0 in 55s, and the quiet-board sweep
      (2026-08-30) reached 5096 PASS / 8 FAIL with all seven waves ARMED.
      The table is the contract the gates implement.*
- [x] **R5** — **Regression sweep at every gate.** Re-run the previous wave's
      gate, not just the current one. The cheap version: keep every gate as a
      script so the whole set is one command.
- [ ] **R6** — **The final gate is the manual.** `help --check` exiting zero
      means every binding that exists is documented and every documented
      binding exists — which is the closest thing this build has to a
      completeness proof ([`06-help/04`](../../06-help/04-drift-check/prd.md)).
      *(b) — `help --check` is a parse error today: `06-help/04-drift-check`
      is still `state: open`, so the completeness proof does not run. This
      box closes when that node lands.*
- [ ] **R7** — **Fresh-machine test is non-negotiable.** The last gate runs on
      a machine (or VM/container) that has never seen this config. Everything
      else can pass on a developer box that already has the tools installed
      and prove nothing.
      *(b) — the fresh-machine run has not happened. The acceptance box
      below records the weaker half (the suite runs end to end on THIS
      machine); the clean-machine run is registered in
      `gates/manual/wave1.md` and untested.*

## Acceptance
- [x] Each gate is a script that exits non-zero on failure, runnable in one
      command. `just gates` (2026-08-21): guard, lint, probe preflight,
      meta-gate, registry integrity, then waves 0–6 — rc 0 in 55s. Each gate
      alone: `bash gates/tree-links.sh` exit 1 (Tier A red by 4, all owned
      elsewhere — see Findings), `bash gates/audit-findings.sh` exit 0,
      `bash gates/manual-coverage.sh` exit 0. Every one of them proved red on
      an induced failure by `just gate-selftest`.
- [x] Interactive-only checks are listed per wave, and no gate silently
      depends on a human having looked. `gates/manual/wave{0..6}.md` +
      `bash gates/manual-coverage.sh` (exit 0): all 12 tasks carrying a
      `manual` note in `plan.json` covered exactly once, count read at run
      time; R3's four hand-named checks matched through `norm`; no box `[x]`.
- [ ] Running all gates from scratch on a clean machine passes end to end.
      *(b) — genuinely unmet: the fresh-machine run is registered in
      `gates/manual/wave1.md` and has not happened. The quiet-board sweep
      proves the weaker half only — the suite runs end to end on THIS machine
      and reports a tally.*

      **Measured 2026-08-30, and still open — for two reasons, only one of
      which is about the gates.** The serial quiet-board sweep
      ([`quiet-board-sweep`](../quiet-board-sweep/prd.md)) reached
      **5096 PASS / 8 FAIL** with all seven waves ARMED. Of the three causes
      behind those 8: one was a contradiction between two board requirements
      and was fixed in the window; one is a gate whose subject (`capsule`) is
      not installed on this machine; one is a probe that passed and failed on
      the same commit. Only the last is "the gates are wrong".

      **"On a clean machine" remains untested by anything here**, and cannot
      be tested here: this box needs the fresh-machine run registered in
      `gates/manual/wave1.md`. What the sweep proves is the weaker half — the
      suite runs end to end on THIS machine and reports a tally rather than
      falling over.

## Findings

Measured by this node's own gates on 2026-08-21, recorded here because a red
gate must be a **routed defect** rather than an unexplained failure. None of
them is fixed here — every one belongs to another node.

### Tier A link breakages — `bash gates/tree-links.sh`, exit 1

`checked 496 links in 88 files, 4 broken`. The count is a moving target (two
`provisioning-rerate` spec links and `capabilities-terminal.md:31` were
repaired by their owners while this node was being built, and the
`.mi/prd` → `.mi/prds` rename is still uncommitted), so the gate asserts the
mechanism, never the number.

| broken link | owner |
|---|---|
| `w0-4-s2-corrections/backlog-closeout/prd.md:56 -> ../w0-2-terminal-respec/prd.md` | [`backlog-closeout`](../corrections/w0-4-s2-corrections/backlog-closeout/prd.md) — the node is one level further up (`../../w0-2-terminal-respec/prd.md`) |
| `06-help/01-content-model/prd.md:155 -> ../../../workflows/refs/laws.md` | [`stale-framework-links`](../corrections/stale-framework-links/prd.md) |
| `06-help/01-content-model/prd.md:709 -> ../../../workflows/refs/worker.md` | [`stale-framework-links`](../corrections/stale-framework-links/prd.md) |
| `06-help/01-content-model/prd.md:785 -> ../../../workflows/refs/laws.md` | [`stale-framework-links`](../corrections/stale-framework-links/prd.md) |

Tier B, reported and never gating: `checked 191 links in 76 files, 95 broken`
— analyst spec notes that copied a relative path from a `prd.md` one directory
up, plus generated files (`plan.md`, `delivery-gantt.md`) still carrying
pre-rename `../prd/` paths. A generated file's broken link is the generator's
bug and no lane may hand-edit it; `specs/**` are working notes with a lifetime
of one ticket. Neither is the tree's link health.

### Audit-finding disposition — `bash gates/audit-findings.sh`, exit 0

`48 findings, 0 undisposed` (T 11 · C 5 · L 12 · M 20), shape and S1 reach
clean. **The number moved while this node was being specced, and the reason
matters more than the number.** The spec measured seven undisposed — `T-2`,
`T-4`, `T-6`, `T-9`, `M-10`, `M-11`, `M-19`. All seven are now disposed of by
exactly one route: R7 of
[`backlog-closeout`](../corrections/w0-4-s2-corrections/backlog-closeout/prd.md)
names all seven and routes the four terminal ones to
[`w0-2-terminal-respec`](../corrections/w0-2-terminal-respec/prd.md). None
carries an inline verdict and none is named in `plan.json`, so the moment that
R7 line is reworded the seven go orphan again — which is the gate working as
intended, not a fragility to paper over. `backlog-closeout` remains the node
that finishes them.

### Cross-lane reds the sweep surfaced (reported, not gating — both waves are PENDING)

Running the whole set for the first time found two failures in scripts this
node must not edit. Both are recorded here rather than fixed:

- **`tests/deploy-skeleton.sh:212` is now wrong *because* G.1 landed.** Its
  check `push: --list exits 0 with gates/justfile absent (optional import)` is
  written as `[ ! -e "$REPO/gates/justfile" ] && just -f … --list`, i.e. it
  asserts the file's ABSENCE in the live repo. That was true until this node
  created `gates/justfile`, and the intent — "`--list` still works when the
  optional import is missing" — needs a copy of the repo with `gates/`
  removed, not an absence assertion against the working tree. Owner:
  [`repo-skeleton`](../../05-platform/01-deploy-mechanism/repo-skeleton/prd.md)
  (P.1).
- **`tests/live-bugs.sh` fails two `doc:` checks** — `doc: the L-12 correction
  is recorded` and `doc: L-13 recorded`, both `grep`s over
  `.mi/docs/capabilities-provisioning.md`. That file is being rewritten right
  now by `w0-4-s2-corrections/provisioning-rerate` (W0.4i), which appears to
  have dropped the two correction records the script asserts. Owner: that
  node, with [`w0-6-live-bugs`](../corrections/w0-6-live-bugs/prd.md) as the
  script's owner if the record is meant to move rather than survive.

### Not automated, deliberately

**R7's fresh-machine run is a procedure, not a script** —
[`gates/manual/wave6.md`](../../../gates/manual/wave6.md). A scratch-`HOME`
gate on this developer box passes while proving nothing: every tool is already
on `PATH`, every brew formula installed, every cache warm. That is precisely
what R7 warns against. The isolation has to be a real machine boundary
(`docker` and `lima` are both installed, so the file names concrete commands).
The file says so next to the procedure, so nobody "improves" it into a script.

### For the wave gates that do not exist yet

Waves 2, 3, 5 and 6 have an **empty gates cell** in
[`gates/waves.tsv`](../../../gates/waves.tsv). That is legal only while
they are PENDING: the moment every task in a row is `done` at its node, the
wave is ARMED and an empty cell is RED. Each wave's own tasks write its gate
into `gates/` and register it there;
[`gates/probes.sh`](../../../gates/probes.sh) is the machinery they call,
so those gates are three lines each rather than three hours each.

## Out of scope
- Anything this node's Requirements do not name. The epic ([`../prd.md`](../prd.md)) owns the shared invariants.

## Closing note

*Closed 2026-08-21 by the orchestrator.* `just gates` → **exit 0, 433 PASS**,
re-run independently, and it works from the repo root *and* from a
subdirectory. 22 files, ~1,900 lines, under `gates/` only — the root `justfile`
is byte-identical (`git diff -- justfile` → 0 lines), and `tests/` was invoked,
never edited. `shellcheck` clean. The live-config guard wrapped every sweep:
sha256 `02d5d4ee…c850a1` and `source-path /Users/feb/dev/.files/home` on entry
and exit.

All six spec verifies green from RED baselines (four at exit 127, two at "no
such recipe"). Boxes: 48 across the specs, plus R2 and its three sub-boxes, R3
and R5 in the PRD. **W0.3's `[~]` link-check box was correctly not touched** —
spec02 cause-fixes it, but re-ticking it is W0.3's.

Left open with stated reasons rather than fudged: R1 (per-task policy), R4
(waves 1–6 gates belong to their own tasks), R6 (`help --check` does not exist
yet), R7 and acceptance #3 (need a machine that has never seen this config).

**The design decision that matters: a wave ARMED with no gate registered is
red**, not silent. "This wave finished and nobody wrote its gate" is the exact
failure that produced this node, and it is now loud.

**R7 shipped deliberately un-automated** as a numbered container procedure in
`gates/manual/wave6.md`, with a note explaining why nobody should improve it
into a script: a fresh-machine gate run under a scratch `HOME` on a developer
box passes while proving nothing.

Two implementation constraints worth keeping: `gates/justfile` must use
`source_directory()` — `justfile_directory()` resolves to the *root* justfile's
directory inside an import and broke every recipe from a subdirectory; and all
untouched-file proofs use sha256, because `git status --porcelain` printed 166
lines throughout.

**Two cross-lane reds this node surfaced by running**, both confirmed by the
orchestrator and now owned by
[`gate-reconciliation`](../corrections/gate-reconciliation/prd.md):
`tests/deploy-skeleton.sh:212` asserts `gates/justfile` is *absent*, so G.1
landing turns it red; and `tests/live-bugs.sh` fails its `L-12`/`L-13` doc
greps because W0.4i rewrote the file they read. Both are gates owned by closed
tickets, broken by later legitimate work — the same supersession class, but in
the repo's real gates rather than in spec verifies.

## Defect fixed after closing — 2026-08-21

*Found by [`backlog-closeout`](../corrections/w0-4-s2-corrections/backlog-closeout/prd.md)
(W0.4h) by hitting it; fixed by the orchestrator.*

`gates/audit-findings.sh --selftest` exited 1 once a real `**Fixed` marker
existed on its hardcoded probe row (`M-11`). Its `strip_id_everywhere`
neutraliser read

    sed -E "/^\| *$id *\|/ s/$MARKERS/(was &)/gI"

and `&` re-inserts the **whole match**, so `**Fixed` became `(was **Fixed)` —
which still matches `MARKERS`. The row therefore stayed inline-disposed after
being neutralised, and the three "undisposed with all routes removed"
counterfactuals plus the green counterfactual all went red. `MARKERS` already
captures the verdict word, so the fix is one group: `(was \1)` yields
`(was Fixed)`, with no `**`, which does not match.

Confirmed both ways: `--selftest` now exits **0** with 0 FAIL, and the real
wave-0 gate (`bash gates/audit-findings.sh`, no flag) was green throughout —
`waves.tsv` runs it without the flag, so the sweep was never affected. The two
`backlog-closeout` checks and this node's own `specs/spec03.md` verify, all of
which run the selftest, now exit 0.

Worth noting what this was: **a bug in the counterfactual machinery, not in the
gate.** The gate's own answer was right all along; the code that proves the gate
can fail was what broke, and only once the tree contained the very marker the
gate exists to recognise. It was invisible until a lane actually disposed a
finding.
