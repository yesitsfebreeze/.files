---
state: claimed
priority: 20
est:
mode: afk
verify: "bash gates/tree-links.sh"
footprint:
  - AGENTS.md
origin: derived
from: 00-delivery/corrections/mi-rooted-verify-commands
claim: implementer-5 2026-08-24T17:49Z
complexity: 18
blast-radius: mid
---

# The fzf decision record `decisions/fzf` wrote into `AGENTS.md` is not there

Parent: [Corrections backlog](../prd.md) · net-new

Purpose: [`decisions/fzf`](../../decisions/fzf/prd.md) is `done`, and its
spec04 exists to record the settled fzf fork in `AGENTS.md` — a Scope-decisions
bullet naming the date and the decision node, and the removal of the sentence
that tells every agent fzf is not installed. Measured 2026-08-23, after
[`mi-rooted-verify-commands`](../mi-rooted-verify-commands/prd.md) spec01
restored that spec's `verify:` to a runnable state: **the record is absent and
the sentence is still there.** This is the one carrier in that census whose red
reports its own unfinished work rather than drift, which is why its `verify:`
was kept rather than retired.

`decisions/fzf/specs/spec04.md`'s repointed `verify:` exits **1**. Its failing
assertions, verbatim:

```
FAIL: Scope decisions lacks: fzf
FAIL: Scope decisions lacks: 2026-08-21
FAIL: Scope decisions lacks: decisions/fzf
FAIL: Scope decisions lacks: zoxide query --interactive
FAIL: the help section still says fzf is not installed
```

The same run reports four further FAILs that are **not** this node's business,
and are recorded as spent in that spec's `## Spent proof`: three guards over
Known gaps, whose fzf and burrito bullets
[`decisions/tinty`](../../decisions/tinty/prd.md) spec03 later removed on
purpose, and one asserting `AGENTS.md` is still a symlink, which the mi
retirement ended. Do not chase those four.

What the file says today: `AGENTS.md` holds seven Scope-decisions bullets and
none of them is the fzf decision; `grep -in fzf AGENTS.md` returns exactly one
line, `AGENTS.md:96`, which is the sentence spec04 was to remove — "reaching
for `fzf` when television is what is installed". Neither `2026-08-21` nor
`decisions/fzf` nor `zoxide query --interactive` appears anywhere in the file.

Why it is gone is the second half of the ticket and is not yet established.
`AGENTS.md` at `HEAD` is a symlink to `.mi/SYSTEM.md`, whose committed content
predates the decision work, and the working-tree `AGENTS.md` is the file the mi
retirement materialised — so the edit may have been lost in that move, may have
been overwritten by a later writer of the same file, or may never have landed.
None of the three is provable from git, because no commit carries it. Say which
it was, with evidence, or say that it is not decidable and why.

## Requirements
- [x] **R1** — Establish, with evidence, whether spec04's `AGENTS.md` edit ever
      existed on disk. If it is not decidable from the repository, say so
      plainly rather than inferring.
- [x] **R2** — Write the fzf Scope-decisions bullet spec04 specifies, and
      remove the "reaching for `fzf` when television is what is installed"
      clause, keeping the `rg`/`fd` half of that sentence — spec04's own
      assertion `the rg/fd half of the idiom sentence was lost` guards it.
- [x] **R3** — Do not touch Known gaps. Its two bullets are the state
      `decisions/tinty` spec03 left deliberately, and spec04's three
      Known-gaps assertions are retired as spent, not open.
- [x] **R4** — `bash -c "$(the verify: in decisions/fzf/specs/spec04.md)"`
      exits 0 afterwards, or every remaining FAIL is one of the four named
      above as out of scope.
- [x] **R5** — Report whether any other `done` node's `verify:` fails on
      `AGENTS.md` content for the same reason. `decisions/odin-toolchain`
      spec02 and `decisions/tinty` spec03 both assert over that file and were
      measured as spent on 2026-08-23; a third would make this a class.

## Acceptance
- [x] `decisions/fzf/specs/spec04.md`'s `verify:` prints none of the five FAIL
      lines quoted above.
