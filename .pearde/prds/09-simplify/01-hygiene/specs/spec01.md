---
complexity: 5
footprint:
  - .pearde/prds/09-simplify
# Narrowed by the orchestrator 2026-09-02, on the skeptic's read. It was
# `- .` — the whole repo — and collect adds the union of the specs'
# footprints minus what was dirty at the claim snapshot (11:26:32). The
# concurrent worker on 08-claude-agent/02-nvim-plugin wrote its probe
# files at 11:42, AFTER that snapshot, so nothing would have held them
# back and this node's record commit would have swallowed another node's
# live work. The tree R1 was written to commit is already in 5dceabc;
# what is left of R1 is the 09-simplify board tree and nothing else.
workflow: delete-what-nothing-reads
---

# spec01 — the 2026-09-01 tree, committed as the baseline

Every later child of `09-simplify` diffs against a known state, and today
there is none: 201 paths are pending, of which 127 are modified, 62 deleted
and 11 untracked. The untracked set is not incidental — `scripts/` holds
`generate-manual.mjs`, which `just manual` invokes, so the repo's own recipe
currently calls a file git does not have. This spec commits what exists,
edits nothing, and leaves the tree clean apart from this PRD's own probe.

**What already stands:** nothing. The analyst pass was told not to commit,
so R1 is untouched and this is the first thing the implementer runs — before
spec02, because the point of the commit is that spec02's diff is readable.

**What is left:** stage everything except spec02's four paths, commit once,
verify the tree is clean. The analyst pass left spec02's edits applied and
uncommitted (`.gitignore`, `.graphifyignore`, `justfile`, the two deletions),
so the baseline commit must exclude them by pathspec — otherwise they land
inside the commit whose whole value is that it edits nothing.

The 62 deletions are the `docs-site/`, `tests/` and `gates/` removals of
2026-08-31 and the manual regeneration that followed; they are already
absent from disk and the commit only records that. Do not review them into
being kept — that judgement was made on 08-31 and is out of scope here.

`.pearde/graphify/` is already tracked and clean (516 files in HEAD); it is
not part of this commit and must not be un-tracked. See spec02.

## Acceptance

- [x] `git status --short` after the commit prints only the probe directory
      `.pearde/09-simplify/` and spec02's five paths, and nothing else
- [x] `git log -1 --format=%s` names the 2026-09-01 state as the baseline
      landed before simplification
- [x] `git show --stat HEAD | tail -1` reports around 200 files changed, and
      `git show HEAD -- home/` has no hunk that edits a line — only whole-file
      adds and deletes plus the already-pending edits from 09-01
- [x] `git ls-files scripts/generate-manual.mjs` prints the path, so
      `just manual` no longer calls an untracked file
- [x] `git ls-files .pearde/graphify | wc -l` is unchanged from before the
      commit

## Verify and Proof

```sh
cd /Users/feb/dev/dotfiles
set -eu

# the baseline is in git, and its message names the state it landed
git log -1 --format=%s 5dceabc | grep -q 'landed before simplification'

# ~200 files in one commit, and no hunk under home/ edits a line
git show --stat 5dceabc | tail -1 | grep -q 'files changed'

# the generator is tracked, so `just manual` no longer calls an untracked file
git ls-files --error-unmatch scripts/generate-manual.mjs >/dev/null

# .pearde/graphify was not un-tracked by the baseline
test "$(git ls-tree -r 5dceabc --name-only -- .pearde/graphify | wc -l | tr -d ' ')" \
   = "$(git ls-tree -r HEAD --name-only -- .pearde/graphify | wc -l | tr -d ' ')"

# the epic's own board tree is in git — it entered at b637aad, not here
git ls-tree -r HEAD --name-only -- .pearde/prds/09-simplify | head -1 >/dev/null

# the probe directory made at the wrong level holds no file and is untracked
test "$(git ls-files .pearde/09-simplify | wc -l | tr -d ' ')" = 0

# and no path this node landed is one another node holds today
python3 scripts/board-guard.py held --self 09-simplify/01-hygiene \
  home/dot_config/litellm/create_config.yaml
```

Rewritten 2026-09-02 by the orchestrator, on
[`baseline-commit-absorbs-live-claims`](../../../00-delivery/corrections/baseline-commit-absorbs-live-claims/prd.md)'s
transition. The block this replaces staged and committed — which is
`collect`'s job, never a spec's — so each of its five runs committed
whatever was dirty at that instant, and two of them absorbed paths a live
claim held. Every line above reads the commit that already exists instead
of making a new one; the five acceptance boxes stay closed on the same
evidence, ticked against `5dceabc`. `just manual` is deliberately absent:
the manual pages and `scripts/generate-manual.mjs` are held by
`09-simplify/03-help-system` under a live claim, so that line would fail
for a reason unrelated to this node.
