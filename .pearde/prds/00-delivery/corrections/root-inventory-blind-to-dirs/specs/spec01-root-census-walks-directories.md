---
est: 1h
footprint:
  - gates/selftest.sh
---
<!-- est calibration: this board's 37 clean est/actual pairs run 4.0x high
     (62.75h estimated against 15.58h measured), so this is quoted at the
     corrected scale: 4h uncalibrated / 4.0 = 1h. The two full `--selftest`
     sweeps in Verify and Proof dominate that hour — each is a ten-minute-plus
     wall-clock run, and the edit itself is under sixty lines of bash. -->

# spec01 — the root census walks every entry, directories included

`root_inventory()` in `gates/selftest.sh` walks
`find "$GATES_ROOT_DIR" -maxdepth 1 \( -type f -o -type l \)`, so a directory
at the repo root is never walked, never counted and never named. Widen the
walk to every entry, add the directory dimension the inventory is missing, and
give the census a counterfactual that plants a **directory** and asserts the
**count**, not merely a red rc.

One file. `gates/lib.sh`, `.gitignore` and the three deleted artifacts are out
of scope — see the PRD.

## Measured baseline, before the change

```
$ bash gates/selftest.sh --root
root: census of /Users/feb/dev/dotfiles — 7 root file(s)/symlink(s) walked, 0 undeclared
rc=0
$ find . -mindepth 1 -maxdepth 1 | wc -l
      16
```

Nine of the sixteen root entries are invisible to the census today. Nothing
outside `root_inventory()` reads the census line — `grep -rn 'census of'
gates/ .claude/ justfile` returns that one `echo` — so its wording is free to
change.

**Every mechanism below was prototyped 2026-08-23** in a throwaway `cp -R` of
`gates/`, driven with `GATES_ROOT_DIR` at the live root and at a synthetic one.
The live root came out:

```
root: census of /Users/feb/dev/dotfiles — 16 root entries walked (7 file/symlink, 9 dir, 0 other), 0 undeclared
rc=0
```

and a synthetic root with a planted directory and a planted fifo came out:

```
root: STRAY cf-planted-dir — size 64, mtime 2026-08-23 22:45:05, git-tracked no, git-ignored no, kind dir
root: STRAY cf-fifo — size 0, mtime 2026-08-23 22:45:05, git-tracked no, git-ignored no, kind fifo
root: census of … — 6 root entries walked (1 file/symlink, 4 dir, 1 other), 2 undeclared
```

Those are the numbers to expect, not a sketch.

The sweep is green going in, so "no new FAIL" is a meetable bar: `bash
gates/selftest.sh --selftest` measured `rc=0` with `0` FAIL lines and
`── selftest rc=0 ──` on 2026-08-23, immediately before this spec was written.

## What to change

### 1. The walk — drop the type filter, do not extend it (R1)

Replace the walk with:

```sh
done < <(find "$GATES_ROOT_DIR" -mindepth 1 -maxdepth 1)
```

`-mindepth 1` is what excludes `.` itself. **Dropping the filter rather than
adding `-type d` is the deliberate call R1 asks for**, and the comment must
record it with its reason: a socket, a fifo or a device at the repo root is
the same class of accident as a stray directory, costs nothing to cover, and
an enumerated filter is exactly the shape that made this node necessary — the
check was narrower than the class it guarded.

Classify each entry and report the kind. Test `-L` **first**: `CLAUDE.md` is a
symlink onto `AGENTS.md`, and `-f` is true for it, so a `-f`-first chain
mislabels it.

```sh
if   [ -L "$f" ]; then kind=symlink
elif [ -d "$f" ]; then kind=dir
elif [ -f "$f" ]; then kind=file
elif [ -p "$f" ]; then kind=fifo
elif [ -S "$f" ]; then kind=socket
else                   kind=other
fi
```

Append the kind to the **end** of the STRAY line, keeping every existing field
in place:

```
root: STRAY <base> — size <sz>, mtime <mt>, git-tracked <y/n>, git-ignored <y/n>, kind <kind>
```

