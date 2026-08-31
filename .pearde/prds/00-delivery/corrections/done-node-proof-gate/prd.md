---
state: deferred
priority: 14
est:
mode: afk
needs:
  - 00-delivery/corrections/done-nodes-without-proof
verify: ""
origin: derived
from: 00-delivery/corrections/mi-rooted-verify-commands
claim: 
complexity: 55
blast-radius: mid
---

# Gate the property the board actually cares about: a `done` node's proof runs

Parent: [Corrections backlog](../prd.md) · net-new

Purpose: [`mi-rooted-verify-commands`](../mi-rooted-verify-commands/prd.md)'s
R5 recommended a path-existence check on `verify:` and then argued itself out
of gating it, on five reasons. The fifth settles it: after that node's repoint,
**every path exists, Tier A is green, and 37 of 62 verifies still prove
nothing.** A gate asserting "every verify names an existing path" would go
green on a board where most of these `done` nodes' proofs are spent — the
overclaimed guard this whole family of nodes exists to correct.

The stronger property is decidable and is what `done` is supposed to mean:
**every `done` node's `verify:` is non-empty and exits 0.**

**Deferred on purpose, and the dep is the point.** A gate that starts red on
eighteen nodes gets switched off, so
[`done-nodes-without-proof`](../done-nodes-without-proof/prd.md) has to work
that list down first. This node exists now so the recommendation is not lost
between the two.

## Requirements
- [ ] **R1** — The check asserts, for every `state: done` node: `verify:` is
      non-empty, and the command exits 0. Frontmatter read with a
      frontmatter-scoped reader — `gates/wave-status.sh`'s `node_state()`
      already stops at the closing `---` and is the shape to port.
- [ ] **R2** — **It runs in the wave runner, not per-commit.** `just gates`
      alone exceeds ten minutes and this multiplies that. Say which wave, and
      whether it belongs beside `gates/wave-status.sh --run` rather than in a
      wave cell.
- [ ] **R3** — **A red must be actionable, not a wall.** Report per node, and
      make the failure name the node and its command. A gate that says "31
      nodes failed" is a gate nobody reads.
- [ ] **R4** — **Build the advisory path-existence check too, and keep it
      advisory**, with the five reasons recorded in its header so nobody
      promotes it to gating. It catches a real class cheaply — all 62
      carriers plus the two mode-126 cases — and its limits are exactly why it
      must not be the gate.
- [ ] **R5** — Do not register it while its dep's list is non-empty. Report
      the wave and segment; `gates/waves.tsv` is the orchestrator's, and the
      precedent is `gates/nushell-module-staging.sh`, written with one known
      MISS and registered only once that MISS was closed.

## Acceptance
- [ ] The check runs and reports per node, with a `done`-but-unproven node
      quoted as a named failure.
- [ ] A counterfactual: a `done` node with `verify: ""` is flagged, and one
      with a passing command is not.
- [ ] The advisory check's header carries all five reasons it is not the gate.
- [ ] The wave and segment reported, and `gates/waves.tsv` **unmodified** —
      md5 quoted before and after.

## Out of scope
- Fixing any node's proof.
- Registration, held until the dep's list is empty.

## The census, run 2026-08-24

Population derived from `find prds -name prd.md` with a frontmatter-scoped
reader that stops at the closing `---`. Never from a list. The board moved
during the run: `AGENTS.md` was rewritten mid-sweep by another lane and
committed as `872d7b0`, and `tests/nvim-lsp.sh` was dirty throughout.

| measure | value |
|---|---|
| nodes | 147 |
| `state: done` | 116 |
| `done` with `verify: ""` | **22** |
| `done` with a non-empty `verify:` | 94 |
| distinct commands behind those 94 | 60 |
| `done` nodes sharing a command with another node | **49 of 94** |
| of the 22, carrying a written reason for the empty field | **1** |
| `done` nodes with no `task:`, unreachable from `gates/waves.tsv` | **50 of 116** |
| R4's advisory path-existence misses, all 147 | **0** |

58 of the 60 commands were executed serially, ~35 minutes.
`just gate-selftest && just gates` was **not** run — `gates/justfile:31-32`
makes `gate-selftest` a one-line recipe over `gates/selftest.sh`, which
measured rc 1, so the `&&` short-circuits and the node is red without the
~50-minute half. `04-shell/07-quicklist`'s value was run on its own.

**36 of 116 `done` nodes — 31% — fail R1 as written.** 22 on the non-empty
half, 14 on the exit-0 half.

### The 14 exit-code reds

