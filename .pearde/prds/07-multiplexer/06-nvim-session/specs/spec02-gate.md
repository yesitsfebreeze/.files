---
complexity: 8
footprint:
  - tests/nvim-session.sh
---

# spec02 — the gate that proves the round trip, and can fail

`tests/nvim-session.sh` proves the node's whole claim against a real headless
Neovim running the real config: a session is written on exit, the published
restore command brings the buffers back, and neither happens by accident.

**This already stands and is green** — 17 tree checks, 3 counterfactual
selftests, 12 headless checks, `rc=0` on 2026-08-29 against nvim 0.12.4 and
persistence.nvim `b20b2a7`. What is left is to keep it honest if the spec
changes, and to understand why three of its checks are shaped the way they
are.

The three checks that make the round trip falsifiable, and which must not be
dropped as redundant:

- **A bare `nvim` restores nothing.** Without it, the restore check proves
  nothing about the restore *command* — an auto-restoring plugin would pass
  the round trip identically. This check is the one that separates
  persistence.nvim from auto-session, and it is why `07-persistence` has to
  be handed an explicit command rather than assuming a plain relaunch works.
- **Exiting an empty nvim leaves the session byte-identical.** This is
  `need = 1` holding: a pane where nvim was opened and closed without a file
  must not destroy what resurrect is meant to bring back.
- **No `Session.vim` appears in the work tree.** The Q13 preamble assumed
  resurrect's `session` strategy, which requires exactly that file in the
  pane's cwd. This node deliberately does not write it, and the check is what
  stops someone quietly reintroducing it.

Two mechanics measured while building it, both worth keeping:

- **The parser seed must be the full live list, not a trimmed one.** Seeded
  with nine of the sixteen parsers, nvim-treesitter's `install()` reached the
  network at `BufReadPost`: seven `Downloading tree-sitter-*` lines on the
  stage's stderr and a false red on the empty-stderr check. A parser missing
  from the seed source is `PROBE-ERROR`, never a skip.
- **The persistence seed carries a documented fallback.** Every sibling gate
  copies each `lazy-lock.json` key from `$HOME/.local/share/nvim/lazy` and
  treats an absent clone as `PROBE-ERROR`. persistence.nvim is not there
  until spec04 runs, so this gate — and only this gate — falls back to a
  pinned clone of the lockfile commit, printing a `NOTE` line when it does.
  A silent fallback would hide the day the live install stops matching the
  lockfile. **Do not copy this fallback into the sibling gates**: that is
  fifteen files and another node's contract.

## Acceptance

- [x] `bash tests/nvim-session.sh` exits 0, with a `--tree` and a
      `--headless` stage that can each be run alone
- [x] the tree stage strips comment lines before matching, so a claim cannot
      be satisfied by the prose that explains it (the `lazy = false` trap
      `tests/nvim-explorer.sh` records — this file's own header contains that
      string)
- [x] at least three counterfactual selftests, each proving a tree check by
      its own red: a copy with `lazy = false` deleted, a copy overriding
      `need`, and a copy naming a different plugin
- [x] the headless stage asserts, through the real config under lazy:
      `plugins["persistence.nvim"].lazy = false`, the plugin loaded at
      startup, `#persistence#VimLeavePre` registered, and the session
      directory created by `setup()`
- [x] the headless stage runs the full round trip — exit with two files,
      then restore with `nvim -c "lua require('persistence').load()"` — and
      asserts both buffers by name
- [x] the three falsifiers above are present and pass: bare nvim restores
      nothing, an empty exit leaves the session unchanged, no `Session.vim`
      in the work tree
- [x] a non-default git branch gets its own session file, so two branches in
      one directory do not overwrite each other
- [x] every staged run leaves stderr empty
- [x] `bash gates/nvim-seed-registry.sh` accounts for this gate as `seeded`
      and stays set-equal

## Verify and Proof

```sh
cd /Users/feb/dev/dotfiles
bash tests/nvim-session.sh
bash gates/nvim-seed-registry.sh
```