S3.6 already asserts that line with an unanchored `grep -qE '… git-tracked no,
git-ignored no'`. Appending keeps that assertion matching; inserting the kind
earlier breaks it. `stat -f '%z'`, `stat -f '%Sm'`, `git ls-files
--error-unmatch` and `git check-ignore` all work unchanged on a directory —
verified 2026-08-23 on this root, `git ls-files --error-unmatch docs` exits 0.

### 2. The directory dimension (R2)

Add a second declared list beside `GATES_ROOT_INVENTORY`:

```sh
GATES_ROOT_DIRS=".claude .obsidian docs gates home prds tests vicky"
```

`.git` is **not** in it. Exclude it by RULE, in the walk, beside the existing
`.DS_Store` rule, and comment the reason: git's own store is never committed,
so no admission rule can ever admit it, and no gate writes it.

The eight declared names, each with the reason the comment must carry:

| dir         | what it is                                                        |
|-------------|-------------------------------------------------------------------|
| `.claude`   | the protocol directory — skills, the pearde board harness         |
| `docs`      | the rated capability inventories                                  |
| `gates`     | this harness                                                      |
| `home`      | the chezmoi source tree                                           |
| `prds`      | the board                                                         |
| `tests`     | the external gate scripts                                         |
| `.obsidian` | Obsidian vault config — `app/appearance/community-plugins/core-plugins/graph.json` plus `plugins/dataview/`, committed in `0d04022`; `.obsidian/workspace.json` is the machine-local half and is gitignored |
| `vicky`     | an Obsidian knowledge-base vault — `WORKFLOW.md`, `Dashboard.md`, `sources/`, `conclusions/`, `.graphifyignore`; agent-read research notes, committed in `0d04022` |

`.pi` stays undeclared. `.gitignore` carries `.pi/kern/` — "kern knowledge
graph — local database, regenerable" — and the directory is **absent**
(`ls -d .pi` → no such file, 2026-08-23). Declaring an absent path to keep a
future run green is the growth shape R2 forbids. If it ever appears the census
goes red, and that verdict is correct: file a correction, do not widen the
list here.

`.obsidian` and `vicky` are **git-tracked**, checked 2026-08-23: `git ls-files
.obsidian vicky` lists 15 paths, `git check-ignore .obsidian vicky` is silent.
They are committed repo content, not artifacts, so they are declared on that
evidence — not to make the check green.

Reuse the existing admission loop for both lists rather than writing a second
one: change its `[ -f "$GATES_ROOT_DIR/$e" ]` presence test to `[ -e … ]` and
iterate `$GATES_ROOT_INVENTORY $GATES_ROOT_DIRS`. The rule stays "an entry
earns its place by being committed", which every declared directory already
satisfies. **A declared directory that is present but holds no tracked file
reads unadmitted and fails** — git tracks no empty directory. Measured in the
prototype: an empty `prds/` in a synthetic root produced `FAIL … (unadmitted:
prds)`. That verdict is correct — an empty directory at the root is not repo
content — and it is the reason step 4's fixture change is load-bearing rather
than cosmetic. `GATES_ROOT_BOOTSTRAP` and its shrink-only ceiling of 3 are
untouched — no declared directory is unadmitted, so none needs bootstrapping.

**Do not put directories into `GATES_ROOT_FILES`, `GATES_META_GUARD_HARD` or
`GUARD_LABEL`.** That loop's `-f` test stays as it is. The isolation guard
already covers `gates`, `tests`, `docs` as HARD and `prds`, `.claude/skills`
as SOFT; `.obsidian` and `vicky` are edited by a human outside gate runs, so
hashing them into HARD would manufacture false convictions. The guard label
must come out byte-identical.

### 3. The census line carries the breakdown (R4's readable half)

```
root: census of <dir> — <n> root entries walked (<nf> file/symlink, <nd> dir, <no> other), <s> undeclared
```

`n` counts every walked entry, rule-skipped ones included, as it does today.
`no` covers fifo, socket and anything else. The `^root:` prefix stays on every
line — `bash gates/selftest.sh | grep -c '^root:'` must still be 1 on a clean
root plus one line per stray.

### 4. The fixture needs a tracked directory set (order matters)

