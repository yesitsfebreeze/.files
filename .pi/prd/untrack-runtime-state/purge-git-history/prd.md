---
state: open
mode: afk            # hitl cleared: user approved the rewrite (2026-08-18)
priority: 0
verify: test "$(du -s .git | awk '{print $1}')" -lt 51200
---

# Purge wallpapers from git history

Purpose: The repo's `.git` is 364M, dominated by wallpaper binary blobs (346M) in the commit history. `git rm --cached wallpapers/` stops future tracking but doesn't reclaim historical space. This node rewrites the commit DAG with `git filter-repo` to permanently remove wallpaper blobs from all commits, reducing `.git` below 50M. After this rewrite, everyone must re-clone.

## Requirements
- [ ] `git filter-repo --path wallpapers/ --invert-paths --refs HEAD --force` run to purge wallpaper objects from all commits on `main`
- [ ] After purge, `git gc --aggressive --prune=now` run to reclaim freed space
- [ ] `.git` size under 50M

## Acceptance
- [ ] `du -sh .git` reports under 50M
- [ ] `git rev-list --objects --all | grep wallpapers | wc -l` is 0 (no wallpaper blobs in any commit)

## Out of scope
- Untracking runtime state (`.burrito/`, `.jd/`, `.mcp-ctrl/graph.json`) — handled by parent node
- Moving wallpaper files to a new home — decided separately
- Force-pushing rewritten history to remotes — the user must do this

## Decisions
- Approach: `git filter-repo` was chosen over `git filter-branch` because it's faster (written in C+Python), safer (no shell escaping issues), and already installed (`/opt/homebrew/bin/git-filter-repo`, v2.47.0).
- **User approved the rewrite (2026-08-18)** — "Approve the rewrite". Destructive: all commit hashes change, re-clone + force-push needed.
- **Wallpaper home (user decision)**: separate repo / git-lfs — follow-on work outside this node.
- **Sequencing**: the purge runs AFTER de-windows + installer land (it rewrites the whole DAG; running it mid-flight would invalidate their layers). The conductor runs it directly on the live repo — it cannot run in a layer.
