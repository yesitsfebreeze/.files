---
state: claimed
mode: afk
deps: []
verify: ""
claim: cc-1787255407
---

# Record the live-config bugs so the rebuild fixes them

Purpose: Twelve bugs found in the live configuration. Recording them is half
the job; the other half is making sure each one reaches the node that must not
reproduce it.

## Requirements
- [ ] **R1** — The `L-1`..`L-12` table exists in the backlog and is populated.
- [ ] **R2** — Each bug is either fixed in the PRD that owns it, or recorded
      as accepted-with-reason. L-3 (`rcwd` is really `recent-dirs`, wrong in
      three PRDs and an inventory), L-4 (finder picks are never logged, so
      `04-shell/07`'s premise is wrong) and L-5 (`leadermode.nu` is dead code)
      are still unfixed in the tree.
- [ ] **R3** — L-6 and L-9 are questions, not records: L-6 asks which of two
      inert settings to port, L-9 asks whether shadowing blockwise-visual
      `<C-v>` is intentional. Both say "record it either way"; neither has
      been recorded.
- [ ] **R4** — Each bug names the node that must not reproduce it, so the fix
      is reachable from the implementing task. L-1 belongs to
      `04-shell/06-listing`, L-11 to `02-terminal/03-f5-jump-mode`.

## Acceptance
- [ ] No `L-*` row is left as an open question.
- [ ] Every `L-*` row names the node that owns its fix, and that node's PRD
      reflects it.

## Out of scope
- Implementing the fixes. This node routes them; the S, E and T nodes apply
      them.

## Notes

 R1 is the one box in this conversion that opens `[x]`: the check is `grep -cE
      '^\| *L-[0-9]+' on the backlog, which returns 12, and it would have
      returned a smaller number had the table been incomplete. Everything else
      here is open, because the backlog's own acceptance requires each bug be
      fixed or accepted-with-reason and no rebuild exists yet.
