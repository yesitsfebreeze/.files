---
atomic: rerun-the-drift-check
subject: "`just manual` plus a shasum pair is what says the configuration and its manual still agree"
date: 2026-09-02
updated: 2026-09-02
runs: 4
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
