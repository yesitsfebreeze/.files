---
est: 2.5h
footprint:
  - gates/selftest.sh
---

# spec02 — a declared root inventory, so a stray file FAILs instead of widening the hash

`gates/selftest.sh:100-104` builds its guarded root-file list from a glob:

```sh
for _f in "$REPO_ROOT"/* "$REPO_ROOT/.chezmoiroot" "$REPO_ROOT/.gitignore"; do
  [ -f "$_f" ] && GATES_ROOT_FILES="…$_f"
done
```

A glob cannot have an opinion. Measured today, the guard label reads:

```
sha256 over gates, tests, docs, AGENTS.md, cf-rm-site-dropped.nu,
cf-rm-site-in-another-def.nu, CLAUDE.md, install.sh, justfile, nvim.log,
.chezmoiroot, .gitignore
```

Three leaked artifacts silently joined the isolation contract. Each new one
widens the window a concurrent write can trip, which is the opposite of what
the guard is for. Replace the glob with a **declared inventory**: anything else
at the root is a FAIL that names the file.

Why the repo root is the whole of the needed coverage, mechanistically rather
than hopefully: the leak mechanism is "an unresolved path resolves to `$PWD`"
(spec01), and `gates/waves.tsv`'s header says gate commands run FROM THE REPO
ROOT, so `$PWD` *is* the root. Measured confirmation — the only artifact-shaped
or zero-byte files anywhere in `gates/`, `tests/`, `home/`, `docs/` or the root
are the three at the root:

```
$ find . -path ./.git -prune -o -path ./.obsidian -prune -o -type f -size 0 -print
./cf-rm-site-dropped.nu
./cf-rm-site-in-another-def.nu
./nvim.log
```

## What to change

### 1. The inventory replaces the glob

```sh
# THE ROOT INVENTORY. Not a glob: a glob has no opinion, and three leaked
# counterfactuals joined the isolation contract unnoticed because of that
# (see prds/00-delivery/corrections/gate-artifact-leakage). Regular files and
# symlinks only; .DS_Store is excluded by RULE below, never by listing.
GATES_ROOT_INVENTORY=".chezmoiroot .gitignore AGENTS.md CLAUDE.md install.sh justfile"
# Inventory entries that are not yet committed. SHRINK-ONLY, and pinned below:
# to admit a new root file you must `git add` it. A leaked zero-byte
# counterfactual never gets committed, so it can never buy its way in here.
GATES_ROOT_BOOTSTRAP=".chezmoiroot install.sh justfile"
```

`GATES_ROOT_FILES` is then built from `GATES_ROOT_INVENTORY` (still skipping
entries that are absent, so the guard survives a file legitimately going away).
The label order becomes the inventory order and is therefore deterministic.

### 2. The root check, run ONCE per sweep

A new function — call it `root_inventory` — that:

- lists root regular files and symlinks once (`find "$ROOT" -maxdepth 1
  \( -type f -o -type l \)`), one walk, no per-gate repetition;
- ignores `.DS_Store` by rule, with the existing comment's reason (Finder
  writes it, no gate ever will);
- for each remaining entry not in `GATES_ROOT_INVENTORY`, prints one line with
  its size, mtime, and whether git tracks it
  (`git ls-files --error-unmatch`) and whether git ignores it
  (`git check-ignore`) — that is the census row R1 asks for, produced by a
  tool rather than by hand;
- `chk`s red when the count is non-zero, with the remedy in the label:
  *delete the artifact; or, if it is real repo content, `git add` it and add it
  to `GATES_ROOT_INVENTORY` in the same change.*

Take the root directory from a variable defaulting to `$REPO_ROOT`
(`GATES_ROOT_DIR="${GATES_ROOT_DIR:-$REPO_ROOT}"`), in the same house style as
`GATES_META_GUARD`, so the counterfactual below can point it at a scratch copy.

Prefix every line it prints with `root:` so the once-per-sweep property is
countable.

Two more boxes in the same function:

- every `GATES_ROOT_INVENTORY` entry is tracked **or** named in
  `GATES_ROOT_BOOTSTRAP`;
