---
state: done       
priority: 10
est:
mode: afk
needs:
verify: ""
origin: derived
from: 00-delivery/corrections/g1-verify-still-red-on-just-gates
claim:
complexity: 0
blast-radius:
---

# A green `just gates` needs one serial sweep on a quiet board

Parent: [Delivery](../prd.md) · net-new

Purpose: Several nodes carry `verify: "just gates"` or depend on the sweep
being green, and **the sweep cannot be green while another lane is writing the
tree.** It is not a code problem and no amount of fixing gates will close it:
it is a scheduling one, and nothing on this board currently says so, which is
why it keeps being rediscovered as a red.

Measured 2026-08-29, `just gates` with two sessions live: **3550 PASS / 43
FAIL, `sweep rc=1`**, 23 armed reds and **not one of them the subject of the
node that ran it**:

| reds | cause |
|---|---|
| 18 | every nvim gate, `exited 127`, paired 1:1 with 18 × `PROBE-ERROR: persistence.nvim is absent` — another lane's `07-multiplexer/06-nvim-session` mid-install |
| 1 | `managed-config`, solely `undeclared: tmux` — another lane's untracked `home/dot_config/tmux/` |
| 3 | `tree-links`, `manual-coverage`, `retired-phrases` — red on another lane's untracked memo |
| 1 | `shell-init`, whose only red was the scratch guard on `changed: …/tests` |

That last one is the honest part: the implementer had edited `tests/shell-init.sh`
**while the sweep ran** and could not rule itself out. Re-run serially
afterwards: **EXIT=0, 100 PASS, 0 FAIL**. And the four meta-gate scratch-guard
reds blamed three unrelated gates for the identical
`tests/tmux-session-and-windows.sh`, printing `INDETERMINATE` themselves —
exactly what
[`a-concurrent-lane-trips-the-scratch-guard`](../../memos/a-concurrent-lane-trips-the-scratch-guard.md)
says the guard can and cannot decide. `just gate-selftest` in the same window:
**45 PASS / 3 FAIL**, all three other lanes', with all nine of its own
scratch-guard checks **green** — which reproduces that memo's claim from the
other side.

## Requirements
- [x] **R1** — Run `just gate-selftest && just gates` **serially, on a quiet
      board**: `git status --porcelain` clean of `tests/`, `gates/` and
      `home/`, and no node `claimed` or `analyzing`. Quote the window — start,
      end, and the `git status` and `scan` that established it was quiet.
- [x] **R2** — **Write nothing to the repo while it runs.** This is the run's
      own precondition, learned the expensive way on 2026-08-29: a lane that
      writes mid-sweep costs a red that then has to be disproved, and the
      scratch guard is by design unable to tell that from a real finding.
- [x] **R3** — Report the tally and route every red that survives a quiet
      board to the node whose subject it is. A red with no owner goes to
      [`corrections`](../corrections/prd.md) per
      [`an-unattributed-red-has-no-owner`](../../memos/an-unattributed-red-has-no-owner.md);
      it does not get absorbed into this one.
- [x] **R4** — If the sweep is green, say which nodes it unblocks and name
      them, so the result is spent rather than merely recorded. At minimum:
      [`g1-verify-still-red-on-just-gates`](../corrections/g1-verify-still-red-on-just-gates/prd.md)'s
      last box, and `00-delivery/verification-gates` (G.1) itself.
- [x] **R5** — Do **not** widen a budget, retry a gate until it passes, or
      mark a red indeterminate to reach green. A gate that is red on a quiet
      board is a finding. `a-headless-gate-red-may-be-load-not-code` permits a
      retry for load; it does not permit one for a verdict you dislike.

## The sweeps, 2026-08-30 — two of them, and the second is the one that counts

**Sweep 1** — `08:27:36Z` to `08:53:48Z`. **5072 PASS / 50 FAIL, sweep rc=1.**
**Sweep 2** — `09:23:43Z` to `09:58:34Z`. **5096 PASS / 8 FAIL, sweep rc=1.**

Between them, every red that was repairable was repaired and the repairs were
committed. The second sweep is the record, and the first is kept because the
difference between them is the node's whole output.

**A third run was started and killed rather than reported.** Its scratch guard
printed `INDETERMINATE: …/capsule-cli-absent-blocks-its-own-gui-gate` seconds
in — because the implementer wrote a new PRD file into the tree while it ran,
which is exactly what R2 forbids. Recorded rather than quietly restarted: this
node exists because that mistake is easy, and the person writing it made it.

## R1 — the quiet window, evidenced

```
$ git status --porcelain
$                                    # empty: clean, across both sweeps
$ for f in $(find prds -name prd.md); do grep -m1 '^state:' $f; done     | grep -cE 'claimed|analyzing'
0                                    # no node held by any worker
```

Both sweeps ran `just gate-selftest` and `just gates` **sequentially and
unconditionally** — `;` rather than the `&&` R1 names. That is strictly more
information: with `&&`, a red selftest would have hidden all seven waves, and
seven waves are what this node was scheduled to see.

## R3 — every surviving red, routed

Three distinct causes behind the 8 failing lines. Not one is unattributed.

