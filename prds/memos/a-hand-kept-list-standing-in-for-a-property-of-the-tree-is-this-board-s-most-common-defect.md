---
memo: a-hand-kept-list-standing-in-for-a-property-of-the-tree-is-this-board-s-most-common-defect
kind: note
status: decided
subject: Five independent defects in one week share one mechanism — a maintained list standing in for something the tree already knows — and the tell is that adding a file is correct everywhere except in a list nobody thought to open
date: 2026-08-29
prds:
  - 00-delivery/corrections
  - 00-delivery/wave-registry-keying
  - 00-delivery/corrections/retired-phrases-mention-vs-use
---

# A hand-kept list standing in for a property of the tree

## The shape

A check needs to know something about the repository — which scripts always
run, which tools are declared, which nodes have gates. Instead of **deriving**
it, the check carries a **list** somebody maintains. The list is correct on the
day it is written and silently wrong from the next commit that adds a file.

The tell is always the same: **a change that is correct everywhere else turns
a gate red, or worse, leaves one green when it should not be.** Nobody has
made a mistake. The list simply did not know.

## Five instances, one week

| where | the list | what broke it |
|---|---|---|
| `tests/shell-init.sh` S3.10 | one **literal** always-run script name | `5e7934c` added a second always-run script (the mason seeder). Fixed 2026-08-29 with `always_run_targets()`, derived |
| `gates/waves.tsv` | rows keyed by a hand-issued `task:` id | 0 of 9 `07-multiplexer` nodes have one; **50 of 116 `done` nodes never did**. Open as `00-delivery/wave-registry-keying` |
| `gates/retired-phrases.sh` | exemptions, per phrase | every document that records the gate's red becomes a new carrier. Open as `retired-phrases-mention-vs-use`, whose **R4 forbids** growing the list as the fix |
| `install.sh` `PKGS` ↔ `tests/provisioning.sh` `PROV_BINS` | two lists that must agree | adding `tmux=tmux` reddened `shape`/`prov` until `PROV_BINS` was edited too. Its own header already says it "has to grow whenever `PKGS` does" — a comment doing a check's job |
| `tests/managed-config.sh` `SURFACE` | the declared surface, by name | `0b77a71` arrived with `litellm` undeclared; `07-multiplexer` arrived with `tmux` undeclared |

The `PKGS`/`PROV_BINS` pair is the sharpest: **two hand-kept lists that must
agree, with nothing checking that they do.** Found 2026-08-29 by session
dotfiles-06 while adding one tool.

## What this is not

**It is not an argument for deleting the lists.** Two of the five are
deliberate and should stay: `managed-config`'s `SURFACE` exists *because*
declaring a tool is a decision a person makes — its header says "Editing one of
these lists IS the decision", and that is the point, not the defect. Its
`SURFACE_PENDING` sibling is the pattern that works: a name arrives, is
recorded as pending, and the real decision stays with the node that owns it
(`capsule`, then `litellm`, then `tmux`).

The distinction is **whether the list encodes a decision or a fact.**

- A list of **decisions** — what we have chosen to manage — is right to be
  hand-kept, and its maintenance cost is the point.
- A list of **facts about the tree** — which scripts exist, which nodes have
  gates, which files quote a phrase — is a cache with no invalidation, and it
  is wrong the moment the tree moves.

Four of the five are the second kind wearing the first kind's clothes.

## What to do

**Before writing a list into a check, ask what would happen if someone added a
file.** If the honest answer is "the check silently goes wrong", derive it
instead — `always_run_targets()` and `nushell-module-staging.sh`'s derived
module list are the two worked examples in this tree.

Where a list must stay because it encodes a decision, **something else has to
check the pairing.** `PROV_BINS` is the open case: nothing today would notice
the two lists disagreeing, and the next tool to arrive will find out the same
way this one did.

And when the list *is* the fix people reach for, say so out loud — the
`retired-phrases` node's R4 exists to forbid exactly the repair that would have
made it a sixth instance.
