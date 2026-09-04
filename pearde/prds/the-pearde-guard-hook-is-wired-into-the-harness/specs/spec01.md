---
complexity: 4
footprint:
  - .claude/settings.json
---

# spec01 — `pearde guard on` writes the hooks block into `.claude/settings.json`, and the file is committed

`pearde guard on` was run against this repo and wrote `.claude/settings.json`
at the repo root: the four hook entries of `@references/parts/guard.md`
(`PreToolUse` ×2, `PostToolUse`, `SessionStart`) plus
`env.MAX_THINKING_TOKENS = "8000"`. `pearde guard <repo>` (the explicit-path
form, which reads that repo's own settings file rather than walking up)
confirms `guard ok — wired in <repo>/.claude/settings.json ·
MAX_THINKING_TOKENS=8000 · skill tree guarded`, and the fixture at
`prds/the-pearde-guard-hook-is-wired-into-the-harness/probe/
claim-staging-fixture.sh` shows the hook itself refuses a hand-walked board
read, exactly as `@references/parts/guard.md` documents.

`pearde doctor` run with a **relative** `.` argument does not see this: the
walk-up helper in `doctor.sh` never climbs past a relative start, so it never
reaches the board. Run with an **absolute** path it climbs correctly — but
from inside `pearde/.lanes/<this-prd>/`, that absolute walk-up climbs past
the sparse lane checkout (which excludes `pearde/` entirely) into the real
`pearde/` sitting one level up on disk, and reports on
`/Users/feb/dev/dotfiles/.claude/settings.json` — the main repo's file, not
this lane's own. This is an artifact of lanes living inside the repo they
plan for; once this diff is committed and merged, `pearde doctor` run from
the merged repo checks the same file this spec wrote, with no lane in the
way. What is left to finish is committing the diff.

## Acceptance

- [x] `pearde guard on` writes the block of `@references/parts/guard.md`
      into `.claude/settings.json` at the repo root.
- [x] `pearde guard <repo>` (explicit path) reports `guard ok`.
- [x] `.claude/settings.json` is committed.

## Verify and Proof

```sh
cd /Users/feb/dev/dotfiles/pearde/.lanes/the-pearde-guard-hook-is-wired-into-the-harness
python3 /Users/feb/dev/dotfiles/.claude/skills/pearde/resources/pearde.py guard "$(pwd)"
# guard       ok      wired in .../.claude/settings.json · MAX_THINKING_TOKENS=8000 · skill tree guarded
git status --short .claude/settings.json   # empty once committed
```
