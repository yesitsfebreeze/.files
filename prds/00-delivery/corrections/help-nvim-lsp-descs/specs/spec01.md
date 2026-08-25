---
footprint:
  - home/dot_config/nushell/help/nvim.nuon
  - home/dot_config/nushell/help/use-review.nuon
verify: "nu tests/help-content-model.nu"
---

# spec01 — add the four missing `desc` fields and record the second reading

One behavioral edit (`nvim.nuon`) plus one record edit (`use-review.nuon`),
and they land together because the second is how the first gets a reader
distinct from its writer, per the corpus's review ritual
(`home/dot_config/nushell/help/README.md` "Writing an entry" and
`use-review.nuon`'s own header).

## The live values, verified against the actual keymap file, not the PRD's text

`home/dot_config/nvim/lua/plugins/lsp.lua:80-87` is where these four maps are
set, inside the `LspAttach` autocmd:

```lua
local function bmap(keys, fn, desc)
  vim.keymap.set("n", keys, fn, { buffer = event.buf, desc = "LSP: " .. desc })
end
bmap("gd", vim.lsp.buf.definition, "Goto definition")
bmap("gI", vim.lsp.buf.implementation, "Goto implementation")
bmap("<leader>rn", vim.lsp.buf.rename, "Rename")
bmap("<leader>ca", vim.lsp.buf.code_action, "Code action")
```

So the live `desc` strings are `LSP: Goto definition`, `LSP: Goto
implementation`, `LSP: Rename`, `LSP: Code action` — which happen to match
the PRD's R1 text exactly. They are not taken from the PRD on trust: this is
an independent read of `lsp.lua`, done because R1 says the PRD's list may be
stale and the live code wins if it disagrees. It does not disagree here.

Corroborating record: `use-review.nuon:189-190` already carries notes
written by `impl-H-1-r2` on 2026-08-21 naming the same four strings against
the same two line numbers (`lsp.lua:30-31` and `:32-33` under an older line
count — the maps are now at `:83-86`, inside the `bmap` calls above rather
than bare `vim.keymap.set` calls, but the four `desc` values are unchanged).
Two independent reads, one PRD text, all four strings agree.

## Edit 1 — `home/dot_config/nushell/help/nvim.nuon`

Two entries, four `verify` targets, add `desc` to each — no other field of
either entry changes, and no other entry in the file changes (R2):

```
     {kind: "nvim-map", mode: "n", lhs: "gd", scope: "buffer"}
     {kind: "nvim-map", mode: "n", lhs: "gI", scope: "buffer"}
```
becomes
```
     {kind: "nvim-map", mode: "n", lhs: "gd", desc: "LSP: Goto definition", scope: "buffer"}
     {kind: "nvim-map", mode: "n", lhs: "gI", desc: "LSP: Goto implementation", scope: "buffer"}
```

and
```
     {kind: "nvim-map", mode: "n", lhs: "<leader>rn", scope: "buffer"}
     {kind: "nvim-map", mode: "n", lhs: "<leader>ca", scope: "buffer"}
```
becomes
```
     {kind: "nvim-map", mode: "n", lhs: "<leader>rn", desc: "LSP: Rename", scope: "buffer"}
     {kind: "nvim-map", mode: "n", lhs: "<leader>ca", desc: "LSP: Code action", scope: "buffer"}
```

Field order follows the file's existing convention (`kind`, `mode`, `lhs`,
`desc`, `scope`) — see the `<C-h> <C-j> <C-k> <C-l>` entry's targets for the
same ordering with a `desc` present. `title`, `use`, `why`, `also`, `source`
and every other field of both entries stay byte-identical.

## Edit 2 — `home/dot_config/nushell/help/use-review.nuon`, and a correction
to what this PRD's R3 asks for

**R3's premise does not hold, and this is the spec's one deviation from the
PRD text — reported, not silently absorbed.** R3 says "Adding a field
changes the entries' review digests, so the matching `use-review.nuon` rows
are re-digested by the gate's own digest helper" and models this on
`cdi-manual-source` R2. That PRD's edit changed the `cdi` entry's `source`
field, and `use-review.nuon`'s digest is defined at
`tests/help-content-model.nu:414` as:

```nu
def use-digest [use: string, source: string] {
    $"($use)\n--\n($source)" | hash sha256 | str substring 0..15
}
```

— a hash of `use` and `source` **only**. It has no input from `verify`, so
no input from a target's `desc`. This spec's edit 1 touches neither `use`
nor `source` on either entry (R2 forbids it), so the digest the gate computes
for both rows is unchanged, and the gate will not ask for a new one — unlike
`cdi-manual-source`, where changing `source` mechanically invalidated the
recorded digest. `home/dot_config/nushell/help/README.md`'s own "Two
nuances" section says the same thing directly: `desc` is a `verify`-target
field, and `use-review.nuon` reviews `use` against `source` and the live
route, a different clause entirely from what a `verify` target asserts.

So there is no digest to recompute here, and the implementer must not invent
one — a "re-digest" that reproduces the value already on record is not a
review, it is theatre, and this corpus's own rule against unmeasured claims
("a check written from the answer passes on the answer") argues against
performing an empty ritual and writing it up as if it caught something.

