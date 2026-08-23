---
est: 0.75h
footprint:
  - home/dot_config/nvim/lua/plugins/telescope.lua
  - home/dot_config/nvim/lazy-lock.json
  - tests/nvim-options.sh
---

# spec01 — telescope.lua, three lockfile rows, and the census insert

Port `~/.config/nvim/lua/plugins/telescope.lua` into the repo, grow
`lazy-lock.json` by `telescope.nvim`, `plenary.nvim` and
`telescope-fzf-native.nvim` from a real network run, and insert the new file
into the one hardcoded census string in `tests/nvim-options.sh`. Covers PRD
R1–R5.

Everything asserted below was measured on 2026-08-23 against nvim 0.12.4 in
a seeded scratch `HOME`/XDG root — the live file was not merely read.

## The plugin file

**`lua/plugins/telescope.lua`** — transcribe
`~/.config/nvim/lua/plugins/telescope.lua` (read it; 53 lines) into the
repo's **2-space** indent style. The live file is 4-space; reindent it, and
keep every grep in spec02's gate indentation-independent for that reason.
The live file already satisfies R1–R5 exactly:

- `"nvim-telescope/telescope.nvim"`, `cmd = "Telescope"`;
- `dependencies = { "nvim-lua/plenary.nvim", { "nvim-telescope/`
  `telescope-fzf-native.nvim", build = "make" } }`;
- the five `keys` rows, verbatim, descs included — `<leader>ff` and
  `<leader><space>` → `<cmd>Telescope find_files<CR>` / `Find files`,
  `<leader>fg` → `Live grep`, `<leader>fb` → `Buffers`, `<leader>fh` →
  `Help tags`;
- the `multi_or_select` local: `#picker:get_multi_selection() > 0` →
  `actions.send_selected_to_qflist` + `actions.open_qflist`, else
  `actions.select_default`;
- the shared `maps` table with `["<CR>"] = multi_or_select`,
  `["<Tab>"] = actions.toggle_selection + actions.move_selection_worse`,
  `["<S-Tab>"] = actions.toggle_selection + actions.move_selection_better`;
- `telescope.setup({ defaults = { mappings = { i = maps, n = maps } } })`;
- `pcall(telescope.load_extension, "fzf")`.

Keep all three live comments (the header, the multiselect note, the
shared-table note). No `vim.keymap.set` — the keys live in `keys = …`
(epic I5); no `nvim_create_autocmd` — the file registers none (I7). The
live file has neither; keep it that way.

**Add two comments the live file lacks.** Both record facts measured for
this node, and AGENTS.md's "preserve the hard-won why" makes them part of
the port rather than decoration. spec02's gate asserts both, so they cannot
be dropped later:

1. On the `pcall(telescope.load_extension, "fzf")` line — why the `pcall`.
   Measured: with `build/libfzf.so` absent, `load_extension("fzf")` raises
   (`dlopen … no such file`); **unwrapped it aborts the whole `config`
   function** and lazy reports `Failed to run \`config\` for
   telescope.nvim`. The finder still works either way (`setup()` has
   already run by that line, so the mappings are in place), so the `pcall`
   buys a **clean startup**, not a working finder — say exactly that, or
   the next reader will delete it after seeing the finder survive.
2. Above the `<Tab>` / `<S-Tab>` rows — that they **restate telescope's own
   defaults** (`telescope.nvim/lua/telescope/mappings.lua:167` for `i` and
   `:201` for `n` bind the identical `toggle_selection + move_selection_*`
   pair), and are kept explicit deliberately so an upstream default change
   cannot silently move our marks. Measured: deleting both rows leaves the
   mark→quickfix flow byte-for-byte identical, so no behavioural check can
   ever defend them.

## `lazy-lock.json` — three rows, grown from a real run

E.2's policy (R2): rows come from a real install, never by hand. Flow,
measured end to end:

1. Stage `home/dot_config/nvim/` (with the new `telescope.lua`) into a
   fresh scratch root, no seed, with the **repo lockfile's current rows
   only** — the three new keys absent — and launch
   `nvim --headless +qa`. lazy bootstraps, installs the three plugins, runs
   `build = "make"` and rewrites the scratch lockfile. Measured: 4 s wall
   clock, and `build/libfzf.so` (34840 bytes, arm64) present afterwards.
2. **Merge three rows, do not copy the file.** Take only the
   `plenary.nvim`, `telescope.nvim` and `telescope-fzf-native.nvim` rows
   from the scratch lockfile; leave every existing row byte-identical.
   Measured: the fresh install moved `lazy.nvim` from the repo pin
   `306a0552…` to stable HEAD `85c7ff37…`, so a wholesale copy would
   silently retarget E.2's pin as a side effect of this node.
