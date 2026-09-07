---
kind: work
level: 4
status: done
description: migrate the board's live decisions and knowledge into memos/, then retire the four registers that no longer earn their place
read_when: "asking what the memos migration did, or starting the next consolidation pass"
---

# draft-the-record-from-the-board

## Do

- Take the five live memos in `.pearde/memos/` (5 decisions, 2
  notes), rewrite each as a `kind: decision` in `memos/decision/` with
  the same body, and write the one decision that names the move.
- Take the manual's measured internals and write one `kind: knowledge`
  memo per non-obvious claim, with `home/dot_config/nushell/help/manual/internals/<file>.md`
  as the line-cited source.
- Retire `.pearde/memos/`, `.pearde/wiki/`, `.pearde/graphify/`,
  `.pearde/health/`, `.pearde/grammar.md` from the source tree
  (the wiki/graphify were untracked; the memos and grammar were
  tracked and `git rm`'d; the untracked directories removed from
  disk).
- Keep `.pearde/prds/`, `.pearde/workflows/`, `pearde/settings.md`,
  `pearde/vision.md`; the board is the work-in-flight engine, the
  memos are the settled record, and the two are not the same kind
  of thing.
- Add the distilling of the kern memos system to this repo as
  `memos/` with `scripts/memos-check.py` + `just memos-check`; the
  gate runs in 0.2 s on a 73-memo record and refuses unindexed
  memos, dead links, undeclared kinds, and free-form sections.
- Add `llm -a <program>` to the router — see
  [[llm-launches-any-agent]] for the change; the rest of the file
  is unchanged.

## Check

- `git -C ~/dev/dotfiles status --short` is clean.
- `python3 ~/dev/infra/pearde/resources/pearde.py` reads the board
  (215 PRDs, vision reached, `09-simplify` 103/109 done).
- `just memos-check` is green.
- `~/.config/litellm/agents.json` round-trips: every `llm <agent>`
  registered agent still works, plus `llm -a codex`,
  `llm -a pi`, `llm -a gemini`, `llm -a aider`, `llm -a opencode`
  launch on the proxy with the templated env.

This memo is `done` on 2026-09-07: the commits
`memos: one record replaces the board's registers`,
`memos: the tooling record — 14 knowledge memos from the manual's
measured internals`, and `memos: routines in their kind folder,
every declared kind has at least one memo` together carry the change.