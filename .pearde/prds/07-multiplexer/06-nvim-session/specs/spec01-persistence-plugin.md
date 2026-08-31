---
complexity: 9
footprint:
  - home/dot_config/nvim/lua/plugins/session.lua
  - home/dot_config/nvim/lazy-lock.json
  - home/dot_config/nvim/lua/plugins/which-key.lua
  - tests/nvim-options.sh
---

# spec01 — persistence.nvim writes the session, and the config absorbs it

Neovim gains one plugin spec that saves the open buffer set on exit and
restores it on demand. The plugin choice was delegated to the analyst by the
epic's **Q13**, and the recommendation is **persistence.nvim** — the
reasoning is carried in the spec file's own header, because it is the kind of
reason a later reader will otherwise re-litigate. Two files in the `done`
`03-editor` epic move with it: which-key gains a `session` group, and
`tests/nvim-options.sh`'s exhaustive file census gains the new path.

**This already stands, built and green.** What is left is review, not
construction: read the rationale, confirm the choice, and keep the four files
consistent if anything is changed.

The recommendation, measured rather than assumed (2026-08-29, nvim 0.12.4):

- The PRD's framing does not survive reading either plugin. It offers
  auto-session as the "branch-aware" one that "brings a picker", as if
  persistence.nvim were neither. persistence.nvim is branch-aware by default
  (`branch = true`, appended to the session name as `%%<branch>`) and ships
  `require("persistence").select()`, a picker over `vim.ui.select`.
- What actually separates them is **size** — 180 lines in two files against
  4213 across a package — and **when they restore**. persistence.nvim
  restores only when asked; auto-session's `auto_restore` fires on every bare
  `nvim` started in a directory it has a session for. That second behavior
  reaches past this node's contract into ordinary editing, and this node is
  not licensed to change that.
- `03-editor` **I2** and **I3** point the same way: `:mksession` is the
  built-in, and the only things missing from it are a place to put the file
  and a hook to write it. That is the whole of persistence.nvim.

Three details that are load-bearing and must not be "tidied":

- **`opts = {}`, not an override of `need`.** The default `need = 1` is what
  stops a bare nvim, opened and closed in a directory, from replacing that
  directory's real session with an empty one.
- **`lazy = false`.** A spec carrying `keys` overrides
  `defaults = { lazy = false }` in `lua/config/lazy.lua` (the trap
  `06-explorer` measured for oil.nvim). The save autocmd must be registered
  before the first exit, so the load cannot wait on a keypress.
- **The keys are `<leader>s*`, not persistence.nvim's documented
  `<leader>q*`.** `<leader>q` is already a **leaf** map in this config
  (`Quit`). Binding `<leader>qs` on top of it would make every quit wait
  `timeoutlen` for a second key. `<leader>s` was unbound — the config binds
  `- | b bd c ca cf e f fb ff fg fh p q r rn t tt w` and nothing on `s`.
- **The `session` group goes last in `which-key.lua`**, after `table`.
  `tests/nvim-small-plugins.sh` asserts R2's five groups as five *ascending
  line numbers*, so inserting alphabetically among them goes red on the order
  check while the set check still passes.

## Acceptance

- [x] `home/dot_config/nvim/lua/plugins/session.lua` declares
      `"folke/persistence.nvim"`, one spec in the file, named for the concern
      and not the plugin (`03-editor` **I8**)
- [x] the spec carries `lazy = false` in code, and a comment saying why
- [x] the spec calls setup with `opts = {}` and does **not** set `need`
- [x] the three keys are `<leader>ss` (restore this directory's session),
      `<leader>sl` (restore the last), `<leader>sd` (stop the save), each
      with the `desc` the manual entry names
- [x] the file registers no `nvim_create_autocmd` of its own (`03-editor`
      **I7** — persistence.nvim's own augroup is already cleared, and a
      second, ungrouped one here would double-fire)
- [x] `lazy-lock.json` carries a `persistence.nvim` row on branch `main`
      pinned to a 40-hex commit, in lazy's one-line-per-plugin format — a
      `json.dumps(indent=2)` rewrite reformats all nineteen other rows
- [x] `which-key.lua` declares `{ "<leader>s", group = "session" }` after
      the `table` group, and `bash tests/nvim-small-plugins.sh --tree` stays
      green on both the group check and the group-order check
- [x] `tests/nvim-options.sh`'s file census lists
      `./lua/plugins/session.lua` and the gate's `--tree` stage is green

## Verify and Proof

```sh
cd /Users/feb/dev/dotfiles
bash tests/nvim-session.sh --tree
bash tests/nvim-small-plugins.sh --tree
bash tests/nvim-options.sh --tree
```
