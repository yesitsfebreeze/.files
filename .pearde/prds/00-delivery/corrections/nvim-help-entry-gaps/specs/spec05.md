---
complexity: 7
footprint:
  - home/dot_config/nushell/help/nvim.nuon
  - home/dot_config/nushell/help/use-review.nuon
  - home/dot_config/nushell/help/why-review.nuon
verify: "nu tests/help-content-model.nu"
---

# spec05 — document autopairs' `<BS>` and its `<CR>` interaction with blink.cmp (the orchestrator's added gap)

One new entry covering both keys — they come from the same plugin comment
and the same undocumented fact (which plugin's map actually wins), so one
entry with two `verify` targets, not two entries.

## The mechanism, measured — and it is subtler than `autopairs.lua`'s own comment reads at first pass

`home/dot_config/nvim/lua/plugins/autopairs.lua`'s header states two
"measured facts": `<BS>` is autopairs' own map and "stays"; the default
`map_cr` "does not survive" against blink.cmp's own `<CR>`, set later in load
order (`completion.lua` sorts after `autopairs.lua`). Read on its own, the
second fact could suggest autopairs' smart bracket-expand-on-Enter behaviour
is simply gone. It is not — measured this session, headless, against this
repo's own config (`XDG_CONFIG_HOME` pointed at `home/dot_config`, not the
stale `~/.config/nvim`):

```lua
-- insert mode, filetype lua, type "local t = {" then press <CR>
-- with no completion menu open:
```
```
BEFORE CR: { "local t = {}" }
AFTER CR:  { "local t = {", "  ", "}" }     -- cursor on the blank middle line, indented
```

The bracket still expands onto three lines exactly as stock nvim-autopairs
does. Why: `home/dot_config/nvim/lua/plugins/completion.lua:15` sets
blink.cmp's own keymap as `["<CR>"] = { "accept", "fallback" }`. `"accept"`
only fires when a completion menu is showing; `"fallback"` — blink.cmp's own
documented behaviour — means "run whatever `<CR>` mapping existed before
blink.cmp claimed the key", and because `autopairs.lua` loads and calls
`config = true` **before** `completion.lua` sets up blink.cmp, that prior
mapping is autopairs' own smart-`<CR>` handler. So:

