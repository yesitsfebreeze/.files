---
complexity: 6
footprint:
  - home/dot_config/nushell/help/nvim.nuon
  - home/dot_config/nushell/help/use-review.nuon
verify: "nu tests/help-content-model.nu"
---

# spec01 — document the utility-buffer `q` (R1, R2), and close R3's census

Adds the one entry `nvim.nuon` is missing for a real, undocumented keybinding
(`q` in a utility buffer), records the required second reading in
`use-review.nuon`, and carries the R3 census this node exists to produce —
every keymap `03-editor/02-keymaps` (E.2), `03-editor/03-autocmds` (E.4) and
`03-editor/14-shift-select` (E.14) land, checked against `nvim.nuon`'s
entries.

## R3 — the census (read this before writing the entry; it is what justifies there being exactly one)

Method: every `vim.keymap.set` / `map(...)` call site in
`home/dot_config/nvim/lua/config/keymaps.lua` (E.2),
`home/dot_config/nvim/lua/config/autocmds.lua` (E.4) and
`home/dot_config/nvim/lua/config/shift-select.lua` (E.14), matched against
every `nvim-map` verify target in `nvim.nuon` as it stands before this spec's
edit.

| Source file | mode/lhs | documented in `nvim.nuon`? |
|---|---|---|
| keymaps.lua | n `<C-h>` `<C-j>` `<C-k>` `<C-l>` | yes — `<C-h> <C-j> <C-k> <C-l>` |
| keymaps.lua | n `<C-Up>` `<C-Down>` `<C-Left>` `<C-Right>` | yes — `<C-Up> <C-Down> <C-Left> <C-Right>` |
| keymaps.lua | n `<leader>|` `<leader>-` | yes — `<leader>| and <leader>-` |
| keymaps.lua | n `<S-h>` `<S-l>` `<leader>bd` | yes — `<S-h> <S-l> <leader>bd` |
| keymaps.lua | n/v `<A-j>` `<A-k>` | yes — `<A-j> <A-k>` |
| keymaps.lua | n `<C-d>` `<C-u>` `n` `N` (no desc) | yes — `<C-d> <C-u> n N` (`desc: null`) |
| keymaps.lua | v `<` `>` (no desc) | yes — `< and > (visual)` (`desc: null`) |
| keymaps.lua | n `<leader>w` `<leader>q` | yes — `<leader>w and <leader>q` |
| keymaps.lua | x `<leader>p` | yes — `<leader>p (visual)` |
| keymaps.lua | `<C-q>` deliberately **unbound** (R9's comment) | not a keymap — nothing to document |
| autocmds.lua | `TextYankPost`/`BufReadPost`/`BufWritePre` autocmds | not keymaps — no key is pressed |
| **autocmds.lua** | **n `q`, buffer-local, filetypes `help` `qf` `man` `lspinfo` `checkhealth` `startuptime`** | **NO — the gap this node fixes** |
| shift-select.lua | n `<S-Up>` `<S-Down>` `<S-Left>` `<S-Right>` | yes — `<S-Up> <S-Down> <S-Left> <S-Right>` |
| shift-select.lua | v `<S-Up>` `<S-Down>` `<S-Left>` `<S-Right>` | yes — same entry, visual rows |
| shift-select.lua | i `<S-Up>` `<S-Down>` `<S-Left>` `<S-Right>` | yes — same entry, insert rows |
| shift-select.lua | v `h` `j` `k` `l` | yes — `h j k l (visual)` |
| shift-select.lua | **v `<Up>` `<Down>` `<Left>` `<Right>`** | **partially — the entry's `use` says "or an unshifted arrow", but its `verify` list carries only the four letter keys, not these four arrow rows** |
| shift-select.lua | v `<C-c>` | yes — `<C-c> (visual)` |
| shift-select.lua | v `<C-v>` | yes — `<C-v> (visual)` |

**Two findings.** One is this node's own gap (`q`), fixed below. The other —
`shift-select.lua`'s four visual-mode arrow-key collapse maps
(`<Up>`/`<Down>`/`<Left>`/`<Right>`, lines 122–125) have no `verify` target of
their own, only a passing prose mention — is **reported, not fixed here**: R3
and the PRD's Out of scope both say a gap found outside the one entry this
node owns is a finding for its own correction, not a widening of this one.
Quote this table's row verbatim when filing it; don't re-derive it.

No other gap turned up in E.2/E.4/E.14 against `nvim.nuon`.

## R1 — the new entry

Insert into `home/dot_config/nushell/help/nvim.nuon` immediately after the
`<Esc>` entry (currently lines 20–29) and before `<C-h> <C-j> <C-k> <C-l>`
(currently line 30) — both are bare utility keys outside any plugin, which is
where this one belongs too:

```
    {
        key: "q"
        title: "Close a utility buffer"
        use: "Press `q` in a help, quickfix, man, lspinfo, checkhealth or startuptime buffer to close it — one key across all six. The buffer is also marked unlisted the moment it opens, so it never turns up under `<S-h>`/`<S-l>` or `:bnext` either."
        topic: "edit"
        mode: "nvim:normal"
        verify: [{kind: "nvim-map", mode: "n", lhs: "q", desc: null, scope: "buffer"}]
        source: "prds/03-editor/03-autocmds/prd.md"
    }
```

Filetype list and mechanism, read from
`home/dot_config/nvim/lua/config/autocmds.lua:71-78` (the `close_with_q`
augroup), not from this PRD's framing:

```lua
autocmd("FileType", {
  group = augroup("close_with_q", { clear = true }),
  pattern = { "help", "qf", "man", "lspinfo", "checkhealth", "startuptime" },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = event.buf, silent = true })
  end,
})
```

`desc: null` is deliberate, not an omission this spec is forgetting: the
`vim.keymap.set` call above passes no `desc` at all, so the live map genuinely
carries none — the same shape the schema already uses for the centred-jump and
visual-indent maps (`README.md` "Two nuances"). Writing `desc` absent instead
of `null` would make the (unbuilt) drift check compare the live map's empty
desc against this entry's title and report a permanent, unfixable mismatch.

No `why` field: R1 asks only that the entry name the filetypes, and the
mechanism (`buflisted = false` keeping the buffer out of `:bnext`) is already
folded into the `use` as an observable effect rather than a hidden reason, so
there is nothing here that a `why` would say without restating the `use` — the
corpus's own rule against that (README.md "Writing an entry"). Adding one
would also open a `why-review.nuon` obligation this node's R2 does not ask
for. If a future reader judges a `why` is warranted, that is its own edit with
its own review row, not silently absorbed here.

Placement, topic and mode follow the file's existing convention: `topic:
"edit"` is what every general (non-`find`, non-LSP) `nvim.nuon` entry under
the `# ----- edit` banner carries, and `mode: "nvim:normal"` because `q` is
pressed from normal mode inside the target buffer.

## R2 — the review row

Add one row to `home/dot_config/nushell/help/use-review.nuon`, in the `#
nvim.nuon` section (currently lines 164–191), in the same key order as the
corpus file. Run `nu tests/help-content-model.nu` after landing R1's edit —
it reports the missing row and **prints the exact digest to set**
(`use-digest` of the entry's `use` and `source`); copy that value rather than
computing one by hand.

```
    {id: "q", file: "nvim.nuon", digest: "<paste the gate's reported value>", reviewer: "<second session, not the one that wrote R1>", author: "<the session that wrote R1's use text>", date: "<today>", note: "<what was read: the use against 03-autocmds/prd.md and against home/dot_config/nvim/lua/config/autocmds.lua:71-78 directly, confirming the six filetypes and the buflisted side effect>"}
```

`reviewer` must not equal `author` — the gate refuses a row where they match
(same shape as `cdi-manual-source` R2 and every other author/reviewer pair in
this file). If one session writes both the entry and this row, a second
session reads the `use` against the source PRD and the live route
(`autocmds.lua:71-78`) before the row is written, and it is that second
session's id that goes in `reviewer`.

No `why-review.nuon` row: the new entry carries no `why` (see R1 above), and
that file only requires a row for entries that carry one.

## Out of scope

- The visual-mode arrow-key verify gap this spec's own census found — report
  it, do not fix it here.
- Any entry this spec does not name.

## Acceptance

- [x] The new `q` entry exists in `nvim.nuon` exactly as drafted above,
      placed under the `# ----- edit` banner, immediately after `<Esc>` and
      before `<C-h> <C-j> <C-k> <C-l>`.
- [x] `home/dot_config/nushell/help/use-review.nuon` carries a `q`/`nvim.nuon`
      row: `digest: "b27fb92d6a81d7cf"` (the value `nu
      tests/help-content-model.nu` itself reported as missing), `reviewer:
      "implementer-nvim-help-entry-gaps-r1"` distinct from `author:
      "implementer-nvim-help-entry-gaps"`.
- [x] `nu tests/help-content-model.nu` prints `ok`, exit 0 — quoted:
      ```
      help content model: 95 entries across 4 files, 9 topics, 16 prose-only
      ...
      ok
      ```
- [x] The R3 census table above is quoted verbatim in the DONE report — this
      closes the PRD's "census … in the report as a table" acceptance line.
      Nothing in it is fixed beyond the `q` entry; the arrow-key finding is
      reported, not corrected, per this PRD's Out of scope.

## Verify and Proof

```sh
cd "$(git rev-parse --show-toplevel)"
nu tests/help-content-model.nu | tail -1        # baseline: should already say ok

# after the nvim.nuon edit
open home/dot_config/nushell/help/nvim.nuon | where key == "q" | get 0
nu tests/help-content-model.nu                  # reports the missing use-review row and the digest to set

# after the use-review.nuon edit
open home/dot_config/nushell/help/use-review.nuon | where id == "q"
nu tests/help-content-model.nu                  # expect: ok, exit 0
```
