---
est: 0.75h
footprint:
  - prds/00-delivery/corrections/w0-4-s2-corrections/help/specs/spec05.md
executor: implementer
---

# spec03 — `help/spec05.md`: repoint, and record a guard pinned to a retired marker

**FOOTPRINT COLLISION — already half-resolved.** This spec's only file,
`prds/00-delivery/corrections/w0-4-s2-corrections/help/specs/spec05.md`, is also
in the footprint of
[`git-diff-integrity-boxes`](../../git-diff-integrity-boxes/prd.md)' spec03.
**That side landed first, 2026-08-23**: the fourth `## Acceptance` box no longer
says *"`git diff` on the backlog shows changes to those four rows and nothing
else"*; it now checks by `grep -n '^| M-'` before and after, because the backlog
is untracked and that diff was silent. The file grew from 99 to **108 lines** and
every anchor below is re-measured against the landed version — if the two ever
run concurrently instead of in sequence, re-measure before editing rather than
trusting a line number. Neither side's lines overlap: that spec owns the
Acceptance box at lines 58–71, this one owns the two fenced commands at lines
**83** and **93** plus one appended section.

## The repoint

Two lines, both inside a fenced block in the `## verify` section,
`.mi/prds/` → `prds/`:

| line | what |
|---|---|
| 83 | `let b = ".mi/prds/00-delivery/corrections/prd.md"` and `let k = ".mi/prds/…/help/prd.md"` |
| 93 | `shasum -a 256 .mi/prds/06-help/04-drift-check/prd.md .mi/prds/06-help/05-agent-interface/prd.md` |

Lines 16 and 18 are the "Files touched" list — record, left alone. Keep
`"\\s+"` byte-identical (a nushell double-quoted string carrying the regex
`\s+`; `"\s+"` makes nu refuse to parse).

## The digest block still passes; the nu block does not, and that is the finding

Measured 2026-08-23, repointed:

```
$ shasum -a 256 prds/06-help/04-drift-check/prd.md prds/06-help/05-agent-interface/prd.md
3d916f8a82b8c37366e9571e758cbc461942112b822cd8f527443e78cf4fcadd  …/04-drift-check/prd.md
ec2fdae537d5d22515eb7ba2a812132ee79d2c0c61e0eab9656798d682564cdc  …/05-agent-interface/prd.md
```

Both digests are the values spec05 pins, unchanged since 2026-08-21.

The nu block exits **1**:

```
rows=4 unfixed=4 open=
```

Read that carefully, because the two halves say opposite things:

- `open=` is **empty** — all four of `**R1**`…`**R4**` in `help/prd.md` are
  closed. The substantive half of the check passes.
- `unfixed=4` — none of the four backlog rows `M-13`…`M-16` contains the
  literal string `[x] fixed`.

But all four rows **are** marked fixed. They read *"**Fixed 2026-08-21** —
`w0-4-s2-corrections/help` R1"* and so on. The backlog's marker convention
changed after this node closed, and the reason is recorded in the backlog
itself, on the `M-11` row:

> The bare backticked `[x] fixed` this row carried is not a marker any gate
> recognises. … `M-11` is also the hardcoded probe of
> `gates/audit-findings.sh --selftest`, whose neutraliser re-inserts the marker
> it means to strip — `(was &)` keeps the match — so an inline marker on this
> row makes that selftest's three route counterfactuals unprovable and turns
> `--selftest` red.

So the block is a **spent one-shot guard pinned to a marker the board
deliberately retired**, which is `mi-rooted-verify-commands` spec02's Kind 2,
and its disposition there is on the record for exactly this case — a fenced
carrier with no `verify:` key gets a note beside the block, not a frontmatter
edit.

## What to do, and what not to

- Repoint both blocks. A spent guard is still repointed: an unrunnable command
  fails for the wrong reason and tells the next reader nothing.
- Append a `## Spent proof` section stating: the guard's `open=` half still
  passes; its `[x] fixed` half is pinned to a marker retired because
  `gates/audit-findings.sh --selftest`'s neutraliser re-inserts it (backlog row
  `M-11`); the four rows carry `**Fixed 2026-08-21**` instead. **Name that
  cause.** A reason reading "stale", "outdated" or "no longer applies" fails
  this spec.
- **Do not change `[x] fixed` to `Fixed`, or any other predicate.** Rewriting a
  guard's assertion so a `done` node goes green is the manufactured proof R2
  forbids, and this one would be manufactured against a convention the board
  changed for an unrelated reason.
- **Do not mark the backlog rows.** They are already marked, in the current
  convention, and `prds/00-delivery/corrections/prd.md` is not in this
  footprint.
- Do not touch the `## Acceptance` section. Its fourth box is
  `git-diff-integrity-boxes`' spec03's landed work, and reverting it to the
  `git diff` form it replaced would undo a correction.

