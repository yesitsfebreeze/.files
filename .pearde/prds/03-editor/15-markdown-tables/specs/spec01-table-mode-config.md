---
est: 0.5h
footprint:
  - home/dot_config/nvim/lua/plugins/table-mode.lua
  - home/dot_config/nvim/lazy-lock.json
  - tests/nvim-options.sh
  - home/dot_config/nushell/help/nvim.nuon
---

# spec01 — `table-mode.lua`, one lockfile row, the census, one help fix

Port the `vim-table-mode` spec out of `~/.config/nvim/lua/plugins/editor.lua`
into its own file, grow `lazy-lock.json` by one row, insert the new file into
E.1's exact-equality census, and correct the one false sentence the shipped
manual carries about this node. Covers PRD R1–R4.

Everything asserted below was measured on 2026-08-23 against nvim 0.12.4,
lazy.nvim `306a055` and vim-table-mode `bb02530`, in a scratch root with
`HOME` and all four XDG dirs pinned and the plugin clones copied from the
live tree. Nothing here was inferred from reading the plugin.

**Three of the four requirements have a half that no check can fail.** They
are listed here so the implementer writes the file knowing which lines carry
behaviour and which are belt-and-braces; the executable substitutes are in
[spec02](spec02-gate.md).

## The file name

**`lua/plugins/table-mode.lua`.** The epic's [I8](../../prd.md) says "named
for the plugin" while every landed file is named for the concern
(`completion.lua` for blink.cmp, `colorscheme.lua` for tinted-nvim); the
contradiction is filed as
[`i8-naming-wording`](../../../00-delivery/corrections/i8-naming-wording/prd.md),
which this node does not settle. `table-mode` satisfies both readings — it
is the concern, and it is the plugin name minus the `vim-` prefix, as
[`12-small-plugins`](../../12-small-plugins/prd.md)'s settled
`which-key.lua` drops `.nvim`. The hyphen is that file's separator too.
This resolves the three-way collision on `lua/plugins/editor.lua`: E.11
takes `conform.lua`, E.12 takes three files, E.15 takes this one.

## The file

Transcribe the live spec (`~/.config/nvim/lua/plugins/editor.lua:66–87`, 22
lines) in the repo's **2-space** indent style; live is 4-space, so this is a
reindent. Two changes to the live text, both measured, both mandatory:

**1. Hoist the filetype list into one local.** The live file repeats
`{ "markdown", "markdown.mdx" }` in `ft` and again in the autocmd's
`pattern`. One local, used twice:

```lua
local fts = { "markdown", "markdown.mdx" }
```

`ft = fts` and `pattern = fts`. Measured: lazy does not mutate the shared
table — `require("lazy.core.config").plugins["vim-table-mode"].ft` reads
back `{ "markdown", "markdown.mdx" }` and the two registered `FileType`
autocmds carry patterns `markdown,markdown.mdx`; with the local reduced to
`{ "markdown" }` both follow to one entry, and table mode still enables on
markdown.

**This is the line the `markdown.mdx` scope question turns on.** `.mdx` is
dead configuration, measured independently of
[`07-formatting`](../../07-formatting/prd.md)'s Q2 and agreeing with it:
`vim.filetype.match({ filename = "a.mdx" })` returns nil, opening a `.mdx`
file leaves `filetype` empty, `require("lazy.core.config")` reports
`vim-table-mode` **not loaded**, and `b:table_mode_active` is nil. Nothing
registers the extension — `init.lua` registers `.jd` → `markdown` and
nothing else. The question is already with the user on 07-formatting; the
hoist is what makes either answer a **one-line change to the `local fts =`
line** and nothing else. spec02's gate asserts the two lists are equal to
each other, never a literal `markdown.mdx`, so the gate survives either
answer untouched.

**2. Group the autocmd, and correct the comment above the direct call.**
The live `nvim_create_autocmd("FileType", …)` passes no `group` — the
third site of live bug L-8, named in the epic's [I7](../../prd.md). Pass
`group = vim.api.nvim_create_augroup("table_mode_enable", { clear = true })`.
Measured: with the group, re-running the registration leaves the autocmd
count unchanged; without it, two registrations give two callbacks and the
FileType handler fires twice per event.

