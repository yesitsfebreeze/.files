---
complexity: 12
footprint:
  - prds/03-editor/prd.md
executor: orchestrator   # I8 is another PRD's body; per this PRD's own
                         # scoping note the orchestrator makes this edit
---

# spec01 — I8 restated for the concern, and every filename checked against it

Rewrite `prds/03-editor/prd.md`'s **I8** bullet so it states the convention
actually in force — one file per plugin, **named for the concern it
delivers**, because a concern name survives replacing the plugin behind it —
then check every landed and named-but-unbuilt filename against the new
wording. This is one unit: the census is what proves the rewrite is true
before it is written, and the edit is a wording change only — no box in
`03-editor/prd.md` changes state, no plugin file is renamed.

`prds/03-editor/prd.md` is another PRD's body, so **the orchestrator makes
this edit**, per this PRD's own R1 (the epic invariant text is squarely this
PRD's contract, not a normal cross-PRD write). No other file changes.

## R1 — the exact edit

Current I8, `prds/03-editor/prd.md` (quote is the anchor, not the line
number — the tree has moved once already this session):

```
- [ ] **I8** — **One file per plugin under `lua/plugins/`.** Each plugin
      spec lives in a file named for the plugin; there is no catch-all.
```

Replace the second sentence only. Everything from "there is no catch-all"
through the end of the bullet (the `lua/plugins/editor.lua` history, the
three colliding nodes, the `parallelization` cross-link) is **unchanged** —
R1 of this PRD says that history is correct and stays, and it is the reason
the invariant exists at all.

```
- [ ] **I8** — **One file per plugin under `lua/plugins/`.** Each plugin
      spec lives in a file named for the **concern it delivers**, not the
      plugin itself — a concern name survives replacing the plugin behind
      it. There is no catch-all.
```

Net change: one clause. No link added or removed (the bullet's four
markdown links — `07-formatting`, `12-small-plugins`, `15-markdown-tables`,
`parallelization` — are untouched), so `gates/tree-links.sh` Tier A cannot
move.

## R2 — census of every landed `lua/plugins/*.lua`, against the new wording

Run against `home/dot_config/nvim/lua/plugins/` as it stood 2026-08-25.
`init.lua` is lazy.nvim's bootstrap, not a plugin spec, and is excluded.
Twelve plugin-spec files, all twelve checked:

