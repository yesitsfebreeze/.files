---
complexity: 8
footprint:
  - .gitignore
  - .graphifyignore
  - install
  - justfile
  - home/dot_config/litellm/create_config.yaml
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

```sh
cd /Users/feb/dev/dotfiles
test ! -e install && test ! -e home/dot_config/litellm/create_config.yaml
git check-ignore .pearde/graphify/cache/x
git check-ignore .pearde/graphify/x ; test $? -eq 1
grep -cE '^(\.pi/kern/|vicky/|board|__pycache__/|!\.pearde/wiki/board/)$' .gitignore
grep -c 'docs-site' .graphifyignore
just --list ; grep -c cutover justfile
chezmoi apply --dry-run ; echo "rc=$?"
ls -l ~/.config/litellm/config.yaml
ls .pearde/workflows | wc -l
python3 .claude/skills/pearde/resources/workflows.py list .
git add -A -- .gitignore .graphifyignore justfile install \
  home/dot_config/litellm/create_config.yaml
git commit -m "delete the install duplicate, the generated litellm yaml, the dead ignore rules and the cutover recipe"
git log -1 --stat
```
