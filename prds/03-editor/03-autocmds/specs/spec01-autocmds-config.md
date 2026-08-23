---
est: 0.75h
footprint:
  - home/dot_config/nvim/lua/config/autocmds.lua   # create
  - home/dot_config/nvim/init.lua                  # edit: one require
  - tests/nvim-options.sh                          # edit: one census entry
---

# spec01 — `lua/config/autocmds.lua`: the four behaviors, wired into init.lua

Delivers R1–R5 as one new 50-line module plus two one-line edits: the
`require` that loads it (`init.lua`) and the file census in E.1's gate
(`tests/nvim-options.sh`), which is an exact-match list and goes red the
moment a file appears under `home/dot_config/nvim/`. The port is the live
`~/.config/nvim/lua/config/autocmds.lua` with **two changes, both measured
on nvim 0.12.4 on 2026-08-23**: `vim.hl.on_yank` for the deprecated
`vim.highlight.on_yank` (correction M-3), and a filetype lookup that
actually resolves at `BufReadPost` time, because the live one does not and
its `gitcommit` exclusion is dead code.

## The two live findings this spec fixes

**1. `vim.hl` is available at the version floor — no guard.** R1 asks that
this be confirmed before relying on the new name. It is confirmed:
`$VIMRUNTIME/doc/deprecated.txt` lists `vim.highlight → Renamed to vim.hl`
under the **`DEPRECATED IN 0.11`** section (line 117, between the 0.11
header at 68 and the 0.10 header at 124), and `doc/news-0.11.txt` documents
`vim.hl.range()`. The floor is ≥ 0.11 (epic I6 →
[`packages-installer`](../../../05-platform/02-package-provisioning/packages-installer/prd.md)
R6), so `vim.hl.on_yank` resolves at the floor and the
`(vim.hl or vim.highlight)` fallback R1 offers is **not** written. On the
target binary both names resolve (`type(vim.hl.on_yank)` and
`type(vim.highlight.on_yank)` are both `function`).

**Nothing at runtime can tell the two spellings apart**, which is why the
grep in [spec02](spec02-gate.md) is the only detector: a staged copy using
`vim.highlight.on_yank` still flashes (extmark count 1, measured), and the
deprecation is *silent* — wrapping `vim.notify` and calling
`vim.highlight.on_yank` produced `notify_count=0`. Say this in the file's
comment, because the next reader's instinct is that a deprecated call warns.

**2. The live `gitcommit` exclusion never fires.** Measured: at
`BufReadPost` the callback sees `vim.bo[buf].filetype == ""`. Neovim's own
filetype detection is registered on the same event by
`$VIMRUNTIME/filetype.lua`, and same-event autocmds run in **registration**
order — this module is required from `init.lua`, so it registers *first*.
`nvim_get_autocmds({event = "BufReadPost"})` lists `last_loc` **above** the
two `filetypedetect` entries. Consequence, measured end to end: opening
`COMMIT_EDITMSG` with a `"` mark at line 9 lands the cursor on **line 9**,
not line 1 — the third PRD acceptance box fails against a verbatim port.
(`BufRead` and `BufReadPost` are the same event, so moving to `BufRead`
changes nothing.)

The fix is one line: compute the filetype instead of reading it.
`vim.filetype.match({ buf = buf })` returns `"gitcommit"` at that moment
(measured), so the exclusion fires and the cursor stays put — measured
`ft=gitcommit line=0 mark=9` after the fix, `line=9` without it. Keep the
`vim.bo` read first: once a buffer already has a filetype (a re-read, a
buffer opened a second time) it is authoritative and free, and
`vim.filetype.match` reads buffer content.

**Do not "fix" this by deferring instead.** `vim.schedule`-ing the body also
sees the filetype (measured `scheduled bo.ft='gitcommit'`), but it moves the
cursor after the event-loop turn — in an interactive session that is a
visible jump from line 1, which is exactly the artifact R2 exists to avoid.