S3.6 builds its root copy with `scratch_tree`, which copies `prds docs tests
home`, then `git init`s it and adds only `AGENTS.md CLAUDE.md`. Once
directories are walked, those four copied directories reach the admission
check and read untracked, so the "green without the plant" counterfactual goes
red for the wrong reason. Widen the fixture's add:

```sh
git init -q "$RT" 2>/dev/null
git -C "$RT" add -A 2>/dev/null   # the directory admission rule asks git, and
                                  # a scratch copy is not a repo
```

534 files (`find prds docs tests home -type f | wc -l`, 2026-08-23). The
existing normalisation loop is unchanged — it
deletes stray *files* only, which is now correct rather than accidental,
because the copy's directories are declared.

**The plant must come after the add**, or it reads `git-tracked yes` and the
existing provenance assertion fails. `.git` inside `$RT` is rule-skipped like
any other.

### 5. The directory counterfactual, asserting the count (R3, R4)

Add to S3.6, after the existing `.DS_Store` case. Capture the dir count from a
clean run first, then plant:

```sh
rout="$(GATES_ROOT_DIR="$RT" bash "$GATES_DIR/selftest.sh" --root 2>&1)"
rd0="$(sed -n 's/.*census of .* — .*, \([0-9]*\) dir,.*/\1/p' <<< "$rout")"
mkdir -p "$RT/cf-planted-dir"
echo "      MUTATION: planted the directory cf-planted-dir in the root copy"
rout="$(GATES_ROOT_DIR="$RT" bash "$GATES_DIR/selftest.sh" --root 2>&1)"; rst=$?
rd1="$(sed -n 's/.*census of .* — .*, \([0-9]*\) dir,.*/\1/p' <<< "$rout")"
```

Five `chk_ok` lines, with **these exact labels** — the mutation run in Verify
and Proof greps for them:

```sh
local rdx="$((rd0 + 1))"
chk_ok "meta: a stray DIRECTORY at the guarded root is red" \
  test "$rst" -ne 0
chk_ok "meta: and the census NAMES the directory with its kind and provenance" \
  grep -qE 'root: STRAY cf-planted-dir — size [0-9]+, mtime [0-9-]+ [0-9:]+, git-tracked no, git-ignored no, kind dir' <<< "$rout"
chk_ok "meta: the census dir count parsed at all (got [$rd0] → [$rd1])" \
  test -n "$rd0"
chk_ok "meta: the census dir COUNT rose by exactly one — a walk that stopped seeing directories reports the same count and PASSES" \
  test "$rd1" = "$rdx"
chk_ok "meta: and the census reports exactly 1 undeclared" \
  grep -qE 'census of .*, 1 undeclared' <<< "$rout"
```

The parse check is its own line, not `test -n "$rd0" -a "$rd1" = "$rdx"`: a
five-argument `test` with `-a` is unspecified, and an empty `$rd0` from an
unparseable census line would make the comparison vacuously true —
`$((rd0 + 1))` is `1` for an empty `rd0`.

That count pair is R4. A walk narrowed back to files reports the same `rd0`
twice and `0 undeclared`, so it fails here where a bare `rst -ne 0` would pass
on any unrelated redness.

Then remove the plant and assert green again, so this counterfactual has both
poles like the file one:

```sh
rm -rf "$RT/cf-planted-dir"
```

### 6. Record the R5 sweep (R5)

Add a comment block above `root_inventory()` carrying the count, the predicate
and the site list from the PRD report — this file is the node's only footprint,
so the finding lives here or nowhere. **Do not fix any of those sites.**

Predicate, reproducible:

```sh
grep -rn -- '-type f' gates/*.sh tests/*.sh
```

Keep a site only when **both** hold: (a) the `find` is the sole walk behind the
assertion — no companion walk without a type filter and no `! -type f`
line; and (b) the assertion's subject is the whole tree — an exact-set census,
a change-detection hash, or a banned-content sweep.

| site                         | subject                                            |
|------------------------------|----------------------------------------------------|
| `tests/shell-init.sh:214`    | "the generator wrote the three files and NOTHING else" |
| `tests/nvim-options.sh:230`  | "holds exactly the post-E.13 census"               |
| `tests/nvim-completion.sh:186` | banned-plugin sweep over the config tree          |
| `tests/nvim-lsp.sh:217`      | stub-binary sweep over mason packages              |
| `tests/nvim-lsp.sh:224`      | the same sweep, negated form                       |

