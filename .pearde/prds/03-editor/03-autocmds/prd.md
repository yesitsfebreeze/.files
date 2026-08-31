---
state: done
claim: 
priority: 8
est: 2h
actual: 25m
task: E.4
mode: afk
needs:
  - 03-editor/01-options
  - 00-delivery/corrections/w0-4-s2-corrections
  - 06-help/01-content-model
verify: ""
---

# Autocmds

Parent: [Neovim epic](../prd.md) · C 3 · U 8 · source: "Editor autocmds" in
[`capabilities-nvim.md`(../../../../docs/capabilities-nvim.md)

Purpose: Four small behaviors that make the editor feel finished. Each lives
in its own cleared augroup so a config reload never stacks duplicates.

## Requirements
- [x] **R1** — **Highlight on yank.** `TextYankPost` → `vim.hl.on_yank`,
      150 ms. **Not `vim.highlight.on_yank`**: that is the deprecated
      spelling, and the live `lua/config/autocmds.lua:8` still uses it
      (correction M-3). The target binary is 0.12.4, where `vim.highlight`
      is deprecated in favour of `vim.hl` and on a removal clock; the
      version *floor* is unchanged and is not restated here — see the
      epic's version invariant. Confirm `vim.hl.on_yank` resolves at the
      floor version before relying on it; if it does not, guard with
      `(vim.hl or vim.highlight).on_yank`, never fall back to the
      deprecated name outright.
- [x] **R2** — **Restore last position.** `BufReadPost` moves the cursor to
      the `"` mark when it's within the buffer's line count; excludes
      `gitcommit` (you want the top of a fresh commit message). Wrapped in
      `pcall` — the mark can be invalid for a window that isn't laid out yet.

      **The exclusion must read the filetype with
      `vim.filetype.match({ buf = buf })`, not `vim.bo[buf].filetype`.**
      Amended 2026-08-23 by the orchestrator, on a measurement: as written
      with `vim.bo`, the exclusion is **dead code**. This module is required
      from `init.lua`, so its `BufReadPost` callback registers *before*
      `$VIMRUNTIME/filetype.lua`'s handler on the same event —
      `nvim_get_autocmds` lists `last_loc` above both `filetypedetect`
      entries — and `vim.bo[buf].filetype` is still `""` when it runs
      (measured: `LASTLOC sees ft=''`). Opening `COMMIT_EDITMSG` with a `"`
      mark at line 9 therefore lands on line 9, which is exactly what
      acceptance box 2 forbids. `vim.filetype.match({ buf = buf })` returns
      `"gitcommit"` at that point (measured: `ft=gitcommit line=0 mark=9`).

      `vim.schedule` also produces the right filetype and is **rejected**:
      it jumps the cursor after the first redraw, so the fix would be
      visible as a flicker. The live `~/.config/nvim` has this bug today —
      a verbatim port would have shipped it, which is why the amendment is
      here rather than only in the spec.
- [x] **R3** — **Trim trailing whitespace on save.** `BufWritePre` runs
      `keeppatterns %s/\s\+$//e`, bracketed by `winsaveview`/`winrestview` so
      the cursor and scroll position survive.
- [x] **R4** — **Close utility buffers with `q`.** `FileType` in {help, qf,
      man, lspinfo, checkhealth, startuptime} → unlist the buffer and map
      buffer-local `q` to `close`.
- [x] **R5** — **Grouped, and cleared.** Each of R1–R4 registers under its
      own `nvim_create_augroup(<name>, { clear = true })`:
      `highlight_yank`, `last_loc`, `trim_whitespace`, `close_with_q`. This
      file is the part of the config that already satisfies the epic's
      [I7](../prd.md) — it is stated here as a requirement so a later edit
      cannot quietly drop a `group =` and still pass review. The
      violations I7 exists for are in the plugin specs, not here.

## Acceptance
- [x] Yanking flashes the region briefly — the `nvim.hlyank` namespace holds
      one extmark shortly after the yank and none a quarter-second later,
      with `hl_group = "IncSearch"`. Whether that flash is *visible* against
      base16 is the one thing headless cannot settle; it is the E.4 row on
      `gates/manual/wave3.md`.

      Executed 2026-08-23, `bash tests/nvim-autocmds.sh --headless`:
      `before=-1 after=1 row=0 hl_group=IncSearch priority=200 end_row=1
      at100=1 at250=0`. The visibility half is the handed-over checklist
      row; the row text is with the orchestrator, which owns
      `gates/manual/wave3.md`.
- [x] Reopen a file edited mid-document: the cursor returns to where it was;
      `git commit` opens at line 1. The `git commit` half is the check that
      catches R2's amended filetype read — with `vim.bo` it lands on the
      mark instead, so this box fails against a verbatim port.

      Executed: two sessions in one `XDG_STATE_HOME` over a 200-line file
      report `cursor=137 mark=137`; the same shape over `COMMIT_EDITMSG`
      reports `cursor=0 mark=9 ft=gitcommit`. The counterfactual with the
      `vim.filetype.match` line deleted reports `cursor=9` — the verbatim
      port really does fail this box.
- [x] Save a file with trailing spaces: they vanish, the view doesn't jump.
      Both halves are observable, and the second has a counterfactual: with
      `winsaveview` omitted, a cursor at line 200 with topline 190 moves to
      370/360.

      Executed: the 42-byte fixture writes to 33 bytes with 0 lines carrying
      trailing whitespace, the tab indent intact; the 400-line fixture keeps
      `line 200 -> 200, topline 190 -> 190`, and the mutated copy reports
      `line 200 -> 370, topline 190 -> 360`.
- [x] `:help x` then `q` closes it, and the help buffer never appears in
      `:bnext` cycling.

      Executed: `ft=help wins_open=2 wins_after=1`, and with a real file plus
      `:help` open `listed=1 names=pos.txt`. The six utility filetypes each
      report `buflisted=false` with a buffer-local `q` mapped to
      `<cmd>close<CR>`; the `lua` and `markdown` controls stay listed with no
      `q` map.
- [x] **Reworded 2026-08-23 by the orchestrator, because the original could
      not fail.** It read: "`:source $MYVIMRC` twice, then yank: the region
      flashes once, not three times." Two measurements retire it —
      `:source $MYVIMRC` re-registers nothing at all (`require` caches the
      module, so the yank group stays at 1), and a stacked callback does not
      flash more than once anyway (`on_yank` clears its namespace first, so
      the extmark count is 1 even with three callbacks registered). The
      intent was to observe R5's `clear = true`, and the observable that
      *does* move is the group census: **9 autocmd groups with
      `clear = true`, 27 with `clear = false`** after two forced module
      reloads. That is the box.

      Executed: `g_total=9` on the real staging and `r_total=9` after two
      forced `package.loaded["config.autocmds"] = nil; require(...)` rounds;
      the `clear = false` copy reports `g_total=9` then `r_total=27`.

## Out of scope
- Anything this node's Requirements do not name. The epic ([`../prd.md`](../prd.md)) owns the shared invariants.
