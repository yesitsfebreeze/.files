---
state: done
claim: 
priority: 30
est: 3.25h
actual: 30m
mode: afk
verify: ""
origin: derived
from: 00-delivery/corrections/gui-dies-claim-carriers
---

# A class of `verify:` commands point at paths the mi retirement deleted

Parent: [Corrections backlog](../prd.md) · net-new

Purpose: `prds/00-delivery/corrections/w0-2-terminal-respec/specs/spec06.md`
carries a frontmatter `verify:` that greps `.mi/prds/…` — a path the mi-era
retirement removed. The command **cannot run**. And
[`gui-dies-claim-carriers`](../gui-dies-claim-carriers/prd.md)'s analyst
reports it is not one file: *"every `w0-2-terminal-respec` spec carries a
`.mi/`-rooted `verify`."*

Why this matters more than a stale path: the board protocol makes `verify:`
the command that proves a node, and `verify: ""` is the documented way to say
**unproven**. A `verify` naming a deleted path is worse than an empty one — it
*looks* proven. Every one of those specs is `done`, so the board currently
records a set of nodes as verified by commands that cannot execute.

The same retirement is already the subject of
[`stale-mi-paths`](../stale-mi-paths/prd.md), which is `done` — so this is
either a gap that node left or a class it was not scoped to cover. **Establish
which before specifying**, because "we already did this" is exactly the answer
that let five `GUI launch dies` carriers survive a node claiming to have fixed
the last one.

## Requirements
- [x] **R1** — **Census first: every `verify:` in the tree that names a path
      which does not exist.** Not just `.mi/`-rooted ones, and not just
      `w0-2-terminal-respec` — the finding arrived as one file and turned out
      to be one directory, so assume the same again. Report each with its
      node's state, because a `done` node with an unrunnable `verify` is the
      serious case.
      *(a) — the census is in the body: 62 carriers, 16 nodes, all `done`,
      widened one file → one directory → 16 nodes; zero `.mi/` paths in any
      `prd.md` frontmatter (re-verified 2026-08-31: `grep -rn '^verify:.*\.mi/'
      prds` → 0).*
- [x] **R2** — Each is either repointed at the command that actually proves
      the node, or set to `verify: ""` with a one-line reason in the body.
      **Do not invent a plausible command.** An unrunnable `verify` at least
      fails loudly; a wrong one that passes is how a node stays `done` while
      unproven.
      *(a) — "Landed 2026-08-23": all 62 runnable, 26 green, 36 red, zero
      unrunnable; the four that die on the deleted `.mi/gantt/plan.json` got
      `verify: ""` plus a reason, because a replacement would be a new claim.*
- [x] **R3** — Report which of these nodes are `done` **and** now have no
      executable proof at all. That list is the actual finding of this node,
      and it may need its own follow-up per node.
      *(a) — the list is the body's reds split (32 red, 4 blanked) and is
      carried into `done-node-proof-gate`, filed as its dep: "a gate that
      starts red on 18 nodes gets switched off."*
- [x] **R4** — Establish whether [`stale-mi-paths`](../stale-mi-paths/prd.md)
      was scoped to cover frontmatter `verify:` values and simply missed
      them, or was scoped to bodies only. Say which, plainly. If it claimed
      completeness, that is the third instance of a node claiming to have
      caught the last carrier and leaving some.
      *(a) — the verdict is in the body: "stale-mi-paths did not overclaim,
      and this is not a third instance of that pattern" — bounded
      done-condition, completeness scoped to `home tests docs .gitignore`,
      and the keep-list names these carriers by name and on purpose.*
