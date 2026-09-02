---
state: done
claim:
priority: 8
est: 2h
task: E.15
mode: afk
needs:
  - 03-editor/04-plugin-manager
  - 06-help/01-content-model
needs:
verify: ""
---

# Markdown table mode

Parent: [Neovim epic](../prd.md) · C 3 · U 5 · source: "Markdown table mode"
in [`capabilities-nvim.md`(../../../../docs/capabilities-nvim.md)

Purpose: Live table alignment while typing markdown: pipes realign on every
`|` in insert mode. Complements prettier's on-save alignment
([07-formatting](../07-formatting/prd.md)) — this one works *during* editing.

## Requirements
- [x] **R1** — **Plugin.** `dhruvasagar/vim-table-mode`, lazy on the
      markdown filetype plus its `TableMode*` / `Tableize` commands.

      **`markdown.mdx` is dropped.** Answered 2026-08-23 by the user on
      [`07-formatting`](../07-formatting/prd.md) Q2 and written in here by the
      orchestrator, because a spec may not edit a sibling PRD's body. The
      filetype is unreachable — `vim.filetype.match({filename="a.mdx"})`
      returns nothing, nothing registers the extension, and there are no
      `.mdx` files under `~/dev`; registering MDX support was declined, so
      `01-options`' `init.lua` is untouched. The single line is
      `local fts = { "markdown" }`, still hoisted out of `ft` and the autocmd
      `pattern` so both consumers follow it, and the gate asserts the autocmd
      patterns *equal* `ft` rather than any literal — so the specs already on
      disk need no edit, exactly as their analyst arranged.
- [x] **R2** — **GitHub-flavored corners.** `g:table_mode_corner = "|"` (the
      default `+` produces non-GFM tables).
- [x] **R3** — **Prefix.** `g:table_mode_map_prefix = "<leader>t"` — matching
      the `table` group registered in which-key
      ([12-small-plugins](../12-small-plugins/prd.md)).
- [x] **R4** — **Auto-enable.** A FileType autocmd enables table mode for
      markdown buffers.

      **The direct call is redundant, and the autocmd is the load-bearing
      half — the opposite of what this requirement said.** Corrected
      2026-08-23 by the orchestrator. R4 claimed "the FileType event that
      lazy-loaded the plugin has already fired for the triggering buffer, so
      without the direct call the first markdown file opened lacks it".
      Measured false: deleting the direct `enable()` call leaves the first
      markdown file opened as `nvim x.md` fully active and realigning,
      because `lua/lazy/core/handler/event.lua:107` sets `exclude = nil` for
      `FileType` and lazy **re-fires it ungrouped** after an `ft` load,
      running the autocmd `config` registered a moment earlier.

      The autocmd is what matters, and the discriminator is the **second**
      markdown buffer: with only the autocmd removed, `:edit t2.md` comes up
      inactive (`| c | d ||`). Keep the direct call if it is cheap, but no
      check may claim to prove it.

      **The same false reason is shipped to users**, in
      `home/dot_config/nushell/help/nvim.nuon`'s `why:` for
      `key: "<leader>t"`. spec01 rewrites that field and the gate bans the
      phrase.

## Acceptance
- [x] Open a markdown file directly (`nvim x.md`) and type a table row: pipes
      align live. **The "corners are `|`" half cannot fail here** — the
      plugin ships `ftplugin/markdown_tablemode.vim` setting
      `b:table_mode_corner = '|'`, and `get_buffer_or_global_option` prefers
      the buffer variable, so deleting `vim.g.table_mode_corner = "|"` leaves
      the markdown border byte-identical `|----|----|`. The substitute is a
      **`text`** buffer via the `cmd` trigger: `|----|----|` with the line,
      `|----+----|` without.
- [x] **Rewritten twice by the orchestrator.** First on 2026-08-23, because
      "renders correctly on GitHub" is not executable: the substitute is the
      delimiter row matching `^|[-:| ]+|$` and containing no `+`.

      **Corrected again on 2026-08-23, after the implementer measured that
      those two clauses cannot discriminate either.** `|||` — precisely the
      row counterfactual 7 produces — *matches* `^|[%-:| ]+|$` and contains
      no `+`, so both specced clauses stay green with the plugin inert. The
      third clause is what carries the box: the delimiter row must hold the
      `-` fill character. Landed as `has_fill`, with the measurement in a
      comment beside it, and it is the clause that turns probe G red under
      cf7 (`border=|||`, `loaded=true`). The box is `[x]` against that
      clause, not against the two that could not fail.
- [x] The maps exist and answer to the configured prefix. **R3's own line
      cannot fail**: `plugin/table-mode.vim:31` already defaults
      `table_mode_map_prefix` to `<Leader>t`, so deleting it leaves every map
      byte-identical. The counterfactual is therefore a **value change**
      (`<leader>z`), not a deletion.
- [x] The `.mdx` filetype is dead configuration, and dropping it is a
      one-line change — **settled 2026-08-23 (dropped, per R1) and landed:
      `local fts = { "markdown" }`, proven by the gate's `spec_ft=markdown`
      and `patterns_equal_ft=true` probes.** Confirmed
      independently: `vim.filetype.match({filename="a.mdx"})` → nil, opening
      `t.mdx` leaves `filetype` empty and `vim-table-mode` **not loaded**. The
      one line to write is `local fts = { "markdown" }` — the sanctioned
      value, not the two-element list this box was written against — hoisted
      out of `ft` and the autocmd `pattern` so both consumers follow it; the
      gate asserts the autocmd patterns *equal* `ft` and never the literal,
      so the answer needed no gate edit.

## Out of scope
- Anything this node's Requirements do not name. The epic ([`../prd.md`](../prd.md)) owns the shared invariants.

## Blocked — one box, and what closes it

Written 2026-08-23T21:30Z by the orchestrator. Everything this node owns is
landed and proven: `bash tests/nvim-markdown-tables.sh` exits 0 at **120 PASS
/ 0 FAIL**, `tests/nvim-options.sh` is green with the new census entry,
`gates/wave-status.sh --validate` no longer names the gate unreferenced, and
`gates/manual-coverage.sh` exits 0. This is not a failed attempt and it does
not want a retry.

**The open box:** `nu tests/help-content-model.nu` exits 1. Editing the `why:`
of `key: "<leader>t"` in `home/dot_config/nushell/help/nvim.nuon` staled that
entry's review digest, and the gate refuses a row whose `reviewer` equals its
`author` — a `why` reviewed by the session that wrote it is the record
vouching for itself, which is the whole point of the ritual
[`cdi-manual-source`](../../00-delivery/corrections/cdi-manual-source/prd.md)
R2 established. The implementer was right to stop rather than invent a
reviewer.

**What closes it:** a reader who did not write the text records the row in
`home/dot_config/nushell/help/why-review.nuon`:

```
{id: "<leader>t", file: "nvim.nuon", digest: "e70cd08965d13ba7",
 reviewer: "<the reader>", author: "<the E.15 lane>", date: "<the day>",
 note: "<the reading>"}
```

**Why it waits rather than being done now:** `why-review.nuon` is inside
[`04-shell/04-television`](../../04-shell/04-television/prd.md)'s footprint
and that node is `claimed` right now. Two sessions writing one review file is
the collision the footprint rule exists to prevent. `needs:` names it. When
that lane lands, the orchestrator dispatches the reader and this node closes —
no re-run of anything above.

**A spec omission, recorded so the next node avoids it:** spec01's footprint
carried `help/nvim.nuon` but not `why-review.nuon`. Every entry edit stales a
digest, so the review file belongs in the footprint of any spec that touches
an entry. Nothing was harmed here — the gate caught it — but the next lane
should not have to be caught.

## Closed 2026-08-23 by the orchestrator

`done`. The blocking event landed: `04-shell/04-television` released
`why-review.nuon`, an independent reader recorded the `<leader>t` row, and
`nu tests/help-content-model.nu` now exits 0 — `92 entries across 4 files, 9
topics, 13 prose-only`, `ok`. Nothing above was re-run; the node's own gate
had been green at 120 PASS / 0 FAIL since the implementer landed it.

**`actual:` is left empty**: there was a BLOCKED round-trip, so elapsed time
here measures how long the review file stayed contended, not the cost of the
work.

**The review was a real reading, and it is worth reading.** It checked every
clause of the new `why` against the plugin source — `table_mode_always_active`
defaults to 0 at `plugin/table-mode.vim:33`, activation is buffer-local
(`autoload/tablemode.vim:146` writes `b:table_mode_active`, `:192-195` reads
it), and the gate's cf2 measures the claim rather than asserting it. It also
established that the **previous** review row had vouched for the old, false
`why` by citing the live config's comment, which repeated the same false
reason — which is precisely the failure the reviewer≠author rule exists to
catch, caught here by the rule working.

Two things the reader flagged rather than waved through, kept because the next
editor of this entry should see them:

1. **One fixture-bound sentence.** "only the file you opened nvim with would
   align" is exact for the fixture it was measured on (`nvim t.md`), but what
   the redundant direct `enable()` actually covers is whichever buffer was
   current at plugin load — start bare and `:e a.md` and that first `:edit`
   aligns too. It names a case, not the rule. It errs in the safe direction,
   and it is the same species of fixture-bound wording that produced the
   false `why` this one replaced.
2. **Thin, not wrong.** Nothing in the entry carries the reason most specific
   to its own key: `vim.g.table_mode_map_prefix` sits in `init` rather than
   `config` because `plugin/table-mode.vim:48-58` derives nine map names from
   the prefix at plugin **load** time, and the value buys no behaviour at all
   — `<Leader>t` is already the plugin default. It is the written contract
   with which-key's `table` group, nothing more. The strongest candidate if
   this field is ever revisited.

## Report

**DONE** — E.15 landed; gate green, one box owed elsewhere.

`bash tests/nvim-markdown-tables.sh` → exit 0, **120 PASS / 0 FAIL**. `--tree` 13 checks + 9 selftests (8 mutations red-then-caught); `--headless` probes A–H all matching the specced values; hermeticity proven (no clone/fetch/ls-remote, no tree-sitter URL, no write to real `~/.config/nvim`). Also green: `tests/nvim-options.sh`, `tests/shell-help.sh`, `gates/wave-status.sh --validate`, `gates/manual-coverage.sh`, and the `--tree` stage of all nine sibling nvim gates.

Landed: `lua/plugins/table-mode.lua` (new, `local fts = { "markdown" }` hoisted out of both `ft` and the autocmd pattern), one `lazy-lock.json` row, the census string in `tests/nvim-options.sh`, the `<leader>t` `why:` in `help/nvim.nuon`, the new gate, and the wave-4 registrations.

**State: `blocked`, not `done`.** `nu tests/help-content-model.nu` exits 1: the `why:` edit staled its review digest, and the gate refuses a row whose reviewer is its author. The row is owed by a reader who did not write the text, into `help/why-review.nuon` — a file the `04-shell/04-television` lane holds right now. `needs: [04-shell/04-television]`.

**Two orchestrator corrections on this transition:**

- PRD acceptance box 2 asserted a delimiter-row pattern that cannot discriminate: `|||` matches `^|[%-:| ]+|$` and holds no `+`, and `|||` is exactly what cf7 produces. The `has_fill` clause the implementer added is what actually reddens probe G; the box now says so.

- spec02 box 4 could not close because the `.mdx` answer made cf6 a no-op mutation (`patterns_equal_ft=true`). Recorded as cf6a, a vacuous-by-construction control, with cf6b as the discriminating replacement.