| file | plugin(s) | verdict |
|---|---|---|
| `completion.lua` | blink.cmp | agrees — concern word, differs from plugin base `blink` |
| `colorscheme.lua` | tinted-nvim | agrees — concern word, differs from plugin base `tinted-nvim` |
| `lsp.lua` | nvim-lspconfig + mason-lspconfig.nvim | agrees — concern word; **no single plugin name could satisfy the old wording at all**, since two plugins share the file |
| `statusline.lua` | lualine.nvim | agrees — concern word, differs from plugin base `lualine`; not in the PRD's original four-row table, additional confirming case |
| `explorer.lua` | oil.nvim | agrees — concern word, differs from plugin base `oil`; also not in the original table, additional confirming case |
| `table-mode.lua` | vim-table-mode | agrees — concern ("table mode") and plugin base (vendor prefix `vim-` stripped) coincide, both readings agree |
| `telescope.lua` | telescope.nvim + plenary.nvim | agrees — concern and plugin base coincide, both readings agree (as the PRD's own table already notes) |
| `treesitter.lua` | nvim-treesitter | agrees — concern and plugin base (`nvim-` stripped) coincide |
| `gitsigns.lua` | gitsigns.nvim | agrees — concern ("git signs") and plugin base coincide |
| `which-key.lua` | which-key.nvim | agrees — concern and plugin base coincide |
| `autopairs.lua` | nvim-autopairs | agrees — concern and plugin base (`nvim-` stripped) coincide |
| `conform.lua` | conform.nvim | agrees, but the one ambiguous case — **not a genuine mismatch, reported rather than silently folded in.** Unlike the other eleven, `conform` is not a distinct concern word (the concern is "formatting" / "format on save"); it is the plugin's own brand name, which happens to also read as the English verb for the concern. `07-formatting` R6 already reasoned through this exact ambiguity when it fixed the same file-naming omission for this node — "conform.lua satisfies both readings" — and named the file before this correction existed. Report this as the one file where the two readings coincide by the plugin author's word choice rather than by a distinct concern name, not as a violation calling for a rename (out of scope per this PRD). |

Verdict: **zero genuine mismatches.** Eleven of twelve are clean concern
names (six of those eleven happen to share a spelling with the plugin's own
base name once its vendor prefix is stripped, which is not a mismatch — the
convention is "named for the concern", and a concern can share a plugin's
name). The twelfth (`conform.lua`) is a bordering case already litigated and
closed by `07-formatting` R6; report it, do not reopen it, do not rename it.

## R3 — the three named-but-thought-unbuilt nodes

`prds/00-delivery/corrections/i8-naming-wording/prd.md` R3 names
`12-small-plugins`, `13-statusline` and `15-markdown-tables` as "unbuilt
editor nodes that will create files". **Measured 2026-08-25: all three are
`state: done`, not unbuilt.** Report this as a finding — the PRD's own R3
premise is stale — separately from the filename check itself, which still
needs to run because "already built" does not change whether the names
agree:

| node | file(s) it created | verdict |
|---|---|---|
| `12-small-plugins` | `gitsigns.lua`, `which-key.lua`, `autopairs.lua` (named explicitly in its own R4) | agrees — landed filenames match R4's names exactly, and R4's names match the restated I8 (see R2 table above); no accommodation needed |
| `13-statusline` | `statusline.lua` (not named in the node's own requirements text; decided at implementation) | agrees — concern-named, see R2 table above |
| `15-markdown-tables` | `table-mode.lua` (not named in the node's own requirements text; recorded in its Report section) | agrees — concern-named, see R2 table above |

No conflict found, so the "12-small-plugins' names win" accommodation this
PRD's R3 anticipates is not needed — the restated I8 and the landed names
already agree.

## Acceptance

- [x] I8's edited text, quoted, matches the R1 block above exactly (one
      clause changed, the rest of the bullet byte-identical). Landed at
      `prds/03-editor/prd.md:80-81`:
      ```
      - [ ] **I8** — **One file per plugin under `lua/plugins/`.** Each plugin
            spec lives in a file named for the **concern it delivers**, not the
            plugin itself — a concern name survives replacing the plugin behind
            it. There is no catch-all.
      ```
      Everything from "The live config has one" onward is untouched.
- [x] The R2 table (all twelve `lua/plugins/*.lua` files) is in the report
      above, with `conform.lua` called out as the one ambiguous-not-mismatched
      case. Zero genuine mismatches found.
- [x] The R3 table (three named nodes) is in the report above, plus the
      finding that all three (`12-small-plugins`, `13-statusline`,
      `15-markdown-tables`) are `done`, not unbuilt, measured 2026-08-25.
- [x] `bash gates/tree-links.sh` Tier A broken count quoted before and after:
      before `checked 1589 links in 456 files, 0 broken`; after
      `checked 1589 links in 456 files, 0 broken`. Equal.

## Verify and Proof

```sh
# before
bash gates/tree-links.sh
# — baseline measured 2026-08-25: checked 1589 links in 455 files, 0 broken

# apply the R1 edit to prds/03-editor/prd.md, then:
bash gates/tree-links.sh
# — must report the same "0 broken" (link count may shift only if the
#   editor's own link-fence tooling reformats whitespace; the broken count
#   must not move)

ls home/dot_config/nvim/lua/plugins/
grep -RhoE '"[a-zA-Z0-9_.-]+/[a-zA-Z0-9_.-]+"' home/dot_config/nvim/lua/plugins/*.lua | sort -u
# — reproduces the R2 census's plugin-to-file mapping

grep -n '^state:' prds/03-editor/12-small-plugins/prd.md \
     prds/03-editor/13-statusline/prd.md \
     prds/03-editor/15-markdown-tables/prd.md
# — reproduces the R3 "all three are done" finding
```