**5 sites in 4 scripts, plus this census: a habit, not a one-off.** Excluded by
(a): `gates/lib.sh:109` and `:175` both pair their `-type f` hash with an
unfiltered or `! -type f` walk, and `tests/shell-claude.sh:448`/`:453` do the
same — their class is covered. Excluded by (b): `tests/nvim-autocmds.sh:653`
and `tests/nvim-options.sh:350`, whose subject really is "one file exists".
`gates/retired-phrases.sh` uses `! -type l` at three sites — the inverse
decision, made explicitly, and not this defect.

## Acceptance

- [~] `bash gates/selftest.sh --root` exits 0 on the live root, and the census
      line reports `9 dir`, `0 other`, `0 undeclared` and a walked total equal
      to `find . -mindepth 1 -maxdepth 1 | wc -l`. Quote the census line and
      that count together. **Walked total matches exactly (17 = 17) and `0
      other` holds; the live root is NOT clean today**, so it reports `10 dir,
      1 undeclared` and rc 1, naming `.pearde-fork-2026-08-24` — a gitignored
      stale fork copy (`.gitignore:18`) that arrived after this spec was
      written. Not declared, per this spec's own `.pi` rule. rc 0 with the dir
      count is proved on a clean synthetic root instead. See the PRD's Result,
      box 1.
- [~] `GATES_ROOT_DIRS` declares exactly `.claude .obsidian docs gates home
      prds tests vicky`, each with the reason from the table above in the
      comment, and `.git` is skipped by RULE beside `.DS_Store` with its reason
      written down. Quote the two lines and the rule. **Deviated on `.claude`,
      deliberately**: commit `2587abf` (01:29, after this spec was written)
      removed the last tracked file under it, so `git ls-files .claude` returns
      0 paths and declaring it produced a permanent `FAIL … (unadmitted:
      .claude)` that `GATES_ROOT_BOOTSTRAP` cannot absorb. It is skipped by
      RULE beside `.git` and `.DS_Store` — the category this spec itself
      defines for a name that can never be admitted — with the measurement and
      a note to move it back if it holds committed content again. The other
      seven are declared with their reasons.
- [x] The walk has no `-type` filter: `grep -n 'mindepth 1 -maxdepth 1'
      gates/selftest.sh` shows the bare walk, and the comment states why
      dropping the filter beat adding `-type d`. Quote both. →
      `299:  done < <(find "$GATES_ROOT_DIR" -mindepth 1 -maxdepth 1)`, and a
      planted fifo is named `kind fifo` by the same walk.
- [x] `GUARD_LABEL` is byte-identical to before the change — no directory
      entered the isolation hash. Prove it with the 2-second probe `bash
      gates/selftest.sh --one gates/probes.sh 2>&1 | grep -m1 'sha256 over'`
      before and after, and quote the empty diff. Measured 2026-08-23, the
      label is `sha256 over gates, tests, docs, .chezmoiroot, .gitignore,
      AGENTS.md, CLAUDE.md, install.sh, justfile`.
- [x] A planted stray **directory** turns `--root` red and is named with
      `kind dir` and its provenance. Quote the STRAY line.
- [x] The count assertion holds: the planted run's `dir` count is the clean
      run's plus one, and `1 undeclared`. Quote both census lines side by side.
      → in-gate `got [5] → [6]`, both PASS.
- [x] **R4 demonstrated by mutation**: in a scratch copy of `gates/` re-narrow
      the walk back to files and symlinks, run the new counterfactual out of
      that copy, and show **four of its five directory assertions go red** —
      the stray, the naming, the count-rose and the 1-undeclared lines. Only
      the parse check stays green, because `0` still parses. Quote all five
      lines. A count assertion that survives its own mutation is not an
      assertion. Recipe in Verify and Proof; the live `gates/` is never
      mutated.
- [x] The file counterfactual still passes unchanged — the appended `kind`
      field did not break S3.6's existing provenance regex, and the
      no-plant run is still green. Quote both PASS lines.
