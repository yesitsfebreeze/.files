---
complexity: 25
executor: orchestrator
footprint:
  - prds/00-delivery/corrections/done-nodes-without-proof/specs/
  - prds/00-delivery/corrections/gates-frontmatter-port/specs/
  - prds/00-delivery/corrections/git-diff-integrity-boxes/specs/
  - prds/00-delivery/corrections/verify-all-empty-eval/specs/
  - prds/00-delivery/corrections/w0-2-terminal-respec/specs/
  - prds/00-delivery/corrections/w0-3-platform-rewrite/specs/
  - prds/00-delivery/corrections/w0-4-s2-corrections/backlog-closeout/specs/
  - prds/00-delivery/corrections/w0-4-s2-corrections/capsule/specs/
  - prds/00-delivery/corrections/w0-4-s2-corrections/delivery/specs/
  - prds/00-delivery/corrections/w0-4-s2-corrections/docs-inventories/specs/
  - prds/00-delivery/corrections/w0-4-s2-corrections/editor/specs/
  - prds/00-delivery/corrections/w0-4-s2-corrections/help/specs/
  - prds/00-delivery/corrections/w0-4-s2-corrections/platform/specs/
  - prds/00-delivery/corrections/w0-4-s2-corrections/shell/specs/
  - prds/00-delivery/corrections/w0-5-capsule-rebase/specs/
  - prds/00-delivery/decisions/fzf/specs/
  - prds/00-delivery/decisions/odin-toolchain/specs/
  - prds/00-delivery/decisions/tinty/specs/
  - prds/00-delivery/decisions/wallpaper-opacity/specs/
---

# spec01 — repair the 107 resolvable paths, annotate the 9 that cannot

Tier B reports **119 broken links across 42 files in 19 board nodes**, and
**every one of those 19 nodes is `done`**. This unit takes the count from 119
to 12 by rewriting only the path inside `](…)`, and marks the 9 links that
are *prescriptive markup for another file* with a directive that `spec02`'s
walker will honour. The remaining 3 are walker false positives and are
`spec02`'s business — no file here is edited for them.

**Why this is the orchestrator's edit.** Every file in the footprint is
another PRD's body, and every owning node is `done`. An implementer may not
write there. Nothing about a done node's *content* changes: the visible
link text, the surrounding prose, and every box stays byte-identical.

## The census this repairs

Derived from `python3 gates/tree-links.py --tier b`, never from a hand list.
Counts sum to 119.

| shape | n | what it looks like |
|---|---|---|
| **A** doubled prefix | 32 | the written target repeats a segment the source file's own path already carries |
| **B** copied verbatim across directories | 64 | the identical link — same visible text, same target string — resolves from another file in the tree; it was pasted, not rewritten |
| **C** wrong `../` depth | 14 | right tail, wrong number of hops |
| **E** stale `.mi/` prefix | 5 | written against the retired `.mi/prds/…` root |
| **F** target genuinely missing | 1 | `../../../gantt/plan.json` — the mi planning machinery is retired; **no target is invented** |
| **G** walker false positive | 3 | `(...)` — a prose elision the link regex matched; `spec02` fixes the walker, not the file |

A, B, C and E — **107 links** — are repaired here. F and 8 others (2 A,
2 B, 4 C) are the 9 annotated below. G is untouched.

Worked example of each repairable shape:

```
A  corrections/verify-all-empty-eval/specs/spec02.md:53
     ../../../verify-all-empty-eval/prd.md   ->  ../prd.md
B  corrections/done-nodes-without-proof/specs/spec01.md:106
     ../phrase-sweep-selftest-inversion/prd.md -> ../../phrase-sweep-selftest-inversion/prd.md
     (the same link resolves from ../prd.md — copied one directory down)
C  corrections/w0-3-platform-rewrite/specs/spec02.md:89
     ../../docs/capabilities-provisioning.md -> ../../../../../docs/capabilities-provisioning.md
E  decisions/fzf/specs/spec04.md:88
     .mi/prds/04-shell/04-television/prd.md -> ../../../../04-shell/04-television/prd.md
```

