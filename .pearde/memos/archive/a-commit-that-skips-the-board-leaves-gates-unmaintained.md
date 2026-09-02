---
memo: a-commit-that-skips-the-board-leaves-gates-unmaintained
kind: note
status: decided
subject: 0b77a71 landed code ahead of its PRD and left two separate gates unmaintained — the registry row and the managed surface — because the spec footprint that would have carried both was never written
date: 2026-08-28
prds:
  - 04-shell/10-litellm-launcher
  - 00-delivery/corrections/waves-registry-missing-s10
  - 00-delivery/corrections/g1-verify-still-red-on-just-gates
---

# a-commit-that-skips-the-board-leaves-gates-unmaintained — the footprint is what maintains the gates

## What happened

`0b77a71` (`04-shell/10-litellm-launcher`, 2026-08-28) landed a node and its
gate across **36 files**. The node's own Provenance records that it was built
ahead of the board — *code now, PRD after* — so it never passed through
`open → specced → claimed`.

Two gates went unmaintained as a result, and they were found **by two
different nodes, by accident, on the same day**:

| gate | what was missed | found by |
|---|---|---|
| `gates/waves.tsv` | no row registering `tests/shell-litellm.sh` against `S.10`, so the gate was run by no sweep | [`waves-registry-missing-s10`](../00-delivery/corrections/waves-registry-missing-s10/prd.md) |
| `tests/managed-config.sh` | `dot_local` and `litellm` added under `home/` without the declared surface being updated | [`g1-verify-still-red-on-just-gates`](../00-delivery/corrections/g1-verify-still-red-on-just-gates/prd.md) |

## The mechanism, which is the part worth carrying

Neither was a silent check. `wave-status.sh --validate` and
`managed-config.sh` were both **loud** and both sat red — attributable to
another lane, so nobody owned them.

What was missing is upstream of the checks: **a spec's `footprint:` is what
tells the author which shared files their change touches.** Write the spec and
`gates/waves.tsv` and `tests/managed-config.sh` appear in the footprint, so
updating them is part of the unit rather than something to remember. Skip the
board and there is no footprint, so the shared files are exactly the ones that
get missed — they are not in the diff the author is thinking about.

## What a reader should do with this

- **A node built ahead of its PRD owes a footprint audit before it is called
  done.** Not a re-run of its own gate, which passes: a sweep of which
  *shared* files its change should have touched. `gates/waves.tsv`, the
  declared-surface tests, and the wave registry are the three that have bitten.
- **A red attributed to "another lane" is still owed to somebody.** Both of
  these survived because every reader who saw them correctly concluded they
  were not theirs. That is the failure mode a loud check has.

## Why this is a memo and not a node

The two instances are already filed as nodes and are being fixed. This records
the *cause* they share, which no PRD owns and the code will not explain — and
`g1-verify-still-red-on-just-gates` R5 asks for the sweep of `0b77a71` that
would find a third, if there is one.