3. **Keep lazy's one-line-per-plugin format.** Each row is exactly
   `  "<name>": { "branch": "<b>", "commit": "<40hex>" },`. Measured trap:
   rewriting the file with `json.dump(…, indent=2)` splits every row across
   four lines, and `tests/nvim-completion.sh`'s truncated-commit **selftest
   silently stops mutating anything** — its `sed` is line-scoped on the
   `blink.cmp` line — so the selftest goes red and E.6's gate fails on a
   pure formatting change. Merge textually, or write the rows back in
   lazy's shape.
4. Do **not** transcribe the rows from `~/.config/nvim/lazy-lock.json`.
   Measured: the live pin for `telescope.nvim` is `427b576c…`, and a fresh
   resolve today lands on `40aedd8a…` (2026-08-17, `fix(finders): yield
   once per await_count entries in oneshot replay loop`) — upstream master
   has moved past the live pin. `plenary.nvim` (`74b06c6c…`) and
   `telescope-fzf-native.nvim` (`b25b749b…`) happened to match; that is
   luck, not a rule. Whatever the run resolves is the row.

`tests/nvim-plugin-manager.sh` needs **no edit**: its seed helper and its
`--network` restore comparison are both already driven by the lockfile's
key list, so all three keys enter both automatically. Verified — both
stages green on the widened lockfile with that file untouched.

## `tests/nvim-options.sh` — the census insert

One hardcoded string, the `--tree` census equality. **Read the line in the
file as it stands; do not transcribe a fixed list from this spec.**
[`09-lsp`](../../09-lsp/prd.md) is claimed right now and is editing the
same string; whichever node lands second must insert into what it finds, or
it drops the other's row. Insert `./lua/plugins/telescope.lua` at its
`LC_ALL=C` position — last among the `lua/plugins/` entries, after
`./lua/plugins/lsp.lua`. Leave the label wording alone; it belongs to the
lane that last touched it.

The seed helper in that file is already lockfile-driven, so nothing else
there changes.

## The manual entry — read-only check

`home/dot_config/nushell/help/nvim.nuon` already carries all five entries
for this node (`<leader>ff and <leader><space>`, `<leader>fg`,
`<leader>fb`, `<leader>fh`, and `<Tab> <S-Tab> <CR> (telescope)`), each
with `source: "prds/03-editor/08-telescope/prd.md"`. Every `nvim-map`
target matches measured reality: the descs read back `Find files`,
`Find files`, `Live grep`, `Buffers`, `Help tags` **before** telescope
loads, because lazy registers the `keys` stubs with their descs at startup.
This node owes no help edit. Confirm the entries still match; a mismatch is
a correction to file, never an edit — the S.5 lane holds
`home/dot_config/nushell/`.

## Acceptance

- [x] `home/dot_config/nvim/lua/plugins/telescope.lua` exists, is 2-space
      indented, carries every value R1–R5 names, both added comments, and
      no `vim.keymap.set` / `nvim_create_autocmd` (spec02's `--tree` stage
      is the check; run the greps inline until it exists).

      72 lines. `bash tests/nvim-telescope.sh --tree` closes all of it,
      including two checks written for this box: `tree: 2-space indent, no
      tabs — the live 4-space file was reindented` (an anchored match on
      `^  "nvim-telescope/telescope.nvim",$` plus a no-tabs sweep, with a
      selftest that reindents a copy to 4 spaces and goes red — a width
      check would not do, a 4-space ladder being just as even as a 2-space
      one), `tree: the pcall comment carries the clean-startup reason` and
      `tree: the <Tab> comment names telescope's own mappings.lua
      defaults`. Inline confirmation of the ladder: leading-indent widths
      are 0, 2, 4, 6, 8 and no line holds a tab.
- [x] `home/dot_config/nvim/lazy-lock.json` parses, holds
      `plenary.nvim`, `telescope.nvim` and `telescope-fzf-native.nvim` with
      40-hex commits, every pre-existing row byte-identical, and lazy's
      one-line-per-plugin format intact.

      The whole diff is three added lines and nothing else — no existing
      row moved, no separator comma touched, because the three rows sort
      before `tinted-nvim` and the last row keeps its comma-free shape:

      ```
      +  "plenary.nvim": { "branch": "master", "commit": "74b06c6c…" },
      +  "telescope-fzf-native.nvim": { "branch": "main", "commit": "b25b749b…" },
      +  "telescope.nvim": { "branch": "master", "commit": "40aedd8a…" },
      ```

      `python3 -c 'json.load(...)'` reads 10 keys. The `lazy.nvim` pin is
      still E.2's `306a0552…`, not the `85c7ff37…` the generation run
      resolved.
