---
kind: documentation
description: Build, check, and navigate this repo — the commands a change runs
read_when: running or verifying a repo change
---

# commands

```
just memos-check        # the memos gate alone — regenerates every index level
just manual             # regenerate the manual's guide/ + reference/ from the .nuon surfaces
just board-guard prd paths   # refuse a path another PRD holds under a live claim
just board-guard-blocks # refuse a spec whose Verify block stages or commits
just push               # stage, commit, push
```

One gate run is one command and one exit read: `just memos-check; echo "exit=$?"`.
A bare run followed by a second run for the exit code reads the tree twice, and
the tail of a passing run looks exactly like the tail of a failing one.

The shell is nushell: any command carrying a loop, a variable or word-splitting
goes inside `bash -c '…'` that begins with its own `cd`, and every path outside
that directory is absolute.

Deploying is `chezmoi apply` — nothing in this file deploys. Retiring a file
is two edits and is proven at the deployed path ([[a-retirement-is-two-edits]]).

See [[memo-index]] and [[the-manual-is-markdown]].