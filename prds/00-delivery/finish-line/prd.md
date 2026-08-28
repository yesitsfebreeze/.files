---
state: open
priority: 30
est: 0h
kind: epic
mode: afk
needs:
verify: ""
origin: requested
---

# Finish line — the settled contract for closing this repo

Parent: [Delivery](../prd.md) · net-new

Purpose: A drill on 2026-08-28 put the board's whole remaining frontier to the
user in one round — six forks, every one answered. This node is that contract,
and its children are the work the answers created. Nodes that already existed
carry their answer in their own `## Answers`; only genuinely new work branches
from here.

The question behind the round was "all the open things we need to finish this
repo asap", so every answer was read through that lens: what is the smallest
honest path to a closed board.

## The six answers

**1 — `help --check` ships for two surfaces, not three.**
[`06-help/04-drift-check`](../../06-help/04-drift-check/prd.md) builds R1
(nushell) and R2 (Neovim); R3 (WezTerm) defers to
[`drift-check-terminal-surface`](drift-check-terminal-surface/prd.md). The
terminal surface was the cut because it is the smallest payoff and already
carries a recorded blind spot: `Ctrl+Shift+T` resolves against WezTerm's own
`SpawnTab` default whether or not a capsule binding is ever written, so the
check passes there either way. Consequence, recorded rather than discovered
later: [`coverage`](../../06-help/01-content-model/coverage/prd.md) R3 defers
with it, and R5 closes for the two built surfaces only.

**2 — about twenty manual boxes, not eighty-eight.**
The committed set is `gates/manual/wave4.md`'s five C.4 capsule rows plus its
T.4, T.6, T.7 and E.14 rows — the minimum that turns blocked nodes into done
ones. The other ~68 boxes across the seven wave files stay open as honest debt
rather than being quietly dropped or falsely ticked.

**3 — an invariant is prose, not a box.**
Eight epics and the root sit `open` only because I1–I8 are unticked, and an
invariant is a constraint children reference, not work anyone performs. A box
nobody can ever run is what keeps them open forever. See
[`epic-invariants-prose`](epic-invariants-prose/prd.md). Epics then close on
their children.

**4 — `S4.30` closes `unmeasured`, with the bound stated.**
[`nushell-core-s430-stall`](../corrections/nushell-core-s430-stall/prd.md)
does not buy the 25-minute load campaign. `unmeasured` is a verdict its own R2
explicitly allows, and its own spec argues a 40 s ceiling sits an order of
magnitude away from where load puts a pty call.

**5 — the agent overview derives its tool names.**
[`agent-overview-derived-tools`](agent-overview-derived-tools/prd.md) — the
render reads the idioms entry's own content instead of a human restating it,
so the block informs without a second place for `rg`/`fd`/`tv` to live. This
answers H.5 and unblocks
[`06-help/05-agent-interface`](../../06-help/05-agent-interface/prd.md).

**6 — doctor debt is repaired on live nodes only.**
[`doctor-debt-live-nodes`](doctor-debt-live-nodes/prd.md). History stays
history: rewriting 29 closed rounds would mean inventing intent nobody had,
and an inferred `from:` is a guess written as a fact.

## What this contract does NOT settle
- Anything on `gates/manual/wave*.md` outside the committed ~20 boxes.
- [`d3-tick-breaks-unticked-rule`](../corrections/d3-tick-breaks-unticked-rule/prd.md),
  which is its own open fork and was filed before this round.
- Whether the deferred WezTerm surface is ever built. Answer 1 defers it; it
  does not cancel it.

## Acceptance
- [ ] Every child of this node is `done` or explicitly deferred on the record.
- [ ] `python3 .../plan.py plan` shows no node waiting on a decision this
      round already answered.
