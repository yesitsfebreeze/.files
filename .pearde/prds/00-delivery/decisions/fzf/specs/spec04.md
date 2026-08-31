# spec04 — Stop the working contract from teaching the old answer

est: 0.5h

## Goal

`.mi/SYSTEM.md` is the working contract every agent reads before touching
this repo (`AGENTS.md` and `CLAUDE.md` are symlinks to it). It is wrong about
fzf in two separate places, and both are load-bearing:

1. **`## Known gaps`** still says *"**Three scope decisions are blocked on
   the human** (task D.1): … and is fzf an accepted exception to 'tv owns
   every picker' or replaced."* It is now two, and this one is answered. A
   stale gap is worse than a missing one: it invites a second round of a
   question a person already settled, and `## Known gaps` opens by scoping
   itself to things "recorded so nobody mistakes them for finished work".
2. **The `help` section**, line ~93, gives the canonical example of the
   failure `help` exists to prevent as *"reaching for `fzf` when television
   is what is installed"*. fzf **is** installed — P.2 R7 requires it, and
   this decision is why. The one sentence in the contract that teaches
   agents not to guess at tooling is itself guessing.

This is the same failure the decision's own answer names for `help`
(spec03), one level up: a document teaching a rule the environment does not
honour. Fixing it there and not here would leave the contract contradicting
the manual.

## Contention — this spec is the contended one, hold it if you must

Three separate hazards. Read all three before claiming.

- **`## Known gaps` bullet 2 is shared with two still-open decisions.**
  It names burrito (D.1a) and tinty (`decisions/tinty`, D.1b, currently
  `state: analyzing`) alongside fzf. This spec **rewrites the bullet down to
  two and must not answer either of them** — the verify asserts both survive.
  Serialise against `decisions/tinty`; whichever of the three lands last
  removes the bullet entirely.
- **`decisions/odin-toolchain`'s spec02 has a guard this spec deliberately
  breaks.** Its verify contains
  `grep -qF "and is fzf an accepted" .mi/SYSTEM.md`, labelled *"an unrelated
  Known-gaps bullet was disturbed"* — written to stop an unrelated spec
  touching our bullet, and correct at the time. Once fzf is decided, that
  string is a guard on a stale sentence. **Do not edit
  `decisions/odin-toolchain/specs/spec02.md`** — it is another ticket. Report
  it to the orchestrator so the owner retires the guard; its sibling check
  (`Known gaps holds exactly 3 bullets`) still passes after this spec, so the
  string is the only collision.
- **`.mi/SYSTEM.md` had uncommitted modifications at speccing time**
  (`impl-D-2` was mid-edit on the Odin gap bullet, which is why `## Known
  gaps` already shows three bullets and not the four `AGENTS.md` describes).
  Run after `decisions/odin-toolchain` is released, and re-read the section
  before editing.

## Files touched

- `.mi/SYSTEM.md` — two edits, described below. Edit the **target**, not the
  `AGENTS.md` / `CLAUDE.md` symlinks; replacing a symlink with a regular file
  is a silent fork of the contract.

Nothing else. Not `.mi/prds/README.md` — its `## Excluded` list is for
`DO NOT PORT` decisions, and this is not an exclusion; fzf is being *kept*.

## What to write

### 1. `## Known gaps` — the bullet drops to two decisions

Replace bullet 2. Keep the burrito and tinty clauses word-for-word; only the
count and the fzf clause change:

> - **Two scope decisions are blocked on the human** (task D.1): does burrito
>   or WezTerm own tabs/panes, and does tinty stay (it owns the palette
>   everything else inherits, yet is deferred as cosmetic).

Delete the fzf clause outright. Do **not** leave a "fzf was settled, see …"
pointer here — this section is for gaps, and the record lives in
`00-delivery/corrections/prd.md` decision 3 with the scope-decision statement
in step 2 below. The other two gap bullets (`02-terminal`, `03-editor/14`)
are untouched.

### 2. `## Scope decisions already made` — extend the two-finders bullet

That section already carries the sibling fact, *"**Two finders,
deliberately.** television in the shell …, telescope in the editor. They are
not to be unified."* This is where a reader looks, so extend that bullet
rather than adding an eighth:

> - **Two finders, deliberately.** television in the shell
>   ([`04-shell/04`](../../../../04-shell/04-television/prd.md)), telescope in
>   the editor ([`03-editor/08`](../../../../03-editor/08-telescope/prd.md)).
>   They are not to be unified. **fzf is a third picker and the one accepted
>   exception** to "tv owns every picker screen": `zi`/`cdi` reach it through
>   `zoxide query --interactive`, and owning that screen would mean owning
>   zoxide's frecency ranking. Decided 2026-08-21 — see
>   [`decisions/fzf`](../prd.md) and the
>   invariant it amends, [`04-shell`](../../../../04-shell/prd.md) I3.

