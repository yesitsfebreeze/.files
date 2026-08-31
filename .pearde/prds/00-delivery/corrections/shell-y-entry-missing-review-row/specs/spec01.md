---
complexity: 2
footprint:
  - home/dot_config/nushell/help/use-review.nuon
---

# spec01 — the `y` review row in use-review.nuon

One row in `home/dot_config/nushell/help/use-review.nuon`: the reading of
shell.nuon's `y` entry (the yazi alias, a concurrent lane's uncommitted
working-tree addition) against its source PRD
(`prds/04-shell/02-aliases-utilities/prd.md` R1) and its live route
(`alias y = yazi`, config.nu:114), recorded with the digest the content-model
gate requires, from a reviewer who wrote none of the text.

**What already stands (pass one, uncommitted, this node's claim):** the row is
written — `id: "y"`, `file: "shell.nuon"`,
`digest: "b88bef74e7a115cc"`, `reviewer: "analyst-shell-y-row"`,
`date: "2026-08-31"`, with the reading in its `note` — and the gate is green.
`nu tests/help-content-model.nu` exited 0 (`ok`, 102 entries) after exactly
one violation before it. What may be left to finish: nothing on this unit
unless the concurrent yazi lane rewords the entry's `use` or `source` before
committing — the digest keys on that pair, so a reword goes red by design and
the row is re-read and re-digested rather than patched; that re-read is this
same unit rerun, not a new one.

## Acceptance

- [x] `nu tests/help-content-model.nu` exits 0 with no violation — after the
      change it printed `help content model: 102 entries across 4 files,
      9 topics, 15 prose-only` … `ok`, exit `0`; before the row it exited 1
      with `1 violation(s): shell.nuon [y]: has no row in use-review.nuon`.
- [x] The `y` row names the digest the gate names and a reviewer distinct
      from the entry's author — `open
      home/dot_config/nushell/help/use-review.nuon | where id == "y" |
      select id file digest reviewer date` reads back
      `[[id, file, digest, reviewer, date]; [y, "shell.nuon",
      "b88bef74e7a115cc", analyst-shell-y-row, "2026-08-31"]]`. The entry was
      written by a concurrent lane whose session id is recorded nowhere, so
      the `author` field is omitted rather than invented (the ritual's own
      rule) and the row's `note` records that the reviewer wrote none of it;
      the gate's reviewer-equals-author check reports nothing.

## Verify and Proof

```sh
nu tests/help-content-model.nu
nu -c 'open home/dot_config/nushell/help/use-review.nuon | where id == "y" | to nuon'
```