- [x] The generation root proves the rows came from a run: quote the
      scratch lockfile's three rows and
      `ls -l <root>/data/nvim/lazy/telescope-fzf-native.nvim/build/`
      showing `libfzf.so`.

      Staged with the repo lockfile's seven rows only, `nvim --headless
      +qa`, 3.8 s wall clock. The scratch lockfile grew exactly the three
      rows above, and:

      ```
      -rwxr-xr-x  1 feb  wheel  34840 Aug 23 14:47 libfzf.so
      … Mach-O 64-bit dynamically linked shared library arm64
      ```

      The same run moved `lazy.nvim` to `85c7ff37…` in the scratch file,
      which is why the merge was three rows and not a copy.
- [x] `bash tests/nvim-options.sh` exits 0 with the census grown by
      `./lua/plugins/telescope.lua` and no other census entry lost.

      Exit 0. `PASS  tree: home/dot_config/nvim/ holds exactly the post-E.5
      census … (got: ./init.lua ./lazy-lock.json ./lua/config/lazy.lua
      ./lua/config/options.lua ./lua/plugins/colorscheme.lua
      ./lua/plugins/completion.lua ./lua/plugins/init.lua
      ./lua/plugins/lsp.lua ./lua/plugins/telescope.lua)` — inserted at its
      `LC_ALL=C` position, after `lsp.lua`, into the string as found.
- [x] `bash tests/nvim-plugin-manager.sh --tree` and `--headless` exit 0
      with that file untouched (`git diff --stat` names it nowhere).

      Both stages exit 0. The untouched half was read with `git diff
      --name-only -- tests/nvim-plugin-manager.sh`, which is empty:
      `--stat` is unusable in this tree, since it reports every other
      lane's staged work, so the same question was asked scoped to the one
      file.
- [x] `bash tests/nvim-plugin-manager.sh --network` exits 0 and its restore
      loop prints nine commit equalities, three of them the new keys.

      Exit 0, and **ten** equalities rather than nine — the lockfile holds
      10 keys now, not 9, because E.10's mason rows landed after this spec
      was written. Three of them are the new keys, each `want` = `got`:
      `plenary.nvim` `74b06c6c…`, `telescope-fzf-native.nvim` `b25b749b…`,
      `telescope.nvim` `40aedd8a…`. The count in this box is stale; the
      substance it asks for is proven.
- [x] `bash tests/nvim-completion.sh` exits 0 — in particular the
      truncated-commit selftest, which the lockfile format decides.

      74 PASS, 0 FAIL, exit 0, including `PASS  selftest: a lockfile copy
      with a truncated blink.cmp commit goes red` — the line-scoped `sed`
      still mutates, so the one-line-per-plugin shape survived the merge.
      Neither documented flake reproduced on this run.
- [x] `assert_unchanged` green in every gate run — no write to real
      `~/.config/nvim`, `~/.local/share/nvim`, `~/.local/state/nvim`,
      `~/.cache/nvim`.

      Green in every run quoted here: `nvim-telescope.sh` (both stages and
      the no-arg run), `nvim-options.sh`, `nvim-plugin-manager.sh` (all
      three stages), `nvim-completion.sh`, `nvim-colorscheme.sh`,
      `nvim-lsp.sh`.

**Flake warning, measured 2026-08-23 — do not chase these.** Two sibling
gates go red on the **pristine tree** when the machine is loaded, and both
were reproduced on the unmodified repo with no telescope change present:

- `tests/nvim-completion.sh` — 17 FAILs, starting at `R3: blink's async
  keymap setup registered its InsertEnter autocmd`, and sometimes
  `changed: /Users/feb/.local/share/nvim` from `assert_unchanged`. Blink's
  async keymap setup does not register inside its 10 s wait under load.
- `tests/nvim-plugin-manager.sh --headless` — `clone failure: exit 1
  within the watchdog, no hang (got: TIMEOUT)`, twice over.

Both are load and concurrency, not this node. Re-run each on its own on a
quiet machine; do **not** edit either gate, and do not run this node's
gates concurrently with [`09-lsp`](../../09-lsp/prd.md)'s — the two lanes
share `~/.local/share/nvim` through `snapshot_paths`, which is
machine-global and reddens from a neighbour's mason install.

## Verify and Proof

```sh
bash tests/nvim-options.sh
bash tests/nvim-plugin-manager.sh
bash tests/nvim-completion.sh
python3 -c 'import json; d=json.load(open("home/dot_config/nvim/lazy-lock.json")); print(sorted(d))'
/usr/bin/grep -n 'commit' home/dot_config/nvim/lazy-lock.json | head -20
```