## The file

**create** `home/dot_config/nvim/lua/config/autocmds.lua`, two-space indent
to match the ported `options.lua` and the plugin specs (the live file's four
spaces was normalised at E.1):

```lua
-- Four small behaviors, each in its own cleared augroup: clear = true is
-- what makes re-registration idempotent, so re-running this module replaces
-- its callbacks instead of stacking a second copy (epic I7, live bug L-8).
local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

-- Highlight on yank. vim.hl, NOT vim.highlight: the latter was renamed in
-- 0.11 (deprecated.txt) and is on a removal clock. The rename is the one
-- thing no runtime check can catch — the deprecated call still flashes and
-- warns nobody (measured: notify count 0) — so the gate greps for it.
-- timeout = 150 is also vim.hl.on_yank's own default; it is written out
-- because R1 specifies the duration, not because it changes behavior.
autocmd("TextYankPost", {
  group = augroup("highlight_yank", { clear = true }),
  callback = function()
    vim.hl.on_yank({ timeout = 150 })
  end,
})

-- Return to the last edit position when opening a file.
--
-- The filetype has to be COMPUTED here, not read. This module is required
-- from init.lua, so its BufReadPost callback registers before the one
-- $VIMRUNTIME/filetype.lua installs on the same event, and same-event
-- autocmds fire in registration order: vim.bo.filetype is still "" at this
-- point and a filetype-based exclusion silently never matches. Measured on
-- 0.12.4: the live config's gitcommit exclusion is dead for exactly this
-- reason, and a commit message opens on the previous commit's cursor line.
-- vim.filetype.match resolves it now; deferring with vim.schedule would
-- also work but moves the cursor after the first redraw, which is the
-- visible jump this autocmd exists to prevent.
autocmd("BufReadPost", {
  group = augroup("last_loc", { clear = true }),
  callback = function(event)
    local buf = event.buf
    local ft = vim.bo[buf].filetype
    if ft == "" then
      ft = vim.filetype.match({ buf = buf }) or ""
    end
    -- A fresh commit message opens at the top, never where the last one
    -- was left.
    if vim.tbl_contains({ "gitcommit" }, ft) then
      return
    end
    local mark = vim.api.nvim_buf_get_mark(buf, '"')
    local lcount = vim.api.nvim_buf_line_count(buf)
    if mark[1] > 0 and mark[1] <= lcount then
      -- pcall: the mark can be invalid for a window that is not laid out
      -- yet, and a hard error here would abort the read.
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- Trim trailing whitespace on save. The substitute leaves the cursor on the
-- last line it changed, so the view is saved and restored around it —
-- without the bracket, saving a 400-line file with trailing space on line
-- 370 drags the cursor there from line 200 (measured).
autocmd("BufWritePre", {
  group = augroup("trim_whitespace", { clear = true }),
  pattern = "*",
  callback = function()
    local save = vim.fn.winsaveview()
    vim.cmd([[keeppatterns %s/\s\+$//e]])
    vim.fn.winrestview(save)
  end,
})

-- Close utility buffers with `q`, and keep them out of buffer cycling: an
-- unlisted help buffer never turns up under :bnext.
autocmd("FileType", {
  group = augroup("close_with_q", { clear = true }),
  pattern = { "help", "qf", "man", "lspinfo", "checkhealth", "startuptime" },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = event.buf, silent = true })
  end,
})
```

Value changes from live beyond the two findings: **none**. Same four events,
same four group names, same six filetypes, same `keeppatterns` command, same
`pcall`, same 150 ms.

## `init.lua` — insert, do not append

`require("config.autocmds")` goes **above** `require("config.lazy")` and
below `require("config.options")` (epic I1). The existing `vim.filetype.add`
block stays where it is; put the new require after it, immediately before
the lazy require, so the resulting order reads options → autocmds → lazy.