Match the link style the section already uses (repo-root-relative, because
`AGENTS.md` is read from the root through the symlink). The bullet count in
that section stays at seven.

### 3. The `help` section sentence

*"…reaching for `fzf` when television is what is installed, `grep` when `rg`
is, or `find` when `fd` is."* Keep the `rg` and `fd` halves exactly. Rewrite
the first so it is true of an environment where both are installed — the
point was never "fzf is absent", it is "tv is the picker here":

> reaching for `fzf` when television is the picker this config drives (fzf
> is installed, but only as `zi`'s dependency)

Any phrasing works as long as the sentence no longer asserts fzf is not
installed and the other two examples survive. The verify flattens the file's
newlines before looking for the old clause, because it wraps across two lines
in the source — so a replacement that merely re-breaks the same words will
still fail.

Do not touch anything else in the file. In particular the rating-system
section, the PRD-tree table and the conventions list are out of scope.

## Acceptance

- [ ] `## Known gaps` contains no occurrence of `fzf`, and no longer says
      `Three scope decisions`.
- [ ] `## Known gaps` still names burrito and tinty, still holds exactly
      three bullets, and the `02-terminal` and `03-editor/14` bullets are
      byte-identical.
- [ ] Neither the burrito nor the tinty fork is answered by this spec — the
      bullet still describes them as blocked on the human.
- [ ] `## Scope decisions already made` names `fzf`, carries `2026-08-21`,
      links `decisions/fzf`, names `zoxide query --interactive`, and still
      opens that bullet with `Two finders, deliberately`.
- [ ] That section still holds exactly seven bullets — the fact was folded
      into the existing one, not added as an eighth.
- [ ] The `help` section no longer says fzf is not installed, and still
      carries the `grep`/`rg` and `find`/`fd` examples.
- [ ] `AGENTS.md` and `CLAUDE.md` are still symlinks to `.mi/SYSTEM.md`.
- [ ] The file still wraps at ~78 columns (tables exempt).
- [ ] `.mi/prds/00-delivery/decisions/odin-toolchain/specs/spec02.md` is
      unmodified, and its now-stale guard is reported to the orchestrator
      rather than fixed here.

verify: `bash -c 'cd "$(git rev-parse --show-toplevel)"; s=AGENTS.md; rc=0; t=$(printf "\140"); K() { awk "/^## Known gaps/{k=1;next} /^## /{k=0} k" "$s"; }; S() { awk "/^## Scope decisions already made/{k=1;next} /^## /{k=0} k" "$s"; }; K | grep -qi "fzf" && { echo "FAIL: Known gaps still lists fzf as blocked on the human"; rc=1; }; K | grep -qF "Three scope decisions" && { echo "FAIL: the bullet still counts three open decisions"; rc=1; }; K | grep -qi "burrito" || { echo "FAIL: the burrito fork was dropped from Known gaps"; rc=1; }; K | grep -qi "tinty" || { echo "FAIL: the tinty fork was dropped from Known gaps"; rc=1; }; K | grep -qF "02-terminal" || { echo "FAIL: the 02-terminal gap bullet was disturbed"; rc=1; }; K | grep -qF "03-editor/14" || { echo "FAIL: the shift-select gap bullet was disturbed"; rc=1; }; [ "$(K | grep -c "^- \*\*")" -eq 3 ] || { echo "FAIL: Known gaps should still hold exactly 3 bullets"; rc=1; }; for x in "fzf" "2026-08-21" "decisions/fzf" "zoxide query --interactive"; do S | grep -qF "$x" || { echo "FAIL: Scope decisions lacks: $x"; rc=1; }; done; S | grep -qF "Two finders, deliberately" || { echo "FAIL: the two-finders bullet was replaced instead of extended"; rc=1; }; [ "$(S | grep -c "^- \*\*")" -eq 7 ] || { echo "FAIL: Scope decisions should still hold exactly 7 bullets"; rc=1; }; tr "\n" " " < "$s" | tr -s " " | grep -qF "reaching for ${t}fzf${t} when television is what is installed" && { echo "FAIL: the help section still says fzf is not installed"; rc=1; }; grep -qF "${t}grep${t} when ${t}rg${t} is" "$s" || { echo "FAIL: the rg/fd half of the idiom sentence was lost"; rc=1; }; { [ -L AGENTS.md ] && [ -L CLAUDE.md ]; } || { echo "FAIL: AGENTS.md/CLAUDE.md are no longer symlinks"; rc=1; }; [ $rc -eq 0 ] && echo OK; exit $rc'`

**Proven RED against the current tree before being written here.** Seven
failures, exit 1: `Known gaps still lists fzf as blocked on the human`, `the
bullet still counts three open decisions`, the four missing `Scope decisions`
strings, and `the help section still says fzf is not installed`. Six checks
already pass and are survivor guards against overreach — burrito and tinty
still named, both other gap bullets intact, the three-bullet and seven-bullet
counts, the two-finders opener, the `rg`/`fd` examples, and the symlinks.
