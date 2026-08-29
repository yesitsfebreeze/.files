---
complexity: 4
footprint:
  - tests/nvim-session.sh
  - tests/nvim-small-plugins.sh
---

# spec04 — put the plugin where fifteen gates look for it

Adding one row to `lazy-lock.json` breaks the **headless stage of every nvim
gate in the repo** until the plugin exists in the developer's live clone
directory. This is the last piece of work on the node, it is one command, and
it is the only part the analyst pass could not perform: those gates read
`$HOME/.local/share/nvim/lazy` and nothing in this repo may write it.

Measured 2026-08-29, after the lockfile row landed:

```
tests/nvim-small-plugins.sh --tree      52 PASS, 0 FAIL
tests/nvim-small-plugins.sh (headless)  PROBE-ERROR: .../persistence.nvim is absent
```

Fifteen gates seed this way — autocmds, colorscheme, completion, explorer,
formatting, keymaps, lsp, markdown-tables, options, plugin-manager,
shift-select, small-plugins, statusline, telescope, treesitter. The
`PROBE-ERROR` is deliberate and correct: `gates/nvim-seed-registry.sh`'s
header records the day nvim-treesitter entering the lockfile broke three
gates at once, and an absent clone must never read as a skip. This is the
same defect arriving a second time, from a second row.

Nothing places the clone on its own. `install.sh` has no `Lazy` step —
plugins arrive when nvim first runs the deployed config — and `just cutover`
has not run, so `chezmoi source-path` still answers with the pre-rebuild
repo and the deployed `~/.config/nvim` is not this tree.

```sh
git clone https://github.com/folke/persistence.nvim \
  "$HOME/.local/share/nvim/lazy/persistence.nvim"
git -C "$HOME/.local/share/nvim/lazy/persistence.nvim" \
  checkout b20b2a7887bd39c1a356980b45e03250f3dce49c
```

Then **re-pin if the commit moved**: if a `Lazy sync` is used instead and
lazy writes a different sha, carry that sha back into `lazy-lock.json` in
the same change, per the lockfile policy in `lua/config/lazy.lua`.

Once the live clone exists, `tests/nvim-session.sh`'s pinned-clone fallback
stops firing (its `NOTE` line disappears) and the gate seeds like every
sibling. Leave the fallback in place: it is what makes this node's gate
provable on a machine that has not run the clone yet.

## Acceptance

- [x] `$HOME/.local/share/nvim/lazy/persistence.nvim` exists and its `HEAD`
      is the commit `lazy-lock.json` pins
- [x] `bash tests/nvim-session.sh` runs with no `NOTE ... falling back to a
      pinned clone` line on stderr
- [x] all fifteen lockfile-seeded nvim gates run to completion — no
      `PROBE-ERROR ... persistence.nvim is absent` from any of them
- [x] `tests/nvim-options.sh`, `tests/nvim-small-plugins.sh` and
      `tests/nvim-explorer.sh` are green end to end, tree and headless
- [x] if the pinned commit was changed, `lazy-lock.json` carries the new sha
      in lazy's one-line-per-plugin format

The fourth box was **left open by the implementer deliberately, and closed by
the orchestrator on 2026-08-29 after widening this spec's footprint.** The
history is kept because it is the reason the footprint moved.

`nvim-options.sh` and `nvim-explorer.sh` were green end to end (74/0 and
107/0). `nvim-small-plugins.sh` was not: with the clone in place its headless
stage ran for the first time and went red **146 PASS / 5 FAIL**, because its
`C/R2` checks hardcode **five** which-key leader groups and this node's
`session` group makes it six (`wk_decl_n=6`). Its tree stage was green, which
is the only stage the analyst could reach — the absent clone PROBE-ERRORed the
headless one and masked it. The implementer reported the repair with exact line
numbers in `probe/notes.md` step 23 rather than performing it, because
`tests/nvim-small-plugins.sh` was in no spec's footprint. **That refusal was
correct and the footprint was wrong**: this file is the exact analogue of
`tests/nvim-options.sh`, whose which-key census the analyst *did* update and
*did* place in spec01's footprint. One census file was listed and its sibling
was not.

Repaired by the orchestrator: five → six in the declared count, the ordered
readback, and both mutation counterfactuals (`cf6`'s renamed-group line and
`cf7`'s deleted-`<leader>b` count, which now reads five rather than four).
Measured after: **`bash tests/nvim-small-plugins.sh` rc=0, 151 PASS, 0 FAIL**,
with `cf6` and `cf7` still passing — so the six-group assertion binds rather
than having been loosened to accommodate the change. The count moved because
the tree did, which is the only honest reason to move a census.

Recorded against
[`a-hand-kept-list-standing-in-for-a-property-of-the-tree`](../../../memos/a-hand-kept-list-standing-in-for-a-property-of-the-tree-is-this-board-s-most-common-defect.md):
a gate hardcoding the number of which-key groups is a fact about the tree
written as a maintained list, and it goes wrong the moment anyone adds a group.
Repairing the number does not fix that shape — the next group added reds it
again.

## Verify and Proof

```sh
cd /Users/feb/dev/dotfiles
bash tests/nvim-session.sh
bash tests/nvim-options.sh
bash tests/nvim-small-plugins.sh
bash tests/nvim-explorer.sh
```