**The seam comment contains the literal string `require("config.lazy")`
twice.** A `sed`/replace on that string rewrites the prose and produces a
broken comment — it happened while measuring this spec. Edit the file by
hand or by exact-line match.

Update the seam comment in the same edit: it currently names both E.3 and
E.4 as pending inserts. After this lands only `02-keymaps` (E.3) is
outstanding, and its require goes **above** this one. Leaving the comment
naming E.4 tells the next reader a file that already exists still has to be
added.

The first require must remain `config.options` — `tests/nvim-options.sh`
asserts exactly that (`tree: the first require in init.lua is
config.options`), with comment lines stripped first.

## `tests/nvim-options.sh` — grow the census, one entry

E.1's gate holds an exact-match list of every file under
`home/dot_config/nvim/`. Verified on a scratch copy of this repo with the
new file in place: the gate reports **one** FAIL, that census check, and 72
other PASS — nothing else in it regresses. After inserting the entry: exit
0, 74 PASS.

**Read the line, do not transcribe it.** `03-editor/09-lsp` is claimed and
writing this same census right now, so the list you find may be longer than
the one measured here. Find the `[ "$files" = "..." ]` comparison in
`stage_tree`, and insert `./lua/config/autocmds.lua` at its `LC_ALL=C`
sorted position — which is **immediately after `./lazy-lock.json` and before
`./lua/config/lazy.lua`** (`a` < `l`), whatever else the list holds. Change
nothing else in the script; the census label says "post-E.6" and renaming it
is not this node's business.

One writer per file: if 09-lsp holds `tests/nvim-options.sh` when you get
here, hand the one-entry insert to the orchestrator rather than editing
around it.

## Hands off

- **No manual entry.** `home/dot_config/nushell/help/nvim.nuon` carries no
  entry sourced to this PRD, and this node adds none — the same call
  [`05-completion`](../../05-completion/specs/spec01-plugin-and-lockfile.md)
  made: `home/dot_config/nushell/` is the S.5 lane's. It is also not
  mechanically possible for you: `tests/help-content-model.nu` requires a
  `use-review.nuon` row per entry whose reviewer is **not** the author, so
  an entry written and reviewed by this session would fail the gate it is
  supposed to satisfy. The gap (the utility-buffer `q` gesture is
  undocumented) is a correction to file, never an edit.
- **No keymaps beyond the buffer-local `q`.** General maps are
  [`02-keymaps`](../../02-keymaps/prd.md); nothing here is global.
- **No plugin spec, no lockfile.** `lazy-lock.json` is untouched; this
  module depends on nothing outside core.
- **`tests/live-bugs.sh` stays untouched.** It reads the *live*
  `~/.config/nvim` — including using `lua/config/autocmds.lua` as its
  positive control for the grouped-autocmd check — and nothing in this node
  changes that file.

## Acceptance

- [x] `home/dot_config/nvim/lua/config/autocmds.lua` exists and holds
      exactly four `autocmd(` call sites, each with its own
      `group = augroup("<name>", { clear = true })`; the four names are
      `highlight_yank`, `last_loc`, `trim_whitespace`, `close_with_q`.
      Ran `bash tests/nvim-autocmds.sh --tree`: `PASS tree: exactly 4
      autocmd( call sites`, `PASS tree: exactly 4 group = lines`, `PASS
      tree: exactly 4 { clear = true }`, and one PASS per group name.