| node | command | rc | what failed |
|---|---|---|---|
| `corrections/gate-artifact-leakage` | `bash gates/selftest.sh` | 1 | 3 FAILs, 2 of them concurrent-lane artifacts |
| `corrections/gates-lib-anchored-lookup` | same | 1 | same run |
| `corrections/phrase-sweep-selftest-inversion` | same | 1 | owns the real half — `retired-phrases.sh --selftest` rc 1 |
| `corrections/lsp-gate-parser-seed` | `bash tests/nvim-lsp.sh` | 1 | `race/R1 … got 0/10`, from a **`claimed`** lane's uncommitted edit |
| `03-editor/09-lsp` | same | 1 | same |
| `corrections/mi-lowercase-verify-sections` | its own `verify-census.py --check` | 1 | 1 carrier: a `.mi/gantt/plan.json` string inside a sentence saying it is retired |
| `corrections/w0-4-s2-corrections/help` | its own `verify.sh` | 1 | `FAIL spec04 block 2`, 1 of 5 |
| `corrections/w0-4-s2-corrections/shell` | its own `verify.sh all` | 1 | `39/42 (3 FAILED)`: TV-8, TV-11, TV-12 |
| `00-delivery/parallelization` | `check-waves.py` | 1 | `FAIL A6 task id(s) outside the adversarial-verify table` |
| `00-delivery/work-breakdown` | `check-tables.py` | 1 | **crash** — `ValueError: could not convert string to float: '45m'`, line 521 |
| `02-terminal/06-launchd-path` | `bash tests/wezterm-launchd-path.sh` | 1 | `94 run, 93 passed, 1 failed` — `spawn/cf2: the copy no longer seeds PATH` |
| `05-platform/03-shell-init-generation` | `bash tests/shell-init.sh` | 1 | 2 apply-stage FAILs, plus 1 board-write artifact |
| `00-delivery/verification-gates` | `just gate-selftest && just gates` | 1 | derived from the measured `gates/selftest.sh` rc |
| `04-shell/07-quicklist` | prose | 2 | `bash: syntax error near unexpected token '('` |

Five of the fourteen are **the day's, not the board's**: the three
`gates/selftest.sh` carriers and the two `tests/nvim-lsp.sh` carriers are
decided by concurrent lanes, not by their own subject.

### What R1 cannot decide, measured

| shape | nodes | evidence |
|---|---|---|
| a board-wide walker as the node's standing proof | **12** | `lualine-auto-theme-claim`, `stale-mi-keeplist-ruling`, `truncated-source-attributions`, … all `bash gates/tree-links.sh`, a markdown-link checker. Not one of the twelve is about a link |
| a whole-workspace command | 1 | `00-delivery/verification-gates`. pearde's README already calls this an unclosable box: *"it measures the tree's worst neighbour, not this node's work"* |
| a runner that reports instead of gating | 1 | `wezterm-gate-positional-lookups` → `bash gates/wave-status.sh --run 4` → **exit 0**, 524s, with `tests/wezterm-launchd-path.sh` inside it at 93/94. Wave 4 is PENDING (17/18, `C.4` blocked), and a PENDING wave reports without failing |

R1 is green on all fourteen. The prose value is the one shape it catches that
R4's advisory check cannot see — no `/` token, so there is no path to test.

### Two structural facts R2 and R5 do not account for

**No wave cell can hold this check.** `gates/waves.tsv` rows are keyed by task
id; 50 of 116 `done` nodes carry no `task:`, every `corrections/*` and
`decisions/*` among them. Only `sweep()` reaches the population — and
`sweep()` **re-enters**: `sweep()` → the proof gate →
`00-delivery/verification-gates`' verify → `just gates` →
`wave-status.sh --sweep`, unbounded. `wezterm-gate-positional-lookups` repeats
the shape one level down. A named re-entrancy exclusion, reported as SKIPPED,
is mandatory.

**Spec-level proof cannot be resolved mechanically.** Spec files come in three
shapes: delimited (`---`), bare (`verify:` on line 1, no delimiters), and none
at all — `decisions/tinty/specs/spec03.md` opens `# spec03 — …` and carries
`verify: ""` at line 183 **and** the retired command at line 210. A reader
ported from `node_state()` sees zero of the last two. R1's scope — `prd.md`
frontmatter — is the only readable surface, and the "standing-proof convention"
this node inherited from `done-nodes-without-proof`'s closeout therefore means
moving one command into `prd.md` per node, in a field only the orchestrator
writes.

### R5's registration condition is unsatisfiable

R5 says *"do not register while its dep's list is non-empty"*.
[`done-nodes-without-proof`](../done-nodes-without-proof/prd.md) is `done` and
its list is 22 — larger than the eighteen the deferral was written against —
because its own Out of scope forbade it from closing any: *"Writing any missing
proof. R1 reports; each is its own node."* Those nodes were never filed.

## Questions

Asked 2026-08-24, from the census above.

Question *Q1*: **What happens to the 22 `done` nodes whose `verify:` is `""`?**
R1's non-empty half fails on all 22 the moment the gate runs, and
`AGENTS.md:250` defines the field's `""` as exactly what the gate would
report: *unproven*. Only 1 of the 22 records a reason.