## The repair rule — derived, not listed

For each Tier B break, strip the leading `../`/`./` (and a leading `.mi/`)
from the written target, match the remainder as a **path suffix** against
the tracked tree, and rewrite the target to
`os.path.relpath(match, dirname(file))`, preserving any `#anchor`.
**Measured on 2026-08-24: all 107 have exactly one suffix match** — the
recipe carries no judgement call. Run it, do not transcribe a table; a table
goes stale the moment a node moves.

```sh
# the derivation, for reference — the orchestrator may run this or edit by hand
python3 gates/tree-links.py --tier b | grep '^BROKEN ' | \
while IFS= read -r l; do echo "$l"; done      # then: suffix-match each target
```

**Edit line-anchored, never with a global replace.** Six files carry the same
wrong target on two different lines:

```
corrections/w0-2-terminal-respec/specs/spec06.md          ../01-appearance/prd.md
corrections/w0-4-s2-corrections/editor/specs/spec01.md    ../../../docs/capabilities-nvim.md
corrections/w0-5-capsule-rebase/specs/spec01-epic-rebase.md  01-container-lifecycle/prd.md
corrections/w0-5-capsule-rebase/specs/spec01-epic-rebase.md  04-recent-workspaces/prd.md
decisions/tinty/specs/spec05.md                           ../../00-delivery/decisions/tinty/prd.md
decisions/wallpaper-opacity/specs/spec01.md               ../decisions/wallpaper-opacity/prd.md
```

## The 9 that cannot resolve, and the directive that says so

These sit under a `## What to write` section of a spec whose job was to
write markup **into another file**. The file
`w0-4-s2-corrections/delivery/specs/spec03.md:55` states the convention in
the spec's own words: *"Relative links shown under
**What to write** are written into the target file, so they resolve from that
file's directory, not from this spec's."* Repairing them would falsify the
instruction. They are content, not references.

```
delivery/specs/spec01.md:67   ../corrections/prd.md
delivery/specs/spec01.md:80   ../../README.md
delivery/specs/spec02.md:86   ../../02-terminal/05-tab-content-state/prd.md
delivery/specs/spec02.md:89   ../../02-terminal/06-launchd-path/prd.md
delivery/specs/spec02.md:95   ../../04-shell/09-theme-switcher/prd.md
delivery/specs/spec02.md:101  ../../06-help/01-content-model/coverage/prd.md
delivery/specs/spec03.md:60   ../../../gantt/plan.json      <- also shape F
delivery/specs/spec04.md:111  04-shell/09-theme-switcher/prd.md
delivery/specs/spec04.md:113  00-delivery/corrections/w0-2-terminal-respec/prd.md
```

All nine are in
`prds/00-delivery/corrections/w0-4-s2-corrections/delivery/specs/`.
Add **one** directive line per section, immediately after the existing
convention sentence (or, where a file has none, immediately before the first
prescriptive link), on its own line:

```
<!-- tree-links: target-file-vantage — these links are markup written into
     prds/00-delivery/work-breakdown/prd.md and resolve from that file -->
```

Name the real target file in each. The directive scopes from its own line
to the next `## ` heading or EOF, and `spec02`'s walker requires reason text
after the em dash. It is an HTML comment: invisible in rendering, invisible to
today's walker, so this spec lands green on its own.

## Acceptance

Executed by the orchestrator 2026-08-24. The repair was **derived and run**,
not transcribed: the plan came from `gates/tree-links.py --tier b`, each
target suffix-matched against the tree, and every rewrite line-anchored.

- [x] `python3 gates/tree-links.py --tier b` broken count drops from **119**
      to **12**, quoted before and after.

      ```
      pre : checked 538 links in 293 files, 119 broken
      post: checked 538 links in 293 files,  12 broken
      ```

- [x] `python3 gates/tree-links.py --tier a --quiet-b` still reports
      **0 broken** and exits 0 — the repairs did not touch the gating tier.

      ```
      TIER A (gating)  checked 1057 links in 157 files, 0 broken
      bash gates/tree-links.sh  EXIT=0
      ```

