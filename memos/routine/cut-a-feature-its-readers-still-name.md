---
kind: routine
name: cut-a-feature-its-readers-still-name
description: 09-simplify/03-help-system
read_when: "executing cut-a-feature-its-readers-still-name"
---

# cut-a-feature-its-readers-still-name

_Origin: `pearde/workflows/cut-a-feature-its-readers-still-name.md` (workflow subject: "09-simplify/03-help-system")_


## Use when

- A node says "delete this machinery and keep the small thing it grew around",
  and the machinery has live readers that must be cut in the same pass.
- Not when nothing reads the thing being deleted and no behaviour a person
  uses goes with it — that is `delete-what-nothing-reads`, which says so in
  its own Use when, and it is cheaper.
- Step 3 fires only when the cut is really a *move* — the machinery leaves
  for a home of its own rather than ceasing to exist. Where it simply goes,
  skip step 3 and run 1, 2, 4-10. Added 2026-09-02 by the orchestrator, on
  09-simplify/08-litellm-out's analyst flagging that this file's Use when
  covered its run only because the small thing kept was the entry point
  itself.

## Steps

| # | atomic | why | on failure |
|---|--------|-----|------------|
| 1 | `measure-the-premise-not-the-prd` | every line number in the contract held, but two requirements were scoped wrong against the tree: all 116 `source:` values were already dead paths, and five stale claims were named where nine existed | `stop` |
| 2 | `prove-nothing-reads-it` | a whole-tree grep found a third renderer of the corpus in `tv-all`, live-bound from `tmux.conf` and named nowhere in the contract or its footprint | `→ 1` |
| 3 | `stage-the-extraction-in-a-throwaway-project` | two of the five files being moved were python3 under a bash-looking directory, and running the entry point from the staged copy found a call back into the very shell config it was leaving — neither is visible in a plan | `→ 2` |
| 4 | `carry-the-why-across-the-rewrite` | the file shrank 404 → 198 lines and its constraint comments were the expensive part; re-lodging them beside the code that still needs them is what stops a rewrite from spending a day of somebody's past work | `→ 3` |
| 5 | `regenerate-every-derived-surface` | half the manual is generated from the files being edited, so a source fix that skips the generator ships a page that still says the old thing | `→ 4` |
| 6 | `apply-scoped-not-bare` | two other analysts had uncommitted work in the tree; a bare `chezmoi apply` would have deployed a half-built Dockerfile alongside this change | `→ 5` |
| 7 | `prove-in-a-shell-that-loaded-the-config` | `nu -c` loads no config and reports the rewritten `help` as absent; `nu -l` is what makes the render a result | `→ 6` |
| 8 | `check-what-apply-left-behind` | `chezmoi apply` left all four deleted files deployed, so the deletion was true of the repo and false of the machine, and one of them kept a picker channel pointing at a function that was gone | `→ 7` |
| 9 | `prove-the-orphan-can-be-owned-by-its-replacement` | five of the six removal entries the contract asked for named paths the replacement installs to, and the entry fires on every apply — they would have uninstalled it on every deploy, forever | `→ 8` |
| 10 | `run-the-verify-twice` | the first block passed on a violated assertion, because `! cmd` is exempt from `set -e`; a second run is also what catches a check that asserted the act instead of the post-state | `→ 9` |