The comment the live file carries above `enable()` reads "The FileType
event that lazy-loaded us already fired for this buffer." **That is false on
lazy `306a055`, and R4's stated reason with it.** Measured: with the direct
`enable()` deleted, the first markdown file opened as `nvim x.md` still
comes up with `b:table_mode_active = 1`, `updatetime = 500`, the `<Bar>`
insert map installed, and live realignment working. lazy re-fires the event
after loading an `ft`-lazy plugin, and for `FileType` specifically it
re-fires **ungrouped**: `lua/lazy/core/handler/event.lua:107` sets
`exclude = event ~= "FileType" and M.get_augroups(event) or nil`, so
`M.trigger` takes the `opts.exclude == nil` branch and calls
`nvim_exec_autocmds("FileType", { buffer = buf })` with no group filter —
which runs the autocmd `config` registered one moment earlier.

Keep the direct call: R4 names it, it is idempotent (`TableModeEnable` on an
already-active buffer is a no-op), and it is the guard against a lazy
version that re-fires with a group filter. Replace the comment with the
measured truth, in this shape:

```lua
-- Belt and braces. lazy re-fires FileType UNGROUPED after loading an
-- ft-lazy plugin (core/handler/event.lua:107 sets exclude=nil for
-- FileType), so the autocmd above already covers the buffer that
-- triggered the load — measured 2026-08-23 on lazy 306a055, with this
-- line deleted the first markdown file still aligns. Kept against a
-- lazy that re-fires with a group filter.
```

Nothing but the comment changes about that line, and spec02 gates the
comment's presence, because no behaviour can defend it.

### What the file must contain

- `"dhruvasagar/vim-table-mode"` (R1).
- `ft = fts` and `cmd = { "TableModeToggle", "TableModeEnable",
  "TableModeRealign", "Tableize" }` (R1). Exactly those four: measured at
  startup in a non-markdown buffer, `vim.fn.exists()` is `2` for each and
  `0` for `TableModeDisable` and `TableSort`, so the list is the whole
  contract.
- `init = function()` — not `config` — setting `vim.g.table_mode_corner =
  "|"` (R2) and `vim.g.table_mode_map_prefix = "<leader>t"` (R3). `init`
  is load-bearing: `plugin/table-mode.vim:48–58` derives
  `g:table_mode_realign_map` and eight siblings **from the prefix at plugin
  load time**, so a prefix set in `config` would land after the maps were
  already built. Measured: `g:table_mode_realign_map` reads `<leader>tr`.
- `config = function()` with the `enable()` local, the grouped `FileType`
  autocmd over `fts`, and the direct `enable()` call (R4).
- The GFM comment above `table_mode_corner`, and the corrected comment
  above `enable()`.

### R2 and R3 are dead configuration, and the file keeps them anyway

Recorded so nobody restores a check that cannot fail, and so nobody
"cleans up" the two lines without knowing what they do and do not buy.

- **R2, `g:table_mode_corner = "|"`.** The plugin ships
  `ftplugin/markdown_tablemode.vim`, one line: `let b:table_mode_corner =
  '|'`. `tablemode#utils#get_buffer_or_global_option` prefers the buffer
  variable, so **in a markdown buffer the global is shadowed and never
  read**. Measured: with the line deleted, `g:table_mode_corner` falls back
  to the plugin default `+`, `b:table_mode_corner` is still `|`, and the
  border row produced by `tablemode#table#AddBorder` is byte-identical —
  `|----|----|`. The line earns its place only through the `cmd` trigger,
  in a buffer with no table-mode ftplugin: in a `text` buffer after
  `:TableModeEnable`, the same border is `|----|----|` with the line and
  `|----+----|` without it. That `.txt` probe is R2's only discriminator.
- **R3, `g:table_mode_map_prefix = "<leader>t"`.** `plugin/table-mode.vim:31`
  already defaults it to `<Leader>t`. Measured: with the line deleted every
  map is identical — `<leader>tm` → `tablemode#Toggle()`, `<leader>tt` →
  `<Plug>(table-mode-tableize)`, buffer-local `<leader>tr` →
  `<Plug>(table-mode-realign)`, buffer-local `<leader>tdd` →
  `<Plug>(table-mode-delete-row)`. **No deletion counterfactual on this
  line can go red.** Only a value change moves anything: set to
  `<leader>z` and all four move to `<leader>z*`. The line is worth keeping
  as the written contract with which-key's `table` group
  ([`12-small-plugins`](../../12-small-plugins/prd.md) R2) — that group is
  a declaration this node's `<leader>tt` is the first child of — but it
  buys no behaviour.

## `lazy-lock.json` — one row