- [x] **Reworded by the orchestrator: the grep cannot pass on the correct
      file.** The whole-file count of `vim.highlight` is **1**, on the comment
      line this very spec prescribes (`-- Highlight on yank. vim.hl, NOT
      vim.highlight: …`). Same trap `tests/nvim-statusline.sh` hit with
      `theme = "auto"`. Resolved the same way: the ban runs comment-stripped,
      with a two-sided control — the literal on a **code** line goes red, the
      same literal in a **comment** stays green. Measured: whole-file hits on
      the correct file **1 (all comment)**, comment-stripped **0**. The box's
      second half (`vim.hl.on_yank({ timeout = 150 })` present) is green.
      Original box:`/usr/bin/grep -c 'vim\.highlight' home/dot_config/nvim/lua/config/autocmds.lua`
      is 0, and `vim.hl.on_yank({ timeout = 150 })` is present (M-3).

      **NOT TICKED — the check as written fails the correct file.** The
      whole-file count is **1**, on the comment line this spec itself
      prescribes (`-- Highlight on yank. vim.hl, NOT vim.highlight: …`). A
      whole-file ban means the file may never *name* the thing it forbids,
      which is the trap `tests/nvim-statusline.sh` hit with `theme = "auto"`
      and resolved by stripping comments first. `tests/nvim-autocmds.sh`
      does the same: comment-stripped count **0**, with a two-sided control
      — the literal planted on a CODE line goes red, the same literal in a
      COMMENT stays green. Ran it: `whole-file 'vim.highlight' hits on the
      CORRECT file: 1 (all comment) · comment-stripped: 0`, `PASS tree: M-3
      no vim.highlight in CODE`, `PASS selftest: the deprecated spelling on
      a code line goes red on M-3's ban`, `PASS selftest NEGATIVE CONTROL:
      the same literal in the file's own COMMENT stays GREEN`. The second
      half is proven: `PASS tree: R1 vim.hl.on_yank({ timeout = 150 })`.
- [x] `init.lua` requires, in order, `config.options`, `config.autocmds`,
      `config.lazy`; the seam comment is intact (no truncated
      `require("config.lazy")` in the prose) and no longer names E.4 as
      pending. Ran `--tree`: `init.lua requires (comments stripped):
      config.options config.autocmds config.lazy`, plus `PASS tree: the seam
      comment no longer names E.4 as a pending insert` and `PASS tree: every
      require( in the seam comment is a COMPLETE require("…")`.
- [x] `bash tests/nvim-options.sh` exits 0 after the census insert, with no
      FAIL line. (Before the insert it fails exactly one check — quote both
      runs.) Before: `exit=1`, 72 PASS, one FAIL — `FAIL tree:
      home/dot_config/nvim/ holds exactly the post-E.13 census —
      statusline.lua included (got: ./init.lua ./lazy-lock.json
      ./lua/config/autocmds.lua …)`. After: `exit=0`, 74 PASS, 0 FAIL,
      `PASS — the options baseline is the live baseline, proven in a hermetic
      Neovim`.
- [x] `bash tests/nvim-autocmds.sh` (spec02) exits 0 — it holds every
      behavioral box, including the two acceptance boxes a verbatim port
      would fail. `rc=0`, 114 PASS, 0 FAIL.
- [x] `bash tests/nvim-plugin-manager.sh --tree` and
      `bash tests/nvim-completion.sh --tree` / `--headless` still exit 0 —
      ran all three: plugin-manager `--tree` rc 0 / 16 PASS, completion
      `--tree` rc 0 / 25 PASS, completion `--headless` rc 0 / 57 PASS. —
      they stage this whole config, so the new module loads inside their
      probes too. Measured on a scratch copy: completion `--tree` 0,
      `--headless` 0 (57 PASS). Two known environment flakes, both
      reproduced on the **unmodified** repo, so neither is yours: a cold
      `--headless` run can lose the async blink keymap-desc checks (re-run),
      and `nvim-plugin-manager.sh --headless` fails its clone-failure probe
      with `TIMEOUT` where the network is blocked.

## Verify and Proof

```sh
cd /Users/feb/dev/dotfiles
bash tests/nvim-autocmds.sh              # spec02's gate — the behavior
bash tests/nvim-options.sh               # census grown, wave 1 still green
bash tests/nvim-completion.sh --tree
bash tests/nvim-completion.sh --headless
/usr/bin/grep -n 'require(' home/dot_config/nvim/init.lua
/usr/bin/grep -c 'vim\.highlight' home/dot_config/nvim/lua/config/autocmds.lua
```