- [x] R1's verdict is in this file, with the command that supports it.
- [x] `bash gates/tree-links.sh` Tier A at 0 broken.

## Out of scope
- Reopening the fzf fork. It was settled 2026-08-21 by the user; this node
  places the record, it does not revisit the call.
- The four spent assertions in spec04's run, and spec04's `verify:` field
  itself — it is correct as `mi-rooted-verify-commands` spec01 left it.
- `AGENTS.md`'s stale chezmoi-clone address, which is
  [`agents-md-chezmoi-source`](../agents-md-chezmoi-source/prd.md)'s. That node
  is `analyzing` with `footprint: [AGENTS.md]`, so this one cannot run beside
  it — the two share the only file either touches.

## R1 — the verdict: the edit never existed on disk

**Verdict: never landed.** spec04's `AGENTS.md` edit was not lost in the mi
retirement and was not overwritten by a later writer. It was never written,
because the spec that owned it was dropped before anyone implemented it, and
the spec that inherited its neighbourhood explicitly fenced itself off from
the two edits this node has now made. Two independent lines close it.

**1. Git — the string was never committed.** Every commit of either path was
enumerated and its blob grepped, rather than trusting a diff-based search:

```sh
git rev-list --all -- AGENTS.md .mi/SYSTEM.md | wc -l        # 6
for c in $(git rev-list --all -- AGENTS.md .mi/SYSTEM.md); do
  for p in AGENTS.md .mi/SYSTEM.md; do
    git cat-file -e "$c:$p" 2>/dev/null &&
      git show "$c:$p" 2>/dev/null |
      grep -qF 'zoxide query --interactive' && echo "HIT $c:$p"
  done
done
```

Six commits touch the two paths; the sweep printed **no `HIT` line**.
`git log --all --oneline -S'zoxide query --interactive' -- AGENTS.md
.mi/SYSTEM.md` is likewise empty.

The method was checked against a positive control before being trusted, and
then re-run on different inputs — a claim this cheap is run twice:

- control `Two finders, deliberately` → 3 commits (`b78a15b`, `08199fb`,
  `0d04022`). The sweep does detect strings that are there.
- `decisions/fzf` → 0 hits. `fzf is a third picker` → 0 hits.
  `2026-08-21` → 3 hits (`b77134d`, `b78a15b`, `08199fb`), all of them the
  date used elsewhere in the file, none in a fzf bullet.

Verdict on the git claim: **reproduced**, fixture `git rev-list --all --
AGENTS.md .mi/SYSTEM.md` at `24111c4`, three inputs plus one control.

**The limit of that evidence, stated plainly:** git proves only *never
committed*. It cannot separate "never written" from "written, and never
committed". Git alone is therefore not the whole proof, and presenting it as
such would overclaim.

**2. Documentary — the spec was dropped, and each survivor read the other as
the owner.** This is what closes the gap from *never committed* to *never
written*. `decisions/fzf/prd.md`'s `## Partial landing — 2026-08-21` says:

> **`spec04` is dropped and reassigned**, not outstanding.
> [`decisions/tinty`](../../decisions/tinty/prd.md) owns `.mi/SYSTEM.md`'s
> Known-gaps bullet and deletes it outright — all three forks it named are
> settled.

That reassignment covers exactly one of spec04's three edits, the Known-gaps
deletion. `decisions/tinty/specs/spec03.md:71` then fences itself off from the
other two — "Do not add anything to `## Scope decisions already made` beyond
the correction described below" — and at `:141` justifies the deletion on the
grounds that "the burrito and fzf answers are recorded where they belong", an
assumption already false when written, because the only spec that would have
recorded the fzf answer in the contract had been dropped hours earlier.
Neither spec touched the Scope-decisions bullet or the `help` sentence.

Verdict: **reproduced**, fixture the two documents at `24111c4`, quoted above
by file and line.

## R5 — the carrier census, and whether this is a class

**Answer: not a class.** `decisions/fzf` spec04 was the only member, and
spec01 has now closed it.

