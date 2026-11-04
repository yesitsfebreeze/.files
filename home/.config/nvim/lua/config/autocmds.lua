-- lua/config/autocmds.lua
-- Why this file is shaped the way it is:
--   manual → internals/neovim

local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

autocmd("TextYankPost", {
  group = augroup("highlight_yank", { clear = true }),
  callback = function()
    vim.hl.on_yank({ timeout = 150 })
  end,
})

autocmd("BufReadPost", {
  group = augroup("last_loc", { clear = true }),
  callback = function(event)
    local buf = event.buf
    local ft = vim.bo[buf].filetype
    if ft == "" then
      ft = vim.filetype.match({ buf = buf }) or ""
    end
    if vim.tbl_contains({ "gitcommit" }, ft) then
      return
    end
    local mark = vim.api.nvim_buf_get_mark(buf, '"')
    local lcount = vim.api.nvim_buf_line_count(buf)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

autocmd("BufWritePre", {
  group = augroup("trim_whitespace", { clear = true }),
  pattern = "*",
  callback = function()
    local save = vim.fn.winsaveview()
    vim.cmd([[keeppatterns %s/\s\+$//e]])
    vim.fn.winrestview(save)
  end,
})

-- Start files in Insert. Vim's easy mode ('insertmode') was removed from
-- Neovim, so this is the whole of it: no mode juggling, Esc still reaches
-- Normal, and buffers that carry their own mode (terminal, help, pickers,
-- plugin floats) are skipped.
autocmd("BufWinEnter", {
  group = augroup("start_insert", { clear = true }),
  callback = function(event)
    if event.buf ~= vim.api.nvim_get_current_buf() then
      return
    end
    if vim.bo[event.buf].buftype ~= "" then
      return
    end
    vim.cmd("startinsert")
  end,
})

autocmd("FileType", {
  group = augroup("close_with_q", { clear = true }),
  pattern = { "help", "qf", "man", "lspinfo", "checkhealth", "startuptime" },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = event.buf, silent = true })
  end,
})
