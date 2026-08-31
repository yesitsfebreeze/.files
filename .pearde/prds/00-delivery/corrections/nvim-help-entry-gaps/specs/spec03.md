---
complexity: 3
footprint:
  - home/dot_config/nushell/help/nvim.nuon
  - home/dot_config/nushell/help/why-review.nuon
verify: "nu tests/help-content-model.nu"
---

# spec03 — bring `<leader>e`'s `why` in line with the landed explorer (R5)

`03-editor/06-explorer` (E.10) shipped `lazy = false` for oil.nvim; the
`<leader>e` entry's `why` still describes the pre-fix, lazy-on-keys shape.
One field, plus the review row it invalidates.

## What is wrong, measured against this repo's own source (not the stale `~/.config/nvim`)

`nvim.nuon`'s `<leader>e` entry (currently lines 223–232) carries:

```
why: "Open it with the key, not with `:e some/dir`. The plugin is lazy on that key, so its file-explorer hijack is not installed until the first time you press it — and netrw is disabled, so before that press `:e` on a directory reaches neither one."
```

`home/dot_config/nvim/lua/plugins/explorer.lua` (as it stands in this repo,
**not** the deployed `~/.config/nvim`, which still lacks `lazy = false`
entirely — confirmed by `diff`, and it is the reason a naive headless test
against the live host would have reproduced the *old*, wrong claim) sets:

```lua
return {
  "stevearc/oil.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  lazy = false,
  ...
}
```

`03-editor/06-explorer/prd.md`'s own Implementation record already flags this
exact staleness (its "Two corrections to file" section, filed against S.5 and
never landed): *"Measured under the landed shape: `:e some/dir` opens oil
(`filetype = oil`, buffer `oil://…`) with no key pressed."*

Reproduced independently this session, headless, `XDG_CONFIG_HOME` pointed at
`home/dot_config` so lazy.nvim loads *this repo's* plugin specs against the
already-installed plugin cache:

```lua
vim.cmd("edit " .. vim.fn.getcwd())
-- immediately after, no key pressed:
vim.bo.filetype   --> "oil"
vim.api.nvim_buf_get_name(0)  --> "oil:///Users/feb/dev/dotfiles/"
```

So `:e some/dir` reaches oil **before** `<leader>e` is ever pressed — the
opposite of what the entry currently says.

## The edit

Replace the `why` field (line 229). Suggested text, not mandatory verbatim —
it must say oil is eager and the hijack is installed at startup, not on
first press:

```
why: "`<leader>e` is the fast path, not the only one: oil loads eagerly (`lazy = false`) so its `default_file_explorer` hijack is installed at startup, and `:e some/dir` reaches it with no key pressed. Netrw is disabled either way, so nothing else could claim the directory instead."
```

No other field of the entry changes — `key`, `title`, `use`, `topic`, `mode`,
`verify` and `source` stay as they are.

## The review row

Editing `why` invalidates the `why-review.nuon` row for `<leader>e` (line
117, currently no `note`, `digest: "6567f2685c326f64"` against the *old*
pair). Run `nu tests/help-content-model.nu` after the `nvim.nuon` edit — it
reports the stale digest and prints the value to set. A reader distinct from
whoever wrote the new `why` reads it against `explorer.lua` and the measured
`:e <dir>` result above, then updates the row:

```
{id: "<leader>e", file: "nvim.nuon", digest: "<paste the gate's reported value>", reviewer: "<second session>", author: "<session that wrote the why>", date: "<today>", note: "<confirm lazy=false at explorer.lua and the headless :e <dir> -> filetype=oil measurement, and say what the prior text got backwards>"}
```

## Out of scope

- The `use` field and every other field of this entry.
- `03-editor/06-explorer/prd.md` itself — it already carries the correct,
  measured record in its Implementation record; this spec only catches up
  the manual to it. Nothing here reopens that PRD.
- Any other entry in `nvim.nuon`.

## Acceptance

- [x] The entry's `why` no longer says oil is "lazy on that key" or that
      `:e some/dir` "reaches neither one" before a key is pressed; it says
      oil loads eagerly and the hijack is live at startup. Confirmed
      `lazy = false` at `explorer.lua:38`, and independently re-ran the
      headless measurement: `:e <cwd>` with no key pressed against this
      repo's config gives `filetype=oil`,
      `bufname=oil:///Users/feb/dev/dotfiles/`.
- [x] The `why-review.nuon` row for `<leader>e` carries
      `digest: "3d35cc67da8009d6"` (the value the gate reported after the
      edit landed), `reviewer: "implementer-nvim-help-entry-gaps-r1"`
      distinct from `author: "implementer-nvim-help-entry-gaps"`.
- [x] `nu tests/help-content-model.nu` prints `ok`, exit 0 — confirmed after
      landing the review row.

## Verify and Proof

```sh
cd "$(git rev-parse --show-toplevel)"
nu tests/help-content-model.nu | tail -1        # baseline

open home/dot_config/nushell/help/nvim.nuon | where key == "<leader>e" | get why.0
nu tests/help-content-model.nu                  # reports stale why-review digest, prints the value to set

open home/dot_config/nushell/help/why-review.nuon | where id == "<leader>e"
nu tests/help-content-model.nu                  # expect: ok, exit 0
```
