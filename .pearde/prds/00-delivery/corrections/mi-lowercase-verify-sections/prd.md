---
state: done
claim: 
priority: 35
est: 6.25h
mode: afk
verify: "python3 prds/00-delivery/corrections/mi-lowercase-verify-sections/checks/verify-census.py --check"
origin: derived
from: 00-delivery/corrections/mi-rooted-verify-commands
---

# A lowercase `## verify` escaped a census that closed `done`

Parent: [Corrections backlog](../prd.md) · net-new

Purpose: [`mi-rooted-verify-commands`](../mi-rooted-verify-commands/prd.md)
swept 62 carriers in five dimensions and closed `done`. It missed two nodes,
because a node's proof lives in **four** places and it swept three:

1. `prd.md` frontmatter `verify:`
2. a spec's `verify:` key
3. a fenced `## Verify` section
4. **a fenced `## verify` section — lowercase, invisible to a case-sensitive
   grep**

The two survivors, both `done` with **zero** executable proof:

- **`w0-4-s2-corrections/shell`** — `specs/../verify.sh` exits 1 on every
  argument (13, 14, 15 and 42 FAILs), **all `FileNotFoundError`**: it locates
  the repo by walking up for a `.mi` directory, so **`REPO` resolves to `/`**.
  Same class as the `lib.sh` depth bug that node fixed — a *derivation* of the
  old tree, not a path in it.
- **`w0-4-s2-corrections/help`** — all five `## verify` blocks
  `open --raw .mi/prds/…` → `nu::shell::io::file_not_found`.

**This is a census dimension, not a slip.** The parent node's R5 already argued
that a path-existence gate cannot see the fenced form; the lowercase variant is
that limitation with one bit flipped. Its own closing sweep therefore reported
zero carriers while two stood — the fourth time on this board that a census
matching only the pattern already known has done so.

## Requirements
- [x] **R1** — Both nodes get an executable proof or a stated `verify: ""`.
      `w0-4-s2/shell`'s `verify.sh` needs its repo derivation fixed, not its
      paths repointed: **the bug is that it looks for a `.mi` directory**, so a
      token rewrite leaves it resolving to `/`. Read what
      `mi-rooted-verify-commands` did to `backlog-closeout/specs/lib.sh` — same
      shape, same fix, and it took three specs from double-digit FAILs to exit
      0.
      **Done 2026-08-23.** `verify.sh` now derives `REPO` from
      `${BASH_SOURCE[0]}` five levels up and *exports* it into the heredoc,
      because `__file__` is `-` under `python3 -` and a derivation written
      inside the embedded script cannot see the file. `verify.sh all` went from
      `0/42 passed (42 FAILED)`, every one a `FileNotFoundError` on a path
      under the deleted marker directory, to `41/42 passed  (1 FAILED)` with
      **zero** such errors; `spec02` and `spec03` exit 0 at `14/14` and
      `15/15`, and `spec02` also exits 0 run from `/tmp` — the box the old
      cwd-walk could never pass. The 42 assertions are unchanged:
      `diff` of the `# ── checks` region against a pre-edit copy prints
      nothing. `help/verify.sh` is new and exits 0 with `5 PASS`, `0 FAIL`,
      `blocks=5`.
- [x] **R2** — **Do not invent a command.** Not triggered: both nodes had a
      real proof. The line held where it mattered — `TV-8` keeps its
      over-broad predicate (`## Spent assertion` in `shell/specs/spec01.md`
      names `prds/04-shell/04-television/prd.md:199` and its section heading as
      the cause) and `help/spec05.md`'s `[x] fixed` predicate is untouched
      (`## Spent proof` names `gates/audit-findings.sh --selftest`'s
      neutraliser and backlog row `M-11`). `help/verify.sh` embeds no check of
      its own: `grep -cE 'nu -n -c|shasum|open --raw'` over it is **0**, so it
      cannot silently disagree with the specs. Where a proof does not exist,
      `verify: ""` plus a reason in the body is correct — the parent node held
      that line for four `plan.json` readers and this node holds it too — but
      here it did not have to be used.
