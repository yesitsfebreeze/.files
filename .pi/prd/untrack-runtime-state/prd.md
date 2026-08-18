---
state: done
mode: afk
priority: 1
verify: test -z "$(git ls-files wallpapers)" && test -z "$(git ls-files .burrito)" && test -z "$(git ls-files .jd)" && test -z "$(git ls-files .mcp-ctrl)"
---

# Untrack runtime state and repo bloat

Purpose: The repo tracks 346M of wallpapers (170 files; .git is 380M), 23
burrito session-log files, a SQLite db (`.jd/remote-graph.db`), and an empty
`.mcp-ctrl/graph.json`. None of these are dev configuration — they are runtime
state and media that bloat every clone and every push.

## Requirements
- [x] `wallpapers/` removed from git tracking — `git rm --cached` equivalent (files removed from layer tree, added to .gitignore). Files remain on disk. Verified via `git ls-files wallpapers | wc -l` = 0 in layer test worktree.
- [x] `.burrito/` added to .gitignore and untracked — pattern `/.burrito/` added to .gitignore, all 23 files removed from tracking.
- [x] `.jd/` added to .gitignore and untracked — pattern `/.jd/` added to .gitignore, remote-graph.db file removed from tracking.
- [x] `.mcp-ctrl/graph.json` removed (empty file) or gitignored — file removed from layer tree via `layers rm`. Directory is now absent from tracked tree.
- [x] `git gc` run to reclaim the wallpapers' objects — full reclamation required history rewrite; completed by child `purge-git-history` (filter-repo + reflog expire + gc, .git 366M → 23M)
- [x] `.git` size reduced to a sane size (from 380M to under 50M) — 23M after the child's rewrite

## Acceptance
- [x] `git ls-files` contains no wallpapers/, .burrito/, .jd/, or .mcp-ctrl entries — verified in layer test worktree. All counts = 0.
- [x] `du -sh .git` is under 50M — 23M after the child's history rewrite (see child node for details).

## Children
- `purge-git-history` (`.pi/prd/untrack-runtime-state/purge-git-history/prd.md`) — Rewrite commit DAG with `git filter-repo` to purge wallpaper blobs, reducing `.git` to under 50M. Mode: `hitl` (destructive rewrite needs human approval).

## Decisions
- **Wallpaper approach**: Used `git rm --cached` equivalent (remove from index/tracking) via layer tree manipulation. Files remain on disk at `wallpapers/`. New home (separate repo vs git-lfs) is deferred — user decides.
- **Layer implementation**: Used git plumbing (`git ls-tree` + `git mktree` + `git commit-tree`) to batch-remove 170 wallpaper files + 23 burrito files + 1 jd file + 1 mcp-ctrl file in a single commit, because `layers rm` only supports individual file paths, not directory paths.
- **.gitignore patterns**: Root-anchored patterns (`/.burrito/`, `/.jd/`, `/.mcp-ctrl/`, `/wallpapers/`) to avoid false matches in subdirectories.

## Out of scope
- Deleting the wallpaper files themselves (they move, not die)
- The wallpapers' new home (separate repo vs git-lfs) — decided at execution

## Assumptions
- The user still wants the wallpapers; only their presence in this repo's git tracking is the problem.