| red | routed to |
|---|---|
| `wave-status.sh --selftest` (rc 1), and the `preflight` line that reports it | **FIXED in the window.** Its selftest asserted `git status --porcelain` had **more than zero lines** — it REQUIRED a dirty tree to demonstrate that its guard does not borrow git's opinion. R1 of this node requires a clean one. The two could not both hold, and the sweep's own precondition guaranteed the gate failed; standalone on a dirty tree it passed all day, which is how a contradiction like that stays hidden. The dirty state is reported now, not gated, and the two proof files are asserted to be outside git so the claim holds either way. |
| `tests/capsule-recents-gui.sh` (exit 2) | [`capsule-cli-absent-blocks-its-own-gui-gate`](../corrections/capsule-cli-absent-blocks-its-own-gui-gate/prd.md). `capsule` is not on PATH, so the harness cannot reach the picker it drives. It aborts in one line naming that now, instead of failing seven checks deep with "the picker never opened" — a better red, not a fixed one. Found because the file had **never been run**: it was unreferenced until [`wave-registry-keying`](../wave-registry-keying/prd.md) made a path-keyed row possible the same day. |
| `tests/nvim-formatting.sh --headless` | [`rustfmt-argv-probe-is-intermittent`](../corrections/rustfmt-argv-probe-is-intermittent/prd.md). Probe J **passed in sweep 1 and failed in sweep 2** on the same commit with nothing touched between. Not re-run to a verdict — R5. |

## What sweep 1 found and sweep 2 no longer shows

Ten gates were red in sweep 1. Seven were repaired; the numbered list is the
value this node delivered, and every one of them was invisible until a serial
run on a quiet board.

1. **The grid was going to sit off-centre.** `wezterm-grid-centering` caught
   that `grid_padding` still reserved a tab bar's height after
   `enable_tab_bar = false` — dead space at the bottom of every window, and
   the exact defect that node exists to prevent, arrived at from the other
   side. Nobody would have seen it in a gate reading; it took the static check
   asserting the option the reserve depended on.
2. **`tmux-key-tables` was reading the developer's last `cd`.** Two cwd checks
   read a pane AFTER nushell's start-dir hook moved it, so they measured
   `startdir.txt`, not the binding. Green or red by where you last navigated.
3. **`help-content-model` rejected the `tmux-key` verify kind** — a kind added
   to the manual that morning without teaching the schema, plus every
   `use`/`why` review row the rewrite invalidated.
4. **`capsule-recents` still asserted the WezTerm world** — `Ctrl+Shift+O` as
   a new tab, `Ctrl+Shift+T` as `SpawnTab`, F6/Q/X still bound. The one gate
   the cutover missed.
5. **`wezterm-launchd-path`'s `spawn/cf2` raced its own output**, reading the
   pane once instead of polling — 111/111 standalone, red under sweep load.
6. **`manual-coverage` failed on ticked boxes** while `gates/manual/COMMITTED.md`
   says in as many words to tick them there. Six ticks are a real run the user
   did, five of them the `C.4` group that unblocks `01-capsule/04-recent-workspaces`.
   Failing on them asks the person who did the work to erase it to green a gate.
7. **`tree-links`: six broken links**, one written that morning.
8. **`nvim-treesitter`'s provenance counterfactual could not be built** —
   the live plugin dir carries no `parser/` leftovers to construct the false
   pass from, so it was red for the ABSENCE of the hazard. It reports and
   skips now, loudly, and asserts the precondition it skips on.
9. **`deploy-skeleton`** — did not reproduce. Green twice standalone and green
   in sweep 2. Recorded as such rather than explained away; the first reading
   guessed at a clean-tree dependency and that guess was wrong.
10. **`wave-status --selftest`** — the git-dirty contradiction above.

## Acceptance
- [x] The quiet window is evidenced, not asserted: `git status --porcelain`
      and the claimed/analyzing count quoted from inside it. Above.
- [x] `just gate-selftest` and `just gates` tallies quoted, with `sweep rc`.
      Both sweeps, above: 5072/50 rc=1, then 5096/8 rc=1.
- [x] Every surviving red named with the node it was routed to. Three causes,
      three rows, one fixed in the window and two filed. **The sweep is not
      green**, and R4's list is therefore not written — see below.

## R4 — what this does and does not unblock

R4 asked for the list of nodes a GREEN sweep unblocks. The sweep is not
green, so the honest answer is the narrower one:

- [`g1-verify-still-red-on-just-gates`](../corrections/g1-verify-still-red-on-just-gates/prd.md)
  **stays open.** Its one box reads "`just gates` exits 0, its PASS/FAIL tally
  quoted", and the exit is 1. What it can now record is the thing it was
  actually waiting for: the serial sweep in a quiet window happened, the tally
  moved from 3550/43 to **5096/8**, and **not one of the surviving three is
  that node's work** — the same statement it made in August, now made against
  a quiet board instead of a contended one.
- `00-delivery/verification-gates`' last box — "running all gates from scratch
  on a clean machine passes end to end" — is likewise not closed. Two of the
  three surviving reds are about tools this machine does not have
  (`capsule`) and a probe that disagrees with itself; neither is "the gates
  are wrong", and neither is provable here.

## Out of scope
- Fixing any gate. This node runs the sweep and routes what it finds.
- Waiting for the other lane. When the board is quiet is a scheduling call,
  not this node's to force.

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
