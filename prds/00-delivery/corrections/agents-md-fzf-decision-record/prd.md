---
state: open
priority: 20
est:
mode: afk
verify: "bash gates/tree-links.sh"
footprint:
  - AGENTS.md
origin: derived
from: 00-delivery/corrections/mi-rooted-verify-commands
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
- [ ] **R1** — Establish, with evidence, whether spec04's `AGENTS.md` edit ever
      existed on disk. If it is not decidable from the repository, say so
      plainly rather than inferring.
- [ ] **R2** — Write the fzf Scope-decisions bullet spec04 specifies, and
      remove the "reaching for `fzf` when television is what is installed"
      clause, keeping the `rg`/`fd` half of that sentence — spec04's own
      assertion `the rg/fd half of the idiom sentence was lost` guards it.
- [ ] **R3** — Do not touch Known gaps. Its two bullets are the state
      `decisions/tinty` spec03 left deliberately, and spec04's three
      Known-gaps assertions are retired as spent, not open.
- [ ] **R4** — `bash -c "$(the verify: in decisions/fzf/specs/spec04.md)"`
      exits 0 afterwards, or every remaining FAIL is one of the four named
      above as out of scope.
- [ ] **R5** — Report whether any other `done` node's `verify:` fails on
      `AGENTS.md` content for the same reason. `decisions/odin-toolchain`
      spec02 and `decisions/tinty` spec03 both assert over that file and were
      measured as spent on 2026-08-23; a third would make this a class.

## Acceptance
- [ ] `decisions/fzf/specs/spec04.md`'s `verify:` prints none of the five FAIL
      lines quoted above.
- [ ] R1's verdict is in this file, with the command that supports it.
- [ ] `bash gates/tree-links.sh` Tier A at 0 broken.

## Out of scope
- Reopening the fzf fork. It was settled 2026-08-21 by the user; this node
  places the record, it does not revisit the call.
- The four spent assertions in spec04's run, and spec04's `verify:` field
  itself — it is correct as `mi-rooted-verify-commands` spec01 left it.
- `AGENTS.md`'s stale chezmoi-clone address, which is
  [`agents-md-chezmoi-source`](../agents-md-chezmoi-source/prd.md)'s. That node
  is `analyzing` with `footprint: [AGENTS.md]`, so this one cannot run beside
  it — the two share the only file either touches.
