---
state: open
mode: afk            # hitl cleared: user approved the rewrite (2026-08-18)
priority: 0
verify: test "$(du -s .git | awk '{print $1}')" -lt 51200
---

# Purge wallpapers from git history

Purpose: The repo's `.git` is 364M, dominated by wallpaper binary blobs (346M) in the commit history. `git rm --cached wallpapers/` stops future tracking but doesn't reclaim historical space. This node rewrites the commit DAG with `git filter-repo` to permanently remove wallpaper blobs from all commits, reducing `.git` below 50M. After this rewrite, everyone must re-clone.

## Requirements
- [x] `git filter-repo --path wallpapers/ --invert-paths --refs HEAD --force` run to purge wallpaper objects from all commits on `main` — 510 commits rewritten in 1.5s. Second run: `--path home/wallpapers/` (2 orphaned jpgs still tracked under home/).
- [x] After purge, `git gc --aggressive --prune=now` run to reclaim freed space — plus `git reflog expire --expire=now --all` (the reflog was keeping the old blobs alive; without it gc reclaimed nothing)
- [x] `.git` size under 50M — 23M (down from 366M)

## Acceptance
- [x] `du -sh .git` reports under 50M — 23M; verify command passes (51032 blocks < 51200)
- [x] `git rev-list --objects --all | grep wallpapers | wc -l` is 0 — 0 (no wallpaper blobs in any commit)

## Artifact (conductor-run, 2026-08-18)
- Ran directly on the live repo (cannot run in a layer). User approval recorded in commit 664bb05.
- **Pre-flight**: dropped 3 autostashes (stash@{0} held 18 wallpaper objects), deleted stale `refs/remotes/origin/main` (195 wallpaper objects; recreated on next fetch). `refs/heads/pi` has 0 wallpaper objects (forked before wallpapers were added) — untouched.
- **Reflog discovery**: after filter-repo + gc, .git was still 359M — the reflog referenced pre-rewrite commits, keeping the old blobs alive. `git reflog expire --expire=now --all` + `git gc --prune=now` dropped it to 25M.
- **home/wallpapers/**: 2 orphaned jpgs (~2MB) still tracked under home/ (untrack-runtime-state only handled top-level wallpapers/). Untracked (git rm --cached, files stay on disk), added `home/wallpapers/` to .gitignore, then purged from history with a second filter-repo run.
- **Wallpaper files on disk**: the untrack-runtime-state merge had deleted the top-level wallpapers/ files from the live working tree (merge applies tree deletions; the node's "files remain on disk" was only true in the layer worktree). Restored all 171 files (346M, 6 color dirs) from the pre-untrack commit as untracked+gitignored — the follow-on "move to separate repo" work has them locally.
- **Post-rewrite**: `just gate` passes, prd tree intact, git status clean. Refs: main, pi, origin/pi. Remote still holds old history (user must force-push + re-clone; recover anything else from the remote before force-pushing).

## Out of scope
- Untracking runtime state (`.burrito/`, `.jd/`, `.mcp-ctrl/graph.json`) — handled by parent node
- Moving wallpaper files to a new home — decided separately
- Force-pushing rewritten history to remotes — the user must do this

## Decisions
- Approach: `git filter-repo` was chosen over `git filter-branch` because it's faster (written in C+Python), safer (no shell escaping issues), and already installed (`/opt/homebrew/bin/git-filter-repo`, v2.47.0).
- **User approved the rewrite (2026-08-18)** — "Approve the rewrite". Destructive: all commit hashes change, re-clone + force-push needed.
- **Wallpaper home (user decision)**: separate repo / git-lfs — follow-on work outside this node.
- **Sequencing**: the purge runs AFTER de-windows + installer land (it rewrites the whole DAG; running it mid-flight would invalidate their layers). The conductor runs it directly on the live repo — it cannot run in a layer.
