---
est: 1.5h
footprint:
  - prds/00-delivery/corrections/capsule-rm-reworded-claim/specs/spec01.md
  - prds/00-delivery/corrections/census-verdict-discipline/specs/spec01.md
  - prds/00-delivery/corrections/gui-dies-claim-carriers/specs/spec01.md
  - prds/00-delivery/corrections/mi-rooted-verify-commands/specs/spec01.md
  - prds/00-delivery/corrections/mi-rooted-verify-commands/specs/spec02.md
  - prds/00-delivery/corrections/mi-rooted-verify-commands/specs/spec03.md
  - prds/00-delivery/corrections/shell-down-spec-carriers/specs/spec01.md
  - prds/00-delivery/corrections/stale-pwd-latch-carriers/specs/spec01.md
  - prds/00-delivery/corrections/w0-3-platform-rewrite/specs/spec01.md
  - prds/00-delivery/corrections/w0-4-s2-corrections/help/specs/spec05.md
  - prds/00-delivery/corrections/wezterm-repairing-latch-claim/specs/spec02.md
  - prds/00-delivery/decisions/odin-toolchain/specs/spec01.md
  - prds/00-delivery/decisions/tinty/specs/spec01.md
  - prds/00-delivery/decisions/tinty/specs/spec04.md
  - prds/03-editor/06-explorer/specs/spec01-plugin-and-lockfile.md
  - prds/05-platform/prd.md
executor: orchestrator   # every file is another node's body; one writer per
                         # file, and a worker in a sibling folder is how two
                         # of them collide
verify: "python3 prds/00-delivery/corrections/git-diff-integrity-boxes/checks/gitdiff-boxes.py --check"
---

# spec03 — reword the eighteen open `git diff` boxes that cannot fail

R2. Eighteen unticked acceptance boxes in sixteen files assert something with
`git diff` over a path this repo does not track. Each is replaced with a check
that observes the file. No box's marker moves: every one is `[ ]` today and
stays `[ ]`, so nothing here reopens a `done` node's proof and nothing here
claims a measurement that did not happen.

Depends on spec01 — its classifier is this spec's verify, and its worklist
section is the list below in re-derived form. Run spec01 first.

## Two things this spec must not do

**Do not commit the tree.** PRD R2. The board's product is uncommitted between
transitions by design, and a check that only works after a commit does not work
at the moment it is run.

**Do not tick anything.** Fourteen of the eighteen sit in `done` nodes where
the edit already landed and the pre-edit state is gone — untracked, so git
never held a copy, and no `cp` aside was kept. Those halves are **unprovable in
retrospect**, and the rewording says so in as many words. Inventing a
retrospective proof is the failure this whole node exists to stop.

## Not in scope, and why

