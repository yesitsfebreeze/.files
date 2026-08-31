# spec01 — `lua/config/keymaps.lua` + the init.lua seam

Delivers R1–R9 as one new file plus one inserted line. Create
`home/dot_config/nvim/lua/config/keymaps.lua` holding the general map set
— the live `~/.config/nvim/lua/config/keymaps.lua` lines 1–46, minus the
`<Esc>` map (R1) and minus everything below them (the shift-select block
is E.14's) — and insert its require into `init.lua` at the seam E.1 left.
Every `desc` string is contract: `help/nvim.nuon` already fixes it.

**Est:** 0.5h

**Footprint:** `home/dot_config/nvim/lua/config/keymaps.lua` (create),
`home/dot_config/nvim/init.lua` (one inserted require — SHARED SEAM:
`03-autocmds` E.4, same wave, inserts here too; the orchestrator
serializes E.3/E.4 on this file)

Amended 2026-08-23 (implementer, on the orchestrator's instruction): the
footprint was one file short. `tests/nvim-options.sh` (E.1's gate) asserts
an EXACT `find | LC_ALL=C sort` census of `home/dot_config/nvim/`, so any
node that lands a new file there must add its own entry or leave that gate
red. This node adds `./lua/config/keymaps.lua` between
`./lua/config/autocmds.lua` and `./lua/config/lazy.lua`, and nothing else
in that file. It is the house rule, not a special case: `15-markdown-tables`
added `./lua/plugins/table-mode.lua` and `07-formatting`
`./lua/plugins/conform.lua` the same way.

## The init.lua seam

Insert `require("config.keymaps")` below `require("config.options")` and
ABOVE `require("config.lazy")` — epic I1's order is options → keymaps →
autocmds → lazy, and the seam comment in `init.lua` already says wave-3
nodes insert above the lazy line. Leave the seam comment standing: E.4
still inserts after this. Touch nothing else in the file.

## The maps — exact, matching live and the manual

`local map = vim.keymap.set` at the top, then, with the file's header
comment carried from live ("General keymaps. Plugin-specific maps live in
their plugin specs (keys = ...)" — epic I5):

| mode | lhs | rhs | desc |
|---|---|---|---|
| n | `<C-h>` | `<C-w>h` | Go to left window |
| n | `<C-j>` | `<C-w>j` | Go to lower window |
| n | `<C-k>` | `<C-w>k` | Go to upper window |
| n | `<C-l>` | `<C-w>l` | Go to right window |
| n | `<C-Up>` | `<cmd>resize +2<CR>` | Increase height |
| n | `<C-Down>` | `<cmd>resize -2<CR>` | Decrease height |
| n | `<C-Left>` | `<cmd>vertical resize -2<CR>` | Decrease width |
| n | `<C-Right>` | `<cmd>vertical resize +2<CR>` | Increase width |
| n | `<leader>\|` | `<cmd>vsplit<CR>` | Split right |
| n | `<leader>-` | `<cmd>split<CR>` | Split below |
| n | `<S-h>` | `<cmd>bprevious<CR>` | Previous buffer |
| n | `<S-l>` | `<cmd>bnext<CR>` | Next buffer |
| n | `<leader>bd` | `<cmd>bdelete<CR>` | Delete buffer |
| n | `<A-j>` | `<cmd>m .+1<CR>==` | Move line down |
| n | `<A-k>` | `<cmd>m .-2<CR>==` | Move line up |
| v | `<A-j>` | `:m '>+1<CR>gv=gv` | Move selection down |
| v | `<A-k>` | `:m '<-2<CR>gv=gv` | Move selection up |
| n | `<C-d>` | `<C-d>zz` | *(none)* |
| n | `<C-u>` | `<C-u>zz` | *(none)* |
| n | `n` | `nzzzv` | *(none)* |
| n | `N` | `Nzzzv` | *(none)* |
| v | `<` | `<gv` | *(none)* |
| v | `>` | `>gv` | *(none)* |
| n | `<leader>w` | `<cmd>write<CR>` | Save |
| n | `<leader>q` | `<cmd>quit<CR>` | Quit |
| x | `<leader>p` | `"_dP` | Paste (keep register) |

Modes verbatim: `v` for the four visual maps above, `x` for `<leader>p` —
that is the live file and the manual's verify targets. Every desc is the
exact string in `nvim.nuon`'s `nvim-map` targets; the six no-desc maps
are `desc: null` there, meaning the drift check asserts existence only —
adding a desc to one contradicts the manual's "no desc on purpose".

Two comments are load-bearing and go in the file:

1. On the centered-jump group, the live comment plus its reason: these
   carry no desc because which-key should not list a key whose behavior
   is the vim default plus a re-centre (`nvim.nuon` records the same).
   Do not "simplify" the `zz` away as redundant under `scrolloff=999`:
   scrolloff never scrolls past the end of the buffer, `zz` does, so the
   append is what keeps the last half-screen centered — and `zv` in
   `nzzzv` opens the fold a match lands in.
2. R9, written where a later agent would break it: `<C-q>` is left
   unbound on purpose. It is the blockwise-visual synonym and the escape
   hatch that makes E.14's visual `<C-v>` shadow (live bug L-9, ported
   as decided) acceptable. No node in the epic may map it.

## Hands off

- **No `<Esc>` map** (R1). `hlsearch=false` (E.1 R6) makes it inert;
  the L-6 decision dropped it. Note for the report, not for this
  footprint: `nvim.nuon`'s `<Esc>` entry documents the non-ported
  binding but carries a `nvim-map` verify target, which will not
  resolve against the rebuilt config — a correction candidate for the
  backlog; help files sit in the S.5 lane and are not touchable here.
- **No shift-select machinery.** The live file's `shift_select` flag,
  `feed` helper, `ModeChanged` autocmd, `<S-arrow>` maps, visual
  `h/j/k/l` collapse maps, and visual `<C-c>`/`<C-v>` all belong to
  [`14-shift-select`](../../14-shift-select/prd.md) (E.14, deps on this
  node). The live `ModeChanged` autocmd is also ungrouped — live bug
  L-8 — and must not be reproduced here in any form: this file contains
  zero autocmds.
- **No plugin references** (PRD acceptance): no `require(`, no plugin
  name, nothing lazy-loaded. which-key descriptions come free from
  `desc`.
- No help entry changes: every `nvim.nuon` target this node's maps must
  satisfy already exists; nothing is added or edited there.

## Acceptance

- [x] `home/dot_config/nvim/lua/config/keymaps.lua` exists and holds
      exactly the 26 maps above — no `<Esc>`, no `<C-q>`, no
      `<S-Up/Down/Left/Right>`, no visual `<C-c>`/`<C-v>`, no
      `nvim_create_autocmd`, no `require(`.
  - Ran 2026-08-23, `bash tests/nvim-keymaps.sh --tree`:
    `PASS  tree: exactly 26 map( call sites — spec01's table, no more and
    no less`, plus `PASS tree: R1 no nohlsearch anywhere`, `PASS tree: R1
    no <Esc> map`, `PASS tree: no shift-select machinery`, `PASS tree: zero
    autocmds`, `PASS tree: no require(`, `PASS tree: no map call on <C-q>,
    <C-c> or <C-v>`. spec01's own verify agrees:
    `grep -cE 'nvim_create_autocmd|shift_select|<S-Up>|<C-c>|nohlsearch'` →
    `0`.
- [x] `init.lua` requires, in order: `config.options`, `config.keymaps`,
      `config.lazy` — keymaps inserted, not appended.
  - `grep -n require home/dot_config/nvim/init.lua` → lines 8, 16, 18, 20:
    `config.options`, `config.keymaps`, `config.autocmds`, `config.lazy`.
    Gate: `PASS tree: the required modules run options -> keymaps -> lazy
    (I1)` and `PASS tree: config.keymaps is INSERTED above config.lazy, not
    appended`. E.4's `config.autocmds` had already landed at the seam, so
    the require went in ABOVE it, exactly where the seam comment says.
- [x] Both load-bearing comments are present (the no-desc reason with the
      scrolloff/past-end distinction; the `<C-q>` stays-unbound R9 note).
  - `PASS  tree: the no-desc/re-centre comment is present, with the
    past-the-end distinction` · `PASS  tree: the R9 <C-q>-stays-unbound
    note is present`. Both checks are controlled: deleting either line
    turns its own check red in the selftests.
- [x] `bash tests/nvim-keymaps.sh` (spec02) exits 0.
  - 108 PASS, 0 FAIL, `exit=0`, ending
    `PASS — all 26 keymaps are in the file, read back as specced, fire as
    specced, and <C-q> stays unbound`.

Checked by hand, not gated (it would give the desc contract two owners and
couple this gate to a file the S.5 lane is editing): all 26 rows match
`help/nvim.nuon`'s `nvim-map` targets exactly — same mode, same lhs, same
`desc`, and `desc: null` on exactly the six desc-less maps
(`<C-d>`, `<C-u>`, `n`, `N`, visual `<`, visual `>`).

## Verify

```sh
cd /Users/feb/dev/dotfiles
bash tests/nvim-keymaps.sh
/usr/bin/grep -n 'require' home/dot_config/nvim/init.lua
/usr/bin/grep -cE 'nvim_create_autocmd|shift_select|<S-Up>|<C-c>|nohlsearch' \
  home/dot_config/nvim/lua/config/keymaps.lua   # expect 0
```