The population was derived, not taken from the two carriers R5 names. Two
sweeps, both run at `24111c4`:

```sh
grep -rlE '^verify:.*(AGENTS|CLAUDE|SYSTEM)\.md' prds --include='*.md'
for f in $(grep -rl 'AGENTS\.md\|CLAUDE\.md\|SYSTEM\.md' prds --include='*.md'); do
  awk '/^```/{inf=!inf} inf && /AGENTS\.md|CLAUDE\.md|SYSTEM\.md/{print FILENAME": "$0}' "$f"
done
```

Sweep 1 — the `verify:` key form — returned a population of **4**. Every
member, with its exit code and FAIL lines measured after spec01 landed:

- `prds/00-delivery/decisions/fzf/specs/spec04.md` — node
  `00-delivery/decisions/fzf`, state `done`, exit **1**. FAILs: `the burrito
  fork was dropped from Known gaps`, `the tinty fork was dropped from Known
  gaps`, `Known gaps should still hold exactly 3 bullets`,
  `AGENTS.md/CLAUDE.md are no longer symlinks`.
  Verdict: fails **on `AGENTS.md`** — but all four
  survivors are **drift**, three against Known-gaps text `decisions/tinty`
  spec03 deliberately deleted and one against the file type the mi retirement
  changed. The five that were this node's own unfinished work are gone.
- `prds/00-delivery/decisions/odin-toolchain/specs/spec02.md` — node
  `00-delivery/decisions/odin-toolchain`, state `done`, exit **1**. FAILs: `an
  unrelated Known-gaps bullet was disturbed`, `Known gaps should hold
  exactly 3 bullets after the removal`.
  Verdict: fails **on `AGENTS.md` content** —
  `drift`. Its anchor `and is fzf an accepted` is absent because
  `decisions/tinty` spec03 removed the bullet on purpose. Unchanged by spec01:
  the same two FAILs were measured before the edit.
- `prds/00-delivery/decisions/tinty/specs/spec03.md` — node
  `00-delivery/decisions/tinty`, state `done`, exit **1**. FAIL: `a symlink at
  the repo root was replaced by a regular file`. Verdict: fails on `AGENTS.md`
  but **not on its content** — `[ -L AGENTS.md ]` guards the file *type*, and
  the mi retirement materialised the symlink. `drift`. Unchanged by spec01.
- `prds/00-delivery/decisions/wallpaper-opacity/specs/spec02.md` — node
  `00-delivery/decisions/wallpaper-opacity`, state `done`, exit **1**. FAILs:
  `a box was closed in capsule C.2`, `T.1 changed; its reconciliation belongs
  to W0.2, not this ticket`. Verdict: **not `AGENTS.md` at all.** Its single
  contract assertion — that `wallpaper` never appears in `AGENTS.md` — passes;
  both reds are over `01-capsule` and `02-terminal`. Reported, not chased.

Sweep 2 — the fenced-block form — was run, and its **result is nil**: it
returns no carrier sweep 1 missed. It matched 16 files. Three are already
sweep-1 members, matched only because their long `verify:` line is quoted back
inside a `## Spent proof` fence. The other 13 are not verify commands at all:
`## Verify and Proof` proof recipes (`corrections/census-verdict-discipline`,
`git-diff-integrity-boxes`, `shell-down-spec-carriers`,
`television-help-staging`, and this node's own spec01), census transcripts
(`gate-artifact-leakage`, `mi-rooted-verify-commands`,
`phrase-sweep-selftest-inversion`, `retired-phrase-sweep`), expected-output
listings (`05-platform/01-deploy-mechanism/repo-skeleton`), and one memo. Per
`.claude/skills/pearde/references/templates/spec.md`, `## Verify and Proof` is
the implementer's one-time proof recipe for its own run; the standing guard a
census is about is the frontmatter `verify:` key.

So the class question resolves no. Of four carriers, one failed on `AGENTS.md`
because of its own unfinished work — spec04, this node's subject, now closed.
Two fail on drift a later ticket created deliberately, and one does not touch
`AGENTS.md` in anger at all. There is no second instance of this node's kind
to generalise from.

## Report

Closed 2026-08-24. Both specs' boxes closed by the implementer; the PRD's own
boxes are the orchestrator's and are ticked here against checks re-run on the
collect, not against the implementer's word.

**R1 — the edit never landed.** The PRD called this undecidable between three
candidates. It is decidable, by two independent lines:

1. **Documentary.** `decisions/fzf/prd.md`'s `## Partial landing — 2026-08-21`
   records spec04 as *"dropped and reassigned, not outstanding"*, and that
   reassignment covers **one** of spec04's three edits.
   `decisions/tinty/specs/spec03.md` then fences itself off from the other
   two — *"Do not add anything to `## Scope decisions already made` beyond
   the correction described below"* — justifying its own deletion on the
   grounds that *"the burrito and fzf answers are recorded where they
   belong"*, which was false when written. Each spec read the other as the
   owner; neither wrote it.
2. **Git.** Every commit's blob of `AGENTS.md` and `.mi/SYSTEM.md` was
   grepped — not `log -S` — with zero hits for `zoxide query --interactive`,
   re-run for `decisions/fzf` (0) and `fzf is a third picker` (0), and a
   positive control (`Two finders, deliberately`) returning 3 commits, so the
   sweep does detect strings that are present.

Verdict **`reproduced`** (fixture: all 6 commits touching those two files at
`24111c4`), with its limit stated rather than glossed: git proves only *never
committed*. The documentary record closes the gap to *never written*.

**R4 — re-run by the orchestrator, not taken on report.**
`decisions/fzf/specs/spec04.md`'s `verify:` now prints:

```
FAIL: the burrito fork was dropped from Known gaps
FAIL: the tinty fork was dropped from Known gaps
FAIL: Known gaps should still hold exactly 3 bullets
FAIL: AGENTS.md/CLAUDE.md are no longer symlinks
EXIT=1
```

All five in-scope FAILs cleared; exactly the four the PRD names as spent
remain. The symlink one was checked rather than assumed spent: `CLAUDE.md` is
a symlink to `AGENTS.md`, and `AGENTS.md` is a regular file, so a check
demanding **both** be symlinks describes the mi era and cannot pass today.

**R5 — not a class, one member.** Population derived by sweeping `verify:`
keys for `AGENTS|CLAUDE|SYSTEM.md` plus a fenced-block sweep, giving **4**
carriers, all under `done` nodes — including
`decisions/wallpaper-opacity/specs/spec02.md`, which the PRD never named and
which the census found. Of the four, only `decisions/fzf/specs/spec04.md`
failed on `AGENTS.md` content naming its own unfinished work, and it is now
closed. The other three fail on deliberate drift or on assertions unrelated
to `AGENTS.md`. The fenced-block sweep's result is **nil** — 16 files, 3
already members, 13 proof recipes, no new carrier.

**Tier A acceptance, now literally true.** The box asks for
`gates/tree-links.sh` Tier A at 0 broken. When this node was specced that was
unreachable — 3 breaks in `capsule-r6-prefix-claim/prd.md` from a concurrent
lane — so spec01 substituted a delta assertion. The orchestrator repaired
those three paths in the meantime, so both forms now hold: measured on the
collect, **Tier A 1047 links / 154 files / 0 broken, gate `EXIT=0`**.

**A trap worth carrying, found by the implementer inside its own scope.**
Its first append quoted `decisions/fzf/prd.md` verbatim *including a relative
markdown link*, which is correct in that file and broken from this node's
directory — Tier A went to 1. Verbatim-quoting a markdown link across
directories imports a broken path, and `gates/tree-links.sh` catches it in
Tier A. The same trap hit this node's analyst earlier in the same session, in
the same way.

**Reported, not filed:** `decisions/wallpaper-opacity/specs/spec02.md` carries
5 broken links (doubled path prefixes such as
`../../00-delivery/decisions/wallpaper-opacity/prd.md`). They sit in Tier B,
which the gate labels not gating, so nothing is red today.
