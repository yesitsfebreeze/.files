---
complexity: 2
footprint:
  - home/dot_config/nushell/help/nvim.nuon
verify: "nu tests/help-content-model.nu"
---

# spec04 — give the eight "Neovim's own LSP keys" targets their real `desc` (R6)

A `verify`-block-only edit. `use` and `why` are untouched, so — unlike
spec02 and spec03 — this one touches no review file.

## What is wrong, measured

`nvim.nuon`'s `Neovim's own LSP keys` entry (currently lines 339–358) marks
all eight `nvim-map` targets `desc: null`, which per the schema means "the
live map carries no `desc` on purpose — existence only, never a mismatch"
(`README.md` "Two nuances"). Measured against Neovim 0.12.4's own runtime
(`vim.fn.maparg`, `--clean` for the five that are global, an attached LSP
client for `K`, which is buffer-scoped — matching the entry's existing
`scope: "buffer"` on that one row only):

| key | live `desc` |
|---|---|
| `K` | `vim.lsp.buf.hover()` |
| `grn` | `vim.lsp.buf.rename()` |
| `gra` | `vim.lsp.buf.code_action()` |
| `grr` | `vim.lsp.buf.references()` |
| `gri` | `vim.lsp.buf.implementation()` |
| `gO` | `vim.lsp.buf.document_symbol()` |
| `]d` | `Jump to the next diagnostic in the current buffer` |
| `[d` | `Jump to the previous diagnostic in the current buffer` |

Source: `$VIMRUNTIME/lua/vim/_core/defaults.lua:206-277` (the six
`vim.lsp.buf.*` maps and the two diagnostic-jump maps) and
`$VIMRUNTIME/lua/vim/lsp.lua:865-874` (the `LspAttach`-scoped `K` map,
`{ desc = 'vim.lsp.buf.hover()' }`, only set when `keywordprg` is empty and no
existing `K` map exists — which is why it alone carries `scope: "buffer"`
already, and why `K` returned nothing under `nvim --clean` with no client
attached: it is not a global map, exactly as `README.md`'s own "One more
measured detail" paragraph already says). None of this depends on which
`lsp.lua` (repo vs. deployed) is in play — these eight are Neovim core, not
this config's own maps; `home/dot_config/nvim/lua/plugins/lsp.lua:74-88`
confirms the repo's own `LspAttach` autocmd adds only `gd`, `gI`,
`<leader>rn`, `<leader>ca` and re-maps none of the eight.

So `desc: null` was never accurate here: these eight are not the
"carries-no-desc-on-purpose" case the schema's `null` exists for (that shape
is real elsewhere — the centred-jump maps, the visual-indent maps — where the
live keymap genuinely passes no `desc`). Because `null` means
existence-only, this never surfaces as a drift-check mismatch once
`06-help/04-drift-check` exists; it is inaccurate prose that a check cannot
catch, which is exactly why R6 exists as its own line.

## The edit

Replace the eight `verify` targets (lines 347–356) — `mode`, `lhs` and
`scope` (where present) are unchanged, only `desc` moves from `null` to the
measured string:

```
    verify: [
        {kind: "nvim-map", mode: "n", lhs: "K", desc: "vim.lsp.buf.hover()", scope: "buffer"}
        {kind: "nvim-map", mode: "n", lhs: "grn", desc: "vim.lsp.buf.rename()"}
        {kind: "nvim-map", mode: "n", lhs: "gra", desc: "vim.lsp.buf.code_action()"}
        {kind: "nvim-map", mode: "n", lhs: "grr", desc: "vim.lsp.buf.references()"}
        {kind: "nvim-map", mode: "n", lhs: "gri", desc: "vim.lsp.buf.implementation()"}
        {kind: "nvim-map", mode: "n", lhs: "gO", desc: "vim.lsp.buf.document_symbol()"}
        {kind: "nvim-map", mode: "n", lhs: "]d", desc: "Jump to the next diagnostic in the current buffer"}
        {kind: "nvim-map", mode: "n", lhs: "[d", desc: "Jump to the previous diagnostic in the current buffer"}
    ]
```

`title`, `use`, `topic`, `mode`, `also`, `why` and `source` are all
byte-identical — this edit is scoped to the `verify` block alone.

## Why no review-row edit — the deviation to report, not silently absorb

Both `use-review.nuon`'s digest (`use`/`source`) and `why-review.nuon`'s
digest (`use`/`why`) are defined in `tests/help-content-model.nu` (`use-digest`
at line 414, `why-digest` at line 382) as hashes over those field pairs only.
Neither takes `verify` as input. This edit touches only `verify`, so neither
digest changes and the gate will not ask for a new row — the same reasoning
`help-nvim-lsp-descs/specs/spec01.md` already used for its own four `desc`
additions on `gd`/`gI`/`<leader>rn`/`<leader>ca`. Writing a "re-digest" here
that reproduces the value already on record would be theatre, not a review,
and this corpus's own rule against unmeasured claims argues against
performing it.

The existing `why-review.nuon` row for this entry (line 123,
`digest: "8a795c015b386192"`) stays untouched. Its `note` already describes
the `]d`/`[d`/`<C-w>d` correction from an earlier session and says nothing
about `desc`, so nothing in it is made stale by this edit.

## Out of scope

- Any field of this entry other than the eight `verify` targets' `desc`.
- Any other entry in `nvim.nuon`.
- Re-digesting either review file for this entry — see above.

## Acceptance

- [x] All eight `nvim-map` targets on `Neovim's own LSP keys` carry the
      measured `desc` string in place of `null`; `mode`, `lhs` and `K`'s
      `scope: "buffer"` unchanged. Independently re-measured against
      `$VIMRUNTIME/lua/vim/_core/defaults.lua` (`nvim --clean --headless`,
      Neovim 0.12.4) for the six global maps — `grn -> vim.lsp.buf.rename()`,
      `gra -> vim.lsp.buf.code_action()`, `grr -> vim.lsp.buf.references()`,
      `gri -> vim.lsp.buf.implementation()`, `gO ->
      vim.lsp.buf.document_symbol()`, `]d -> Jump to the next diagnostic in
      the current buffer`, `[d -> Jump to the previous diagnostic in the
      current buffer` — and grepped `$VIMRUNTIME/lua/vim/lsp.lua:873` for
      `K`'s `desc = 'vim.lsp.buf.hover()'`. All eight match this spec's
      table exactly.
- [x] `git diff -U0 home/dot_config/nushell/help/nvim.nuon` shows only the
      eight target lines changed within this spec's own edit (the file's
      full diff also carries spec01/02/03's separate, earlier hunks, landed
      first in this same session).
