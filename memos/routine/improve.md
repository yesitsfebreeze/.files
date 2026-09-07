---
kind: routine
name: improve
description: The improvement loop — sweep the record and the tree for the next open thread, research it, land the finding as a memo, repeat.
read_when: "looking for what to work on next, or running a research pass"
---

1. Read

- `memos/SYSTEM.md`, then [[the-open-work-index]].
- `git status --short` and `git log --oneline -10` — what the tree is
  mid-change on is never the thread this routine picks up.

2. Sweep

Gather candidate threads, cheapest source first, stop at the first that
yields one:

- `rg -l 'status: open' memos/work/` — work memos nobody ran.
- `rg -n 'A: \?' memos/question/` — questions the drill left open.
- The board: `python3 ~/dev/infra/pearde/resources/pearde.py` — the four
  PRDs still off `done`.
- The tree itself: a `chezmoi diff` that is not empty, a manual page whose
  command no longer runs, a claim in a `kind: knowledge` memo the config has
  since falsified.

3. Pick

One thread per pass. Prefer, in order: a falsified claim (the record lies),
a blocked work memo (something is stuck), an open question (something is
unknown), open work (something is unbuilt), a research lead (something is
worth measuring).

4. Research

Probe before writing. One instrument; confirm with a second of a different
kind. Write what was measured and how, what it would change.

5. Land

A settled finding is a memo of the kind it belongs to ([[memo-writing]]) —
a `kind: decision` when a call was made, `kind: research` when tentative,
a `kind: work` memo when it is a change to make. `just memos-check` green.

6. Loop

Back to step 2. The loop ends when a full walk yields nothing, or the
caller stops it. The pass itself is not a memo.