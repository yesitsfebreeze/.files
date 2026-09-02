---
complexity: 8
footprint:
  - .pearde/prds/09-simplify/01-hygiene/specs/spec01.md
  - .pearde/prds/00-delivery/corrections/baseline-commit-absorbs-live-claims/prd.md
workflow: prove-a-recorded-defect-from-its-artifacts
---

# spec03 — spec01 of 01-hygiene, and the reconciliation that closed

R3 and the unclosed reconciliation. Both are corrections to what is written
down, and both were measured during this node's build rather than argued.

**What already stands, and is not work:** R3's second defect is **already
corrected**. `01-hygiene`'s spec02 was rewritten by the orchestrator on
2026-09-02 and names all four of its own sub-defects in prose — the
`git add -A -- … install` that dies once the file is gone, `grep -c` exiting
1 on the zero a deletion produces, `git commit` in a verify block
re-committing, and `chezmoi apply --dry-run ; echo rc=$?` swallowing the
status. Its Verify block is now a re-runnable proof. Nothing to do; the box
below records it.

**R3's first defect is real but misdescribed, and the correction has to say
so.** The PRD says `':!.pearde/09-simplify'` names "a path that does not
exist". It does exist: an empty, untracked probe directory made at 11:20 at
the wrong level — probes belong at `prds/<prd>/probe/`. So the exclusion
matched a directory that held no file, which git would never have staged,
and it was a no-op for a *different* reason than the one recorded. What the
exclusion did **not** cover is `.pearde/prds/09-simplify` — the node's own
board state — and that state was in fact swept, into `b637aad` at 11:52:16.
Git's silence on an unmatched exclude pathspec is real and confirmed
separately: `git add --all --dry-run -- . ':!.pearde/NO-SUCH-PATH'` exits 0
and writes nothing to stderr.

**The reconciliation closes.** Recounted with one counter on both sides —
a line starting `+` and not `+++` is an addition, `-` and not `---` a
deletion, applied identically to the claim diff and to `git show 5dceabc`.
Over the 187 files the two share, **both sides read `+2029/-12196`, and
zero shared files differ**. `01-hygiene` R1's claim that the baseline edited
no content **holds**. The two figures in the PRD body were `+2029/-12074`
and `+1857/-10109`; neither survives the recount, which is exactly what the
node warned would happen. The 3 files only in the claim are spec01's
declared exclusions, as recorded.

**One fact the node does not carry, and must.** The baseline subject was
committed **five times**, not once: `5dceabc` 11:39:04, `b637aad` 11:52:16,
`2f4b52f` 11:53:04, `7b44151` 11:53:14, `adcd544` 11:53:27. The cause is
spec01's Verify block, which commits — so every re-run of that block
committed whatever was dirty at that instant. Two of the five absorbed
live-claim paths: 5 in `5dceabc`, 6 in `b637aad`. The blast radius on the
record is one commit and three paths; it is two commits and eleven.

**What is left:** rewrite `01-hygiene`'s spec01 Verify block as a proof of
the post-state — no `git add`, no `git commit`, no `git reset` — the way its
spec02 already is; write the recount, the misdescription and the five
commits into this node's body. Do not rewrite history: `5dceabc` and
`b233cc0` are out of scope and so are the three later commits.

## Acceptance

- [x] `python3 scripts/board-guard.py verify-blocks` exits 0 — no spec on
      the board stages or commits, `01-hygiene`'s spec01 included
      *(run 2026-09-02, after the orchestrator applied this node's
      replacements: `rc=0`, no output. Before: exit 1 on 5 acting lines in 2
      files. Re-censused over the whole board: 1 line in 1 file left,
      `09-simplify/01-hygiene/specs/spec02.md:122` `git add -n`, exempt as a
      dry run.)*
- [x] `01-hygiene`'s spec01 Verify block re-runs: run it twice from a clean
      tree, exit 0 both times, and `git status --short` is byte-identical
      before and after
      *(run 2026-09-02, the block extracted from the rewritten spec and run
      as-is: `RUN1=0`, `RUN2=0`, and `git status --short` hashes to
      `da594834fcf88da495690e0852941a15` before and after both runs. It
      stages nothing: every line reads `5dceabc` or the index rather than
      writing.)*
- [x] this node's body carries the recount as a number: `+2029/-12196` on
      both sides over 187 shared files, 0 files differing, and says the
      purity claim holds
      *(run 2026-09-02: `probe/recount.py` prints `shared, claim side:
      +2029/-12196`, `shared, commit side: +2029/-12196`,
      `delta: +0/-0`, `shared files whose counts differ: 0`, and both
      figures are in the body.)*
- [x] this node's body names all five baseline commits with their times, and
      says which two absorbed live-claim paths and how many each
      *(run 2026-09-02: `git log --format=%s --all | grep -c 'landed before
      simplification'` = 5, and all five shas grep out of the body.)*
- [x] this node's R3 no longer says `.pearde/09-simplify` does not exist, and
      says instead what the exclusion did and did not cover
      *(run 2026-09-02: `grep -c 'a path that does not exist'` = 0; R3 now
      says the directory exists, is empty and untracked — measured:
      `git ls-files .pearde/09-simplify` = 0 lines, `git status --short`
      = 0 lines — and that `.pearde/prds/09-simplify` is what was swept,
      into `b637aad`.)*
- [x] `01-hygiene`'s spec02 is untouched — it was already correct
      *(mtime `2026-09-02 12:12:03`, before this claim at 12:20; this
      worker made no edit to it.)*

## Verify and Proof

```sh
cd /Users/feb/dev/dotfiles
set -eu
P=.pearde/prds/00-delivery/corrections/baseline-commit-absorbs-live-claims/prd.md
H=.pearde/prds/09-simplify/01-hygiene/specs/spec01.md

python3 scripts/board-guard.py verify-blocks

# the recount, re-derived here rather than trusted from the body
python3 .pearde/prds/00-delivery/corrections/baseline-commit-absorbs-live-claims/probe/recount.py \
  | grep -q '^delta:               +0/-0$'
grep -q '+2029/-12196' "$P"
grep -q '187' "$P"

# five commits, named
test "$(git log --format=%s --all | grep -c 'landed before simplification' || true)" = 5
for c in 5dceabc b637aad 2f4b52f 7b44151 adcd544; do grep -q "$c" "$P"; done

# the misdescription is gone
test "$(grep -c 'a path that does not exist' "$P" || true)" = 0

# spec01 of 01-hygiene no longer stages or commits
test "$(grep -cE '^\s*git (add|commit|reset)' "$H" || true)" = 0

# and git's silence on an unmatched exclusion still holds
E=$(mktemp); git add --all --dry-run -- . ':!.pearde/NO-SUCH-PATH-AT-ALL' >/dev/null 2>"$E"
test ! -s "$E"; rm -f "$E"
echo PASS
```
