---
state: claimed
mode: afk
priority: 1
verify: test "$(git ls-files wallpapers | wc -l)" = 0 && test "$(git ls-files .burrito | wc -l)" = 0 && test "$(git ls-files .jd | wc -l)" = 0 && test "$(git ls-files .mcp-ctrl | wc -l)" = 0
claim: 01a01605-6d60-7e7e-adc5-36557224f3f4
---

# Untrack runtime state and repo bloat

Purpose: The repo tracks 346M of wallpapers (170 files; .git is 380M), 23
burrito session-log files, a SQLite db (`.jd/remote-graph.db`), and an empty
`.mcp-ctrl/graph.json`. None of these are dev configuration — they are runtime
state and media that bloat every clone and every push.

## Requirements
- [ ] `wallpapers/` removed from git tracking (moved to a separate repo, git-lfs, or a local non-tracked dir)
- [ ] `.burrito/` added to .gitignore and untracked
- [ ] `.jd/` added to .gitignore and untracked
- [ ] `.mcp-ctrl/graph.json` removed (empty file) or gitignored
- [ ] `git gc` run to reclaim the wallpapers' objects
- [ ] `.git` size reduced to a sane size (from 380M to under 50M)

## Acceptance
- [ ] `git ls-files` contains no wallpapers/, .burrito/, .jd/, or .mcp-ctrl entries, and `du -sh .git` is under 50M.

## Out of scope
- Deleting the wallpaper files themselves (they move, not die)
- The wallpapers' new home (separate repo vs git-lfs) — decided at execution

## Assumptions
- The user still wants the wallpapers; only their presence in this repo's git tracking is the problem.
