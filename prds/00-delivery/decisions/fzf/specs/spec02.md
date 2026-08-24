# spec02 — Carve the exception into the board

est: 0.75h

## Goal

The decision's own wording is that the exception must be **"written down, not
merely tolerated"**. Right now it is tolerated in three different registers,
and all three are wrong in the same direction:

- `04-shell/prd.md` I3 states the invariant flatly — *"tv owns every picker
  screen. No hand-coded TUIs"* — with no exception. An invariant with a
  silent violation is not an invariant; the next agent who finds `zi`
  spawning fzf either "fixes" it or concludes the invariants are decorative.
- `04-shell/03-zoxide` R2 is a single clause — *"interactive picker, same
  recents logging"* — that never says which picker, so the exception is
  invisible at the site that creates it.
- `packages-installer` R7 already hard-codes the outcome with a shrug:
  *"`fzf` is required whether or not it is wanted"*. That is a decision
  smuggled in as an inconvenience. It is now a decision, so it should read
  like one.

This spec closes the node's second acceptance box — "every node listed as
gated on this decision has had its requirements reconciled with the answer".

**The gated set is exactly three nodes**, verified by
`grep -rln "decisions/fzf" .mi/prds/`:

| node | task | reconciliation |
|---|---|---|
| `04-shell/03-zoxide` | S.4 | R2 gains the mechanism and the exception |
| `05-platform/02-package-provisioning/packages-installer` | P.2 | R7's shrug becomes a stated decision |
| `06-help/04-drift-check` | H.4 | **no requirement change** — see below |

`06-help/04-drift-check` lists this node in `deps` because a drift check must
not run against an undecided world, not because any of its R1–R8 depend on
the answer: they are surface-agnostic (introspect, report undocumented /
stale / mismatched, exempt prose, allowlist noise, exit code, stay off the
hot path). What the answer changes is the *content* it checks against, and
that is spec03's `help` entry. Record this reading in the node's own PRD —
step 4 below — so "reconciled" is a checked claim rather than an omission.

The invariant edit to `04-shell/prd.md` is not on the gated list and is
required anyway: the answer names it explicitly as one of the two places the
exception must live.

## Files touched

Body text only in all three. **Do not edit any frontmatter** — the
orchestrator owns `state`, `deps`, `claim` and `verify`, and in particular
the `deps` entry naming this decision node stays until the orchestrator
clears it.

- `.mi/prds/04-shell/prd.md` — invariant **I3** only.
- `.mi/prds/04-shell/03-zoxide/prd.md` — requirement **R2** only.
- `.mi/prds/05-platform/02-package-provisioning/packages-installer/prd.md` —
  requirement **R7** only.
- `.mi/prds/06-help/04-drift-check/prd.md` — one line under `## Out of
  scope`; see step 4 for why that is the honest home and not a new
  requirement.

None of these is contended: no other in-flight ticket names them. Verify with
`git status --short` before starting.

Not this spec's: `.mi/prds/00-delivery/corrections/prd.md` (spec01),
`home/dot_config/nushell/help/**` (spec03), `.mi/SYSTEM.md` (spec04).

## What to write

### 1. `04-shell/prd.md` — I3 names the exception and its reason

Replace the I3 bullet. Keep the requirement number: other documents cite
invariants by number, and `03-zoxide` R4 already leans on the funnel pair.

- [ ] **I3** — **tv owns every picker screen, with exactly one named
      exception.** No hand-coded TUIs; new pickers are new cable channels
      plus a typed decode. The exception is **fzf**, reached only through
      `zoxide query --interactive` behind `zi`/`cdi`
      ([03-zoxide](../../../../04-shell/03-zoxide/prd.md) R2). Zoxide ships its own interactive
      mode, and replacing it with a tv channel would mean reimplementing its
      frecency ranking and its `--exclude $PWD` semantics to own one picker
      screen — so fzf stays in the required package set
      ([P.2](../../../../05-platform/02-package-provisioning/packages-installer/prd.md)
      R7) as `zi`'s dependency, never as a picker anything else may reach
      for. It is an exception and **not a precedent**: a second picker
      outside tv is a new decision, not an appeal to this one, and `help`
      documents it so the manual does not teach a rule the environment
      breaks. Decided 2026-08-21 (user), recorded in
      [decisions/fzf](../prd.md).

Keep the box open (`- [ ]`) — nothing here is implemented.

### 2. `04-shell/03-zoxide/prd.md` — R2 says which picker, and why

Replace R2, keeping its number and its recents clause:

- [ ] **R2** — **`zi`** (and the `cdi` alias) — interactive picker, same
      recents logging as R1. It shells out to `zoxide query --interactive`,
      which spawns **fzf**; it is *not* rewritten against a tv-backed
      picker. This is the one accepted exception to the epic's
      [I3](../prd.md) "tv owns every picker screen", decided 2026-08-21
      (user) — reimplementing zoxide's frecency ranking behind a cable file
      buys one consistent screen at the cost of owning the ranking, and the
      exception is documented in `help` rather than left as a surprise.

### 3. `packages-installer/prd.md` — R7's shrug becomes a decision

Leave the package list itself byte-identical — it is cited as a set and the
verify guards it. Replace only the trailing parenthetical:

> (`fzf` is in the set as `zi`'s dependency, not as a picker to reach for:
> `zoxide query --interactive` spawns it. **Decided 2026-08-21 (user)** — an
> accepted, documented exception to `04-shell`'s "tv owns every picker
> screen"; see
> [`decisions/fzf`](../prd.md) and the
> record in [`corrections`](../../../corrections/prd.md),
> decision 3.)

The old wording — "required whether or not it is wanted" — must be gone. It
reads as an installer working around a disagreement; there is no
disagreement.