## Acceptance

- [ ] The repointed digest block exits **0**: both digests print in order and
      match `3d916f8a…` and `ec2fdae5…`.
- [ ] The repointed nu block exits **1** printing exactly
      `rows=4 unfixed=4 open=` — `rows=4` proves it still locates the rows, and
      an empty `open=` proves the node's own four boxes are closed. A `rows=0`
      is a different failure and a finding.
- [ ] `spec05.md` carries a `## Spent proof` section that names
      `gates/audit-findings.sh --selftest` and backlog row `M-11` as the cause
      of the retired marker. A reason containing only "stale"/"outdated" fails
      this box.
- [ ] `grep -n '\.mi/' help/specs/spec05.md` returns exactly **2** lines, 16
      and 18, both outside any fence.
- [ ] The neighbour's landed rewording survives untouched. Prove by content,
      not `git diff` (`prds/` is largely untracked, so a diff box over it passes
      by observing nothing): `cp` the file aside **before the first write**, then
      `diff <(awk '/^## Acceptance/,/^## verify/' /tmp/spec05.orig) <(awk '/^## Acceptance/,/^## verify/' spec05.md)`
      prints nothing. Anchor on that section, not on a line number — the number
      moved once already. The box must still read `grep -n '^| M-'` and must not
      mention `git diff` as its instrument.
- [ ] `grep -c '"\\\\s+"' help/specs/spec05.md` is 1.
- [ ] `bash gates/tree-links.sh` Tier A: **0 broken**.

## Verify and Proof

```sh
cd "$(git rev-parse --show-toplevel)" || exit 1
rc=0
p(){ if [ "$2" = 0 ]; then echo "PASS  $1"; else echo "FAIL  $1"; rc=1; fi; }
F=prds/00-delivery/corrections/w0-4-s2-corrections/help/specs/spec05.md

# fence 1 of the ## verify section = the nu block; fence 2 = the digest block
blk(){ awk -v want="$1" '/^## verify/{s=1} s&&/^```/{n++; if(n==2*want-1){f=1;next} if(n==2*want){f=0}} f' "$F"; }

bash -c "$(blk 1)" >/tmp/h5.txt 2>&1; ec=$?
[ "$ec" = 1 ]; p "the nu block exits 1 (spent half), got $ec" $?
grep -q '^rows=4 unfixed=4 open=$' /tmp/h5.txt
p "it prints exactly 'rows=4 unfixed=4 open=' ($(cat /tmp/h5.txt))" $?

bash -c "$(blk 2)" >/tmp/h5d.txt 2>&1; p "the digest block exits 0" $?
grep -q '^3d916f8a82b8c37366e9571e758cbc461942112b822cd8f527443e78cf4fcadd ' /tmp/h5d.txt
p "04-drift-check digest matches" $?
grep -q '^ec2fdae537d5d22515eb7ba2a812132ee79d2c0c61e0eab9656798d682564cdc ' /tmp/h5d.txt
p "05-agent-interface digest matches" $?

grep -q '^## Spent proof' "$F"; p "a Spent proof section exists" $?
awk '/^## Spent proof/,0' "$F" | grep -q 'audit-findings.sh --selftest'
p "its cause names the selftest neutraliser" $?
awk '/^## Spent proof/,0' "$F" | grep -q 'M-11'
p "its cause names backlog row M-11" $?

n=$(grep -c '\.mi/' "$F"); [ "$n" = 2 ]; p "exactly 2 .mi/ record lines left (got $n)" $?
awk '/^## Acceptance/,/^## verify/' "$F" | grep -q "grep -n '\^| M-'"
p "the neighbour's reworded box still reads grep -n '^| M-'" $?
# Every `git diff` in Acceptance must be a REJECTION, never an instrument:
# the orchestrator's landed rewording says "git diff on the backlog cannot
# carry it: that file is untracked", so a bare absence test is measured-false
# and contradicts the box above it, which requires that rewording to survive.
sec=$(awk '/^## Acceptance/,/^## verify/' "$F")
tot=$(printf '%s\n' "$sec" | grep -c 'git diff')
rej=$(printf '%s\n' "$sec" | grep -c 'git diff.*\(cannot\|untracked\|not a check\|is silent\)')
[ "$tot" -ge 1 ] && [ "$tot" = "$rej" ]
p "every git diff in Acceptance is a rejection, not an instrument ($rej of $tot)" $?
[ "$(grep -c '"\\\\s+"' "$F")" = 1 ]; p "the nushell \\s+ literal is intact" $?

bash gates/tree-links.sh 2>&1 | head -5 | grep -q '0 broken'
p "tree-links Tier A: 0 broken" $?
exit $rc
```
