---
complexity: 3
footprint:
  - home/dot_config/nushell/help/shell.nuon
  - home/dot_config/nushell/help/manual/guide/agents.md
---

# spec02 — the manual's agents guide says the guard is on and what it refuses, in one sentence

The `pearde [cmd]` entry's `use:` field in `home/dot_config/nushell/help/
shell.nuon` gained one sentence: the guard is wired into this repo's
`.claude/settings.json`, and it refuses a hand-walked board read, a repeated
read, a `state:` edit outside `pearde set`, and a destructive git command
against a tree the session does not own, before the tool runs. `just manual`
was run and regenerated `home/dot_config/nushell/help/manual/guide/
agents.md` (the `reference/` twin carries no `use:` prose, so it is
unchanged) — this is the generated file the drift check compares, so the
source edit and the regenerated page travel in the same diff. What is left
to finish is committing both files.

## Acceptance

- [x] `home/dot_config/nushell/help/shell.nuon`'s `pearde [cmd]` entry names
      the guard being on and what it refuses, in one sentence.
- [x] `just manual` was re-run after the edit, so `guide/agents.md` carries
      the same sentence.
- [ ] Both files are committed together.

## Verify and Proof

```sh
cd /Users/feb/dev/dotfiles/pearde/.lanes/the-pearde-guard-hook-is-wired-into-the-harness
grep -c "guard hook is wired" home/dot_config/nushell/help/shell.nuon            # 1
grep -c "guard hook is wired" home/dot_config/nushell/help/manual/guide/agents.md # 1
just manual   # regenerates cleanly, no diff against the committed pair once staged
```
