---
complexity: 14
footprint:
  - scripts/board-guard.py
  - justfile
workflow: prove-a-recorded-defect-from-its-artifacts
---

# spec01 — the guard, and the check for the hole it covers

R2. Two checks in one file, because they are two halves of one rule: a path
another node holds under a live claim is not this node's to stage, and a
spec's `## Verify and Proof` block is not the place staging happens at all.

**What already stands — built and proven by this node's probe, uncommitted
at `probe/`:**

- `probe/claim_guard.py` is the held-paths guard. Given a path set (or, with
  none, what a bare `git add --all` would take) it names every path a live
  claim holds and exits 1. Replayed against `5dceabc` with the board tree
  archived out of that same commit, it names **five** paths: the three board
  files the skeptic reported *and* the two code footprint files the
  implementer reported as F-A. Both independent reports, reproduced from
  artifacts in one run.
- It reads `state:` + `claim:` off each `prd.md`, **not** `.pearde/.claims/`.
  This is the correction R2 needs and does not yet carry: the victim's claim
  directory was stamped `2026-09-02 11:44:46`, five minutes *after* the
  11:39:04 commit that swept it. A guard reading only the snapshot dir would
  have passed the very commit that caused this node to exist. The snapshot
  dir is a second source, never the first.
- `probe/verify.sh` runs six proofs and is re-runnable — checked twice, exit
  0 both times, nothing staged and nothing committed.

**What `collect` already does, so this spec does not rebuild it:** collect
refuses a cross-claim path today. Demonstrated on a two-PRD fixture built at
run time — `alpha` claimed, `beta` analyzing, both footprints naming
`src/shared.txt` — where `collect --dry alpha` answers, without being asked
to:

    collect: alpha: src/shared.txt is in beta's footprint too — not only
    this PRD's edits; `--widen src/shared.txt` takes it whole

R2's sentence "Today nothing checks it" is therefore false of `collect` and
true of everything that bypasses it. That is the hole this spec covers.

**What is left:**

1. Move `probe/claim_guard.py` to `scripts/board-guard.py`, unchanged in
   behaviour, and give it a second subcommand `verify-blocks` that reads
   every ```sh block under a `## Verify and Proof` heading in
   `.pearde/prds/**/*.md` and exits 1 on a line beginning `git add`,
   `git commit`, `git rm`, `git reset` or `git stash`. A census run during
   this node's build found **8 such lines in 5 files**; three of them are
   `01-hygiene`'s spec01, which is what committed the tree five times.
2. Two `just` recipes, `board-guard` and `board-guard-blocks`, so the check
   is one word and not a remembered path.
3. `scripts/generate-manual.mjs` is held by `09-simplify/03-help-system`
   right now — the guard said so when this spec's own footprint was checked
   against it. Add nothing to that file; `scripts/board-guard.py` is new and
   free.

## Acceptance

- [x] `python3 scripts/board-guard.py held --self <any node> README.md`
      exits 0 and prints nothing — a free path is silent
      *(run 2026-09-02: `rc=0`, no output.)*
- [x] the guard, replayed against `5dceabc` with that commit's own board
      tree, exits 1 and its output names all five of
      `08-claude-agent/02-nvim-plugin/prd.md`, `.../report.md`,
      `.../specs/spec01.md`, `home/dot_config/nvim/lazy-lock.json` and
      `home/dot_config/nvim/lua/plugins/claude.lua`
      *(run 2026-09-02: `5 path(s) held by a live claim — none staged:`,
      all five named, each `held by 08-claude-agent/02-nvim-plugin
      (analyzing, claim analyst-nvim 2026-09-02 11:17)`.)*
- [x] `python3 scripts/board-guard.py verify-blocks` exits 1 today and names
      `09-simplify/01-hygiene/specs/spec01.md`, and exits 0 once spec03 of
      this node has rewritten that block
      *(both halves run 2026-09-02. Before: exit 1, naming that file's lines
      62, 63 and 67 and `ls-icons-glyphs/specs/spec03.md:234,237`. After the
      orchestrator applied this node's replacement text to both files:
      `rc=0`, no output. The census over the whole board is now 1 line in 1
      file, `09-simplify/01-hygiene/specs/spec02.md:122` `git add -n`, a dry
      run and exempt.)*
- [x] `just --list` shows `board-guard`, and `just board-guard` runs it
      *(run 2026-09-02: `just --list` lists `board-guard` and
      `board-guard-blocks`; `just board-guard` with no argument reports the
      68 held paths a bare `git add --all` would take today, and
      `just board-guard <node> README.md` exits 0.)*
- [x] the guard reads `state:`/`claim:` from `prd.md`: with
      `.pearde/.claims/` moved aside entirely, the replay above still names
      all five paths
      *(run 2026-09-02: the replay tree is `git archive`d out of `5dceabc`
      and carries no `.claims/` at all — `test ! -e "$W/.pearde/.claims"`
      passes — and the five paths are still named.)*

## Verify and Proof

```sh
cd /Users/feb/dev/dotfiles
set -eu
W=$(mktemp -d); trap 'rm -rf "$W"' EXIT

# a free path is silent
python3 scripts/board-guard.py held \
  --self 00-delivery/corrections/baseline-commit-absorbs-live-claims README.md

# the real incident, replayed out of the commit's own tree
git archive 5dceabc .pearde/prds | tar -x -C "$W"
git show --name-only --format= 5dceabc > "$W/staged.txt"
if python3 scripts/board-guard.py held --self 09-simplify/01-hygiene \
     --board "$W/.pearde" --repo "$W" --stdin < "$W/staged.txt" 2> "$W/g.txt"
then echo "FAIL: guard passed the commit that caused this node"; exit 1; fi
for p in .pearde/prds/08-claude-agent/02-nvim-plugin/prd.md \
         .pearde/prds/08-claude-agent/02-nvim-plugin/report.md \
         .pearde/prds/08-claude-agent/02-nvim-plugin/specs/spec01.md \
         home/dot_config/nvim/lazy-lock.json \
         home/dot_config/nvim/lua/plugins/claude.lua; do
  grep -q -- "$p" "$W/g.txt"
done
# and it did that with no .claims/ at all
test ! -e "$W/.pearde/.claims"

# no spec stages or commits
python3 scripts/board-guard.py verify-blocks

just --list > "$W/r.txt"
case "$(cat "$W/r.txt")" in *board-guard*) ;; *) exit 1 ;; esac
echo PASS
```
