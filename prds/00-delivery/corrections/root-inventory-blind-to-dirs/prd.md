---
state: done
commit: 3bf5354
claim:
priority: 37
est: 1h
actual: 30m
mode: afk
needs:
  - 00-delivery/corrections/gate-artifact-leakage
footprint:
  - gates/selftest.sh
verify: "bash gates/selftest.sh --root"
origin: derived
from: 00-delivery/corrections/gate-artifact-leakage
---

# The root inventory walks files and symlinks, so a stray *directory* is invisible

Parent: [Corrections backlog](../prd.md) · net-new

Purpose: [`gate-artifact-leakage`](../gate-artifact-leakage/prd.md) replaced
`gates/selftest.sh`'s root glob with a declared six-name inventory, and it
works — for files and symlinks. Its walk is
`find . -maxdepth 1 \( -type f -o -type l \)`, so a directory left at the repo
root is not walked, not counted, and not reported. The census prints
`0 undeclared` and all three `root:` checks pass with the stray sitting beside
them.

**Measured, and by accident.** Verifying that node's guard fix, the
orchestrator ran its legal-scratch probe — `GATES_KEEP_TMP="$PWD/.gates-legal-probe"`,
which `lib.sh` creates by design — and then ran the census with the directory
still present:

```
.gates-legal-probe/                    ← present, mtime 21:05
root: census of /Users/feb/dev/dotfiles — 7 root file(s)/symlink(s) walked, 0 undeclared
PASS  root: nothing at the root outside GATES_ROOT_INVENTORY (0 stray)
rc=0
```

The directory was the orchestrator's own leak, removed immediately. The gap it
exposed is the point: **the one artifact shape the new guard's own legal-case
probe creates is the shape the new census cannot see.** Both landed in the same
change.

This is not a criticism of that node's work. Its R1 census was scoped to
artifact *shape* — zero-byte, `cf-*`, `*.log`, `*.tmp`, `*.bak`, `*.orig`,
`*.rej` — and every artifact it found was a file, so a file-and-symlink walk
covered every observed case. The defect is that the *check* is narrower than
the *class*, and nothing said so.

## Requirements
- [x] **R1** — The root walk sees directories. Add `-type d` (excluding `.`
      itself) or drop the type filter entirely, and decide deliberately which:
      dropping it also catches sockets and fifos, which cost nothing to cover
      and are the same class of accident.
- [x] **R2** — The inventory needs a directory dimension. `.git`, `.claude`,
      `docs`, `gates`, `home`, `prds`, `tests` are legitimate root
      directories; `.obsidian` and `vicky` are present and are neither
      declared nor obviously repo content — **report what they are before
      declaring them**, and do not admit a directory to the inventory just to
      make the check green. That is the growth shape
      `gate-artifact-leakage`'s bootstrap ceiling exists to prevent.
- [x] **R3** — A counterfactual that plants a stray **directory** in a scratch
      copy and asserts the census goes red, naming it. The existing
      counterfactuals plant files; a file-planting counterfactual could never
      have caught this, which is why it did not.
- [x] **R4** — Assert the reported **count**, not merely that the run is red.
      A walk that stopped seeing directories would report 0, pass, and take
      the new counterfactual green when it must be red — the silent-green
      shape of
      [`staging-gate-vacuous-green`](../staging-gate-vacuous-green/prd.md),
      and the same tripwire
      [`phrase-sweep-selftest-inversion`](../phrase-sweep-selftest-inversion/prd.md)
      wrote for its own waiver count.
- [x] **R5** — Report whether any other check on the board filters by
      `-type f` where the class it guards is wider. State the predicate. Do
      not fix them here — one file per node — but a count says whether this is
      one bug or a habit.

## Acceptance
- [~] `bash gates/selftest.sh --root` exits 0 on a clean root, with the
      directory count in the census line and the walked total quoted. **Met on
      a clean root, not on the live one**: the live root is not clean today, and
      the census is right about that — see Result, box 1.
- [x] A planted stray directory turns it red and is named in the output,
      quoted.
- [x] R4's count assertion demonstrated: break the directory walk on purpose
      in a scratch copy and show the counterfactual goes red, not green.
- [x] `.obsidian` and `vicky` accounted for in writing — declared with a
      reason, or reported as needing the user's call.
