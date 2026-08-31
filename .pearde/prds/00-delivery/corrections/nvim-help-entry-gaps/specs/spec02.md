---
complexity: 3
footprint:
  - home/dot_config/nushell/help/nvim.nuon
  - home/dot_config/nushell/help/why-review.nuon
verify: "nu tests/help-content-model.nu"
---

# spec02 — fix the telescope entry's `prose` reason (R4)

One clause of one `why` field, plus the review row that clause invalidates.
`kind: "prose"` on the `<Tab> <S-Tab> <CR> (telescope)` entry stays exactly
right — only the *reason given* for it is wrong, and this spec corrects the
reason, not the kind.

## What is wrong, measured independently of the PRD's claim

`nvim.nuon`'s `<Tab> <S-Tab> <CR> (telescope)` entry (currently lines
300–309) carries:

```
why: "`prose` because these live inside telescope's own mapping table rather than in Neovim's keymap list — there is no `lhs` to introspect, even though the keys are real."
```

`"there is no lhs to introspect"` is false. Measured this session, headless,
against this repo's own config (`XDG_CONFIG_HOME` pointed at
`home/dot_config`, **not** the stale `~/.config/nvim` — that tree still runs
the pre-rebuild config, confirmed by `diff`: no `lazy = false` on
`explorer.lua`, no `shift-select` require in `init.lua`, no `autopairs.lua`
at all. Testing against it would have measured the wrong thing):

```lua
vim.cmd("Telescope find_files")
-- after the picker opens:
vim.fn.maparg("<Tab>", "i", false, true)
```

returns a full table, not an empty one:

```
{
  buffer = 1,
  desc = "telescope|toggle_selection + move_selection_worse",
  lhs = "<Tab>",
  lhsraw = "\t",
  mode = "i",
  ...
}
```

`lhs = "<Tab>"` is present, `buffer = 1` says it is a real (buffer-local)
map. The `why`'s own factual claim is refuted by the tool it says cannot
reach the map.

**Why `kind: "prose"` still stands, for a different reason than the one on
record.** `telescope.lua:41-58` sets the three keys inside
`telescope.setup({ defaults = { mappings = { i = maps, n = maps } } })`,
which telescope applies as a buffer-local map on the **prompt buffer it
creates when a picker opens** — not at config-load time, and not on any
buffer that exists before or after that picker closes. So `maparg` can see
the map, but only from inside a live picker on that picker's own buffer;
`nvim --headless` with no picker open, or a probe on any other buffer, finds
nothing. That is a real introspection limit — just not the one the entry
states. `README.md`'s own `verify` table (`kind: prose` row) says `prose`
covers "an entry with no live counterpart… or one with no introspectable
handle" — this is squarely the second case, correctly classified, wrongly
explained.

## The edit

Replace the `why` field (line 306) with a reason naming the actual
constraint — buffer-local existence tied to a live picker, not absence of an
`lhs`. Suggested text, not mandatory verbatim:

```
why: "`prose` because these maps are buffer-local to telescope's own prompt buffer, created only while a picker is open and gone once it closes — `maparg` can see them (a live picker really does return an `lhs`, with `buffer = 1`), but nothing static can, so no `nvim --headless` probe outside a running picker has anything to check against."
```

No other field of the entry changes — not `key`, `title`, `use`, `topic`,
`mode`, `also`, `verify` or `source`.

## The review row

Editing `why` invalidates `why-review.nuon`'s row for this entry (digest keys
on the `use`/`why` pair — `why-review.nuon`'s own header, and confirmed by
`tests/help-content-model.nu`'s `why-digest`). Current row (line 121):

```
{id: "<Tab> <S-Tab> <CR> (telescope)", file: "nvim.nuon", digest: "9631262753acf151", reviewer: "impl-H-1-r7", author: "impl-H-1", date: "2026-08-21", note: "..."}
```

Run `nu tests/help-content-model.nu` after the `nvim.nuon` edit lands — it
reports this row's digest is stale and **prints the value to set**
(`why-digest` of the new `use`/`why` pair). A reader distinct from whoever
wrote the new `why` text reads it against `telescope.lua:41-58` and the
maparg measurement above, then updates `digest`, `reviewer`, `author` and
`note`:

```
{id: "<Tab> <S-Tab> <CR> (telescope)", file: "nvim.nuon", digest: "<paste the gate's reported value>", reviewer: "<second session>", author: "<session that wrote the why>", date: "<today>", note: "<confirm the buffer-local/picker-lifetime reason against telescope.lua:41-58 and a live maparg check, and say the prior 'no lhs' claim was refuted, not merely superseded>"}
```

## Out of scope

- The `use` field of this entry, and every other field.
- Any other entry in `nvim.nuon`.

## Acceptance

- [x] The entry's `why` no longer contains "there is no `lhs` to introspect"
      or an equivalent false claim; `verify` is unchanged, still
      `[{kind: "prose"}]`. Confirmed independently before editing: headless
      against this repo's config, `Telescope find_files` open,
      `vim.fn.maparg("<Tab>", "i", false, true)` returned `lhs = "<Tab>"`,
      `buffer = 1` — the refuted claim reproduced exactly as this spec
      states.
- [x] The `why-review.nuon` row for `<Tab> <S-Tab> <CR> (telescope)` carries
      `digest: "88bce566500afd15"` (the value the gate reported after the
      edit landed), `reviewer: "implementer-nvim-help-entry-gaps-r1"`
      distinct from `author: "implementer-nvim-help-entry-gaps"`, and a
      `note` naming the maparg measurement.
- [x] `nu tests/help-content-model.nu` prints `ok`, exit 0 — confirmed after
      landing the review row.

## Verify and Proof

```sh
cd "$(git rev-parse --show-toplevel)"
nu tests/help-content-model.nu | tail -1        # baseline

open home/dot_config/nushell/help/nvim.nuon | where key == "<Tab> <S-Tab> <CR> (telescope)" | get why.0
nu tests/help-content-model.nu                  # reports stale why-review digest, prints the value to set

open home/dot_config/nushell/help/why-review.nuon | where id == "<Tab> <S-Tab> <CR> (telescope)"
nu tests/help-content-model.nu                  # expect: ok, exit 0
```
