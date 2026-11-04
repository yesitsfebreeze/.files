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

-- 'scrolloff' cannot scroll above line 1 or below the last line, so the first
-- and last half screen are never centred. Pad both ends of the buffer with
-- empty virtual lines and, while the cursor is in either half, hold the view
-- by hand (scrolloff off, topline and topfill set). In between, scrolloff=999
-- does the centring and keeps the cursor centred under wheel scrolling too.
-- Ceiling: counts buffer lines, so wrapped or folded lines near either end
-- shift the cursor off centre by their extra rows; at the ends a wheel scroll
-- moves the view without the cursor until the next cursor move.
local center_ns = vim.api.nvim_create_namespace("center_pad")
local center_group = augroup("center_pad", { clear = true })

local function half(win)
  return math.floor((vim.api.nvim_win_get_height(win) - 1) / 2)
end

local function center_pad(win)
  local buf = vim.api.nvim_win_get_buf(win)
  vim.api.nvim_buf_clear_namespace(buf, center_ns, 0, -1)
  if vim.bo[buf].buftype ~= "" then return end
  local lines = {}
  for _ = 1, half(win) do lines[#lines + 1] = { { "", "" } } end
  vim.api.nvim_buf_set_extmark(buf, center_ns, 0, 0, { virt_lines = lines, virt_lines_above = true })
  local last = vim.api.nvim_buf_line_count(buf) - 1
  vim.api.nvim_buf_set_extmark(buf, center_ns, last, 0, { virt_lines = lines })
end

local function center_hold(win)
  local buf = vim.api.nvim_win_get_buf(win)
  if vim.bo[buf].buftype ~= "" then return end
  local h = half(win)
  local lnum = vim.api.nvim_win_get_cursor(win)[1]
  local edge = lnum <= h or lnum >= vim.api.nvim_buf_line_count(buf) - h
  vim.wo[win].scrolloff = edge and 0 or 999
  vim.api.nvim_win_call(win, function()
    vim.fn.winrestview({ topline = math.max(1, lnum - h), topfill = math.max(0, h - lnum + 1) })
  end)
end

autocmd({ "BufWinEnter", "VimResized", "WinResized", "TextChanged", "TextChangedI" }, {
  group = center_group,
  callback = function()
    center_pad(0)
    center_hold(0)
  end,
})

autocmd({ "CursorMoved", "CursorMovedI" }, {
  group = center_group,
  callback = function()
    center_hold(0)
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
-- Normal, and every buffer that is not a plain editable file stays in Normal
-- (terminal, help, pickers, plugin floats, oil, fugitive, diffview).
-- The check waits one tick: plugins such as oil set 'buftype' only after
-- BufWinEnter, so checking right away sees "" and wrongly enters Insert.
autocmd("BufWinEnter", {
  group = augroup("start_insert", { clear = true }),
  callback = function(event)
    vim.schedule(function()
      if event.buf ~= vim.api.nvim_get_current_buf() then
        return
      end
      if require("config.insert").editable(event.buf) then
        vim.cmd("startinsert")
      elseif vim.api.nvim_get_mode().mode == "i" and vim.bo[event.buf].buftype ~= "prompt" then
        -- A screen opened from Insert (help, :Lazy) would inherit it.
        -- Prompt buffers (telescope) want Insert and set it themselves.
        vim.cmd("stopinsert")
      end
    end)
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