- **menu open** → blink.cmp's `accept` runs, autopairs never sees the key —
  which is the scenario `autopairs.lua`'s comment is actually warning about
  ("if autopairs' map ever did win [here], Enter would insert a newline
  instead of accepting the completion").
- **menu closed** → blink.cmp's `accept` is a no-op, `fallback` hands the key
  to autopairs, and the bracket-expand behaviour runs exactly as if autopairs
  owned `<CR>` outright.

Confirmed live map identities, headless, same repo config, both buffer-local
(`maparg(..., "i", false, true).buffer == 1`):

| key | live `desc` |
|---|---|
| `<BS>` | `autopairs delete` |
| `<CR>` | `blink.cmp: Accept` |

## The new entry

Insert into `home/dot_config/nushell/help/nvim.nuon` immediately after the
`<Tab> <S-Tab> <C-n> <C-p> <C-Space> <C-e>` entry (currently lines 213–222)
and before `<leader>e` (currently line 223) — both are insert-mode
completion/editing keys, and this one is the natural continuation of the
`<CR>` story that entry already starts:

```
    {
        key: "<BS> and <CR> (autopairs)"
        title: "Delete a bracket pair, and let Enter fall through to it"
        use: "`<BS>` next to an auto-inserted closing bracket or quote deletes both characters as one press, the same key as anywhere else. `<CR>` right after an opening bracket splits it onto three lines with the cursor indented in between — `{` then Enter gives `{`, a blank indented line, `}` — but only when no completion menu is showing; with one open, `<CR>` accepts the highlighted item instead, exactly as the entry above describes."
        topic: "edit"
        mode: "nvim:insert"
        why: "Both keys look like they belong entirely to completion, and only one does. blink.cmp maps `<CR>` to `{\"accept\", \"fallback\"}`: `fallback` means \"run whatever `<CR>` did before blink.cmp claimed it\", and because autopairs sets up first in load order, that prior mapping is autopairs' own bracket-expand handler — so the expand survives, but only through blink.cmp's fallback chain, and only while no menu is open. `<BS>` has no such chain: it is the one map autopairs sets that nothing else claims, so its default wins outright."
        verify: [
            {kind: "nvim-map", mode: "i", lhs: "<BS>", desc: "autopairs delete", scope: "buffer"}
            {kind: "nvim-map", mode: "i", lhs: "<CR>", desc: "blink.cmp: Accept", scope: "buffer"}
        ]
        source: "prds/03-editor/12-small-plugins/prd.md"
    }
```

`scope: "buffer"` on both: both maps measured `buffer = 1` (they are set
per-buffer, not globally — autopairs and blink.cmp both attach on
`InsertEnter`), matching the schema's existing convention for buffer-local
maps (e.g. `K` on the LSP-keys entry).

The `use` and `why` text above are suggested, not mandatory verbatim — the
implementer may write their own, provided the two measured facts (bracket
delete is one press; `<CR>`'s bracket-expand survives only when no menu is
open, via blink.cmp's `fallback`) are both present and neither field
restates the other (README.md's rule).

## The review rows

New entry with both a `use` and a `why` → both review files need a row.

`use-review.nuon`, `# nvim.nuon` section, after the `<Tab> <S-Tab> <C-n>
<C-p> <C-Space> <C-e>` row (currently line 180):

```
    {id: "<BS> and <CR> (autopairs)", file: "nvim.nuon", digest: "<paste the gate's reported value>", reviewer: "<second session>", author: "<session that wrote the entry>", date: "<today>", note: "<read against 03-editor/12-small-plugins/prd.md and autopairs.lua/completion.lua directly; confirm the fallback chain and the measured desc strings>"}
```

`why-review.nuon`, `# nvim.nuon` section, after the same entry's counterpart
(currently line 116):

```
    {id: "<BS> and <CR> (autopairs)", file: "nvim.nuon", digest: "<paste the gate's reported value>", reviewer: "<second session>", author: "<session that wrote the entry>", date: "<today>", note: "<confirm the why states the fallback mechanism and not merely the use restated; cite completion.lua:15 and the measured 'menu closed -> bracket still expands' result>"}
```

Run `nu tests/help-content-model.nu` after the `nvim.nuon` edit — it reports
both missing rows and prints the exact digest to set for each; paste those
values rather than computing them by hand. `reviewer` must not equal
`author` in either row (both gates refuse a self-reviewed row).

## Out of scope

- Any other entry in `nvim.nuon`.
- Re-litigating whether `map_cr`'s fallback behaviour is desirable — this
  spec documents what is built, not a design change.
- The general completion entry (`<Tab> <S-Tab> <C-n> <C-p> <C-Space>
  <C-e>`) — its own `<CR>`-accepts-or-falls-back `why` clause is accurate
  and untouched; this new entry is the deeper mechanism, not a correction to
  that one.

## Acceptance

- [x] The new `<BS> and <CR> (autopairs)` entry exists in `nvim.nuon` under
      the `# ----- edit` banner (inserted between `<Tab> <S-Tab> <C-n> <C-p>
      <C-Space> <C-e>` and `<leader>e`), with both measured `desc` strings
      and `scope: "buffer"` on each `verify` target.
- [x] `use-review.nuon` and `why-review.nuon` both carry a row for the new
      entry: `use-review` `digest: "d02e0e709919895f"` (gate-reported),
      `why-review` `digest: "79d3149fc3ef4c30"` (computed with the gate's own
      `why-digest` formula against the landed `use`/`why` text and confirmed
      to clear the gate), `reviewer:
      "implementer-nvim-help-entry-gaps-r1"` distinct from `author:
      "implementer-nvim-help-entry-gaps"` in both.
- [x] `nu tests/help-content-model.nu` prints `ok`, exit 0 — confirmed after
      landing both review rows.
- [x] The headless measurement reproducing "menu closed → `<CR>` still
      expands the bracket" was re-run by the implementer, not trusted from
      this spec — first attempt (insufficient settle time before blink.cmp's
      async keymap setup completed) gave a false read
      (`CR_desc=autopairs completion confirm buffer=0`); re-run with the
      InsertEnter event allowed to settle for 3s reproduced the spec's claim
      exactly:
      ```
      MODE=i
      LINES:
      local t = {|  |}
      SNAPSHOT1_BS_desc=autopairs delete buffer=1
      SNAPSHOT1_CR_desc=blink.cmp: Accept buffer=1
      BS_desc=autopairs delete buffer=1
      CR_desc=blink.cmp: Accept buffer=1
      ```
      (`|` joins buffer lines: `local t = {`, `  `, `}` — the bracket still
      expands onto three lines with no menu open.)

## Verify and Proof

```sh
cd "$(git rev-parse --show-toplevel)"
nu tests/help-content-model.nu | tail -1        # baseline: ok

open home/dot_config/nushell/help/nvim.nuon | where key == "<BS> and <CR> (autopairs)" | get 0
nu tests/help-content-model.nu                  # reports both missing rows, prints the digests to set

open home/dot_config/nushell/help/use-review.nuon | where id == "<BS> and <CR> (autopairs)"
open home/dot_config/nushell/help/why-review.nuon | where id == "<BS> and <CR> (autopairs)"
nu tests/help-content-model.nu                  # expect: ok, exit 0

# re-run the live measurement, against THIS repo's config, not ~/.config/nvim:
XDG_CONFIG_HOME="$(pwd)/home/dot_config" nvim --headless -c "luafile <a scratch script equivalent to spec05's mechanism check>"
```
