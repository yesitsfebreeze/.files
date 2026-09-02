---
state: done
priority: 9
est:
mode: afk
claim: 
complexity: 21
blast-radius: low
commit: 7db0342
needs:
  - 03-editor/03-autocmds
  - 03-editor/06-explorer
  - 03-editor/08-telescope
  - 03-editor/09-lsp
  - 06-help/02-help-command
verify: ""
origin: derived
from: 03-editor/03-autocmds
---

# The editor's utility-buffer `q` has no manual entry

Parent: [Corrections backlog](../prd.md) · net-new

Purpose: E.4's analyst found (2026-08-23) that
`home/dot_config/nushell/help/nvim.nuon` carries **no entry** for the
`close_with_q` binding — the `q` that closes help, quickfix, `lspinfo`,
`startuptime` and the other utility buffers. It is a keybinding a user
presses, so [`AGENTS.md`(../../../../../AGENTS.md)'s rule applies literally:
"If you add a keybinding or command, add its manual entry in the same
change — otherwise `help --check` reports it as undocumented."

Why it was not added in the same change, and why that was right: the corpus
lives under `home/dot_config/nushell/`, which is the shell lane's footprint,
and `tests/help-content-model.nu` requires every entry to carry a
`use-review.nuon` row whose reviewer is **not** its author. An implementer
writing its own entry cannot satisfy that, so E.4 correctly reported the gap
instead of reaching across the lane. The `05-completion` precedent is the
same. This node is where it lands.

## Requirements
- [x] **R1** — `nvim.nuon` carries an entry for the utility-buffer `q`,
      naming the filetypes it closes, sourced at
      [`03-editor/03-autocmds`](../../../03-editor/03-autocmds/prd.md). The
      filetype list is read from what E.4 actually landed in
      `home/dot_config/nvim/lua/config/autocmds.lua`, not from this PRD.
      Landed: spec01, `nu tests/help-content-model.nu` -> `ok`.
- [x] **R2** — The entry's `use-review.nuon` row is digested by the gate's
      own helper, with a reader-reviewer distinct from the author, per the
      corpus's review ritual — the same shape as
      [`cdi-manual-source`](../cdi-manual-source/prd.md) R2.
      Landed: spec01, digest `b27fb92d6a81d7cf` as reported by the gate.
- [x] **R3** — **Census the rest of the editor's bindings while here, and
      report rather than fix.** This node exists because one binding was
      missed; the question worth answering is how many others are. Compare
      every keymap E.2, E.4 and E.14 land against `nvim.nuon`'s entries and
      list the gaps. Any gap outside this node's one entry is a reported
      finding and its own correction — widening here would hide how large
      the drift is.
      Landed: spec01's census table, quoted verbatim in the DONE report. One
      other gap found (shift-select.lua's four visual-mode arrow-key
      collapse maps have no `verify` target, only prose) — reported, not
      fixed, per Out of scope.

- [x] **R4** — The telescope entry's stated reason is corrected. E.9's
      analyst measured (2026-08-23) that
      `<Tab> <S-Tab> <CR> (telescope)` justifies its
      `verify: [{kind: "prose"}]` with *"there is no `lhs` to introspect"* —
      which is false: inside a live picker,
      `maparg("<Tab>", "i", false, true)` returns a table with
      `buffer = 1`. **`prose` remains the right kind** — the maps are
      buffer-local and exist only while a picker is open, so no static
      introspection can reach them — so this is a one-clause reason fix, not
      a change of kind. Everything else in that entry and its four siblings
      matched measured reality exactly, including the "best match sits at
      the bottom, `<Tab>` walks up the screen" claim (row 249 → 248).
      Folded in here rather than filed separately: same file, same lane,
      same review ritual, and one sentence does not earn its own node.

- [x] **R5** — The `<leader>e` entry's `why` is brought in line with what
      E.10 lands. E.10's analyst measured (2026-08-23) that it still
      describes the pre-correction shape — "the plugin is lazy on that key,
      so its file-explorer hijack is not installed until the first time you
      press it — and netrw is disabled, so before that press `:e` on a
      directory reaches neither one." E.10 removes exactly that shape (oil
      loads eagerly, `lazy = false`), so the `why` documents a behaviour the
      rebuild does not have. No gate catches it:
      `tests/help-content-model.nu:200` checks key presence only.
      Landed: spec03, `lazy = false` confirmed at `explorer.lua:38`, headless
      `:e <cwd>` measurement re-run and confirmed `filetype=oil`.
- [x] **R6** — The `Neovim's own LSP keys` entry stops claiming the eight
      core maps carry no `desc`. E.7's implementer measured that they do
      (`vim.lsp.buf.rename()`, `Jump to the next diagnostic in the current
      buffer`, and so on), while the entry marks all eight `desc: null` with
      the note "carries no `desc` on purpose". An explicit `null` means
      existence-only, so this never goes red — it is inaccurate prose rather
      than a drift failure, which is exactly why it needs a node to catch
      it.
      Landed: spec04, all eight `desc` strings independently re-measured
      against `$VIMRUNTIME` and matched.

## Acceptance
- [x] `nu tests/help-content-model.nu` passes with the new entry and its
      review row, output quoted:
      ```
      help content model: 96 entries across 4 files, 9 topics, 16 prose-only
      ...
      ok
      ```
- [x] The census in R3 is in the report as a table: every editor keymap in
      the deployed config, and whether `nvim.nuon` documents it. See spec01's
      census table, quoted verbatim in the DONE report.
- [ ] Once [`06-help/04-drift-check`](../../../06-help/04-drift-check/prd.md)
      exists, `help --check` reports the utility-buffer `q` as documented.
      Until then, say so rather than ticking this against a check that does
      not run yet. `06-help/04-drift-check` is still `state: open` as of this
      implementation — left unticked per this box's own instruction.
      *(b) — genuinely unmet: `06-help/04-drift-check` is still `state:
      open`, so `help --check` cannot report the utility-buffer `q`. The box
      itself instructs leaving it unticked until then.*

## Out of scope
- Fixing any other gap the R3 census finds. Report them; each is its own
  node with its own review row.
- The four absent `desc` fields on the LSP entries, which are already
  [`help-nvim-lsp-descs`](../help-nvim-lsp-descs/prd.md).

## Added 2026-08-24 by the orchestrator — one more gap, from E.12's implementer

`nvim-autopairs`' **`<BS>`** (autopairs delete) and its **`<CR>`** interaction
with blink.cmp have no manual entry, and both are keys a user presses. Found
while landing [`12-small-plugins`](../../../03-editor/12-small-plugins/prd.md),
reported rather than filed as its own node because it is the same lane problem
this node already owns: the corpus needs a reader who is not the author, and
one more entry does not need one more PRD.
