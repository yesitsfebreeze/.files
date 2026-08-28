---
state: open
priority: 4
est: 1.5h
mode: afk
needs:
  - 06-help/04-drift-check
verify: "help --check exits 0 with the terminal surface enabled"
origin: requested
from: 00-delivery/finish-line
---

# The deferred third surface — `help --check` against WezTerm

Parent: [Finish line](../prd.md) · net-new

Purpose: [`06-help/04-drift-check`](../../../06-help/04-drift-check/prd.md)
R3 — introspect the terminal via `wezterm show-keys --lua`, plus `--key-table`
for the F5 jump table. Answer 1 of the [finish-line round](../prd.md) cut it
from the first build so `help --check` could ship for the two surfaces that
carry most of the manual. **Deferred, not cancelled**, and this node is where
that promise is kept.

Why this was the surface to cut, recorded so the choice is auditable: the
terminal check has a blind spot the board already measured. `Ctrl+Shift+T`
resolves against WezTerm's **own** `SpawnTab` default, so its drift check
passes whether or not a capsule binding is ever written — named as a blind
spot in [`coverage`](../../../06-help/01-content-model/coverage/prd.md) R3.
A check that passes for the wrong reason is the least valuable third.

## Requirements
- [ ] **R1** — `help --check` grows the terminal surface: `wezterm show-keys
      --lua` for the top-level bindings, `--key-table` for the F5 jump table
      ([`02-terminal/03`](../../../02-terminal/03-f5-jump-mode/prd.md)).
- [ ] **R2** — The `Ctrl+Shift+T` blind spot is closed or recorded as
      unclosable: a binding that matches a WezTerm default must be
      distinguishable from one this config actually sets, or the check must
      say it cannot tell.
- [ ] **R3** — `coverage` R3 and R5's terminal half close against this, which
      is the reason the node exists.
- [ ] **R4** — R8 of the parent still holds: `--check` spawns wezterm, plain
      `help` never does.

## Acceptance
- [ ] Deleting a documented terminal binding is reported as stale.
- [ ] Adding an undocumented one is reported and exits non-zero.
- [ ] A binding that exists only as a WezTerm default is either reported
      correctly or explicitly listed as indistinguishable, with the
      measurement.

## Out of scope
- The shell and Neovim surfaces; the parent owns those and ships first.