(a) **Write a standing proof for each.** 20 nodes of work, one node each — the
    dep already argued 2 are structural (`w0-4-s2-corrections`, a parent whose
    children carry the proof; `homebrew-bootstrap`, absorbed into P.2). The
    gate then lands clean and `done` means what the board says it means.
(b) **Make the reason the requirement.** `verify: ""` stays legal when the body
    records why, and the gate asserts the reason. 21 sentences to write —
    editorial, not engineering — but a sentence is not a check.
(c) **Narrow R1 to the second half.** Non-empty ⇒ exits 0; empty is reported,
    never failed. Lands with no preparatory work, and accepts 22 permanently
    `done`-and-unproven nodes as the steady state.

Recommendation **(a) for the 20, (b) for the 2 structural ones.** The 20 are
filed as their own nodes, because this node's Out of scope ("Fixing any node's
proof") holds. The cost is visible and it is the point: (c) is the shape this
family of corrections exists to reject.

Question *Q2*: **A gate on the exit code is green on 14 proofs that measure
nothing. Is closing that this node's job, or its own?**
Twelve nodes are proved by a markdown-link walker, one by a whole-workspace
command pearde already names an unclosable box, one by a runner that reports
instead of gating. R1 passes every one.

Recommendation: **its own node, filed before this gate registers.** R1 is worth
having — it caught the prose value and eight standing reds — but registering it
while these fourteen read as proven buys a green light the board has not
earned, which is the overclaimed guard this family corrects.

Question *Q3*: **Five of the fourteen reds are today's board, not the node's.
What is the gate's rule for a live tree?**
`tests/nvim-lsp.sh` is dirty and owned by a `claimed` lane, so `03-editor/09-lsp`
and `lsp-gate-parser-seed` are red on a third node's unfinished work.
`gates/selftest.sh` reported `changed: AGENTS.md` from commit `872d7b0`, landed
mid-run. `gates/selftest.sh`'s own header already rules that a hash and a time
window cannot attribute a concurrent write and that the only cure available
today is a quiet board.

(a) **Run only on a quiet board** — the wave runner refuses when
    `git status --porcelain` names a file under `tests/`, `gates/` or `home/`,
    or when any node is `claimed`.
(b) **Report the dirty ones as INDETERMINATE**, the way `gates/selftest.sh`
    already treats the live board, and gate only on the clean set.
(c) **Run against `HEAD` in a scratch worktree**, so a lane in flight cannot
    change the verdict.

Recommendation **(c), with (b) as the fallback** — it is the only one of the
three that makes the check reproducible, and `git worktree add` over `HEAD` is
cheap. It costs the gate the ability to see uncommitted work, which is correct:
the board's claim is about what is `done`, and `done` is committed.

Question *Q4*: **R5's condition is unsatisfiable. What replaces it?**
Recommendation: **build it, run it, register it only when the check is green**,
the `gates/nushell-module-staging.sh` precedent — that gate shipped with one
known MISS recorded in its header and was registered once the MISS closed. The
red list above goes in the header so nobody reads the deferral as an oversight.
The trigger becomes a number this node can watch — reds at zero — rather than
another node's list.

## Answers

Answered 2026-08-25 by the user, all four as recommended.

Q1: **(a) for the 20, (b) for the 2 structural ones.** File 20 standing-proof
nodes; `w0-4-s2-corrections` and `homebrew-bootstrap` get a written reason
instead. This node's Out of scope ("Fixing any node's proof") still holds —
the 20 are filed as their own nodes, not fixed here.

Q2: **Its own node, filed before this gate registers.** The 14 hollow-proof
carriers (12 link-walker, 1 whole-workspace, 1 report-not-gate) are not this
node's to fix.

Q3: **(c) scratch worktree over `HEAD`, (b) INDETERMINATE as the fallback**
if the worktree approach proves impractical.

Q4: **Build it, run it, register only once green**, per the
`gates/nushell-module-staging.sh` precedent. The red list goes in the gate's
own header.

## Deferred — the tripwire, 2026-08-25

The analyst returned SPECCED (`specs/spec01.md` the R1 gate,
`specs/spec02.md` the R4 advisory check; complexity 55, blast-radius mid) —
both real and both already on disk. It also proposed ~21 further derived
PRDs for Q1/Q2 (19 standing-proof repoints + 2 policy nodes), which triggered
the board's derived-work tripwire: recounted at 12 `origin: derived` in-flight
against 12 `origin: requested` in-flight, exactly equal, and the 21 proposed
would have pushed derived to 33.

Put to the user; answer: **defer the whole derived tree, including this
node's own two specs**, rather than implement the gate now and file the
follow-ups piecemeal. Nothing in the 21-node list was filed. This node stays
`deferred` — parked, not scheduled — until the user reopens it. The two specs
on disk are real work and are not lost; `retry` (or hand-dispatch) picks them
up as-is.
