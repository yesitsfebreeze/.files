---
state: done
claim:
priority: 8
est: 4h
task: E.12
mode: afk
needs:
  - 03-editor/04-plugin-manager
  - 00-delivery/corrections/w0-4-s2-corrections
  - 06-help/01-content-model
verify: ""
---

# Git signs, discovery, autopairs

Parent: [Neovim epic](../prd.md) · C 2 · U 7 · sources: "Git signs"
(C 2 / U 7 — dominant), "which-key" (C 2 / U 7), "Autopairs"
(C 1 / U 6) in
[`capabilities-nvim.md`(../../../../docs/capabilities-nvim.md)

Purpose: Three small quality-of-life plugins, grouped because none needs its
own file. Explicitly NOT here: line/block commenting. Neovim 0.10+ ships `gc`,
`gcc`, and `gc{motion}` natively — no Comment.nvim.

## Requirements
- [x] **R1** — **gitsigns.** `lewis6991/gitsigns.nvim`, lazy on
      `BufReadPre`/`BufNewFile`. Signs: `▎` (U+258E) for add, change and
      changedelete; for delete and topdelete, a **non-empty single-codepoint
      glyph distinct from `▎`** — recommended `` (U+F0DA,
      `nf-fa-caret_right`), the character LazyVim's gitsigns block uses and
      the lineage this sign set came from; fallback, if that does not render
      in the terminal font, gitsigns' own defaults `_` (delete) and `‾`
      (U+203E, topdelete), which additionally keep the below/above
      distinction. **Live bug L-10, do not reproduce:** both are literally
      `text = ""` live (`lua/plugins/editor.lua:12–13`), so a deleted hunk
      gets a blank sign cell — the one hunk kind with no line of its own to
      colour, hence invisible. The codepoint is written as a `U+` number
      and not only as a pasted character because a character lost in
      copy-paste is how the bug happened.

      **Landed 2026-08-24 with the recommended glyph, and the fallback's
      condition was measured rather than assumed.** `add`/`change`/
      `changedelete` are U+258E, `delete`/`topdelete` are U+F0DA.
      `wezterm ls-fonts --text` resolves U+F0DA to `glyph=fa-caret_right` at
      `cells=1` out of `CaskaydiaCoveNerdFont-Regular.ttf`, and U+258E to
      `drawn by wezterm because custom_block_glyphs=true` — so the "if that
      does not render" condition is false and the fallback is not taken. The
      gate *accepts either set*: it extracts the five values instead of
      matching literals, and one of its selftests substitutes the `_` / `‾`
      fallback and requires it to stay **green**, which is the control that
      keeps the check from over-fitting to U+F0DA.
      `bash tests/nvim-small-plugins.sh --tree` prints every value as
      `U+XXXX`, and runs `wezterm ls-fonts` over each distinct glyph with a
      U+F0000 negative control that must report `Placeholder glyphs`.
- [x] **R2** — **which-key.** `folke/which-key.nvim` on `VeryLazy`, with named
      leader groups: `<leader>f` find, `<leader>b` buffer, `<leader>c` code,
      `<leader>r` rename/refactor, `<leader>t` table. Group names must stay in
      sync with the keymaps that live under them.

      **The sync clause is mechanical, and the gate asserts the mechanism
      rather than a fixed list.** `tree:fix()` deletes a group node with no
      child keymap, so the rendered set is exactly the declared groups that
      have a live keymap in the current buffer — and lazy's `keys =` stubs
      count as live keymaps from startup. Re-measured 2026-08-24 against the
      tree as it now stands (`02-keymaps`, `07-formatting` and
      `15-markdown-tables` have all landed since this node was specced):
      **`b`, `c` and `f` render, `r` and `t` do not** —
      `f:live=4 b:live=1 c:live=1 r:live=0 t:live=0`, where `f` is
      telescope's four `<leader>f*` stubs, `b` is `<leader>bd` in
      `lua/config/keymaps.lua` and `c` is conform's `<leader>cf` stub. `r` is
      buffer-local on `LspAttach`; `t` is vim-table-mode's own prefix, built
      at plugin load time inside a markdown buffer. So the gate computes the
      live-keymap set itself and asserts rendered == live, which is why it
      needed no edit when the tree moved and needs none when the rest of the
      epic lands.
- [x] **R3** — **autopairs.** `windwp/nvim-autopairs` on `InsertEnter`,
      default config.
- [x] **R4** — **Three files, not one.** Per the epic's
      [I8](../prd.md), these three specs live in
      `lua/plugins/gitsigns.lua`, `lua/plugins/which-key.lua` and
      `lua/plugins/autopairs.lua` — never in a shared
      `lua/plugins/editor.lua`, which is what the live config has and what
      puts this node, [`07-formatting`](../07-formatting/prd.md) and
      [`15-markdown-tables`](../15-markdown-tables/prd.md) in a three-way
      write collision.

## Acceptance
- [x] Edit a tracked file: change signs appear in the sign column.

      Proven 2026-08-24 by `bash tests/nvim-small-plugins.sh --headless`
      probe B1 over a scratch git repo the gate builds: `gs_attached=true`,
      `gs_head=main`, `mark_count=3`, and `mark_GitSignsChange_row=0` with
      `mark_GitSignsChange_blank=false`, `mark_GitSignsChange_cp=U+258E`.
- [x] Delete a line in a tracked file and write: the sign cell for the
      deleted hunk is not blank, and the glyph is not the `▎` used for
      add/change.

      **The config readback is too weak to be the proof.** Corrected
      2026-08-23 by the orchestrator: the box asked for
      `require("gitsigns.config").config.signs.delete.text` to return a
      non-empty string, and with the glyph emptied (L-10 reproduced) the
      extmark is **still placed** — `sign_hl_group = GitSignsDelete`,
      `sign_text = nil`. A value that reads back fine and paints nothing is
      exactly this box's failure mode. What proves it: read the
      `gitsigns_signs_` extmarks and assert `sign_text` is non-blank **and**
      that the delete family's first codepoint differs from the change
      family's. Keep both halves — only the extmark catches the empty paint.

      **Do not assert that delete and topdelete share one glyph.** R1's
      sanctioned fallback (`_` / `‾` U+203E) is deliberately two *different*
      glyphs, so that formulation would fail the very fallback it
      authorises. Assert non-empty, one codepoint, and disjoint from the
      add/change glyph.

      **Both halves landed, and both were seen to go red under the
      mutation.** The extmark half, probe B1: `mark_GitSignsDelete_row=1`,
      `mark_GitSignsDelete_blank=false`, `mark_GitSignsDelete_cp=U+F0DA`,
      `del_ne_change=true`. Probe B2 covers topdelete on its only route — a
      first-line deletion in a second fixture file: `mark_count=1`,
      `mark_GitSignsTopdelete_row=0`,
      `mark_GitSignsTopdelete_blank=false`, `topdel_ne_addglyph=true`. The
      readback half: `cfglen_{add,change,delete,topdelete,changedelete}=1`.
      Counterfactual 4 reproduces L-10 and turns both red together —
      `cfglen_delete=0`, `mark_count=3` (**the extmark is still placed**),
      `mark_GitSignsDelete_text=[nil]`, `mark_GitSignsDelete_blank=true`,
      `del_ne_change=false`. Counterfactual 5 sets `delete` to `▎` and moves
      **only** the disjointness check: `cfglen_delete=1`,
      `mark_GitSignsDelete_blank=false`, `del_ne_change=false`. Nothing in
      the gate asserts that delete and topdelete share a glyph.
- [x] **Rewritten 2026-08-23 by the orchestrator: this box could not pass,
      and could not have.** It read "Press `<leader>` and pause: the five
      groups are listed with their names."

      `which-key`'s `tree:fix()` **deletes any group node with no child
      keymap**. Measured against the repo tree, of the five declared groups
      the rendered leader menu held **`f` only**: `b` needs
      [`03-editor/02-keymaps`](../02-keymaps/prd.md)'s unlanded
      `keymaps.lua` (that node is `failed`), `t` needs
      [`15-markdown-tables`](../15-markdown-tables/prd.md), and `c`/`r` are
      **buffer-local**, set on `LspAttach`, so they exist only inside an
      LSP-attached buffer. Proved by construction: seeding a global
      `<leader>bd`, a global `<leader>tt` and buffer-local
      `<leader>ca`/`<leader>rn`, then clearing which-key's buffer cache, made
      all five appear. So the box was measuring the rest of the epic, not
      this node.

      Worse, its mechanism is not executable at all:
      `require("which-key").show(...)` **never returns under `--headless`** —
      the session hangs to the watchdog with no output.

      What lands in its place: assert the five **declarations** from
      `Config.mappings` in R2's order, unconditionally; assert the
      **rendered** tree only against a probe-seeded post-E.3/E.15/LSP state;
      and put the popup *drawing* on `gates/manual/wave4.md`, with the
      measurement above as the stated reason.

      **All three landed 2026-08-24, and `show()` was never called.** The
      declaration half, unconditional: `wk_loaded=true`, `wk_decl_n=5`, and
      `wk_decl=<leader>f=find | <leader>b=buffer | <leader>c=code |
      <leader>r=rename/refactor | <leader>t=table` — read from
      `Config.mappings` after firing `User VeryLazy` and waiting for
      `Config.loaded`, filtered to `group` truthy, `mode == "n"` and an `lhs`
      starting `<leader>`. That filter is load-bearing: the list holds 302
      entries and 20 groups, because which-key's own presets are in it, and
      `m.group` is a **boolean** with the name in `m.desc`. The rendering
      half: `sync_ok=true` against the live-keymap set the probe computes
      itself (see R2), then the four missing keymaps seeded and
      `which-key.buf.clear()` called — `all_five_after_seeding=true`, with
      `kids_after` reading `-=Split below <Space>=Find files b=buffer c=code
      e=Open file explorer f=find q=Quit r=rename/refactor t=table w=Save
      |=Split right`. The popup *drawing* is now the first of two `**E.12**`
      rows in `gates/manual/wave4.md`, carrying the
      `show()`-never-returns measurement as its stated reason.
- [x] `gcc` comments a line with no commenting plugin installed.

      Proven by probe E: `gcc_sid=-8` — a **built-in**, not a plugin map —
      `gcc_desc=Toggle comment line`, `gcc_1=[-- local x = 1]`,
      `gcc_back=[local x = 1]`, `gcj_1=[-- local x = 1]`,
      `gcj_2=[-- local y = 2]`, and `comment_plugins=[]` over the whole of
      `lazy.core.config.plugins`, case-folded.
- [x] **Two autopairs behaviour checks are dropped as non-discriminating**,
      measured: `i(x)` → `(x)` and `i(<BS>` → empty line produce the
      identical result with autopairs **absent**. Only `i(` → `()` and
      `i"` → `""` discriminate, and both go red under
      `config = true` → `config = function() end`. Recorded so nobody
      restores a check that cannot fail.

      Landed exactly that way. The gate asserts `pair_paren=[()]` and
      `pair_quote=[""]` and carries the two dropped checks as a comment
      naming why they were dropped. Counterfactual 8 replaces `config = true`
      with an empty function and yields `ap_loaded=true` — so a load-state
      check defends nothing — with `pair_paren=[(]` and `pair_quote=["]`.

## Out of scope
- Anything this node's Requirements do not name. The epic ([`../prd.md`](../prd.md)) owns the shared invariants.

## Failure — history, retried 2026-08-23

Retried 2026-08-23T20:52Z by the user's answer in the round. Set `specced`, not
`open`: the two specs and the three orchestrator-rewritten acceptance boxes
above are the state to resume from, and nothing was half-written. The history
stays for whoever picks it up.

Swept 2026-08-23T20:34Z by the orchestrator, not reported by the worker. The
session holding `claim: implementer-small-plugins 2026-08-23T16:30Z` is gone
and left nothing on disk: no `lua/plugins/gitsigns.lua`,
`lua/plugins/which-key.lua` or `lua/plugins/autopairs.lua`, and no
`tests/nvim-small-plugins.sh` — so the verify command in the frontmatter names
a file that does not exist. Nothing was half-written, so a retry starts clean;
the two specs and the three orchestrator-rewritten acceptance boxes above are
the state to resume from.

## Closed 2026-08-24 by the orchestrator

`done`. `bash tests/nvim-small-plugins.sh` → **exit 0, 151 PASS / 0 FAIL**,
both stages, run five times. Nine neighbouring gates green beside it
(`nvim-options`, `nvim-plugin-manager` including `--network`,
`nvim-completion`, `nvim-colorscheme`, `nvim-lsp`, `help-content-model.nu`,
`manual-coverage`, `tree-links`, `retired-phrases`). All three rewritten
acceptance boxes closed against real measurements, and the census went 16 → 19
with the label `post-E.12`. **`actual:` left empty** — retry over a swept
`claimed`, with a `## Failure` history.

**All three rewrites were re-measured against today's tree rather than against
the box's description of it, and one had already changed.** The which-key box
said the rendered leader menu held `f` alone; today it holds `b`, `c`, `f` —
`02-keymaps` landed `<leader>bd`, and `07-formatting`'s `<leader>cf` is a lazy
`keys =` stub, which is a real keymap from startup. `t` still does not render
even though `15-markdown-tables` landed, because vim-table-mode builds its
prefix at plugin load inside a markdown buffer. So the probe stopped naming a
set: it computes the live-keymap set itself and asserts
`rendered == (live > 0)`, which needs no edit as the rest of the epic fills in.
That is the right answer to a box that kept going stale.

**Two mechanism corrections the specs did not know:**

- gitsigns creates **two** namespaces, `gitsigns_signs_` and
  `gitsigns_signs_staged` (`signs.lua:167`). A `^gitsigns_signs_` prefix loop
  picks the empty staged one and reports `mark_count=0` — an exact-name lookup
  is required, and the reason is in a comment beside it.
- Without `setup()`, `require("nvim-autopairs").config` is **nil**, so the
  readback aborted the probe before the behaviour checks ever ran. `.config or
  {}` fixes it. The spec's table implied this and never said it.

**A harness gotcha worth knowing before it eats a glyph again: the Write tool
silently strips U+F0DA.** The worker wrote both the plugin file and every
quoted proof through `chr(0xF0DA)` instead, and verified the bytes on disk as
`0x258e` / `0xf0da`. It also found that **spec01 line 73 had itself lost the
glyph** — empty backticks inside the very warning that says a lost glyph is how
live bug L-10 happened — and restored it from the `U+` number written beside
it. That is exactly why R1 records the codepoint as a number and not only as a
pasted character.

**The load effect, measured twice and nothing widened.** `tests/nvim-lsp.sh`
went red with `main probe exits 0, no TIMEOUT (got: TIMEOUT)` plus five
dependent attach assertions at 15-minute load average **27.35**, and was clean
on retry at 125 PASS. This node's own gate had one red run out of five at load
**21.5** — `gs_attached=false`, `ns_found=false`, probes D and E TIMEOUT — and
was clean before and after at load 8–9 with a byte-identical config. The
watchdog stayed at 25 s and the attach wait at 5 s. Recorded in
[`a-headless-gate-red-may-be-load-not-code`(../../../../prds/memos/a-headless-gate-red-may-be-load-not-code.md).

**Reported, not fixed:** the `nvim-autopairs` pin diverges from the seed source
(`430522f9` from a fresh clone of `master`, against the live clone's
`7b9923ab`), so the gate exercises one commit while the pin names another —
four pre-existing rows already carry the same drift, and `--network` confirms
the pin restores. And `nvim-autopairs`' `<BS>` and its `<CR>` interaction with
blink have **no manual entry**, though both are keys a user presses; that
finding was added to
[`nvim-help-entry-gaps`](../../00-delivery/corrections/nvim-help-entry-gaps/prd.md)
rather than filed as a new node.

**One review note is no longer stale:** `use-review.nuon`'s
`f60a9eebb54c7f22` reading said the leader menu also lists the bare leader maps
(`w q e | - <space>`). Measured 2026-08-24 against the repo tree, `kids_before`
holds `- <Space> b c e f q w |` — all present now that E.3 and E.10 have
landed. No help file was edited, so no digest was staled.