Append `vim-table-mode` from a real network run: `lazy sync` (or `lazy
install`) in a scratch XDG root, then copy the row it writes. The live
lockfile already holds the pin this repo's clone is at:

```
  "vim-table-mode": { "branch": "master", "commit": "bb025308a45c67c7c8f0763ba37bc2ee3f534df0" },
```

**`master`, not `main`** — checked, not assumed (`git rev-parse
--abbrev-ref HEAD` in the live clone). It sorts last of the twelve keys, so
this is the [11-colorscheme](../../11-colorscheme/prd.md) two-line diff in
its simplest form: a comma appended to the `tinted-nvim` row and one new
last row. **Keep lazy's one-line-per-plugin shape** — `json.dump(indent=2)`
splits every row and silently defuses `tests/nvim-completion.sh`'s
line-scoped truncated-commit selftest. No existing commit value moves.

## `tests/nvim-options.sh` — the census

Line 231 holds E.1's exact-equality file census as one hardcoded string.
**Read it from disk; do not transcribe it from here.** It has grown on
every plugin node today and another may land while this one is in flight.
Insert `./lua/plugins/table-mode.lua` in `LC_ALL=C sort` position, which is
between `./lua/plugins/lsp.lua` and `./lua/plugins/telescope.lua`
(verified). One string edit, nothing else in that file.

## `home/dot_config/nushell/help/nvim.nuon` — one false sentence

The corpus already carries this node's entry (`key: "<leader>t"`, `source:
"prds/03-editor/15-markdown-tables/prd.md"`). Its `use:` field is true —
every map it names was measured present: `<leader>tt`, `<leader>tm`,
`<leader>tr`, and buffer-local `[|` `]|` `{|` `}|` →
`<Plug>(table-mode-motion-left/right/up/down)`.

Its `why:` field is the false R4 reason, shipped:

> The plugin is also enabled once directly at load, not only from its
> FileType autocmd: the event that lazy-loaded it has already fired for the
> buffer that triggered it, so the first markdown file you open would
> otherwise be the one file without alignment.

Replace it with what the FileType autocmd actually buys, which is every
markdown buffer **after** the first:

> Table mode is switched on by a FileType autocmd, not by the plugin
> itself: `vim-table-mode` ships inactive and needs `TableModeEnable` per
> buffer. Without the autocmd only the file you opened nvim with would
> align, and every markdown buffer you `:edit` afterwards would not.

One field on one entry. Do not touch its `key`, `title`, `topic`, `mode`,
`also`, `verify` or `source`; `tests/help-content-model.nu` reads all of
them. **06-help/01-content-model is `done` and owns this file** — the edit
is in this spec's footprint so the orchestrator does not dispatch a lane
over it.

## Acceptance

- [x] `home/dot_config/nvim/lua/plugins/table-mode.lua` exists, 2-space
      indented, and holds `local fts = { … }` used by **both** `ft` and the
      autocmd `pattern` — no second literal filetype list in the file.
- [x] The autocmd passes `group = nvim_create_augroup("table_mode_enable",
      { clear = true })`, and the file's only `nvim_create_autocmd` call is
      that one.
- [x] The comment above the direct `enable()` call states the measured
      lazy re-fire, not the false "already fired for this buffer" reason,
      and names `core/handler/event.lua`.
- [x] `lazy-lock.json` holds `vim-table-mode` with `"branch": "master"` and
      a 40-hex commit, on **one** line, and `diff` against the previous
      version is exactly two changed lines.
- [x] `bash tests/nvim-options.sh --tree` exits 0 with the census
      including `./lua/plugins/table-mode.lua` — quote the census line.
- [ ] `nu tests/help-content-model.nu` exits 0 after the `why:` rewrite,
      and the entry's other fields are byte-identical — quote a `git diff`
      showing one changed field.
- [x] `/usr/bin/grep -rn 'vim-table-mode\|table_mode\|Tableize'
      home/dot_config/nvim/lua/` returned **0** before the file landed —
      run it first and quote the count, so nothing below can pass on
      pre-existing text.

## Verify and Proof

```sh
bash tests/nvim-options.sh --tree
nu tests/help-content-model.nu
python3 -c 'import json;d=json.load(open("home/dot_config/nvim/lazy-lock.json"));print(d["vim-table-mode"])'
git diff -- home/dot_config/nvim/lazy-lock.json home/dot_config/nushell/help/nvim.nuon
bash tests/nvim-markdown-tables.sh
```
