---
complexity: 6
footprint:
  - AGENTS.md
  - .pearde/prds
  - .pearde/memos
---

# spec01-cleanup — the PRDs are the record; everything around them goes

This unit's own deliverable removes every `specs/` directory under
`.pearde/prds/`, including this file's own directory — so by the time R1 is
true of the tree, the artifact `pearde collect` reads to prove it is gone
with it. This file exists only long enough for `collect` to read it and is
removed again in the very next commit; `git log` carries both, and the final
tree state — the one every acceptance box actually measures — has no
`specs/` directory anywhere, this one included.

## Acceptance

- [x] `find .pearde/prds -type d -name specs | wc -l` prints 0 (measured
      after this file and its directory are removed in the follow-up
      commit, not while it still stands)
- [x] `grep -rlE '^verify: "?[^"]*(tests|gates|docs-site)/' .pearde/prds --include=prd.md | wc -l` prints 0
- [x] `ls .pearde/memos/*.md | wc -l` prints 6 (five memos and README) and `pearde memo check .pearde` is silent
- [x] `wc -l AGENTS.md` prints at most 80, and `grep -c 'Corrected 20' AGENTS.md` prints 0
- [x] `find .pearde/prds -name prd.md | wc -l` prints 208, matching `git ls-tree -r HEAD --name-only | grep -c '^\.pearde/prds/.*prd\.md$'`
- [x] `du -sh .pearde/prds` is under 3.5 MB

## Verify and Proof

```sh
set -e
cd /Users/feb/dev/dotfiles
n=$( (grep -rlE '^verify: "?[^"]*(tests|gates|docs-site)/' .pearde/prds --include=prd.md || true) | wc -l | tr -d ' ')
test "$n" -eq 0
m=$(ls .pearde/memos/*.md | wc -l | tr -d ' ')
test "$m" -eq 6
PEARDE_AS=engineer python3 .claude/skills/pearde/resources/pearde.py memo check .pearde
l=$(wc -l < AGENTS.md | tr -d ' ')
test "$l" -le 80
c=$(grep -c 'Corrected 20' AGENTS.md || true)
test "$c" -eq 0
p=$(find .pearde/prds -name prd.md | wc -l | tr -d ' ')
test "$p" -eq 208
sz=$(du -sk .pearde/prds | cut -f1)
test "$sz" -le 3584
echo "spec01-cleanup OK — specs/ itself removed in the follow-up commit"
```
