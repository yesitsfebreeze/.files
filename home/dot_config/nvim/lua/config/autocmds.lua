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
