---
est: 0.5h
footprint:
  - home/dot_config/nvim/lua/plugins/explorer.lua
  - home/dot_config/nvim/lazy-lock.json
  - tests/nvim-options.sh
---

# spec01 — explorer.lua, two lockfile rows, and the census insert

Port `~/.config/nvim/lua/plugins/explorer.lua` into the repo **with the
L-7 correction applied** (`lazy = false`), grow `lazy-lock.json` by
`oil.nvim` and `nvim-web-devicons` from a real network run, and insert the
new file into the one hardcoded census string in `tests/nvim-options.sh`.
Covers PRD R1–R4.

Everything asserted below was measured 2026-08-23 against nvim 0.12.4 in
seeded scratch `HOME`/XDG roots. The live file was not merely read.

## The plugin file

**`lua/plugins/explorer.lua`** — the live file is 12 lines and 4-space
indented; reindent to the repo's **2 spaces**, and keep every grep in
spec02's gate indentation-independent for that reason. The live file
already satisfies R2 and R3 exactly:

- `"stevearc/oil.nvim"`;
- `dependencies = { "nvim-tree/nvim-web-devicons" }`;
- `opts = { view_options = { show_hidden = true } }`;
- `keys = { { "<leader>e", "<cmd>Oil<CR>", desc = "Open file explorer" } }`.

**Add `lazy = false`.** The live file does not have it, and that absence
*is* live bug L-7. `lua/config/lazy.lua` sets `defaults = { lazy = false }`,
but a spec carrying `keys` overrides the default: measured, the live shape
reports `plugins["oil.nvim"].lazy == true` at startup. Put the key on its
own line above `opts`.

Add one comment block above the return, recording R4's decision and the
three measured facts that make it non-negotiable. spec02's gate asserts the
comment mentions `lazy = false` **and** `netrw`, so it cannot be dropped by
a later reader who sees a lazy-loadable plugin loading eagerly:

1. Oil installs its `default_file_explorer` hijack inside `setup()`
   (`oil.nvim/lua/oil/config.lua:4` — the option defaults to `true`), so
   while the plugin is unloaded it hijacks nothing.
2. With netrw disabled by
   [`04-plugin-manager`](../../04-plugin-manager/prd.md) and oil lazy,
   `:e some/dir` opens **an ordinary empty buffer whose name is the
   directory** — `filetype` empty, one blank line, oil still unloaded.
   Measured on the live shape.
3. That is worse than stock. Measured on the same tree with
   `"netrwPlugin"` removed from `disabled_plugins`: `:e some/dir` gives
   `filetype = netrw` and a real directory listing (`netrw v184`). Restore
   the entry and the listing is gone. So the dead end is this config's
   doing, not Neovim's.
4. The cost is bounded and small: with `lazy = false`, lazy reports oil's
   load at **3.0–3.6 ms** at startup (`_.loaded.time`, three runs).

**Do not move the keymap to `keymaps.lua`.** Epic
[I5](../../prd.md) puts plugin keymaps in the plugin's spec, and the
mapping survives the eager load intact. Mechanism, measured, worth the
comment it earns in spec02's gate: `Handler.setup()` runs before
`Loader.startup()`, so lazy registers the `<leader>e` loader stub while oil
is still unloaded; loading oil then calls `Handler.disable` →
`keys:_del` → `keys:_set`, which deletes the stub and sets the **real**
mapping. Read back at startup with `lazy = false`: `rhs = <cmd>Oil<CR>`,
`expr = 0`, `desc = Open file explorer`. On the live lazy shape the same
read gives `rhs = nil`, `expr = 1`, a callback — the loader stub. Both
carry the desc, so a desc-only check cannot tell the two apart; spec02 uses
`expr`/`rhs` and the load state.

No `vim.keymap.set` and no `nvim_create_autocmd` in this file — I5 and I7.
The live file has neither; keep it that way.

## `lazy-lock.json` — two rows, grown from a real run

E.2's policy (R2): rows come from a real install, never by hand. Flow,
measured end to end:

1. Stage `home/dot_config/nvim/` (with the new `explorer.lua`) into a fresh
   scratch root, seed **only** the plugins the repo lockfile already names,
   and launch `nvim --headless +qa` with network. lazy clones `oil.nvim`
   and `nvim-web-devicons` and rewrites the scratch lockfile. Measured: 1.3
   s wall clock, exit 0, empty stderr.
2. **Merge two rows, do not copy the file.** Take only the `oil.nvim` and
   `nvim-web-devicons` rows; leave every existing row byte-identical.
   Measured trap, and it is sharper here than for the sibling nodes: lazy
   rewrites **every** row from the state of the clone it finds, so the run
   moved `nvim-lspconfig` from the repo pin `221c4388…` to `4267d26e…` and
   `mason-lspconfig.nvim` from `9d28935a…` to `67029ccd…` — two rows
   [`09-lsp`](../../09-lsp/prd.md) owns — purely because the seed came from
   the live clones. A wholesale copy retargets another node's pins as a
   side effect of this one.
3. **Keep lazy's one-line-per-plugin format.** Each row is exactly
   `  "<name>": { "branch": "<b>", "commit": "<40hex>" },`. Measured trap:
   rewriting the file with `json.dump(…, indent=2)` splits every row across
   four lines, and `tests/nvim-completion.sh:219`'s truncated-commit
   selftest **silently stops mutating anything** — its `sed` is line-scoped
   on the `blink.cmp` line — so that selftest goes red and E.6's gate fails
   on a pure formatting change. Merge textually, or write the rows back in
   lazy's shape.
