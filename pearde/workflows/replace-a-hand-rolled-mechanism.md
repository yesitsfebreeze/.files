---
workflow: replace-a-hand-rolled-mechanism
subject: 09-simplify/07-provisioning
date: 2026-09-02
runs: 0
---

## Use when

- A phase says a hand-rolled script should become a line of the platform's own
  tooling — "install.sh becomes a Brewfile and sixty lines" — and the thing
  being replaced is still live on the machine you are measuring.
- Not when the old mechanism has no replacement and simply goes: that is
  `delete-what-nothing-reads`, and its `prove-nothing-reads-it` step is enough
  on its own.

## Steps

| # | atomic | why | on failure |
|---|--------|-----|------------|
| 1 | `measure-the-premise-not-the-prd` | the PRD offered to drop `rust`; `conform.lua` still named `rustfmt`, so the offer rested on a fact that was false | `stop` |
| 2 | `prove-the-replacement-is-a-drop-in` | brew's tinty was installed beside the release copy and asked for the same scheme, the same 538 entries and the same hook write BEFORE anything was deleted | `stop` |
| 3 | `delete-the-shadow-the-replacement-leaves` | `~/.local/bin` is ahead of the brew prefix, so the old binary would have won forever and the Brewfile entry would have been decorative | `→ 2` |
| 4 | `prove-nothing-reads-it` | grepping the tree for `PKGS` and `NVIM_MIN_MINOR` before the cut found three manual lines citing them; found afterwards they would have been a documented lie | `→ 1` |
| 5 | `apply-scoped-not-bare` | three run-script targets were pending, one of them a mason seeder this PRD does not own; a bare apply runs all three | `stop` |
| 6 | `run-the-surface-that-consumed-it` | running the rewritten `run_after` directly produced 2280/1966/1809 bytes — identical to the 112-line original, which is the proof the deleted lines were commentary | `→ 2` |
| 7 | `assert-the-post-state-twice` | a verify that passes once is a build script; three runs is what separates the two | `→ 6` |
