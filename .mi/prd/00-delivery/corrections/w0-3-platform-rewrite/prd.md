---
state: open
mode: afk
deps: []
verify: ""
---

# Finish the 05-platform provisioning rewrite

Purpose: The epic and its three children were rewritten, but the rewrite left
residues that the repo's own conventions require. This closes them.

## Requirements
- [ ] **R1** — `.mi/SYSTEM.md`'s epic table still reads `05-platform | macOS
      dependency bootstrap | 1`. The epic now has three children and a
      different subject; update the row.
- [ ] **R2** — `README.md`'s exclusion list carries no provisioning entries,
      though `capabilities-provisioning.md` holds three verdicts (Windows
      config mirroring DO NOT PORT, wp-stat-overlay installer DEFER, published
      docs site DEFER). `SYSTEM.md` requires a DO NOT PORT decision to appear
      in the epic Non-goals *and* the README exclusion list.
- [ ] **R3** — `capabilities-provisioning.md` violates the sort rule: its
      value ratios run 6,7,6,1,4,6,6,6,5,-2,-1,0 in file order and inventories
      are sorted best-ratio first.

## Acceptance
- [ ] The `SYSTEM.md` epic table, the README exclusion list and the inventory
      sort are all correct.
- [ ] The Wave 0 tree link check passes.

## Out of scope
- Re-deriving the epic and its children. That work landed; only the residues
      are open.

## Notes

 This node was almost recorded as done on the strength of the `[x] fixed` mark
      on the Provisioning bullet in the backlog's coverage-gaps section. That
      mark is defined at the top of that file as "already fixed in this pass"
      — the author's own note, not an executed check — and
      `03-verification-gates` req 1 says reading criteria is not executing
      them. The three requirements above are what an actual check found still
      open.