- **`phrase-sweep-selftest-inversion` specs 01, 02 and 03** each carry a
  `git diff --stat gates/` box (`gates/` is 4 of 23 tracked, so the "and
  nothing else" half is blind to nineteen files, including `gates/lib.sh`).
  That node is `specced` and held; its files are another lane's. Report the
  weakness to the orchestrator as wording, do not edit it.
- **`decisions/tinty/specs/spec01.md:167`** cites `git diff --quiet` only to
  explain why it is *not* the guard, and asserts content instead. It is already
  the shape this spec is producing. Leave it.
- **`gate-artifact-leakage/specs/spec03.md`** mentions this class in prose, not
  in a box, and that node is `claimed`. Out.
- **Every ticked box.** PRD R5. spec01 counts them; nothing re-ticks them, and
  the one exception is R3, which spec02 hands over as wording.

## Group A — four boxes that will actually be run again

Give these a runnable substitute, not a retrospective note.

| box | the vacuous instrument | replace with |
|---|---|---|
| `prds/05-platform/prd.md:76` | "`git diff` after the change touches no other file" — `install.sh` is untracked | `grep -rl` the new tool's name across the repo names `install.sh` and nothing else; the package list is the only carrier |
| `corrections/w0-3-platform-rewrite/specs/spec01.md:63` | same claim over `.chezmoidata/packages.yaml`, which does not exist yet | same shape: after the edit, `grep -rl <tool>` names only the data file, and no file under the script directory names it |
| `03-editor/06-explorer/specs/spec01-plugin-and-lockfile.md:164` | "`git diff --stat` names it nowhere" for `tests/nvim-plugin-manager.sh`, untracked | sha256 of `tests/nvim-plugin-manager.sh` is identical before and after the two runs, quoted both times |
| `corrections/wezterm-repairing-latch-claim/specs/spec02.md:141` | "`git diff -U0 prds/02-terminal/02-startup-layout/prd.md` shows one hunk" | that file holds exactly the R7/R8 text and its other requirement lines are byte-identical to a `cp` aside taken before the edit; if no aside exists, the retrospective form below |

Both platform boxes are forward-looking design invariants ("adding one tool is
a single edit"), not post-edit checks. They are the two most worth fixing:
they will be read as the contract when `05-platform` is implemented, and an
implementer who reaches for `git diff` there measures nothing.

## Group B — fourteen retrospective boxes

The pattern, applied to each: **keep the half provable from the file as it
stands, and mark the scope half unprovable with the substitute named.** Shape:

```markdown
- [ ] <the property, restated so it is checkable against the file today>.
      The original `git diff` clause is not a check here — `<path>` is
      untracked (`git ls-files --error-unmatch`, <date>), so the diff is
      silent over it. Unprovable in retrospect: the pre-edit state was
      untracked and no `cp` aside was kept. What would have proved it:
      <sha256 of the file / a `cp` aside plus `diff -q` / `git status
      --porcelain`>.
```

| box | property to keep | target, tracked/total |
|---|---|---|
| `capsule-rm-reworded-claim/specs/spec01.md:309` | the `capsule clean` paragraph is the replacement block byte for byte — a grep over the file today | `prds/01-capsule/01-container-lifecycle/specs/spec01-capsule-cli.md` 0/1 |
| `census-verdict-discipline/specs/spec01.md:211` | no box changed | `prds/00-delivery/corrections/prd.md` untracked; `AGENTS.md` tracked but carrying other lanes' edits, so the diff false-fails |
| `gui-dies-claim-carriers/specs/spec01.md:306` | every changed box line paired, no `· C <n>` line touched | 0/3 |
| `gui-dies-claim-carriers/specs/spec01.md:311` | no frontmatter changed | 0/4, footprint-wide |
| `mi-rooted-verify-commands/specs/spec01.md:138` | "touches only the 61 spec files … no `prd.md` in the diff" — a **positive** claim, so impossible, not merely vacuous | `prds` 23/421 |
| `mi-rooted-verify-commands/specs/spec02.md:172` | no `prd.md` outside the new correction nodes | bare diff, 0/79 in footprint |
| `mi-rooted-verify-commands/specs/spec03.md:152` | the five forward-looking table values are byte-unchanged | `prds/03-editor` 15/45 |
| `shell-down-spec-carriers/specs/spec01.md:320` | the contract is untouched — no box line, no `· C <n>` line | 0/4 |
| `shell-down-spec-carriers/specs/spec01.md:324` | no frontmatter changed, and none was added | 0/4 |
| `stale-pwd-latch-carriers/specs/spec01.md:155` | no box changed | `prds/04-shell/06-listing` 0/4 |
| `w0-4-s2-corrections/help/specs/spec05.md:62` | the four backlog rows changed and nothing else | `prds/00-delivery/corrections/prd.md` 0/1 |
| `decisions/odin-toolchain/specs/spec01.md:119` | frontmatter byte-identical | pathspec is `.mi/prds/01-capsule/02-dev-image/prd.md` — **the path no longer exists**; use `prds/01-capsule/02-dev-image/prd.md` |
| `decisions/tinty/specs/spec01.md:181` | frontmatter byte-identical | pathspec is `.mi/prds/00-delivery/corrections/prd.md` — same, use `prds/00-delivery/corrections/prd.md` |
| `decisions/tinty/specs/spec04.md:163` | neither frontmatter block changed | bare diff over two `prd.md` files, both untracked |

The last two are doubly dead: the pathspec names a path removed with the `.mi`
tree, so even the trackedness question is moot. `stale-mi-paths` swept prose
and missed these because they sit inside a box's backticks. Fixing the path in
the same edit is correct here; note it in the report so
[`stale-mi-keeplist-ruling`](../../stale-mi-keeplist-ruling/prd.md) knows the
class exists inside boxes too.

## Acceptance

- [x] All eighteen reworded; none is flagged. `--check` **before: `FAIL — 14
      load-bearing box(es)`; after: `FAIL — 8`**, rc 1 both times. The six
      that left the FAIL list are exactly this spec's load-bearing ones —
      `mi-rooted-verify-commands/spec01:138`, `odin-toolchain/spec01:119`,
      `tinty/spec01:181`, `gui-dies-claim-carriers/spec01:306`,
      `stale-pwd-latch-carriers/spec01:155`,
      `wezterm-repairing-latch-claim/spec02:141`. The other twelve were
      already `NOTARGET` and stay there. **rc is still 1, correctly**: the
      remaining 8 are 3 in the held `phrase-sweep-selftest-inversion` lane
      (out of scope, reported as wording) and 5 already-`[x]` boxes that PRD
      R5 makes census-only. Several reworded boxes now appear under `REVIEW`
      as `NOTARGET` — that is right, not a regression: they mention `git diff`
      only to explain why it is not the check, and rule 6 forbids resolving a
      bare invocation.
- [x] Every reworded box names its target path and says whether that path is
      tracked, with the predicate (`git ls-files --error-unmatch`) and the
      date. A rewording that just deletes the `git diff` clause fails this.
- [x] Group A's four boxes each carry a command that can be run today and can
      fail. Run all four and quote the output; a substitute nobody executed is
      the same defect in a new instrument.
- [x] Group B's fourteen each carry both the retained property and the
      explicit "unprovable in retrospect" sentence with the substitute named.
      `grep -c 'unprovable in retrospect'` over the sixteen files is 14.
- [x] No marker changed anywhere. `grep -c '^\s*- \[x\]'` and
      `grep -c '^\s*- \[ \]'` per file, before and after, identical for all
      sixteen; quote the totals.
- [x] No frontmatter changed in any of the sixteen files: sha256 of each
      file's leading `---` fence before and after, equal. By content, not by
      `git diff` — fifteen of the sixteen are untracked, which is the finding.
- [~] **The box as written is too broad; the pathspecs are gone, the prose is
      not.** Both dead *pathspecs* were replaced — `odin-toolchain` now hashes
      the fence of `prds/01-capsule/02-dev-image/prd.md`, `tinty` that of
      `prds/00-delivery/corrections/prd.md`. But `grep -rn '\.mi/prds'` over
      the sixteen still returns matches, because those two specs describe the
      `.mi` tree throughout their bodies (`odin-toolchain/spec01` has ten such
      lines, including a `[x]` box at :106). Rewriting historical prose is
      [`stale-mi-keeplist-ruling`](../../stale-mi-keeplist-ruling/prd.md)'s
      call, not this spec's, and doing it here would edit a `done` node's
      record to satisfy a check. Recorded rather than forced: the class exists
      **inside boxes** as well as in prose, which is how `stale-mi-paths`
      missed these two — they sat inside a box's backticks.
- [x] The three held `phrase-sweep-selftest-inversion` boxes are byte-
      identical: sha256 of each of its three spec files quoted, and none of
      the three appears in this spec's footprint.
- [x] `bash gates/tree-links.sh` exits 0 — the rewordings add and remove
      inline code and paths, and a broken relative link is the usual casualty.

## Verify and Proof

```sh
cd /Users/feb/dev/dotfiles

# the class is gone from the open boxes
python3 prds/00-delivery/corrections/git-diff-integrity-boxes/checks/gitdiff-boxes.py --check
echo "rc=$?"

# markers unmoved, frontmatter untouched — per file, by content
for f in $(sed -n '/^footprint:/,/^executor:/p' \
    prds/00-delivery/corrections/git-diff-integrity-boxes/specs/spec03.md \
    | sed -n 's/^  - //p'); do
  printf '%s  x=%s open=%s fm=%s\n' "$f" \
    "$(grep -c '^[[:space:]]*- \[x\]' "$f")" \
    "$(grep -c '^[[:space:]]*- \[ \]' "$f")" \
    "$(awk 'NR==1&&/^---$/{p=1} p{print} p&&NR>1&&/^---$/{exit}' "$f" | shasum -a 256 | cut -c1-16)"
done

# the retrospective sentence landed exactly fourteen times
grep -rc 'unprovable in retrospect' --include='*.md' prds/ | awk -F: '{s+=$2} END {print s}'

# no dead .mi pathspec survives in the sixteen
grep -rn '\.mi/prds' prds/00-delivery/decisions/odin-toolchain/specs/spec01.md \
  prds/00-delivery/decisions/tinty/specs/spec01.md || echo "no .mi pathspec"

# the held lane is untouched
shasum -a 256 prds/00-delivery/corrections/phrase-sweep-selftest-inversion/specs/spec0*.md

bash gates/tree-links.sh
```
