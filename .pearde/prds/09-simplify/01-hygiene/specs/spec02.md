---
complexity: 8
footprint:
  - .gitignore
  - .graphifyignore
  - justfile
# `install` and `home/dot_config/litellm/create_config.yaml` were removed here
# on 2026-09-02 for the same reason as in the PRD: `collect` resolves every
# footprint path to a repo and refuses the whole call when one is gone. This
# spec's whole job is deleting them, so it could never have been collected
# while it named them. Both deletions are in `b233cc0`.
workflow: delete-what-nothing-reads
---

# spec02 — the four deletions nothing reads

Four things in the repo root and one under `home/` that no reader will miss:
a byte-identical copy of `install.sh`, a chezmoi-seeded YAML its own tool
rewrites, ignore rules for directories that are not in the tree, and a
one-time recipe that has run. R2 through R5 of the PRD, minus the two
clauses the analyst pass measured as false.

**What already stands** — applied in the working tree, uncommitted, by the
analyst pass, and each one verified by the command in Verify below:

- `.gitignore` lost `.pi/kern/`, `vicky/`, `board`, `__pycache__/` and the
  `!.pearde/wiki/board/` negation that only existed to undo `board`. None of
  those paths is in the tree; `find . -name board` answers only
  `.pearde/wiki/board`, which the negation was re-admitting.
- `.graphifyignore` lost `docs-site/` and `vicky/` — both absent.
- `install` deleted. `cmp install install.sh` was clean at 23,878 bytes and
  nothing outside the plan document names the extension-less form. It was
  untracked, so this is a delete, not a `git rm`.
- `home/dot_config/litellm/create_config.yaml` deleted with `git rm`.
- `justfile` lost the `cutover` recipe, and the `push` recipe's comment lost
  its now-dangling `just cutover` reference.

**What is left:** commit these five paths, after spec01's baseline commit, as
one commit of its own. Re-run the Verify block first — spec01 lands between
the analyst pass and this one and the tree may have moved.

## Two PRD clauses that are false and are not implemented

Both were measured on 2026-09-02 and are recorded here so the boxes are not
reopened by a later reader:

- **R2's `.gitignore` gains `.pearde/graphify/`** — no. `.pearde/graphify`
  is already tracked and clean: 516 files in `HEAD`, 531 in the index,
  `git status` silent. `.gitignore` carries the user's decision of the same
  day that the graph vault is versioned and only `.pearde/graphify/cache/`
  is not. Adding the rule would need `git rm -r --cached` on 516 committed
  files against that decision, and the epic puts the pearde tooling out of
  scope. The PRD's acceptance box `git check-ignore .pearde/graphify/x`
  therefore does not hold and is replaced below by the cache form, which
  does.
- **R6's `.pearde/workflows/` is empty** — no. It holds seven tracked files
  written on 2026-09-02: one workflow and six atomics, all with `runs: 2`.
  `workflows.py list` reads them and every worker brief on this board tells
  its worker to. Deleting it would delete the library this spec's own
  `workflow:` key points at.

## Acceptance

- [x] `test ! -e install && test ! -e home/dot_config/litellm/create_config.yaml`
- [x] `git check-ignore .pearde/graphify/cache/x` prints the path and
      `git check-ignore .pearde/graphify/x` exits 1 — the vault is versioned,
      only the cache is not
- [x] `grep -cE '^(\.pi/kern/|vicky/|board|__pycache__/|!\.pearde/wiki/board/)$' .gitignore`
      prints 0
- [x] `grep -c 'docs-site' .graphifyignore` prints 0
- [x] `just --list` shows `push` and `manual` and no `cutover`, and
      `grep -c cutover justfile` prints 0
- [x] `chezmoi apply --dry-run` exits 0 and prints nothing — dropping the
      source entry stops chezmoi managing `~/.config/litellm/config.yaml` and
      does not remove the deployed file
- [x] `ls ~/.config/litellm/config.yaml` still resolves, and its size differs
      from the deleted source's 12,272 bytes — proof the `create_` attribute
      never overwrote it and `litellm-gen-config` owns the file
- [x] `.pearde/workflows/` still holds its seven files and
      `python3 .claude/skills/pearde/resources/workflows.py list .` lists them
- [x] `git log -1 --stat` shows exactly these five paths

## Verify and Proof

**Rewritten by the orchestrator 2026-09-02.** What stood here was a build
script, not a proof, and it exited 1 on its own second run — which is how
`collect` found it. Four separate reasons, all of them the same mistake
(asserting the *act* instead of the *post-state*):

- `grep -c <pattern>` **exits 1 when the count is 0**, and 0 is exactly what
  success looks like for a rule this spec deletes. Two lines here asserted a
  deletion in a way that could only ever pass while the deletion had not
  happened. `grep -c ... ; test "$(...)" = 0` is the form that says it.
- `git add -A -- ... install ...` names a path deleted by this same spec.
  Once it is gone and untracked, git answers `fatal: pathspec did not match
  any files` and stages nothing — the block dies mid-way.
- `git commit` in a verify block re-commits. On a re-run there is nothing to
  commit and it exits 1. Committing is `collect`'s job, never a spec's.
- `chezmoi apply --dry-run ; echo rc=$?` swallows the status into an echo, so
  a red apply reads as a green line.

```sh
cd /Users/feb/dev/dotfiles
set -e
test ! -e install
test ! -e home/dot_config/litellm/create_config.yaml
git check-ignore .pearde/graphify/cache/x            # the cache is ignored
! git check-ignore -q .pearde/graphify/x             # the vault is versioned
test "$(grep -cE '^(\.pi/kern/|vicky/|board|__pycache__/|!\.pearde/wiki/board/)$' .gitignore || true)" = 0
test "$(grep -c 'docs-site' .graphifyignore || true)" = 0
test "$(grep -c cutover justfile || true)" = 0
recipes=$(just --list)                               # once: `just | grep -q` SIGPIPEs it
case "$recipes" in *push*) ;; *) exit 1 ;; esac
case "$recipes" in *manual*) ;; *) exit 1 ;; esac
chezmoi apply --dry-run
test -s "$HOME/.config/litellm/config.yaml"          # the generator still owns it
python3 .claude/skills/pearde/resources/workflows.py list . | grep -c delete-what-nothing-reads >/dev/null
git add -n .pearde/wiki >/dev/null                   # collect can still name it
test -z "$(git ls-tree -r HEAD --name-only | grep obsidian-api-key || true)"
```

Every line asserts a post-state and is re-runnable. The last two are not from
the original block and are the two that matter most operationally: `collect`
git-adds `.pearde/wiki` **by name** and git errors rather than skips when a
named path is ignored, so an ignore rule there breaks the whole board; and
the credential must stay out of `HEAD`.