- [x] R5's count with its predicate.

## Result

Implemented 2026-08-24. One file changed: `gates/selftest.sh`.

### 1. The live root is red, and correctly so

The walk now sees every entry, and the first thing it saw was a real stray the
old walk was blind to:

```
$ bash gates/selftest.sh --root
root: STRAY .pearde-fork-2026-08-24 — size 448, mtime 2026-08-23 14:32:15, git-tracked no, git-ignored yes, kind dir
root: census of /Users/feb/dev/dotfiles — 17 root entries walked (7 file/symlink, 10 dir, 0 other), 1 undeclared
FAIL  root: nothing at the root outside GATES_ROOT_INVENTORY/GATES_ROOT_DIRS (1 stray) — …
PASS  root: every GATES_ROOT_INVENTORY/GATES_ROOT_DIRS entry is git-tracked or named in GATES_ROOT_BOOTSTRAP (unadmitted: none)
PASS  root: GATES_ROOT_BOOTSTRAP is shrink-only — at most 3 names (got 3: .chezmoiroot install.sh justfile)
rc=1
$ find . -mindepth 1 -maxdepth 1 | wc -l
      17
```

The walked total matches `find` exactly. `.pearde-fork-2026-08-24` is
`.gitignore:18` — "the stale forked copy it replaced, kept only until it is
salvaged or deleted" — untracked, with its own `.git`, and **not declared**:
declaring a transient local copy to buy a green run is the growth shape R2
exists to stop, exactly as spec01 forbids pre-declaring `.pi`. Deleting it or
deciding about it is a human call outside this node's footprint. Minus that one
entry the root is the 16 entries / 9 directories the analyst measured.

Two minutes later the same command showed a **second** stray — a zero-byte
`nvim.log`, mtime 01:48:55, `kind file`, another lane's live leak and the very
filename that was one of `gate-artifact-leakage`'s original three:

```
root: STRAY nvim.log — size 0, mtime 2026-08-24 01:48:55, git-tracked no, git-ignored no, kind file
root: STRAY .pearde-fork-2026-08-24 — size 448, mtime 2026-08-23 14:32:15, git-tracked no, git-ignored yes, kind dir
root: census of /Users/feb/dev/dotfiles — 18 root entries walked (8 file/symlink, 10 dir, 0 other), 2 undeclared
rc=1
```

Recorded rather than cleaned up: it is not this node's artifact, and the census
naming it within two minutes of its creation is the guard working.

That the census can pass at all is proved on a clean root rather than asserted
— a synthetic root holding `AGENTS.md CLAUDE.md docs/` and nothing else:

```
root: census of <scratch> — 4 root entries walked (2 file/symlink, 2 dir, 0 other), 0 undeclared
PASS  root: nothing at the root outside GATES_ROOT_INVENTORY/GATES_ROOT_DIRS (0 stray) — …
rc=0
```

