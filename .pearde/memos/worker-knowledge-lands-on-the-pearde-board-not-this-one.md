---
memo: worker-knowledge-lands-on-the-pearde-board-not-this-one
kind: note
status: decided
subject: worker knowledge lands on the pearde board not this one
date: 2026-09-02
---

# worker-knowledge-lands-on-the-pearde-board-not-this-one — worker knowledge lands on the pearde board not this one

## Decision

`knowledge.py` invoked by its absolute path in `~/dev/infra/pearde/resources/`
reads and writes **that** repo's `.pearde/wiki/`, not the board it was called
about. Every `remember` and `conclude` a worker on this board has run that way
has landed on the pearde tooling repo's record, and every `query` this board's
step 7 runs that way searches a record this board did not write.

Until the walk-up is fixed upstream, **name the root**:

```
python3 <path>/knowledge.py --root /Users/feb/dev/dotfiles/.pearde/wiki query "<q>"
```

Or invoke the repo-local install, `.claude/skills/pearde/resources/knowledge.py`,
from inside the repo.

## Why

Found 2026-09-02 during `09-simplify`'s ninth pass. This board's own
`.pearde/wiki/sources/` and `conclusions/` hold nothing but their `_index.md` —
202 markdown files under `wiki/`, all of them the `board/` mirror. Yet
`knowledge.py query` from `/Users/feb/dev/dotfiles` reported `52 notes on
record` and returned real titles. `load_notes` only ever reads from disk, so
the two facts could not both be about this board. They are not:
`~/dev/infra/pearde/.pearde/wiki/sources/` holds 44 files, `260902-7c3a.md`
among them.

`260902-7c3a` is the proof it is misrouting rather than an empty base.
`09-simplify/04-nushell`'s report says it recorded that source and concluded
from it — work done on **this** board, about **this** repo's chezmoi, with
provenance reading "measured 2026-09-02 on chezmoi in this repo". The file is
on the other board.

The mechanism is already on record as `[[260902-b1f6]]` — a board whose
`.pearde` is a git worktree defeats `repo_root`'s walk-up. Same class: the
script resolves its root from where the script lives, not from where the work
is.

## Alternatives considered

**Copy the misrouted notes across into this board's `wiki/`** — rejected for
now. It would make this board's record right and leave the cause in place, so
the next worker misroutes the next note and the two records diverge again with
no marker saying which is which. Fix the resolution, then move them once.

**Treat it as a defect in the deliverable and file a PRD** — rejected per
`@references/parts/derived.md`. It changes no verdict about what ships; it
changes only how loudly the board would have noticed something. That is a memo
by the rule's own test.

## Consequences

- This board's step 7 has been querying an unrelated record. Treat every past
  "no hits, gap enqueued" from this board as unproven — the note may exist on
  the other board.
- It cuts both ways and the good half is real: `260902-7c3a` was found this way
  and it settled the `.chezmoiremove` premise for
  `09-simplify/retire-the-unmanaged-television-channels` without a probe. When
  querying about chezmoi, tmux, television or nushell, the tooling repo's
  record is worth searching **as well**, deliberately and with `--root` said
  out loud, because that is where this board's own findings have been going.
- Not fixed here: the misrouted notes are still on the other board, and the
  root resolution is still wrong. Both belong upstream in `~/dev/infra/pearde`,
  with the other durable tooling fixes this board has been carrying.
- `.pearde/wiki/pending/` on this board is empty, so no gap this board enqueued
  has been lost — they went to the other board's pending queue too.