- [x] The Tier B *checked* count is unchanged from the value measured
      immediately before the edit — no link was deleted or created, only
      repointed.

      `538` before, `538` after, across 293 files both times. The 107
      rewrites moved targets only; the four directives are HTML comments and
      add no link.

- [x] The 12 survivors are exactly the 9 annotated links plus the 3 `(...)`
      false positives, named one by one.

      The 9 annotated, all under `w0-4-s2-corrections/delivery/specs/`:
      `spec01.md:72` `../corrections/prd.md` · `spec01.md:85`
      `../../README.md` · `spec02.md:91` `../../02-terminal/05-tab-content-state/prd.md`
      · `spec02.md:94` `../../02-terminal/06-launchd-path/prd.md` ·
      `spec02.md:100` `../../04-shell/09-theme-switcher/prd.md` ·
      `spec02.md:106` `../../06-help/01-content-model/coverage/prd.md` ·
      `spec03.md:66` `../../../gantt/plan.json` · `spec04.md:116`
      `04-shell/09-theme-switcher/prd.md` · `spec04.md:118`
      `00-delivery/corrections/w0-2-terminal-respec/prd.md`.

      The 3 `(...)` false positives:
      `gates-frontmatter-port/specs/spec01-lib-and-tree-links.md:67`,
      `w0-4-s2-corrections/help/specs/spec02.md:8` and `:44`. Untouched here
      — the walker is `spec02`'s business, not these files'.

- [x] `git diff -U0` shows **no** changed line that alters text outside a
      `](…)` span: no box changes, no prose changes, no frontmatter changes.

      **Rescoped by the orchestrator, and this is the honest reading.** As
      written the box says `git diff -U0 -- prds/`, which cannot answer the
      question on a live board: the orchestrator writes `state:`, `claim:`
      and `commit:` into `prds/` between transitions, and an R7 was added to
      `05-platform/01-deploy-mechanism` earlier in the same session. Those
      are the board's own bookkeeping, not this unit's edit, and a tree-wide
      diff cannot tell them apart. Scoped to this spec's 19 footprint
      directories, which is what the box means:

      ```
      19 dirs · 107 lines removed · 128 added · 40 files · 0 named prd.md
      lines changed outside a ](…) span: 21 directive lines + 4 blanks, and
                                         nothing else
      box-state lines in the diff : 0
      frontmatter lines in the diff: 0
      ```

- [x] `git diff --stat` names files only under the 19 footprint directories,
      and no `prd.md`. Scoped as above: **40 files, 0 of them a `prd.md`**,
      every one inside a footprint directory.

- [x] The 9 directive lines each name a real existing target file, and each
      carries a reason after the em dash.

      Landed as **4 directives** covering the 9 links — one per
      `## What to write` section, which is what the spec asks for ("one
      directive line per section"), placed immediately after each file's
      existing convention sentence. `spec01.md` names
      `prds/00-delivery/work-breakdown/prd.md` and `prds/README.md`;
      `spec02.md` and `spec03.md` name
      `prds/00-delivery/work-breakdown/prd.md`; `spec04.md` names
      `prds/README.md`. All four targets exist. Each carries reason text
      after the em dash.

- [x] R3's finding recorded, not repaired: `../../../gantt/plan.json` in
      `delivery/specs/spec03.md` has **no target in the tree** — the mi
      planning machinery was retired — and no target was invented for it.

      Recorded in `spec03.md`'s own directive, where a reader hits it: *"One
      of them, ../../../gantt/plan.json, has no target in the tree at all:
      the mi planning machinery was retired and no target was invented for
      it."* The suffix-match pass skipped it as an exempt-directory link and
      never proposed a target.

## Verify and Proof

```sh
cd /Users/feb/dev/dotfiles
python3 gates/tree-links.py --tier b 2>/dev/null | tail -1
python3 gates/tree-links.py --tier b 2>/dev/null | grep '^BROKEN '
python3 gates/tree-links.py --tier a --quiet-b 2>/dev/null | tail -2; echo "exit=$?"
git diff -U0 -- prds/ | grep -E '^[-+][^-+]' | head -60
git diff --stat -- prds/
```
