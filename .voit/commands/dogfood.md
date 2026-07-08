---
description: Improve the current repo. In the VOIT repo, turn VOIT on itself (find promise/behavior drift, fix at root). In any other repo, ensure VOIT is wired and harvest voit-memory into the repo's own conventions.
---

Dogfood over `$ARGUMENTS` (or the whole repo if empty). First detect which repo
you are in, then run the matching branch:

- **VOIT repo** — `.voit/.claude-plugin/plugin.json` exists (the plugin source is
  vendored here). Improve the plugin itself (branch A).
- **Consumer repo** — no plugin manifest; VOIT is a symlink to the installed plugin.
  Improve *this* repo's efficiency instead (branch B).

```sh
test -f .voit/.claude-plugin/plugin.json && echo VOIT-REPO || echo CONSUMER
```

## Branch A — VOIT repo: turn VOIT on itself

1. Read the doctrine: `jd get voit/dogfood` (or `.voit/.jd/library/voit/dogfood.jd`).
2. Run its loop: scan docs vs code vs runtime, run the mechanical checks (dead
   references), name each mismatch as one line, fix the smallest root-cause change,
   guard it with an assertion in `.voit/scripts/test.sh`.
3. Harvest voit-memory: read `.voit/memory/decisions`, promote every project-agnostic
   convention into the plugin (`voit/conventions` or the right procedure), skip ones
   already there, mark voit-memory entry graduated.
4. Verify: `bash .voit/scripts/test.sh` green, `voit/review` passes on the diff.
5. Commit to the plugin. Do NOT record the fix in voit-memory — the code and the
   commit are the record.

Report each mismatch found and how it was closed (or why deferred).

## Branch B — consumer repo: improve this repo

1. Ensure VOIT is wired. If `.voit/scripts` is missing or `.voit/memory` is not a
   worktree, run `bash .voit/scripts/setup.sh` (idempotent — fills only
   missing keys). Report what it wired or that everything was already in place.
2. Harvest voit-memory into *this repo's own* conventions. The plugin is off-limits
   here — the target is the repo's shipped config, so the knowledge travels with the
   repo, not the plugin:
   - Read `.voit/memory/decisions` (plus flat voit-memory `.jd` files).
   - CLASSIFY each: a durable working rule / convention for this repo → graduate it.
     An instance fact, one-off event, or transient state → skip.
   - PLACE each durable one in the repo's `CLAUDE.md` (create at repo root if absent),
     phrased as a project instruction. Skip any already covered (idempotent).
   - MARK the voit-memory entry `-> graduated to CLAUDE.md` so it is not promoted twice.
3. Report each convention graduated (or why skipped). Do NOT edit the plugin from a
   consumer repo, and do NOT commit voit-memory (it is gitignored) — the CLAUDE.md
   change is the record.
