---
state: open
claim: 
priority: 23
est:
mode: afk
needs:
  - 04-shell/04-television
footprint:
  - home/dot_config/television/cable/git-log.toml
  - home/dot_config/nushell/finder.nu
  - tests/shell-television.sh
verify: "bash tests/shell-television.sh"
origin: derived
from: 04-shell/04-television
---

# `git-log`'s decoder reads field 1, and `--graph` does not put the hash there

Parent: [Corrections backlog](../prd.md) · net-new

Purpose: the `git-log` channel runs `git log --graph` and its `output`
template takes field 1 as the commit hash. On a row carrying graph connector
art, field 1 is not the hash — it is a `|`, a `*`, or nothing. Found
2026-08-23 by [`04-shell/04-television`](../../../04-shell/04-television/prd.md)'s
implementer while auditing that node, and reported rather than fixed because
the channel is carried verbatim by that node's spec01.

**The consequence for a requested PRD, which is why this is a PRD and not a
memo:** it makes
[`04-shell/04-television`](../../../04-shell/04-television/prd.md) R2(b) and
spec01's `git-log.toml` row wrong as written, and it is a real failure at the
keyboard. Measured on this repository's own history: **6 of the first 20 rows**
split wrong — four connector rows yield an empty field 1, and two `| * <hash>`
rows yield `*` while the actual hash sits at field 2. Both of those two are
**real commits**. So picking a commit from a merge lane raises R2(b)'s
empty-decode error instead of running `git show`, and the same template feeds
the preview and all three actions. R2(b)'s "a validity filter that now passes"
is true of first-lane rows only, which is the majority of rows and therefore
the reason nobody noticed.

## Requirements
- [ ] **R1** — Reproduce the split before changing anything, on a history
      with merge lanes. Quote the rows, their field 1, and where the hash
      actually sits. The measurement above is the finder's; confirm it
      independently rather than inheriting it — the corpus is this repo and
      it moves.
- [ ] **R2** — The hash is extracted by something that cannot be fooled by
      lane art. Name the mechanism and why it holds: a `%H`-anchored format,
      a field selected by pattern rather than by position, or dropping
      `--graph` from the channel. Say what each costs — dropping `--graph`
      loses the lane picture the channel exists to show.
- [ ] **R3** — Whatever lands must keep the empty-decode raise meaningful.
      Today a connector row and a genuinely undecodable row produce the same
      error, so the raise cannot distinguish "you picked art" from "the
      decode broke". After the fix, a connector row should not reach the
      decoder at all.
- [ ] **R4** — A counterfactual on a merge-lane row, per
      [`a-counterfactual-proves-its-own-mutation`](../../../memos/a-counterfactual-proves-its-own-mutation.md):
      with the fix reverted the check goes red on a `| * <hash>` row, and the
      fixture carries such a row deliberately rather than hoping the test
      repo grows one.

## Acceptance
- [ ] A pick on a `| * <hash>` row runs `git show` against that commit,
      output quoted.
- [ ] The six mis-splitting rows from R1 are quoted before and after.
- [ ] `bash tests/shell-television.sh` passes, output quoted, with the new
      counterfactual among the executed ones.

## Out of scope
- The other fourteen cable channels. Only `git-log` runs `--graph`.
- The `git-branch` enter-hijack count, which is
  [`04-shell/04-television`](../../../04-shell/04-television/prd.md) R1's and
  was corrected there on 2026-08-23.
