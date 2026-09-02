---
complexity: 10
footprint:
  - .pearde/prds/09-simplify/01-hygiene/prd.md
  - .pearde/prds/09-simplify/prd.md
  - AGENTS.md
workflow: prove-a-recorded-defect-from-its-artifacts
---

# spec02 — retire "commit the current working tree" as a requirement shape

R1. One requirement on this board is written as a bulk commit, and one
epic's children table repeats it in different words. Both are rewritten to
name paths, and the rule that replaces the shape goes where every worker on
this board already reads.

**What already stands:** nothing was rewritten. The census run during this
node's build found the shape in two places, and found that the PRD's own
acceptance box for it is unusable as spelled.

**Two defects in the acceptance box, both measured:**

- `grep -rn 'current working tree' .pearde/prds --include=prd.md` **cannot
  return empty**, because this node's own body quotes the phrase three
  times while explaining the defect. A check that can only pass by deleting
  the record of why it exists is not a check.
- It also **under-matches**. `09-simplify/prd.md` line 72 says "Commit the
  working tree as-is" — the same instruction, a different spelling, and the
  grep misses it entirely.

The replacement is a check on the *shape*, restricted to requirement lines:
a line that is a numbered requirement (`- [ ]` or `- [x]` followed by
`**R<n>**`) and that asks for the tree rather than named paths. Prose that
cites the defect is not a requirement line and does not match.

**What is left:**

1. Rewrite `09-simplify/01-hygiene` R1. It must name what lands: the
   `01-hygiene` folder, the `--also` path already recorded in the same
   requirement, and the exclusion set. Keep the added 2026-09-02 paragraph —
   it is the record of why the `--also` route was named.
2. Rewrite the `01-hygiene` row of `09-simplify`'s children table so it does
   not say "the working tree as-is".
3. Add the rule to `AGENTS.md`, in **How to write a PRD**, beside
   "Everything testable is a box": *a requirement names paths, or an
   exclusion set computed from the live claims; never the tree.* Say why in
   one clause — a bulk add absorbed a concurrently-claimed node's work on
   2026-09-02 — and link this node.

## Acceptance

- [x] no line in `.pearde/prds/**/prd.md` that is a numbered requirement
      asks for the tree — checked by `board-guard.py requirements`, which
      matches the shape and not one spelling, and which does not fire on
      prose that quotes the defect
      *(run 2026-09-02, after the orchestrator applied this node's
      replacement to `09-simplify/01-hygiene` R1: `rc=0`, no output — the
      one survivor is gone. The check's own halves are proven separately: it
      fires on both spellings on a fixture board, and it does not fire on
      this node's four quotations of the phrase, nor on
      `git-diff-integrity-boxes` R4, which says "commit" and "working tree"
      in different clauses.)*
- [x] `09-simplify/01-hygiene` R1 names the paths it lands and the paths it
      holds back, and no longer opens "The current working tree is committed"
      *(read 2026-09-02: R1 now opens "One commit lands the paths this node
      names and no others", names `.pearde/prds/09-simplify/01-hygiene/` and
      `.pearde/prds/09-simplify`, and lists the five paths held back;
      `grep -c 'R1\*\* — The current working tree is committed'` = 0.)*
- [x] `09-simplify`'s children table row for `01-hygiene` no longer says
      "the working tree as-is"
      *(run 2026-09-02: `grep -c 'working tree as-is'
      .pearde/prds/09-simplify/prd.md` = 0; line 72 now reads "Land the
      2026-09-01 state as one commit over the paths R1 names".)*
- [x] `AGENTS.md` carries the rule and links this node, and the link
      resolves to a file on disk
      *(run 2026-09-02: `grep -q 'baseline-commit-absorbs-live-claims'
      AGENTS.md` and `test -f …/prd.md` both pass.)*
- [x] the check fires on a fixture: a requirement line written the old way,
      in a scratch board built at run time, is named and exits 1
      *(run 2026-09-02: exit 1 on `- [ ] **R1** — The current working tree
      is committed as one baseline.` and on `Commit the working tree as-is`;
      exit 0 on `Stage `home/x` and `docs/y``.)*

## Verify and Proof

```sh
cd /Users/feb/dev/dotfiles
set -eu
W=$(mktemp -d); trap 'rm -rf "$W"' EXIT

python3 scripts/board-guard.py requirements          # exits 1 on any survivor

# the rewritten requirement
R=.pearde/prds/09-simplify/01-hygiene/prd.md
grep -q '\*\*R1\*\*' "$R"
test "$(grep -c 'R1\*\* — The current working tree is committed' "$R" || true)" = 0

# the epic's table
test "$(grep -c 'working tree as-is' .pearde/prds/09-simplify/prd.md || true)" = 0

# the rule, and its link
grep -q 'baseline-commit-absorbs-live-claims' AGENTS.md
test -f .pearde/prds/00-delivery/corrections/baseline-commit-absorbs-live-claims/prd.md

# the check can fail: a fixture written the old way
mkdir -p "$W/.pearde/prds/toy"
printf -- '---\nstate: open\n---\n\n# toy\n\n## Requirements\n\n- [ ] **R1** — The current working tree is committed as one baseline.\n' \
  > "$W/.pearde/prds/toy/prd.md"
if python3 scripts/board-guard.py requirements --board "$W/.pearde" 2>"$W/o.txt"
then echo "FAIL: the check cannot fail"; exit 1; fi
grep -q 'toy/prd.md' "$W/o.txt"

# and it does NOT fire on prose that quotes the defect
grep -q 'current working tree' \
  .pearde/prds/00-delivery/corrections/baseline-commit-absorbs-live-claims/prd.md
python3 scripts/board-guard.py requirements
echo PASS
```