- `GATES_ROOT_BOOTSTRAP` holds at most 3 names (`test "$(wc -w <<<
  "$GATES_ROOT_BOOTSTRAP")" -le 3`). This is the anti-growth mechanism: the
  allow-list cannot grow by hand, only by commit, and the bootstrap escape
  hatch can only shrink as the board commits `install.sh`, `justfile` and
  `.chezmoiroot`.

### 3. Call it from `run()` only

Not from `check_contract` (that would walk per gate — the performance rule) and
not from the `--one` path. `--one` is the counterfactual harness:
`contract_says` compares an exact rc, so a dirty root leaking into `--one`'s rc
would break every meta-counterfactual. `run()` is called once from `selftest()`
inside a command substitution, so its rc does not propagate there either.

### 4. Prove it in `--selftest`

Add to `selftest()`, in the existing style (a scratch victim tree, red and
green both asserted):

- `scratch_tree` a copy; plant `cf-planted.nu` in it; `GATES_ROOT_DIR=<copy>`
  → the check is red and its output NAMES `cf-planted.nu`;
- the same copy with the plant removed → green;
- a `.DS_Store` planted in the copy → still green.

### 5. Write the R4 recommendation into the report

R4 asks whether the hash should be derived **from tracked files** plus an
allow-list. Measure it and answer no, with the numbers: `git ls-files | wc -l`
is 99 against 483 untracked-and-un-ignored paths, and `gates/lib.sh`,
`gates/selftest.sh`, `install.sh`, `justfile` and `.chezmoiroot` are all
untracked right now. A tracked-derived guard would stop watching the library
every gate sources — the guard would get *weaker*, not narrower. The inventory
above is the same idea with the tracked set as an admission *rule* rather than
as the membership list, which is why it is built here and the tracked-derived
variant is declined. State that reading of R4 explicitly in the report so the
orchestrator can settle it.

## Acceptance

- [x] The guard label is exactly the inventory, with no artifact names:
      `bash gates/selftest.sh | grep -m1 -o 'sha256 over [^)]*'` prints
      `sha256 over gates, tests, docs, .chezmoiroot, .gitignore, AGENTS.md, CLAUDE.md, install.sh, justfile`
      (order follows the inventory; quote the actual line).
- [x] A planted stray file is RED and NAMED: with `cf-planted.nu` in a
      `scratch_tree` copy, `GATES_ROOT_DIR=<copy> bash gates/selftest.sh`
      exits non-zero and its output matches `root:.*cf-planted.nu`.
- [x] The same copy without the plant is GREEN — the check can pass, so its
      redness means something.
- [x] `.DS_Store` in that copy does not turn it red.
- [x] The census row carries provenance: the red output for the plant states
      its size, its mtime, and that git neither tracks nor ignores it.
- [x] The inventory cannot grow by hand: `GATES_ROOT_BOOTSTRAP` has ≤ 3 names
      and the check asserts it; adding a fourth name makes
      `bash gates/selftest.sh` exit non-zero (demonstrate with a one-off
      `GATES_ROOT_BOOTSTRAP="a b c d"` if the variable is overridable, or by a
      temporary edit reverted in the same box, and quote the FAIL).
- [x] Every inventory entry is tracked or bootstrapped — the check asserts it
      and is green on the real tree.
- [x] One walk per sweep, not one per gate:
      `bash gates/selftest.sh | grep -c '^root:'` is 1 (or the number of lines
      one census emits — state which and why it is independent of the gate
      count).
- [x] `--one` is unaffected: `bash gates/selftest.sh --one gates/probes.sh |
      grep -c 'root:'` is 0, and the meta-counterfactuals still pass
      (`bash gates/selftest.sh --selftest` exits 0).
- [x] The new `--selftest` counterfactuals appear in
      `bash gates/selftest.sh --selftest` output and pass.

## Verify and Proof

```sh
cd "$(git rev-parse --show-toplevel)"
bash gates/selftest.sh | grep -m1 -o 'sha256 over [^)]*'
bash gates/selftest.sh --one gates/probes.sh | grep -c 'root:'
bash gates/selftest.sh --selftest; echo "selftest-of-selftest rc=$?"
bash gates/selftest.sh; echo "sweep rc=$?"
```

Note for sequencing: spec03's green run depends on this spec and on spec01.
