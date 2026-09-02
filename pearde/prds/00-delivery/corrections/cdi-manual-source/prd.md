---
state: done
claim: 
priority: 12
est: 0.5h
actual: 10m
mode: afk
needs:
  - 04-shell/03-zoxide
verify: ""
origin: derived
from: 04-shell/03-zoxide
---

# `cdi` manual entry cites the wrong source PRD

Parent: [Corrections backlog](../prd.md) · net-new

Purpose: S.4's analyst found (2026-08-22) that the `cdi` entry in
`home/dot_config/nushell/help/shell.nuon` carries
`source: prds/04-shell/02-aliases-utilities/prd.md`, but 02's own spec01
explicitly assigns `cdi` to [`03-zoxide`](../../../04-shell/03-zoxide/prd.md)
and 02's gate asserts `cdi` is absent from the aliases surface — the manual
points at the wrong owner. Fixing the `source:` field changes the entry's
use-review digest, so this is a help-review edit, not a drive-by: the
correction re-digests via the gate's own helpers and the new review row
comes from an independent reader that did not write the entry.

## Requirements
- [x] **R1** — `cdi`'s `source:` names `prds/04-shell/03-zoxide/prd.md`;
      no other field of the entry changes. `get source.0` prints
      `prds/04-shell/03-zoxide/prd.md`, and the all-but-`source`
      fingerprint is still `77b658ee1a919c20`.
- [x] **R2** — The matching `use-review.nuon` row is re-digested by the
      gate's digest helper, with a reader-reviewer distinct from the row's
      author, per the help corpus's review ritual. `digest:
      "3a8f2a6e5bdbbb23"`, `author: "implementer-cdi"`, `reviewer:
      "implementer-cdi-r1"`.

## Acceptance
- [x] `nu tests/help-content-model.nu` prints `ok`, exit 0.
- [x] `open home/dot_config/nushell/help/shell.nuon | where cmd == "cdi" |
      get source.0` prints the zoxide PRD path.

## Out of scope
- Any change to `cdi`'s behavior or its `use`/`why` text; only the
  attribution and its review row.