4. Do **not** transcribe the rows from `~/.config/nvim/lazy-lock.json`.
   Today a fresh resolve lands on exactly the live pins for both
   (`oil.nvim b73018b7…`, `nvim-web-devicons 2ae6958d…`, confirmed against
   `git ls-remote … HEAD` for both repos), so a transcription would happen
   to be right. That is luck, not a rule — the same check on the sibling
   node found `telescope.nvim` already moved past its live pin. Whatever
   the run resolves is the row.

`tests/nvim-plugin-manager.sh` needs **no edit**: its seed helper
(`LOCK_KEYS`, line 73) and its `--network` restore comparison (line 385)
are both driven by the lockfile's key list, so both new keys enter
automatically.

## `tests/nvim-options.sh` — the census insert

One hardcoded string, the `--tree` census equality at line 201. **Read the
line in the file as it stands; do not transcribe a fixed list from this
spec.** [`08-telescope`](../../08-telescope/prd.md) and
[`09-lsp`](../../09-lsp/prd.md) are both editing the same string in this
window; whichever node lands last must insert into what it finds, or it
drops the others' rows. Insert `./lua/plugins/explorer.lua` at its
`LC_ALL=C` position — after `./lua/plugins/completion.lua`, before
`./lua/plugins/init.lua`. Leave the label wording alone; it belongs to the
lane that last touched it.

The seed helper in that file is lockfile-driven, so nothing else there
changes.

## The manual entry — read-only, and it will MISMATCH

`home/dot_config/nushell/help/nvim.nuon` already carries the `<leader>e`
entry, and its `verify` target is correct: `{kind: "nvim-map", mode: "n",
lhs: "<leader>e", desc: "Open file explorer"}` reads back exactly that desc
under the eager shape (measured). `tests/help-content-model.nu:200` checks
the key's presence only.

Its `why` field is **stale**: it says "The plugin is lazy on that key, so
its file-explorer hijack is not installed until the first time you press
it — and netrw is disabled, so before that press `:e` on a directory
reaches neither one." That describes the pre-correction shape this node
removes. **Do not edit it** — the S.5 lane holds
`home/dot_config/nushell/`. Report it as a correction to file, quoting the
measurement: under the shape this node lands, `:e some/dir` opens oil
(`filetype = oil`, buffer `oil://…`) with no key pressed.

## Acceptance

- [ ] `home/dot_config/nvim/lua/plugins/explorer.lua` exists, is 2-space
      indented, carries `lazy = false`, `show_hidden = true`, the
      `<leader>e` keys row, the devicons dependency, the R4 comment naming
      `lazy = false` and `netrw`, and no `vim.keymap.set` /
      `nvim_create_autocmd` (spec02's `--tree` stage is the check; run the
      greps inline until it exists).
- [ ] `home/dot_config/nvim/lazy-lock.json` parses, holds `oil.nvim` and
      `nvim-web-devicons` with 40-hex commits, every pre-existing row
      byte-identical (`git diff` shows two added lines and nothing else),
      and lazy's one-line-per-plugin format intact.
- [ ] The generation root proves the rows came from a run: quote the
      scratch lockfile's two rows and
      `git -C <root>/data/nvim/lazy/oil.nvim log -1 --format=%H`.
- [ ] `bash tests/nvim-options.sh` exits 0 with the census grown by
      `./lua/plugins/explorer.lua` and no other census entry lost.
- [ ] `bash tests/nvim-plugin-manager.sh --tree` and `--headless` exit 0
      with that file untouched: `shasum -a 256 tests/nvim-plugin-manager.sh`
      is identical before and after both runs, quoted both times.
      `git diff --stat` cannot answer it — `tests/nvim-plugin-manager.sh` is
      untracked (`git ls-files --error-unmatch`, 2026-08-23; `tests/` is 15 of
      35), so "names it nowhere" is true of every untracked file whether the
      run touched it or not.
- [ ] `bash tests/nvim-plugin-manager.sh --network` exits 0 and its restore
      loop prints one commit equality per lockfile key, two of them the new
      keys.
- [ ] `bash tests/nvim-completion.sh` exits 0 — in particular the
      truncated-commit selftest, which the lockfile format decides.
- [ ] `assert_unchanged` green in every gate run — no write to real
      `~/.config/nvim`, `~/.local/share/nvim`, `~/.local/state/nvim`,
      `~/.cache/nvim`.

**Flake warning, measured by the sibling lane 2026-08-23 — do not chase
these.** `tests/nvim-completion.sh` (blink's async keymap setup missing its
10 s window) and `tests/nvim-plugin-manager.sh --headless` (clone-failure
watchdog reading TIMEOUT) both go red on the **pristine tree** under load.
Re-run each on its own on a quiet machine; do not edit either gate, and do
not run this node's gates concurrently with
[`09-lsp`](../../09-lsp/prd.md)'s — the two lanes share
`~/.local/share/nvim` through `snapshot_paths`, which is machine-global.

## Verify and Proof

```sh
bash tests/nvim-options.sh
bash tests/nvim-plugin-manager.sh
bash tests/nvim-completion.sh
python3 -c 'import json; d=json.load(open("home/dot_config/nvim/lazy-lock.json")); print(sorted(d))'
git diff --stat home/dot_config/nvim/lazy-lock.json
```