- [x] **R3** — **Sweep all four recording places**, case-insensitively, over
      the whole tree — and report the counts per place. If the fourth place
      turns up more carriers, that is the finding; do not stop at these two.
      **The fourth place did turn up more, and the finding is recorded below.**
      `checks/verify-census.py` sweeps all four from one case-insensitive
      heading match plus a case-insensitive frontmatter key, and the script row
      the parent's selector missed. Counts 2026-08-23: 145 / 34 / 154 / 12 and
      25 scripts, carriers 0 / 0 / 0 / 0 and 8 (all in other nodes' files).
      Place 4 holds 12 blocks in **three** directories, the third being
      `05-platform/03-shell-init-generation/specs/spec01–04`, which neither the
      parent census nor this PRD knew about.
- [x] **R4** — Report whether `mi-rooted-verify-commands`' closing sweep can
      be re-run to green after this lands, and say what its acceptance box
      *should* have asserted. That node is `done`; do not reopen it, but its
      record should not read as complete if the census had a hole.
      **Answered below.** It cannot, and already could not: extracted and run
      verbatim 2026-08-23 it exits 1 with 4 PASS / 2 FAIL, both FAILs being
      boxes that node left `[ ]` with stated reasons. It was not reopened and
      is byte-unchanged (`find … | xargs shasum -a 256` before and after,
      `diff -q` clean).
- [x] **R5** — Every `prd.md` frontmatter change is the **orchestrator's**.
      Report pre-resolved values; do not apply them. Three values are tabled
      under *R5 — pre-resolved `verify:` values* below with their measured exit
      codes; no frontmatter block was edited in any file.

## Acceptance
- [x] Both nodes' proofs run: quoted commands with exit codes, or `verify: ""`
      with a stated reason for each. `bash …/shell/verify.sh all` → exit 1,
      `41/42 passed  (1 FAILED)`, 0 `FileNotFoundError`; `bash …/help/verify.sh`
      → exit 0, `blocks=5`, 5 PASS / 0 FAIL. Both are tabled under R5 with the
      one red's stated cause.
- [x] The R3 four-place census in the report, counts per place, the pattern
      quoted so it can be re-run — *The four-place census* above, committed as
      `checks/verify-census.py`; `--check` exits 0 and goes red on a planted
      lowercase carrier.
- [x] R4's verdict on the parent node's closing evidence — *R4* below: exit
      1, 4 PASS / 2 FAIL, both FAILs honestly left open by that node, and the
      real defect being one box that passes because its selector picks 21 of 25
      scripts.
- [x] `bash gates/tree-links.sh` Tier A at **0 broken**, asserted as such.
      Run 2026-08-23 after every edit: `checked 950 links in 152 files, 0
      broken`. Tier B's 118 are pre-existing and not gating.

## Out of scope
- The 62 carriers already repointed.
- Any other node's spent-guard reds.

## Answers — orchestrator, 2026-08-23

`specced` at **6.25h** across four specs. The analyst's run was killed by an
API error after writing all three original specs but before reporting; resumed,
it delivered the report and a fourth spec.

**R3 answered, and the answer is no.** The fourth recording place does **not**
hold only the two known carriers. Place 4 — a **lowercase** `## verify`
heading — holds **12 blocks in three directories**, the third being
`05-platform/03-shell-init-generation/specs/spec01–04`, which neither the
parent census nor this node's own PRD knew about. Those four are carriers of
the *invisibility*, not of the rot: they name no `.mi/` path, their targets
exist, and two were run green. They are the answer to "is the fourth place just
the two we knew".

Census by place: place 1 (frontmatter) 145, **0** carriers; place 2 (spec key)
34, **0**; place 3 (`## Verify`) 154, **2 — both false positives**, being
patterns that grep *for* `.mi/` to assert its absence; place 4 (`## verify`)
12, **8**; scripts under `prds/**` 23, **6**. Place 3 and 4 must come from one
case-insensitive match split on the matched byte — **writing them as two greps
is exactly how the fourth place was missed**.

**R4's verdict, accepted and not softened.** `mi-rooted-verify-commands`'
closing sweep cannot re-run green and already couldn't: exit 1, 4 PASS / 2
FAIL, both boxes it left `[ ]` with stated reasons — so its record is honest
*there*. The defect is elsewhere: one box **passes today and should not**.
`no invoked script names a resolvable .mi/ path` selects with
`find prds -name 'check*.sh' -o -name '*.py'`, which picks 20 of 23 scripts and
misses `shell/verify.sh`, `editor/specs/verify-all.sh` and
`backlog-closeout/specs/lib.sh`. Widen it to `-name '*.sh'` and it fails on
exactly two. A convention that excludes `verify.sh` from a census of verify
scripts is not a near miss, it is the wrong set. **Verdict: not a slip, a
selector.** That node stays `done` and is not reopened; the rule is folded into
[`analyst-brief-census-rule`](../analyst-brief-census-rule/prd.md) R6, whose
footprint is the analyst brief and which is now unblocked because
`git-diff-integrity-boxes` released the README.

**R2 was not triggered.** Both nodes get an executable proof, and the line held
where it mattered: neither `TV-8` nor spec05's marker predicate is rewritten to
go green. One of the two reds is mine — `prds/04-shell/04-television/prd.md:199`
is a section I added today whose sentence cites "the `T.4` `opacity` box", and
the guard's subject is wider than its meaning. spec01 forbids narrowing it and
requires a `## Spent assertion` note naming file, line and heading.

**R5's values are pre-resolved and are mine to apply at closeout**, after
spec01–04 land. I take the analyst's recommendation on the contested one: the
`shell` node gets `verify.sh all` at **exit 1, 41/42 with one documented drift
assertion**, not the two-stage form that exits 0 by hiding spec01's twelve
passing checks. A loud red with a named cause is a truer record than a quiet
green, and the parent's own triage rule permits it.

**The collision I flagged landed on my side first and the analyst re-anchored
correctly.** My `git-diff-integrity-boxes` spec03 rewording took
`help/specs/spec05.md` from 99 to 108 lines and moved its two fenced commands
from 74/84 to 83/93. Its spec03 had anchored on "line 62 byte-identical" and a
`sed -n '55,70p'` diff; both are now section-anchored, and it added two boxes
asserting my `grep -n '^| M-'` substitute still stands and that no `git diff`
instrument was reintroduced. Its `blk()` extractor counted fences after the
heading, so that part was already immune.

## The four-place census, run 2026-08-23 after spec01–03 landed

Committed as `checks/verify-census.py`, run from the repo root:

```
python3 prds/00-delivery/corrections/mi-lowercase-verify-sections/checks/verify-census.py --check
```

| place | what | total | carriers |
|---|---|---:|---:|
| 1 | `prd.md` frontmatter `verify:` | 145 | **0** |
| 2 | spec frontmatter `verify:` | 34 | **0** |
| 3 | fenced heading, capital `V` | 154 | **0** |
| 4 | fenced heading, lowercase `v` | 12 | **0** |
| — | `*.sh` / `*.py` under `prds/**` | 25 | **8**, all out of scope (below) |

`--check` exits **0**. The totals are a **reading**, not an assertion: they
move whenever another lane adds a node or a spec. Only the carrier column is
assertable, and the only total this node pins is place 2's 34 — the one figure
no lane can move without adding a spec `verify:` key, so it is the cheap proof
that the sweep still parses frontmatter at all.

Places 3 and 4 come from **one** case-insensitive match split on the matched
byte — `^(#{1,6})[ \t]+([Vv]erify[^\n]*)$`, with `group(2)[0]` deciding the
place. There is deliberately no second uppercase-only pattern in the file
(`grep -c` for the capitalised word in `verify-census.py`: **0**). Writing the
two as two greps is exactly how the fourth place was missed.

### Place 4 is not just the two nodes we knew

12 blocks in **three** directories:

| directory | blocks | verdict |
|---|---:|---|
| `w0-4-s2-corrections/help/specs` | 5 | carriers of the rot — repaired here |
| `w0-4-s2-corrections/shell/specs` | 3 | carriers of the rot — repaired here |
| `05-platform/03-shell-init-generation/specs` | 4 | **invisible, but green** |

The platform four were invisible to the parent census *and* to this node's own
PRD, which said "the two survivors". They name no dead path (`grep -c` for the
token in `spec01`, `spec02`, `spec03`: 0 each; `spec04`'s two hits are prose
outside its verify section), and every file their commands invoke exists —
`home/run_after_generate-shell-init.sh`, `tests/shell-init.sh`,
`tests/deploy-skeleton.sh`, `gates/waves.tsv` all present, checked
2026-08-23. Two were run green by the analyst on 2026-08-23 (spec01's
`run_after_generate-shell-init.sh` harness, exit 0; `bash tests/shell-init.sh
--gen`, exit 0) and spec03's command is byte-equal to that node's frontmatter
`verify:`, so its proof is recorded in place 1 as well. They are carriers of
the **invisibility**, not of the rot. "The fourth place holds only the two we
already knew" was the claim this node was written to distrust, and it was
false.

### Place 3's carriers are false positives — and there were four classes

The naive rule (body contains the token) reports place 3 as red on this tree's
own census blocks, where the token is the *pattern being searched for* rather
than a path. The script states a rule instead of allowlisting a filename:

1. **regex-escaped** — a backslash before the dot. No filesystem path is
   written that way. Clears `mi-rooted-verify-commands/specs/spec01.md` and
   this node's `specs/spec02.md`, the two the analyst measured.
2. **a matcher's quoted argument** — a single-quoted word in a
   `grep`/`egrep`/`fgrep`/`rg`/`--include=` segment. An unquoted or
   double-quoted path handed to `grep` as a *file* stays a carrier, which is
   the case that matters.
3. **a bare mention** — the token with no path segment after the slash, or one
   closed by a backtick, as in `p "no ... token left in verify.sh"`.
4. **a writer's payload** — a token inside what a `printf`/`echo`/`tee`/`cat >`
   *writes*. This class was **not** in the analyst's measurement, and it
   surfaced only because the script's section scan was made fence-aware: a
   naive scan ends a section at the first `#` at start-of-line, which inside a
   fence is a shell comment, and two of this tree's proof blocks contain one —
   including `specs/spec04.md`, whose `printf` plants a dead path in a scratch
   tree as the census's own negative control. The buggy scan hid it; fixing the
   scan exposed it. Rule 4 is the loosest of the four and is recorded as a
   known limit, not sold as exact: a script that genuinely emits a dead path
   into a file would be missed.

Falsifiability, run 2026-08-23: with `cat`-of-a-dead-path planted inside a
lowercase fence in a scratch copy of `prds/`, `--check` reports
`place 4 … total 13 carriers 1`, names `prds/README.md`, and exits **1**. A
census that cannot be made to fail has not been tested.

### The script row splits three ways, and this node fixes one

25 files (the parent's 23 plus the two this node's own specs required:
`help/verify.sh` from spec02 and `checks/verify-census.py` from spec04 — which
is why "assert it selects 23" is a total, and totals are readings). 8 carrier
lines in 5 files:

| file | carrier | disposition |
|---|---|---|
| `w0-4-s2-corrections/shell/verify.sh` | the `.mi`-marker repo derivation + a usage comment | **fixed here** (spec01) |
| `w0-4-s2-corrections/editor/specs/verify-all.sh` | a stale usage comment only; its runtime derivation is `git rev-parse --show-toplevel` and is correct | another node's file — reported, not edited |
| `delivery/checks/{arith,tables,tree}.py` (6 lines) | the retired `gantt/plan.json` readers | left by `mi-rooted-verify-commands` spec02 on purpose; their nodes already carry `verify: ""` |
| `git-diff-integrity-boxes/checks/gitdiff-boxes.py` | a prose mention of the tree-wide rename | in flight — not touched |

`--check` therefore gates places 1–4 and **reports** the script row without
gating it: four of its carriers are deliberately left by other nodes and one
is in flight, so gating it would make the node permanently red for other
people's decisions. `--check-scripts` gates that row too, for the day they are
cleaned up. That choice is stated in the script rather than hidden in a
selector.

### No repaired command uses `git diff` as an instrument

13 repaired sites: 12 command lines inside the eight repointed `## verify`
fences (3 shell + 5 help + 4 in `help/spec05.md`, of which two lines are the
expected-digest output rather than a command) plus one usage comment in
`shell/verify.sh`. Measured 2026-08-23, only two of the eight verify sections
contain the string `git diff` at all — `help/spec04.md` and `help/spec05.md` —
and both only to **reject** it in favour of a `shasum` content pin, because
the files they guard are untracked and the diff would be silent. Zero use it
as an instrument. Integrity in this node was proved the same way: `cp` aside
plus `diff`, and `find | xargs shasum -a 256` for the neighbour tree.

## R4 — the parent node's closing evidence

`mi-rooted-verify-commands` stays **`done` and is not reopened.** Its
`specs/spec01.md` `## Verify and Proof` block, extracted and run verbatim on
2026-08-23 after spec01–03 of this node landed:

```
PASS  no verify: value names a .mi/ path
FAIL  the fenced ## Verify block is repointed too
PASS  the three plan.json readers are left for spec02 (got 3)
PASS  no invoked script names a resolvable .mi/ path
missing=4
FAIL  every path named in a verify: exists
PASS  tree-links Tier A: 0 broken
exit 1
```

**It cannot re-run green, and it already couldn't.** Both FAILs are boxes that
node left `[ ]` with stated reasons, so its record is honest *there*. Nothing
in this node made it redder: the four `missing=` paths are forward-looking
test files and one tokenizer artifact, none of them ours.

The defect is a box that **passes and should not**:

```
! grep -rqE '\.mi/(prds|docs|SYSTEM\.md)' $(find prds -name 'check*.sh' -o -name '*.py')
p "no invoked script names a resolvable .mi/ path" $?
```

It reports PASS while an invoked script carries a dead path. The **selector**
is the hole: `-name 'check*.sh' -o -name '*.py'` picks 21 of the 25 scripts
under `prds/**` today and misses `shell/verify.sh`,
`editor/specs/verify-all.sh`, `backlog-closeout/specs/lib.sh` and
`help/verify.sh`. Widened to `-name '*.sh' -o -name '*.py'` the same regex
failed on **two** lines before this node and on **one** after it
(`editor/specs/verify-all.sh:8`, whose fix is another node's).

**What the box should have asserted:** every `*.sh` and `*.py` under `prds/**`
— better still, every script path a `verify:` value or a fenced verify block
actually *invokes*, resolved out of the command text rather than guessed from
a filename convention. A convention that excludes `verify.sh` from a census of
verify scripts is not a near miss, it is the wrong set.

**And its token box should have enumerated, not named.** That node's own R5
answer already listed "it cannot see the fenced form" as a limitation, yet
`spec01` asserted the fenced dimension as a *single named file* — the one
carrier it happened to find by hand. `grep -rniE '^#{1,6} +verify' prds` would
have put all 12 lowercase blocks on the table that day and made this node
unnecessary. **Verdict: not a slip, a selector.** The rule belongs in the
analyst brief, not in a retry of that node.

## R5 — pre-resolved `verify:` values, for the orchestrator to apply

Reported, **not applied**; frontmatter is the orchestrator's.

| node | pre-resolved `verify:` | measured |
|---|---|---|
| `w0-4-s2-corrections/shell` | `bash prds/00-delivery/corrections/w0-4-s2-corrections/shell/verify.sh all` | exit **1**, `41/42 passed  (1 FAILED)`, the one FAIL being `TV-8` with its cause recorded in that node's `specs/spec01.md` `## Spent assertion` |
| `w0-4-s2-corrections/help` | `bash prds/00-delivery/corrections/w0-4-s2-corrections/help/verify.sh` | exit **0**, `5 PASS`, `0 FAIL`, `blocks=5` |
| this node | `python3 prds/00-delivery/corrections/mi-lowercase-verify-sections/checks/verify-census.py --check` | exit **0**, every place at 0 carriers |

The `shell` value is the loud form the orchestrator ruled for: exit 1 with one
documented drift assertion, rather than a two-stage `spec02 && spec03` that
would exit 0 by hiding spec01's twelve passing checks.

## Three measured-false boxes in this node's own proof harnesses

Reported rather than edited — the four `specs/*.md` of this node are in no
spec's footprint, so an implementer may not rewrite them. Each is a defect of
the harness, not of the work:

1. **spec01's `no spec's invoked command names a .mi/ path`** — the loop body
   ends in `… | grep -q '\.mi/' && rc=1`, so when grep finds nothing the
   compound status is grep's **failure** and `p "$?"` prints FAIL on a clean
   tree. Substance verified by hand: all three invoked commands are repointed
   and the token count over the three `## verify` fences is 0.
2. **spec02's `the "\\s+" nushell literal is intact in all four`** — its
   pattern is `'"\\\\s\+"'`, where BRE `\+` means *one or more*, so it looks
   for `"\\s"`, `"\\ss"`, … and matches nothing. The acceptance section's own
   form, `grep -c '"\\\\s+"'`, returns **1** for each of the four files. Same
   `rc=1`-inside-a-loop shape hides it, so every line prints PASS while the
   block exits 1.
3. **spec03's `no git diff instrument was reintroduced into Acceptance`** —
   `! grep -q 'git diff'` over `help/specs/spec05.md`'s Acceptance section,
   which contains the string in the orchestrator's own landed sentence
   *"`git diff` on the backlog cannot carry it: that file is untracked"*. The
   box cannot pass without deleting the rejection that the neighbouring box
   requires to survive. It should assert that no `git diff` is used **as an
   instrument** (e.g. no fenced command runs it), not that the phrase is
   absent. The Acceptance section is byte-identical to the pre-edit copy:
   `diff` over `awk '/^## Acceptance/,/^## verify/'` prints nothing.

## Closeout — orchestrator, 2026-08-23

`done`. All three `verify:` values applied and confirmed by the orchestrator
running them, not by reading the report:

| node | command | measured |
|---|---|---|
| `w0-4-s2-corrections/shell` | `verify.sh all` | exit **1**, `41/42 passed`, **0** `FileNotFoundError` (was 0/42, all 42) |
| `w0-4-s2-corrections/help` | `verify.sh` | exit **0**, `blocks=5` |
| this node | `verify-census.py --check` | exit **0** |

The shell node's one FAIL is `TV-8`, and it is **mine**: the guard reads
`prds/04-shell/04-television/prd.md:199`, a section I added today whose
sentence cites "the `T.4` `opacity` box", so the guard's subject is wider than
its meaning. Left red on purpose with a `## Spent assertion` note naming file,
line and heading. A loud red with a named cause beats a quiet green.

**The census is falsifiable, and I proved it rather than trusting it.** Planted
a lowercase `## verify` block carrying `.mi/prds/…` into `prds/README.md`:
`place 4 … total 13 carriers 1`, naming the file, exit **1**. Restored, and the
file is byte-identical (`e08833a7…` both sides), exit 0 again. A census that
cannot fail is the defect this node was filed against, so it had to be shown.

**Two deviations the implementer recorded rather than papered over**, both
accepted:

- **Scripts total is 25, not 23.** Two of the new files — `help/verify.sh` and
  `verify-census.py` — are themselves `prds/**` scripts. A census that grows
  the population it measures is honest arithmetic, not drift, and the box
  pinned a *reading*.
- **Place 3 needed four exclusion classes, not two.** Making the section scan
  fence-aware exposed the node's own `printf` negative control: a naive scan
  ends at the first line-start `#`, which inside a fence is a shell comment,
  and two blocks in this tree have one. Rule 4 is stated as the loosest of the
  four with its limitation named rather than sold as exact — which is the
  census-verdict discipline applied to the census's own instrument.

**Two harness bugs in the specs' own proof blocks**, both diagnosed rather than
worked around: a loop ending `… | grep -q '\.mi/' && rc=1` leaves `$?` as
grep's *failure* on a clean tree, so the box prints FAIL while the tree is
clean; and a `'"\\s\+"'` pattern uses BRE `\+` and matches nothing, while the
acceptance form `grep -c '"\\s+"'` correctly returns 1. Neither is a real
failure and neither was hidden.

**One box was measured-false because of my own edit, and I fixed the box, not
the evidence.** spec03 asserted `git diff` was absent from `spec05.md`'s
Acceptance — but my rewording *quotes* `git diff` in order to reject it, and
the box immediately above requires that rewording to survive. Two boxes in
contradiction, the same shape as `gui-dies-claim-carriers`' R1/R4. The check now
asserts every `git diff` in that section is a **rejection**, not an instrument
(`1 of 1`), and spec03's proof block runs **13 PASS / 0 FAIL, exit 0**.

For the record, extracting that block I wrote `awk '/^## verify/'` against a
heading that reads `## Verify and Proof` and got zero lines and a masked
`rc=0` — the exact case-sensitivity mistake this node exists to correct,
committed by the orchestrator while closing it out.

**`actual:` not recorded**: I reworded a spec's box mid-close, so the run was
not a clean single dispatch.