and again by S3.6's own both-poles assertion, `meta: the copy without the
planted DIRECTORY is GREEN again` → PASS.

### 2. A planted directory (and a fifo) go red, named with their kind

Same synthetic root, `mkdir cf-planted-dir && mkfifo cf-fifo`:

```
root: STRAY cf-planted-dir — size 64, mtime 2026-08-24 01:46:21, git-tracked no, git-ignored no, kind dir
root: STRAY cf-fifo — size 0, mtime 2026-08-24 01:46:21, git-tracked no, git-ignored no, kind fifo
root: census of <scratch> — 6 root entries walked (2 file/symlink, 3 dir, 1 other), 2 undeclared
rc=1
```

The fifo is why the type filter was **dropped** rather than extended with
`-type d`: an enumerated filter is narrower than the class it guards, which is
the defect this node was opened for. In-gate, the same plant against S3.6's
root copy:

```
PASS  meta: a stray DIRECTORY at the guarded root is red
PASS  meta: and the census NAMES the directory with its kind and provenance
PASS  meta: the census dir count parsed at all (got [5] → [6])
PASS  meta: the census dir COUNT rose by exactly one — a walk that stopped seeing directories reports the same count and PASSES
PASS  meta: and the census reports exactly 1 undeclared
PASS  meta: the copy without the planted DIRECTORY is GREEN again
```

### 3. R4 proved by mutation, not by assertion

`gates/` copied to a scratch `$M`, the walk re-narrowed to
`-mindepth 1 -maxdepth 1 -type f -o -type l`, the new counterfactual run out of
that copy. Four of the five go red; only the parse check survives, because `0`
still parses:

```
FAIL  meta: a stray DIRECTORY at the guarded root is red
FAIL  meta: and the census NAMES the directory with its kind and provenance
PASS  meta: the census dir count parsed at all (got [0] → [0])
FAIL  meta: the census dir COUNT rose by exactly one — a walk that stopped seeing directories reports the same count and PASSES
FAIL  meta: and the census reports exactly 1 undeclared
```

The live `gates/` was never mutated; `$M` was removed afterwards.

### 4. `.obsidian` and `vicky` — declared on evidence

Re-measured 2026-08-24, not taken on trust: `git ls-files .obsidian vicky`
lists 15 paths (`.obsidian/app.json` … `vicky/sources/_index.md`) and
`git check-ignore .obsidian vicky` is silent, rc 1. Both are committed repo
content, so the admission rule admits them for the same reason it admits
`docs/`. No user call needed. `.pi` stays undeclared and absent
(`ls -d .pi` → no such file); if it appears the census goes red and that
verdict is correct.

**One deliberate deviation from spec01.** `.claude` is *not* in
`GATES_ROOT_DIRS`; it is excluded by RULE beside `.git` and `.DS_Store`.
spec01 listed it on a measurement taken at 22:48; commit `2587abf` ("retire the
mi skills and workflows", 01:29 the same night) removed the last tracked file
under it, so `git ls-files .claude` now returns **0 paths** and what remains is
a gitignored symlink (`.claude/skills/pearde -> ~/dev/infra/pearde`), gitignored
local state and untracked notes. Declared, it produced a permanent
`FAIL … (unadmitted: .claude)` — measured — and `GATES_ROOT_BOOTSTRAP` cannot
absorb it, being shrink-only with all three names spent. The RULE is the
category spec01 itself defines for a name that can never be admitted, and the
comment records the measurement and says to move `.claude` back into
`GATES_ROOT_DIRS` if it ever holds committed content again.

### 5. R5 — a habit, not a one-off

Predicate `grep -rn -- '-type f' gates/*.sh tests/*.sh`, kept when the find is
the sole walk behind the assertion **and** the assertion's subject is the whole
tree: **6 sites in 5 scripts**, plus this census. `tests/shell-init.sh:214`,
`tests/nvim-options.sh:230`, `tests/nvim-completion.sh:186`,
`tests/nvim-lsp.sh:217`, `tests/nvim-lsp.sh:224`, and
`tests/nvim-keymaps.sh:508` — the sixth appeared when the predicate was re-run
at 01:24 because another lane rewrote that file at 23:52. Not fixed here: one
file per node, and every site is under `tests/`. The full table, with the
exclusions, is the comment block above `root_inventory()`.

### 6. No new FAIL, and the guard label did not move

```
before:  ── selftest rc=0 ──   PASS=17 FAIL=0
after:   ── selftest rc=0 ──   PASS=23 FAIL=0
$ diff <(grep '^FAIL' /tmp/st-before.txt) <(grep '^FAIL' /tmp/st-after.txt)
(no output)
```

+6 PASS is exactly the six new assertions. `GUARD_LABEL` is byte-identical —
`diff` of the `sha256 over …` line before and after is empty, still
`sha256 over gates, tests, docs, .chezmoiroot, .gitignore, AGENTS.md,
CLAUDE.md, install.sh, justfile` — so no directory entered the isolation hash.
`bash gates/selftest.sh | grep -c '^root:'` is **2**: one census line plus one
line for the one stray, which is the documented invariant ("1 on a clean root,
plus one line per stray"), and the plain sweep's rc is 1 for that stray alone.

### Judgement asked for: is a red for a transient root directory too brittle?

No, and this node's own first run is the argument. The gate's subject is "the
repo root holds exactly what the repo declares", and a scratch directory a lane
forgot to remove is precisely the accident that caused
[`gate-artifact-leakage`](../gate-artifact-leakage/prd.md) — three leaked
artifacts silently joined the isolation hash because a glob had no opinion. A
census that tolerates directories "because they are probably temporary" is that
glob again. The right relief valve is the one already in the design: the STRAY
line carries `git-ignored yes/no`, so a reader sees in one line whether the
entry is a deliberate local exclusion or a genuine leak, and can delete it in
seconds. What would be brittle is the opposite fix — auto-admitting every
gitignored root entry — because it hands future `.gitignore` lines the power to
silently un-guard the root.

## Out of scope
- `gates/lib.sh` and the scratch-root guard. Fixed and verified under
  [`gate-artifact-leakage`](../gate-artifact-leakage/prd.md), including the
  `/` pattern hole.
- The three artifacts already deleted, and `.gitignore`, which R5 of that node
  forbids touching.

## Closed 2026-08-24 by the orchestrator

`done`, and **acceptance box 1 is now closed against a run the orchestrator
made** rather than left at `[~]`. The worker reported `--root` exiting **1**,
correctly: the census it had just taught to see directories immediately caught
two strays, and **one of them was the orchestrator's**.

```
root: STRAY nvim.log — size 0, mtime 2026-08-24 01:48:55, git-tracked no, git-ignored no, kind file
root: STRAY .pearde-fork-2026-08-24 — size 448, git-tracked no, git-ignored yes, kind dir
```

`.pearde-fork-2026-08-24` was the displaced copy of the pearde skill, put in
the repo root by the orchestrator hours earlier to preserve it. It has been
**moved out of the repo** to `~/dev/infra/pearde-fork-2026-08-24`, beside the
live skill where it belongs — nothing destroyed, and the `.gitignore` line that
existed only to hide it is gone. `nvim.log` was a zero-byte leak from a live
nvim lane and was removed. Re-run on the cleaned root:

```
root: census of /Users/feb/dev/dotfiles — 16 root entries walked (7 file/symlink, 9 dir, 0 other), 0 undeclared
PASS  root: nothing at the root outside GATES_ROOT_INVENTORY/GATES_ROOT_DIRS (0 stray)
PASS  root: every entry is git-tracked or named in GATES_ROOT_BOOTSTRAP (unadmitted: none)
PASS  root: GATES_ROOT_BOOTSTRAP is shrink-only — at most 3 names
rc=0
```

Exactly the analyst's prototyped figure, 16 entries and 9 directories. **The
gate found a real stray on its first run, and one of them belonged to the
session that commissioned it.** That is the strongest possible answer to
whether it was worth building.

**`actual: 30m` against `est: 1h`.**

**The brittleness question was put to the worker and it answered no, with the
better argument.** A census that tolerates directories because they are
"probably temporary" is the old glob again, and a forgotten scratch directory
is precisely the accident behind `gate-artifact-leakage`. The relief valve is
already designed in: the STRAY line carries `git-ignored yes/no`, so a reader
sees in one line whether it is a deliberate local exclusion or a genuine leak.
Auto-admitting every gitignored root entry would be the brittle fix, because it
hands future `.gitignore` lines the power to silently un-guard the root. Same
answer for `.pi/kern/`: let it go red and file a correction.

**One deliberate deviation, caused by the orchestrator's own commit.**
`.claude` is skipped by RULE rather than declared, because commit `2587abf`
("retire the mi skills and workflows") removed the last **tracked** file under
it — `git ls-files .claude` now returns 0 paths — so declaring it produced a
permanent `unadmitted: .claude`, and `GATES_ROOT_BOOTSTRAP` is shrink-only with
all three names spent. The comment says to move it back if `.claude` ever holds
committed content again.

That finding had a second consequence the worker could not see, now fixed:
**`AGENTS.md` pointed twice at `.claude/skills/prd/README.md`**, a file retired
with those skills, and at a `PRD_TEMPLATE.md` beside it. The working contract
was directing every agent at a missing protocol document; both references now
name the real ones.

**Two findings reported and not acted on:** `gates/lib.sh` still leaks its
scratch dir (`rm: …/gates.RRYfzd: Directory not empty`, rc 0), and R5's census
re-measures as **6 sites in 5 scripts**, not 5 in 4 — `tests/nvim-keymaps.sh:508`
appeared because another lane rewrote that file at 23:52, and the same drift
moved `tests/shell-claude.sh`'s excluded pair from 448/453 to 450/455. A number
that moves while you measure it is the board's own churn, not a defect.
