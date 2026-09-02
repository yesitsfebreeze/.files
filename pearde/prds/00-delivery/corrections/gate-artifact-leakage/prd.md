---
state: done
claim: 
priority: 36
est: 5h
mode: afk
verify: ""
origin: derived
from: 00-delivery/corrections/capsule-rm-guard-attribution
---

# Counterfactual runs are leaking artifacts into the repo root

Parent: [Corrections backlog](../prd.md) · net-new

Purpose: three zero-byte untracked files are sitting in the repo root right
now, left by implementers running counterfactuals:

```
-rw-r--r--  0  Aug 23 16:40  cf-rm-site-dropped.nu
-rw-r--r--  0  Aug 23 16:40  cf-rm-site-in-another-def.nu
-rw-r--r--  0  Aug 23 15:49  nvim.log
```

None is tracked and none is `.gitignore`d — confirmed with `git ls-files` and
`git check-ignore`. The first two are named after
[`capsule-rm-guard-attribution`](../capsule-rm-guard-attribution/prd.md)'s two
counterfactuals; `nvim.log` is from an editor lane.

**They are deliberately not deleted.** They are the evidence, and the defect
is the pattern, not the three files.

Why it matters beyond tidiness: `gates/selftest.sh`'s isolation contract
hashes the repo root, so its guard now reads

> `sha256 over gates, tests, docs, AGENTS.md, cf-rm-site-dropped.nu,
> cf-rm-site-in-another-def.nu, CLAUDE.md, install.sh, justfile, nvim.log,
> .chezmoiroot, .gitignore`

The isolation guard is hashing junk it has no opinion about. Each new stray
file widens the surface a concurrent write can trip, and this board has
already spent time on `selftest.sh` false positives from concurrent writes —
a wider hash makes those more likely, not less. Every gate on the board
declares a scratch directory and asserts it wrote nothing outside it; these
files are that contract failing quietly, in the one place nobody greps.

## Requirements
- [x] **R1** — **Census first: every untracked, un-ignored artifact in the
      repo root and in `tests/`, `gates/`, `home/`.** Report each with its
      likely producer, inferred from its name and mtime. The three above are
      the ones visible at filing time; assume more, because they arrive
      whenever a counterfactual runs.
- [x] **R2a** — **One mechanism is already identified, self-reported, and it
      is a whole class.** `listing-order-lookup-regression`'s implementer
      leaked 7 files into the repo root by running a `cp`-aside baseline from
      the scratchpad: `gates/lib.sh` was never sourced, so `gates_tmpdir` was
      undefined, `SCRATCH=""`, and `cd "" && pwd -P` resolved to the **repo
      root**. **Any gate run with an unresolvable `$REPO` writes its
      counterfactuals into `$PWD`.** A one-line `[ -n "$SCRATCH" ] || exit`
      guard after `gates_tmpdir` stops all of it. It removed its own 7 files;
      the real gate does not leak, confirmed by a clean run.
- [x] **R2** — Establish **which mechanism** leaks. A gate that declares a
      scratch dir and writes outside it is one defect; an implementer running
      a by-hand counterfactual in `$PWD` is a different one, and only the
      first is a gate bug. Say which produced each file, and do not fix the
      second by patching the first.
- [x] **R3** — For any gate that genuinely writes outside its scratch: it
      stops. That is its own `--selftest` contract and the fix belongs in the
      gate, but **name the owning node and report rather than reaching into
      another node's file** unless it is unowned.
- [x] **R4** — Recommend, without building it, whether `gates/selftest.sh`'s
      root hash should be **derived from tracked files plus an explicit
      allow-list** rather than from a directory listing. That would make a
      stray file a *failure* instead of silently widening the hash — which is
      the durable fix. Say what it would break.
- [x] **R5** — Do **not** simply add these names to `.gitignore`. Ignoring an
      artifact hides the leak and keeps the hash wide; the point is that
      nothing should be there. If some artifact genuinely belongs in the tree,
      argue it individually.

