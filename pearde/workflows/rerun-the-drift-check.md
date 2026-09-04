---
atomic: rerun-the-drift-check
subject: "`just manual` plus a shasum pair is what says the configuration and its manual still agree"
date: 2026-09-02
updated: 2026-09-02
runs: 5
tags:
  - atomic
---

## Do

1. `just manual` — regenerate the manual's derived pages from the `.nuon`
   surfaces. It writes into the tree; it does not deploy.
2. Take a `shasum` over `help/manual/guide/` and `help/manual/reference/`
   before and after, and compare.
3. `just board-guard <prd> "<your paths>"` and `just board-guard-blocks`.

## Done when

- The two shasums are identical — the generated pages already matched the
  `.nuon` surfaces, so nothing in the manual is drifting behind the
  configuration.
- `git status` shows a changed page for every `.nuon` you edited and no
  others.
- Both guards exit 0.

## Fails when

- You reach for `help --check`. It was retired with
  `.config/nushell/help-check.nu` and is in `home/.chezmoiremove`;
  `nu -c 'help --check'` returns `nu::parser::unknown_flag`, which reads as
  a broken shell rather than a retired command. There is no `HC_ALLOW`
  allowlist left to grep either.
- `just manual` is run but its output is only eyeballed. It prints a page
  and entry count on every run whether or not anything changed; the shasum
  pair is the only thing that says "no drift".
- `just board-guard` refuses a path that is genuinely yours because a
  *sibling* PRD in a contending state also names it — most often through a
  spec's frontmatter footprint rather than the PRD's own, so it is not
  visible in the sibling's `prd.md`. The guard prints *"Name the paths
  instead of the tree, or pass the exclusion set this prints"*, which is
  advice for a caller who named a directory; a caller who named the exact
  file has no narrower name to give and cannot make it green. Do not drop
  the path from the list to get a zero — that hides the collision from
  `collect`. Isolate it (run the guard over each footprint path alone),
  name the holder and its claim in the report, and say whether the two
  edits actually conflict. Resolving it is a dispatch decision, not a
  worker's.
