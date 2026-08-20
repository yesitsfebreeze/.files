# how — find the capabilities, use each where it fits

Inventory before working. The live surface is authoritative — read the tool
list, the skills, the docs. This table is advisory and says only the part a
surface listing cannot: *when* each one applies.

| Capability | What it is | Use it when |
|---|---|---|
| **pool** | subagents: explore, implement, verify in parallel, each self-contained | anything slow or self-contained — a survey, a refactor, a review. Dispatch and move on |
| **channel** | agents talk to each other: mail, presence, addressing, durable | coordination across sessions, escalations, handoffs. Coarse messages, explicit addressees |
| **workflows / ultracode** | parallel explorers → implementation → adversarial verification of every claim | real node work — the default, not optional |
| **the board** (`.mi/prd/`) | the tree; claim = git commit; four moves | all work lands through it, one node at a time |
| **the human** | naming, taste, money, a reversal | `mode: hitl`, an out-of-scope conflict, an escalation |

1. **Find** — list what exists before starting.
2. **Match** — exploration → pool · coordination → channel · implementation →
   ultracode · landing → the board · decisions → the human.
3. **Use** — dispatch, don't stall. A slow self-contained piece goes to a
   subagent while you take the next.
4. **Refute** — have a verifier attack what you built.

The board is files, so any harness can work it: claude workers, pi sessions,
same brief, same four moves, same lock. The channel is how they talk; the
board is where they agree.

## Laws applied

- **2** — a capability is read off the live surface, never assumed; whatever
  you built is refuted by someone who did not build it
- **4** — one capability per job; a step written around a missing capability
  is a special case