## Acceptance
- [x] The R1 census in the report, one row per artifact with its producer.
- [x] R2's verdict per file: gate bug, or by-hand run.
- [x] `bash gates/selftest.sh` reaches exit 0 with 0 FAIL, run **alone**, and
      its root-hash line quoted so the narrowing is visible.
      *(implementer, 2026-08-23: left OPEN. The narrowed root-hash line is
      quoted in `## Census` below and the sweep is 37 PASS / 1 FAIL, but
      the one FAIL is present identically in the before-run —
      `contract: retired-phrases.sh accepts --selftest and exits 0 (rc 1)`,
      owned by `phrase-sweep-selftest-inversion`, whose own specs carry the
      five UNEXPECTED phrases. Not fixable from this node's footprint.)**Closed by the orchestrator, 2026-08-23T22:05Z**: the
      blocking FAIL is gone. `phrase-sweep-selftest-inversion` landed its
      rebuilt `--selftest`, and a solo run with a before/after hash of the
      watched tree gives **38 PASS / 0 FAIL, rc 0**, window byte-identical.
      Root-hash line: `sha256 over gates, tests, docs, .chezmoiroot,
      .gitignore, AGENTS.md, CLAUDE.md, install.sh, justfile` — the three
      artifacts gone from the guarded set. The implementer was right to leave
      this open rather than annotate it green: the condition was board-wide, it
      was not this node's to meet, and it is met now.)*
- [x] R4's recommendation, with what it would break.

## Out of scope
- Deleting artifacts before the census records them.
- `.gitignore` changes, per R5.

## Answers — orchestrator, 2026-08-23

**A1 — R4's reading: the analyst's is correct; spec02 builds the narrowing.**
"Recommend, without building it" governs the **tracked-derived** variant only.
The acceptance box below it asks for "the root-hash line quoted so the
narrowing is visible", which cannot be satisfied by a recommendation, so the
inventory-derived narrowing was always in scope. Build it.

R4's premise was also **wrong, and the refutation is the more valuable half**.
It proposed deriving the hash from tracked files because I believed `gates/`
was tracked. It is not: **4 of 23** files in `gates/` are tracked, and
`gates/lib.sh` — sourced by every gate — is one of the untracked ones.
Tracked-derived would therefore *stop watching* the file this node is about to
edit. Declining it with those numbers was right; the correction is recorded on
[`git-diff-integrity-boxes`](../git-diff-integrity-boxes/prd.md), where I had
made the same mistake in the opposite direction.

**A2 — R1's premise: substitution accepted.** "Every untracked, un-ignored
artifact" does not discriminate on this board — 483 paths are untracked and
un-ignored, because untracked is the normal state for working content here
(99 tracked in the whole repo). Artifact **shape** is the right predicate:
zero-byte, or `cf-*` / `*.log` / `*.tmp` / `*.bak` / `*.orig` / `*.rej`.
Record the substitution and its reason in the census, so the next reader does
not re-derive it.

**Sequencing.** `gates/lib.sh` is in spec01's footprint and is sourced by
`gates/retired-phrases.sh`, held by
[`phrase-sweep-selftest-inversion`](../phrase-sweep-selftest-inversion/prd.md).
That lane returned **BLOCKED without writing a byte** — the file's md5 is
unchanged — and is back with its analyst for a spec amendment, so `lib.sh` is
free and this dispatches now. If that lane resumes while this one is open, it
reads `lib.sh` and does not write it.

**On finding no gate leaks.** The census verdict that all three artifacts are
by-hand runs, not gate bugs, is the R2 answer and it makes **R3's subject list
empty** — nothing to reach into, which is the outcome R3 was written to
protect against. The five-versus-two counterfactual count is a genuinely good
discriminator: a collapsed `$SCRATCH` leaks all five files that function
writes, and only the two that lane added are present. Keep that argument in
the spec; it is what makes the "by-hand" verdict falsifiable rather than
convenient.

## Census — implementer, 2026-08-23

### R1 — the artifact census, by shape

The predicate is artifact **shape**, not untracked-ness (per A2), and the
substitution is recorded here so the next reader does not re-derive it:
`git ls-files | wc -l` is **99** tracked against **486** paths from
`git ls-files --others --exclude-standard`. Untracked is the normal state of
working content in this repo — `gates/lib.sh`, `gates/selftest.sh`, all of
`home/`, `install.sh`, `justfile` and `.chezmoiroot` are all untracked — so
"untracked and un-ignored" selects nearly the whole tree and discriminates
nothing. Shape does: zero-byte, or a name matching `cf-*`, `*.log`, `*.tmp`,
`*.bak`, `*.orig`, `*.rej`.

| artifact | size | mtime | tracked | ignored | producer | verdict |
|---|---|---|---|---|---|---|
| `cf-rm-site-dropped.nu` | 0 | 2026-08-23 16:40:24 | no | no | `tests/capsule-lifecycle.sh:282`, run by hand | by-hand run |
| `cf-rm-site-in-another-def.nu` | 0 | 2026-08-23 16:40:24 | no | no | `tests/capsule-lifecycle.sh:288`, run by hand | by-hand run |
| `nvim.log` | 0 | 2026-08-23 15:49:06 | no | no | an editor lane by hand; no in-tree writer can produce it here | by-hand run |

Nothing else, and the row set is now produced by a tool rather than by hand —
`bash gates/selftest.sh --root`, measured before the cleanup below:

```
root: STRAY cf-rm-site-dropped.nu — size 0, mtime 2026-08-23 16:40:24, git-tracked no, git-ignored no
root: STRAY cf-rm-site-in-another-def.nu — size 0, mtime 2026-08-23 16:40:24, git-tracked no, git-ignored no
root: STRAY nvim.log — size 0, mtime 2026-08-23 15:49:06, git-tracked no, git-ignored no
root: census of /Users/feb/dev/dotfiles — 10 root file(s)/symlink(s) walked, 3 undeclared
FAIL  root: nothing at the root outside GATES_ROOT_INVENTORY (3 stray) — …
```

Three rows in the table, three `root: STRAY` lines from the tool.

`tests/`, `gates/`, `home/` and `docs/` are **clean** by the same predicate:

```
$ find gates tests home docs \( -name 'cf-*' -o -name '*.log' -o -name '*.tmp' \
      -o -name '*.bak' -o -name '*.orig' -o -name '*.rej' -o -size 0 \) -type f -print
(no output)
```

### R2 — the verdict per file, argued from commands

**All three are by-hand runs. No gate on the board is leaking.**

`cf-rm-site-*.nu` — `tests/capsule-lifecycle.sh:282,288` writes exactly these
two names, and always under `"$SCRATCH/"`. Run for real from the repo root the
gate leaves the root untouched (see the box below: `24 pass, 0 fail`, empty
`find -maxdepth 1` diff). The discriminating detail is the **count**: the same
function writes five counterfactuals — `cf-wez-payload.lua:260`,
`cf-mount-subdir.nu:269`, the two `cf-rm-site-*` at 282/288, and
`cf-universal-claim-restored.nu:300`. A gate whose `$SCRATCH` had collapsed to
`$PWD` would have leaked all five. Exactly the two that the
[`capsule-rm-guard-attribution`](../capsule-rm-guard-attribution/prd.md) lane
*added* are present. The zero length agrees: an `awk … > "$CF_RM_A"` whose
input file does not resolve creates the redirect target and writes nothing.

`nvim.log` — the only in-tree writer of that name is
`tests/shell-zoxide.sh:569`, inside an **unquoted** `<<STUB` heredoc, so
`"$M/nvim.log"` expands at write time; `$M` is always `"$SCRATCH/m-…"`
(lines 639, 649, 663, 672, 677), so even a collapsed `$SCRATCH` yields
`/m-z-file/nvim.log`, never a root-relative `nvim.log`. `grep -rn 'nvim\.log'
gates tests home docs` finds no other writer, and `grep -rn NVIM_LOG_FILE
gates tests home docs` finds nothing. No in-tree gate can produce this file at
the repo root.

### R3 — the subject list is empty

R3 says a gate that genuinely writes outside its scratch stops. No gate does,
so nothing was reached into and no other node's file was touched. What remains
is a class that cannot be linted at all — a by-hand script living outside the
repo — so the two defences built here are **prevention at the one shared
choke-point** (spec01: `gates/lib.sh` refuses a scratch root that is the repo
root or an ancestor of it, at source time, before a byte is written) and
**detection whatever the mechanism** (spec02: the declared root inventory makes
the next stray a named FAIL instead of a silent widening of the hash).

### R4 — the tracked-derived variant, declined, with numbers

R4 proposed deriving the root hash from **tracked files plus an allow-list**.
Measured, that would make the guard *weaker*, not narrower: only **4 of 23**
files under `gates/` are tracked (`gates/manual/wave2.md`,
`gates/nushell-module-staging.sh`, `gates/retired-phrases.sh`,
`gates/waves.tsv`), and `gates/lib.sh` — sourced by every gate, and the file
spec01 edits — is one of the untracked ones, as are `gates/selftest.sh`,
`install.sh`, `justfile` and `.chezmoiroot`. A tracked-derived guard would stop
watching the library every gate sources. What it would break, concretely: the
isolation contract would no longer notice a gate rewriting `lib.sh`,
`selftest.sh` or any of the 19 untracked files in `gates/`, and every gate
whose scratch tree depends on `install.sh` / `.chezmoiroot` would lose its
untouched-file evidence.

What was built instead keeps the same *idea* with the tracked set as an
admission **rule** rather than as the membership list:
`GATES_ROOT_INVENTORY` declares the guarded root files, and a second check
requires every present entry to be git-tracked **or** named in the shrink-only
`GATES_ROOT_BOOTSTRAP` (≤ 3 names, asserted). A leaked zero-byte
counterfactual never gets committed, so it can never buy its way in.

### R5 — `.gitignore` untouched

The remedy is deletion, not ignoring. `.gitignore` was not edited:
`shasum -a 256 .gitignore` is
`6bc62ae7b87675efd2addfa82a5bcd403c974be3a4061b6f72b386c53d821c32` before and
after, and `grep -cE 'cf-rm-site|nvim\.log' .gitignore` is 0.

### Follow-up: `/` was the one ancestor the guard missed

Found by the orchestrator while verifying, and it is the same failure class
this node is about — a non-match indistinguishable from success. Measured with
the `case` pattern alone, no `lib.sh` and no gate involved:

| `GATES_TMP` | pattern before the fix | outcome |
|---|---|---|
| `/` | `//*` | **fell through** |
| `/Users` | `/Users/*` | caught |
| `/Users/feb/dev` | `/Users/feb/dev/*` | caught |
| `/Users/feb/dev/dotfiles` | `/Users/feb/dev/dotfiles/*` | caught |

`"$GATES_TMP"/*` with `GATES_TMP=/` expands to `//*` — two leading slashes —
while `"$REPO_ROOT/"` carries one, so `case` found no match. Every ancestor was
refused except the one that is pure slash. `/` is reachable by the same
accident as the original leak, one character further along: `"${BASE}/"` with
`BASE` empty is `/`, and `GATES_KEEP_TMP` is settable from the environment.

The fix is `${GATES_TMP%/}` in the pattern, with the table above written into
the comment beside it. It changes nothing for any other path — `pwd -P` emits a
trailing slash only for the filesystem root — and the under-repo case stays
legal, which is the property a careless fix breaks. All four outcomes
re-verified after the change:

```
GATES_KEEP_TMP="/"                        → rc 1, FATAL … [/] …
GATES_KEEP_TMP="$(dirname "$PWD")"        → rc 1, FATAL … [/Users/feb/dev] …
GATES_KEEP_TMP="$PWD"                     → rc 1, FATAL … [/Users/feb/dev/dotfiles] …
GATES_KEEP_TMP="$PWD/.gates-legal-probe"  → rc 0, 0 FATAL lines, 3 entries written there
bash gates/probes.sh --selftest (normal)  → rc 0
```

`gates/retired-phrases.sh` is byte-identical across this second `lib.sh` edit
too, in 3.48 s. The probe directory was removed and the maxdepth-1 listing —
directories included — is byte-identical before and after.

Note the spec box that passed while the requirement did not: it tested
`$(dirname "$PWD")`, which was caught. A box is only as wide as its fixture,
so `/` now has a box of its own in spec01.

### The cleanup, and the sweep afterwards

The three artifacts were deleted only after the table above was written, and
the census was re-taken immediately beforehand to catch arrivals — there were
none, still exactly three. After `rm -f`:

```
$ find . -maxdepth 1 \( -type f -o -type l \) | sort
./.chezmoiroot   ./.DS_Store   ./.gitignore   ./AGENTS.md
./CLAUDE.md      ./install.sh  ./justfile
$ git status --porcelain | grep -cE 'cf-rm-site|nvim\.log'                  → 0
$ git ls-files --others --exclude-standard | grep -cE 'cf-rm-site|nvim\.log' → 0
$ bash gates/selftest.sh --root
root: census of /Users/feb/dev/dotfiles — 7 root file(s)/symlink(s) walked, 0 undeclared
PASS  root: nothing at the root outside GATES_ROOT_INVENTORY (0 stray) — …
PASS  root: every GATES_ROOT_INVENTORY entry is git-tracked or named in GATES_ROOT_BOOTSTRAP (unadmitted: none)
PASS  root: GATES_ROOT_BOOTSTRAP is shrink-only — at most 3 names (got 3: .chezmoiroot install.sh justfile)
```

**The narrowing, quoted.** `bash gates/selftest.sh`, run alone, before and
after this node:

```
before:  sha256 over gates, tests, docs, AGENTS.md, cf-rm-site-dropped.nu,
         cf-rm-site-in-another-def.nu, CLAUDE.md, install.sh, justfile,
         nvim.log, .chezmoiroot, .gitignore          (34 PASS / 1 FAIL)
after:   sha256 over gates, tests, docs, .chezmoiroot, .gitignore, AGENTS.md,
         CLAUDE.md, install.sh, justfile             (37 PASS / 1 FAIL)
```

The three artifact names are gone from the guarded set, the order is now the
inventory order and therefore deterministic, and the census walks once per
sweep — `bash gates/selftest.sh | grep -c '^root:'` is **1**, independent of
how many gates the sweep holds (the per-gate path, `check_contract`, and the
`--one` path both stay census-free: `bash gates/selftest.sh --one
gates/probes.sh | grep -c 'root:'` is **0**).

**One FAIL survives, and it is not this node's.** It is present in the
before-run identically: `FAIL contract: retired-phrases.sh accepts --selftest
and exits 0 (rc 1)`. `bash gates/retired-phrases.sh` is red on its own, in
2.95 s, with byte-identical output before and after the `gates/lib.sh` edit,
and its five UNEXPECTED allow-list carriers all live in
[`phrase-sweep-selftest-inversion`](../phrase-sweep-selftest-inversion/prd.md)`/specs/`.
So the acceptance box asking for **0 FAIL** cannot be closed from inside this
node's footprint, and is left open rather than ticked. Everything else in the
sweep is green, and the sweep gained exactly the three new `root:` PASSes.

`bash gates/selftest.sh --selftest` exits **0** with 20 PASS / 0 FAIL,
including the five new root-census counterfactuals (planted stray red and
named with size/mtime/git status, the same copy green without the plant,
`.DS_Store` green, and a fourth `GATES_ROOT_BOOTSTRAP` name red).

## Verification finding — orchestrator, 2026-08-23

Implementer reported **DONE**; held at `claimed` and sent back, for one hole
found while verifying rather than reported.

**`GATES_TMP="/"` is accepted.** Every ancestor of the repo root is refused
except the one that is pure slash:

| `GATES_KEEP_TMP` | outcome |
|---|---|
| `/` | **ACCEPTED — no `FATAL`** |
| `/Users` | `FATAL` |
| `/Users/feb/dev` | `FATAL` |
| `$PWD` (the repo root) | `FATAL` |

Mechanism, isolated to the `case` pattern with no `lib.sh` and no gate in the
way: with `GATES_TMP=/`, `"$GATES_TMP"/*` expands to `//*` — two leading
slashes — and `$REPO_ROOT/` carries one, so the pattern cannot match and the
guard falls through.

**The spec's box is honestly ticked, and that is the finding.** It tests
`$(dirname "$PWD")` = `/Users/feb/dev`, which is caught; the box passed while
the requirement it stands for ("`$REPO_ROOT` **or an ancestor of it**") did
not. A check whose non-match is indistinguishable from success is the class
this node exists to close, and it is the same shape as the `sed` in
[`staging-gate-vacuous-green`](../staging-gate-vacuous-green/prd.md).

`/` is reachable and in-class: the leak this guard was built for was an
unresolved variable collapsing a path, and `"${BASE}/"` with `BASE` empty
yields `/` — the same accident as `cd ""`, one character further along.

**Independently confirmed as correct and not to be re-opened:** the three
artifacts are gone; the repo root is exactly the six-name inventory plus
`.DS_Store` (`CLAUDE.md` is a symlink to `AGENTS.md`, which is why a
`-type f` listing shows five); `.gitignore` untouched at `6bc62ae7…`;
`selftest.sh --root` green — 7 entries walked, 0 undeclared, rc 0, all three
`root:` checks passing; the root hash visibly narrowed to `gates, tests, docs,
.chezmoiroot, .gitignore, AGENTS.md, CLAUDE.md, install.sh, justfile`; and the
`GATES_ROOT_INVENTORY` assignment is a plain one, not `:-`, so the inventory
itself cannot be overridden from the environment.

**`actual:` will not be recorded on this node.** The round-trip is a real
defect found in delivered work, not an orchestrator error like the
`autolist-width-guard-reason` round-trip, so the run does not measure a clean
one.

## Closeout — orchestrator, 2026-08-23

`done`. The `/` hole is closed with `${GATES_TMP%/}` and I verified all four
paths myself, the fourth being the one a careless fix breaks:

```
/                         rc=1  FATAL … refusing a scratch root of [/]
/Users/feb/dev            rc=1  FATAL
/Users/feb/dev/dotfiles   rc=1  FATAL
$PWD/.gates-legal-probe   rc=0  OK        ← a scratch root UNDER the repo stays legal
```

**The meta-gate, re-run solo: 37 PASS / 1 FAIL, rc 1** — and the run is
trustworthy, because it carries its own contamination check. The watched tree
(`gates`, `tests`, `docs`, and the root inventory) was hashed before and after
and came back **byte-identical across the whole window**. The earlier run of
the same command reported a *second* FAIL on the isolation hash; that was mine,
not the gate's — I resumed the implementer to fix `lib.sh` while my own sweep
was running, so the file changed mid-hash. The lesson is the one I have given
four workers this session and then broke myself: a red you have not re-run
solo is not a result.

**The one remaining FAIL is not this node's**, and its two acceptance boxes
that assert `gates/selftest.sh` reaches 0 FAIL are left `[ ]` rather than
annotated green. The FAIL is `contract: retired-phrases.sh accepts --selftest
and exits 0`, whose five carriers are
[`phrase-sweep-selftest-inversion`](../phrase-sweep-selftest-inversion/prd.md)'s
own spec files. Those boxes assert a **board-wide** condition, the same shape as
[`verification-gates`](../../verification-gates/prd.md), and they close when the
board does — not when this node does.

**No `actual:`.** The round-trip was a real defect in delivered work, so the
run does not measure a clean one.

One gap this node's work exposed rather than caused is now
[`root-inventory-blind-to-dirs`](../root-inventory-blind-to-dirs/prd.md): the
root walk is `-type f -o -type l`, so a stray **directory** is neither walked
nor counted. Found because the orchestrator's own legal-scratch probe left one
and the census reported `0 undeclared` beside it. The artifact shape the new
guard's legal case creates is the shape the new census cannot see — and both
landed in the same change.