### 4. `06-help/04-drift-check/prd.md` — record the no-change reading

Append one bullet to `## Out of scope`:

- Deciding whether a documented entry *should* exist. H.4 checks that the
  manual and the live surfaces agree, not that the configuration is right.
  The fzf exception ([decisions/fzf](../prd.md),
  decided 2026-08-21) needed no requirement change here for that reason: it
  changes the manual's content, which is
  [01-content-model](../../../../06-help/01-content-model/prd.md)'s, not the check's rules.

Do **not** add a requirement. Adding an R9 that says "check the fzf entry
exists" would make the check's rule set carry one entry's name, which is
exactly the coupling R5/R6 were written to avoid.

## Acceptance

- [ ] I3 names `fzf`, calls it an exception, names `zoxide query
      --interactive`, links `00-delivery/decisions/fzf`, carries the date
      `2026-08-21`, and says it is `not a precedent`.
- [ ] I3 keeps its number and still states the underlying rule ("tv owns
      every picker screen", "no hand-coded TUIs") — the exception qualifies
      the invariant, it does not delete it.
- [ ] S.4 R2 names `zoxide query --interactive`, names `fzf`, calls it an
      exception, and still carries the `recents` logging clause.
- [ ] P.2 R7 no longer contains `whether or not it is wanted`; it names
      `fzf`, carries `Decided 2026-08-21`, and links `decisions/fzf`.
- [ ] P.2 R7's package list line (`nushell, television, zoxide, …`) is
      byte-identical to before.
- [ ] `06-help/04-drift-check` has a new `## Out of scope` bullet recording
      the no-change reading, and **no new requirement**: R1–R8 keep their
      numbers and text.
- [ ] No box in any of the four files is flipped to `[x]` or `[~]`.
- [ ] No frontmatter field was added, removed or renamed in any of the four.
- [ ] All four files still wrap at ~78 columns (tables exempt).
- [ ] This node's `prd.md` acceptance box 2 is `[x]`, with the check named
      and the H.4 no-change reading stated in one line — not a bare tick.

verify: ""

**Proven RED against the current tree before being written here.** It reports
all five missing I3 strings plus `I3 does not close the exception against
reuse`, the three missing S.4 R2 strings, `P.2 R7 still shrugs`, and the two
missing P.2 R7 strings — twelve failures, exit 1. The positive guards that
already pass and exist to catch overreach: the R2 `recents` clause, P.2 R7's
package list, no closed boxes in any of the three, and no unexpected
frontmatter field.

The `06-help/04-drift-check` bullet is deliberately **not** in the verify: a
grep for it would assert prose the node's own owner may reword, and the
substantive guard there is the negative one — that no requirement was
added — which the acceptance box states and the reviewer checks against
`git diff`. If you would rather it were mechanical: counting the
`**R<n>**` markers under that file's `## Requirements` heading yields 8
both before and after.

## Spent proof

`prds/04-shell/03-zoxide/prd.md` and
`prds/05-platform/02-package-provisioning/packages-installer/prd.md` have
since been implemented and their boxes closed; the guard protects files this
node only read, against churn during its own run.

Retired from `verify:` by
[`mi-rooted-verify-commands`](../../../corrections/mi-rooted-verify-commands/prd.md)
spec02. The command below is byte-identical to what spec01 left in this
file's `verify:`; it is kept because it is the execution record of a check
that once ran green.

```text
verify: `bash -c 'cd "$(git rev-parse --show-toplevel)"; rc=0; e=prds/04-shell/prd.md; z=prds/04-shell/03-zoxide/prd.md; p=prds/05-platform/02-package-provisioning/packages-installer/prd.md; I3() { awk "/\\*\\*I3\\*\\*/{q=1} /\\*\\*I4\\*\\*/{q=0} q" "$e"; }; R2() { awk "/\\*\\*R2\\*\\*/{q=1} /\\*\\*R3\\*\\*/{q=0} q" "$z"; }; R7() { awk "/\\*\\*R7\\*\\*/{q=1} /^## /{if(q)q=0} q" "$p"; }; for s in "fzf" "exception" "zoxide query --interactive" "00-delivery/decisions/fzf" "2026-08-21"; do I3 | grep -qF "$s" || { echo "FAIL: 04-shell I3 lacks: $s"; rc=1; }; done; I3 | grep -qF "not a precedent" || { echo "FAIL: I3 does not close the exception against reuse"; rc=1; }; for s in "zoxide query --interactive" "fzf" "exception" "recents"; do R2 | grep -qF "$s" || { echo "FAIL: S.4 R2 lacks: $s"; rc=1; }; done; R7 | tr "\n" " " | tr -s " " | grep -qF "whether or not it is wanted" && { echo "FAIL: P.2 R7 still shrugs"; rc=1; }; for s in "fzf" "Decided 2026-08-21" "decisions/fzf"; do R7 | grep -qF "$s" || { echo "FAIL: P.2 R7 lacks: $s"; rc=1; }; done; R7 | grep -qF "nushell, television, zoxide" || { echo "FAIL: P.2 R7 lost its package list"; rc=1; }; for f in "$e" "$z" "$p"; do grep -qE "^ *- \[[x~]\]" "$f" && { echo "FAIL: a box was closed in $f"; rc=1; }; awk "NR==1&&\$0==\"---\"{q=1;next} q&&\$0==\"---\"{exit} q{print}" "$f" | grep -oE "^[a-z]+:" | sort -u | grep -vE "^(state|priority|est|task|claim|mode|deps|verify|kind):" | grep -q . && { echo "FAIL: unexpected frontmatter field in $f"; rc=1; }; done; [ $rc -eq 0 ] && echo OK; exit $rc'`
```