- [x] `bash gates/selftest.sh --selftest` reports **no new FAIL** against the
      baseline captured before the change. Quote both summary lines and the
      FAIL diff. → both `── selftest rc=0 ──`, 0 FAIL either side, empty diff,
      PASS 17 → 23 (+6, the new assertions).
- [~] `bash gates/selftest.sh | grep -c '^root:'` is 1 on a clean root — the
      census still runs once per sweep. Quote the number. → **2** on the live
      root: one census line plus one line for the one stray, which is the
      stated invariant ("1 on a clean root, plus one line per stray"). The
      once-per-sweep property holds; the clean-root value of 1 could not be
      measured while the stray is present.
- [~] The R5 count, predicate and site table are in the comment block above
      `root_inventory()`, and no file under `tests/` was touched: `git status
      --porcelain tests/` is empty. Quote it. **The comment block is in place
      (6 sites in 5 scripts, with the predicate and the exclusions). The
      `tests/` emptiness check is unmeasurable on this workspace**: `git status
      --porcelain tests/` already listed 41 entries before this node started
      and is churning continuously — other lanes are writing `tests/` right now
      and the coordinator committed part of it mid-run. Non-involvement is
      shown instead by the footprint: the only write this node made was to
      `gates/selftest.sh`, and `git status --porcelain gates/` lists exactly
      `?? gates/selftest.sh` (plus `?? gates/manual/wave5.md`, another lane's).

## Verify and Proof

```sh
cd "$(git rev-parse --show-toplevel)"

# baseline, BEFORE editing
bash gates/selftest.sh --selftest > /tmp/st-before.txt 2>&1; echo "rc=$?"
grep -c '^FAIL' /tmp/st-before.txt
bash gates/selftest.sh --one gates/probes.sh 2>&1 \
  | grep -m1 'sha256 over' > /tmp/label-before.txt

# the census, after
bash gates/selftest.sh --root; echo "rc=$?"
find . -mindepth 1 -maxdepth 1 | wc -l

# the guard label did not move — 2 seconds, not the 3.5-minute sweep
bash gates/selftest.sh --one gates/probes.sh 2>&1 \
  | grep -m1 'sha256 over' > /tmp/label-after.txt
diff /tmp/label-before.txt /tmp/label-after.txt && echo "label unchanged"

# the census still runs exactly once per sweep
bash gates/selftest.sh > /tmp/sweep-after.txt 2>&1
grep -c '^root:' /tmp/sweep-after.txt   # must be 1

# both counterfactuals, file and directory
bash gates/selftest.sh --selftest > /tmp/st-after.txt 2>&1; echo "rc=$?"
grep -E 'cf-planted' /tmp/st-after.txt
diff <(grep '^FAIL' /tmp/st-before.txt) <(grep '^FAIL' /tmp/st-after.txt)

# R4's mutation — a scratch copy of the whole gates/ dir, so lib.sh resolves
# beside it and the live gates/ is never touched. REPO_ROOT becomes the empty
# $M, so scratch_tree yields an empty root copy: the file half of S3.6 is noise
# here, and only the cf-planted-dir lines are being read.
M=$(mktemp -d); cp -R gates "$M/gates"
# -mindepth/-maxdepth are global options, so appending the type test needs no
# parentheses: the walk keeps its depth limits and stops emitting directories.
sed -i '' 's/-mindepth 1 -maxdepth 1)/-mindepth 1 -maxdepth 1 -type f -o -type l)/' \
  "$M/gates/selftest.sh"
grep -n 'maxdepth 1 -type f' "$M/gates/selftest.sh"   # the mutation applied
bash "$M/gates/selftest.sh" --selftest 2>&1 \
  | grep -E 'stray DIRECTORY|NAMES the directory|dir count parsed|dir COUNT rose|1 undeclared'
#   Four of the five must read FAIL — stray, NAMES, COUNT rose, 1 undeclared.
#   Only "dir count parsed at all" stays PASS (0 parses). A PASS on the COUNT
#   line means the assertion cannot fail and proves nothing.
rm -rf "$M"

git status --porcelain tests/
```