- [x] `nu tests/help-content-model.nu` prints `ok`, exit 0, with the same
      digests on record for this entry's `use-review.nuon` and
      `why-review.nuon` rows before and after — quoted:
      before: `use-review` `23e653c26ae6a046`, `why-review`
      `8a795c015b386192`; after: `use-review` `23e653c26ae6a046`,
      `why-review` `8a795c015b386192` — unchanged, proving R6's claim that
      `verify` does not enter either digest.

## Verify and Proof

```sh
cd "$(git rev-parse --show-toplevel)"
nu tests/help-content-model.nu | tail -1        # baseline: ok

open home/dot_config/nushell/help/use-review.nuon | where id == "Neovim's own LSP keys" | get digest.0    # before
open home/dot_config/nushell/help/why-review.nuon | where id == "Neovim's own LSP keys" | get digest.0    # before

open home/dot_config/nushell/help/nvim.nuon | where key == "Neovim's own LSP keys" | get verify.0

nu tests/help-content-model.nu                  # expect: ok, exit 0, no new/stale-row complaint

open home/dot_config/nushell/help/use-review.nuon | where id == "Neovim's own LSP keys" | get digest.0    # after — same as before
open home/dot_config/nushell/help/why-review.nuon | where id == "Neovim's own LSP keys" | get digest.0    # after — same as before
```