- [x] **R5** — Recommend, without building it, whether a gate should assert
      that every `verify:` names an existing path. `gates/audit-findings.sh`
      already walks every board `prd.md`, so the shape exists — but a
      `verify` may legitimately name a command rather than a file, so say
      what such a check can and cannot decide.
      *(a) — the recommendation is in the body: "build it, ship it advisory,
      and not yet" — the five reasons it cannot decide, and the stronger
      property (every `done` node's `verify:` non-empty and exits 0) filed as
      `done-node-proof-gate`.*

## Acceptance
- [x] The R1 census in the report: every offending `verify:`, its node, its
      state, and what it became.
      *(a) — the census is the body's "62 carriers, 16 nodes, all `done`",
      with the per-node outcome in the "Landed" section (26 green / 36 red /
      zero unrunnable).*
- [x] The R3 list of `done`-but-unproven nodes, explicitly.
      *(a) — the list is the body's reds split and the four blanked
      `verify: ""` cases, carried into `done-node-proof-gate` as its dep.*
- [x] R4's verdict on `stale-mi-paths`, with the evidence.
      *(a) — the verdict and its evidence are in the body's "Corrected and
      settled at spec time" section 3.*
- [x] `bash gates/tree-links.sh` Tier A at 0 broken, asserted as a delta.
      *(a) — run 2026-08-31: `TREE (gating) checked 1773 links in 552 files,
      0 broken`; the 2026-08-23 run in the body quoted 874/143/0 — the tree
      has grown, the delta is still 0.*

## Out of scope
- Re-running any node's proof. This node fixes the pointer; whether the thing
  was ever proved is R3's report and a per-node question.
- Building the R5 gate.

## Corrected and settled at spec time, 2026-08-23

**Three things in this PRD were wrong, and one of them was mine to be wrong
about twice.**

**1. "Worse than an empty one, because it *looks* proven" is true of the
record, not of the command.** The analyst ran all 62 carriers as written: 50
measured, and **none exits 0** (31×1, 15×127, 4×2). Nothing silently passes.
The defect is that the board *records* these nodes as verified; the commands
themselves fail loudly the moment anyone runs them.

**2. The census widened one file → one directory → 16 nodes**, and the last
carrier was found only because the sweep was not shaped like the pattern: a
fenced `## Verify` block in `stale-framework-links/specs/spec01.md` sets
`F=.mi/prds/…` and carries **no `verify:` key at all**, so a key-grep could
never see it. **62 carriers, 16 nodes, all `done`.** Zero `.mi/` paths in any
`prd.md` frontmatter.

**3. R4: `stale-mi-paths` did not overclaim, and this is not a third instance
of that pattern.** I primed the analyst to look for one, and it declined —
correctly, with explicit evidence rather than inference. That node's
done-condition is bounded to "no **shipped file, test, or gate** references a
`.mi/` path"; its completeness measurement is scoped to `home tests docs
.gitignore`, which does not include `prds`; and its spec01 keep-list names
these carriers **by name and on purpose** — *"Their verify commands, sha-pinned
assertions, and mi-era narrative describe the tree as it stood when the work
ran; rewriting them falsifies the record."* It saw them and kept them.

Manufacturing a pattern out of a node that did its job would have been the
same defect as the ones this family exists to correct, pointed the other way.

**But there is a real defect of a different kind: an unreconciled ruling.**
The keep-list's argument — rewriting a citation falsifies the record — is the
*same* argument the orchestrator overruled on that node's own PRD, the same
day, for the `note:` fields: *"The notes cite documents that were `git mv`ed
unchanged; repointing the citation is not falsifying the reading."* That Answer
never came back to the "their verify commands stay" clause written beside it.
Filed as
[`stale-mi-keeplist-ruling`](../stale-mi-keeplist-ruling/prd.md).

## The structural finding the `.mi/` rot was hiding

A mechanical repoint restores **executability to all 62** and **truth to 24**
(18 on the command rewrite, 6 more once the invoked check script is rewritten
too). **32 go red; 4 die on `.mi/gantt/plan.json`**, the schedule of record
that was deleted and whose data now lives in PRD frontmatter in a different
shape — so those get `verify: ""` plus a reason, because a replacement would
be a new claim.

The reds split cleanly, and the split is the finding: **`verify:` is doing two
different jobs on this board.** A *standing proof* that should hold forever,
and a *one-shot delta guard* from the day the node closed — "a box was closed
in `03-editor/01-options`", "an inventory was modified", "a symlink at the repo
root was replaced" — plus pinned content the board has legitimately moved past
(`84 entries` is 92 today; `want 550` lines is 577). spec02 triages that, under
the rule that a red naming **this node's own requirement** is kept and filed,
never blanked.

Four to read hardest, because their FAIL text reads as unfinished work rather
than drift: `editor/spec06` ("3 line(s) still prescribe nohlsearch"),
`editor/spec08` ("4 line(s) reference C-q"), `platform/spec01` and `spec04`
("'burrito' still appears").

## R5 — build it, ship it advisory, and not yet

**Recommendation accepted: a path-existence check on `verify:` is worth
building and must not gate.** It would have caught all 62 carriers plus the 2
mode-126 cases. What it cannot decide, with the last reason being the one that
settles it:

1. A verify may legitimately name a **command**, not a file — `just
   gate-selftest`, `help --check` — which is most of the board's interesting
   values.
2. **Forward-looking paths are correct**: five today name the test their own
   spec will create. Telling them apart needs reading `footprint` — a
   heuristic, not a proof.
3. It cannot see **one level down**: 16 carriers were broken *inside* the
   script the verify invokes.
4. It cannot see the **fenced form** — the same one-dimensional mistake in a
   new costume.
5. **Existence is not truth.** After spec01 every path exists and Tier A is
   green — and **37 of 62 verifies still prove nothing.** A gate asserting
   "every verify names an existing path" would go green on a board where most
   of these `done` nodes' proofs are spent. That is precisely the overclaimed
   guard this family of nodes is about.

**The stronger property, to gate eventually:** every `done` node's `verify:`
is non-empty and exits 0. Decidable, and it is what the board actually cares
about. Deferred deliberately — its runtime exceeds ten minutes, so it belongs
in the wave runner, and R3's list must be worked down first: **a gate that
starts red on 18 nodes gets switched off.** Filed as
[`done-node-proof-gate`](../done-node-proof-gate/prd.md), dep on that list.

## Landed 2026-08-23 — all three specs

**spec01 and spec02 by the implementer; spec03 by the orchestrator** (five
`prd.md` frontmatter values, which is why it was never the worker's). Verified
after: `grep -rn '^verify:.*\.mi/' prds` → **0**;
`bash gates/tree-links.sh` → exit 0, Tier A **874 links / 143 files / 0
broken**, Tier B 114 unchanged.

**All 62 are runnable. 26 green, 36 red, zero unrunnable** — no 127, no 126,
no 2.

**26 green, not the projected 24, because the implementer found a script the
spec did not name.** `w0-4-s2-corrections/backlog-closeout/specs/lib.sh`
encoded the old tree's **depth** — `…/../../../../../../..`, seven levels,
correct under `.mi/prds/…` — so a pure token rewrite left every
backlog-closeout check reading `/Users/feb/dev/prds/…`. Fixed to six levels,
and three specs went from "17 / 33 / 23 FAILs" to **exit 0**. Those FAIL
counts were artifacts of a wrong `REPO`, not drift. That is the difference
between repointing a path and repointing a *derivation*.

**The four reds I flagged to read hardest are all drift, and the reasoning is
better than the verdict.** `editor/spec06`'s three `nohlsearch` hits are in
spec files written *later*, and one of them is literally the non-port record —
`01-options/specs/spec01:79`, *"no `<Esc>` → `nohlsearch` map is added"* — too
many words from `nohlsearch` to match the guard's own exemption. Same shape for
`editor/spec08` (`<C-q>` restated by the node that leaves it unbound),
`platform/spec01` (a counterfactual proof record naming `burrito`) and
`platform/spec04` (`burrito` listed among items *verified absent*). **In every
case the guard is matching the record of the work it was checking for.**

**`gate-home-isolation/spec03` was measured, not skipped** — run deliberately
and alone, ~13 min, with an md5 net that turned out unnecessary: the carrier
restored the board spec file it probes, byte-identical, 0 probe lines left.

**One true red, and it is a real regression on a `done` node.**
`decisions/fzf/specs/spec04.md` fails five assertions naming **its own
requirement on its own file**, and I verified it independently:

```
$ grep -in fzf AGENTS.md
96:prevents the standard failure mode: reaching for `fzf` when television is what
```

Exactly one line — **the sentence spec04 was written to remove.** No fzf
scope-decision bullet exists anywhere in `AGENTS.md`. So `decisions/fzf` is
`done` and its `AGENTS.md` edit never landed. Its other four FAILs *are*
spent. Filed as
[`agents-md-fzf-decision-record`](../agents-md-fzf-decision-record/prd.md),
and I added `footprint: [AGENTS.md]` to it so the overlap check serialises it
against [`agents-md-chezmoi-source`](../agents-md-chezmoi-source/prd.md),
which is `analyzing` on the same file.

**Three boxes stayed open with honest reasons**, and one was unsatisfiable as
written: it demanded zero `.mi/` tokens in a file whose fifteen *other*
references spec01's own prose orders preserved — several, like
`.mi/workflows/refs/laws.md`, have no successor at all. The intended property
was proved instead. A second reads `missing=4` rather than 0: three are
spec03's protected forward-looking `tests/nvim-{keymaps,small-plugins,markdown-tables}.sh`
and one is the tokenizer reading a prose `AGENTS.md/CLAUDE.md` inside a FAIL
message as a path. The third, `git diff --stat`, is unmeasurable because all
61 carriers are untracked.

**A note on the final task notification:** it arrived as `failed` with an API
sleep error, from a **stale poller** after the carrier had already delivered
its full DONE report. The work is verified on disk by the checks above, so the
node closes on evidence rather than on the notification.
