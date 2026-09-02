---
workflow: cut-a-feature-its-readers-still-name
subject: 09-simplify/03-help-system
date: 2026-09-02
runs: 0
---

## Use when

- A node says "delete this machinery and keep the small thing it grew around",
  and the machinery has live readers that must be cut in the same pass.
- Not when nothing reads the thing being deleted and no behaviour a person
  uses goes with it — that is `delete-what-nothing-reads`, which says so in
  its own Use when, and it is cheaper.

## Steps

| # | atomic | why | on failure |
|---|--------|-----|------------|
| 1 | `measure-the-premise-not-the-prd` | every line number in the contract held, but two requirements were scoped wrong against the tree: all 116 `source:` values were already dead paths, and five stale claims were named where nine existed | `stop` |
| 2 | `prove-nothing-reads-it` | a whole-tree grep found a third renderer of the corpus in `tv-all`, live-bound from `tmux.conf` and named nowhere in the contract or its footprint | `→ 1` |
| 3 | `carry-the-why-across-the-rewrite` | the file shrank 404 → 198 lines and its constraint comments were the expensive part; re-lodging them beside the code that still needs them is what stops a rewrite from spending a day of somebody's past work | `→ 2` |
| 4 | `regenerate-every-derived-surface` | half the manual is generated from the files being edited, so a source fix that skips the generator ships a page that still says the old thing | `→ 3` |
| 5 | `apply-scoped-not-bare` | two other analysts had uncommitted work in the tree; a bare `chezmoi apply` would have deployed a half-built Dockerfile alongside this change | `→ 4` |
| 6 | `prove-in-a-shell-that-loaded-the-config` | `nu -c` loads no config and reports the rewritten `help` as absent; `nu -l` is what makes the render a result | `→ 5` |
| 7 | `check-what-apply-left-behind` | `chezmoi apply` left all four deleted files deployed, so the deletion was true of the repo and false of the machine, and one of them kept a picker channel pointing at a function that was gone | `→ 6` |
| 8 | `run-the-verify-twice` | the first block passed on a violated assertion, because `! cmd` is exempt from `set -e`; a second run is also what catches a check that asserted the act instead of the post-state | `→ 7` |