What **is** real and worth doing, in the same spirit as R3's ask for a
second reader: the two rows' `note` fields describe the *old* state of the
entries — `id: "gd and gI"`'s note says "the verify target omits `desc`,
which per the file header means compare against the title, but live sets
`LSP: Goto definition` / `LSP: Goto implementation` … — a drift-check false
failure waiting for 04-drift-check, not a `use` defect", and `id: "<leader>rn
and <leader>ca"`'s note says the same. Both are now stale as descriptions of
the live file: the omission the note describes no longer exists once edit 1
lands. A reader distinct from the implementer (the same "reviewer $\neq$
author" shape R3 and `cdi-manual-source` both use) reads edit 1 against
`lsp.lua`, confirms the four `desc` values are correct, and updates each
row's `note` to say so and to name this PRD as where the fix landed. `digest`,
`id`, `file`, `reviewer` (unless the same person is available and it stays
put) and `date` are touched only as needed to keep the row honest; `digest`
specifically is **not** rewritten, because rewriting it to the same value it
already holds would misrepresent a no-op as a check.

Suggested `note` text (the reader may write their own, as long as it reads
the live file rather than restating this spec):

```
note: "verify targets now carry desc, added by
00-delivery/corrections/help-nvim-lsp-descs. Confirmed against
lua/plugins/lsp.lua:83-86 (LspAttach bmap calls): gd -> \"LSP: Goto
definition\", gI -> \"LSP: Goto implementation\". The prior note's
description of an absent desc no longer matches the file; digest is
unchanged because use/source were not touched by this fix."
```

(and the equivalent for `<leader>rn and <leader>ca`, naming `LSP: Rename` /
`LSP: Code action`.)

## Out of scope

- Any other entry in `nvim.nuon`, and any entry's `title`.
- Any other row in `use-review.nuon`.
- `why-review.nuon` — neither entry carries a `why`.
- Building or invoking `06-help/04-drift-check` (`help --check`) — it is
  `state: open` (task H.4) and does not exist yet, confirmed by `help.nu`'s
  `help` command frontmatter, which defines `--all --mode --entry --topic
  --delegate --fuzzy --json --md` and no `--check`. The Acceptance box below
  uses the gate that does exist.

## Acceptance

- [x] Both `gd and gI` verify targets now carry `desc: "LSP: Goto
      definition"` and `desc: "LSP: Goto implementation"` respectively,
      `scope: "buffer"` unchanged, no other field added — landed at
      `home/dot_config/nushell/help/nvim.nuon:321-322`.
- [x] Same for `<leader>rn and <leader>ca`: `desc: "LSP: Rename"` and
      `desc: "LSP: Code action"` — landed at
      `home/dot_config/nushell/help/nvim.nuon:334-335`.
- [x] `git diff -U0 home/dot_config/nushell/help/nvim.nuon` shows only the
      four target lines changed, one `-`/`+` pair each, quoted:
      ```
      @@ -321,2 +321,2 @@
      -            {kind: "nvim-map", mode: "n", lhs: "gd", scope: "buffer"}
      -            {kind: "nvim-map", mode: "n", lhs: "gI", scope: "buffer"}
      +            {kind: "nvim-map", mode: "n", lhs: "gd", desc: "LSP: Goto definition", scope: "buffer"}
      +            {kind: "nvim-map", mode: "n", lhs: "gI", desc: "LSP: Goto implementation", scope: "buffer"}
      @@ -334,2 +334,2 @@
      -            {kind: "nvim-map", mode: "n", lhs: "<leader>rn", scope: "buffer"}
      -            {kind: "nvim-map", mode: "n", lhs: "<leader>ca", scope: "buffer"}
      +            {kind: "nvim-map", mode: "n", lhs: "<leader>rn", desc: "LSP: Rename", scope: "buffer"}
      +            {kind: "nvim-map", mode: "n", lhs: "<leader>ca", desc: "LSP: Code action", scope: "buffer"}
      ```
- [x] `nu tests/help-content-model.nu` prints `ok`, exit 0 — 94 entries
      across 4 files, 9 topics; both rows' recorded digests (`d0e0edc7a74aa65b`,
      `c0df9bb17a7735fc`) unchanged, confirming R3's finding that `desc`
      does not enter the digest.
- [x] The two `use-review.nuon` rows' `note` fields updated by a second
      reader (`orchestrator-help-nvim-lsp-descs-r2`, distinct from the
      `nvim.nuon` edit), no longer describing the entries as missing `desc`;
      `digest` left untouched on both, per the spec's own reasoning against
      recomputing a value that did not change.

## Verify and Proof

```sh
cd "$(git rev-parse --show-toplevel)"

# baseline
nu tests/help-content-model.nu | tail -1        # expect: ok

# after edit 1
open home/dot_config/nushell/help/nvim.nuon | where key == "gd and gI" | get verify.0
open home/dot_config/nushell/help/nvim.nuon | where key == "<leader>rn and <leader>ca" | get verify.0
git diff -U0 home/dot_config/nushell/help/nvim.nuon

# gate still passes — and specifically does NOT ask for a re-digest on
# either row, because use/source are untouched
nu tests/help-content-model.nu                  # expect: ok, exit 0

# after edit 2 (note-only, digest unchanged)
open home/dot_config/nushell/help/use-review.nuon | where id == "gd and gI"
open home/dot_config/nushell/help/use-review.nuon | where id == "<leader>rn and <leader>ca"
nu tests/help-content-model.nu                  # expect: ok, exit 0
```
