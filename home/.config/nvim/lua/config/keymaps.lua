-- lua/config/keymaps.lua
-- Why this file is shaped the way it is:
--   manual → internals/neovim

local map = vim.keymap.set

map("n", "<C-h>", "<C-w>h", { desc = "Go to left window" })
map("n", "<C-j>", "<C-w>j", { desc = "Go to lower window" })
map("n", "<C-k>", "<C-w>k", { desc = "Go to upper window" })
map("n", "<C-l>", "<C-w>l", { desc = "Go to right window" })

map("n", "<C-Up>", "<cmd>resize +2<CR>", { desc = "Increase height" })
map("n", "<C-Down>", "<cmd>resize -2<CR>", { desc = "Decrease height" })
map("n", "<C-Left>", "<cmd>vertical resize -2<CR>", { desc = "Decrease width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<CR>", { desc = "Increase width" })

map("n", "<leader>|", "<cmd>vsplit<CR>", { desc = "Split right" })
map("n", "<leader>-", "<cmd>split<CR>", { desc = "Split below" })

map("n", "<S-h>", "<cmd>bprevious<CR>", { desc = "Previous buffer" })
map("n", "<S-l>", "<cmd>bnext<CR>", { desc = "Next buffer" })
map("n", "<leader>bd", "<cmd>bdelete<CR>", { desc = "Delete buffer" })

map("n", "<A-j>", "<cmd>m .+1<CR>==", { desc = "Move line down" })
map("n", "<A-k>", "<cmd>m .-2<CR>==", { desc = "Move line up" })
map("v", "<A-j>", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("v", "<A-k>", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")
map("n", "n", "nzzzv")
map("n", "N", "Nzzzv")

map("v", "<", "<gv")
map("v", ">", ">gv")

map("n", "<leader>w", "<cmd>write<CR>", { desc = "Save" })
map("n", "<leader>q", "<cmd>quit<CR>", { desc = "Quit" })

map("x", "<leader>p", [["_dP]], { desc = "Paste (keep register)" })

-- Esc is the way back: from any editor mode it lands in Insert, after
-- closing a focused picker or float so a sub-modal cannot trap you. In a
-- screen that is not a plain file (oil, :Lazy, help) it lands in Normal.
--
-- F6 is the way out. One press goes Normal and opens the leader at once;
-- a second press closes the leader and stays Normal. Neither gesture waits
-- for a possible second key.
local modes = { "n", "i", "v", "x", "s", "o" }
local esc = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
-- Esc moves the cursor one cell left on the way out of Insert. This does
-- not, so a block cursor stays on the same cell across a mode change.
local leave_insert = vim.api.nvim_replace_termcodes("<C-\\><C-n>", true, false, true)

-- Leave the current mode now, so the leader key fed next is read in Normal.
local function to_normal()
  local mode = vim.api.nvim_get_mode().mode
  -- Queued, never "x": feedkeys(..., "x") from a mapping or timer leaves
  -- later typed keys unprocessed.
  if mode == "i" or mode == "ic" or mode == "ix" then
    -- The Insert caret sits one cell right of the Normal cursor. Leaving
    -- Insert moves the block one cell left; restore the column so the
    -- cursor stays put (clamped at end of line, where Vim cannot go).
    local col = vim.api.nvim_win_get_cursor(0)[2]
    vim.api.nvim_feedkeys(leave_insert, "n", false)
    vim.defer_fn(function()
      local row = vim.api.nvim_win_get_cursor(0)[1]
      local line = vim.api.nvim_get_current_line()
      vim.api.nvim_win_set_cursor(0, { row, math.min(col, math.max(#line - 1, 0)) })
    end, 1)
  elseif mode ~= "n" then
    vim.api.nvim_feedkeys(esc, "n", false)
  end
end

-- Which-key owns Esc while its popup is open and swallows it, so the
-- editor's Esc map never runs. Watch for that close and finish the
-- gesture: Esc closes the leader and lands in Insert, F6 leaves Normal.
local last_key = nil
local leader_watch = nil

vim.on_key(function(key)
  last_key = key
end)

local function watch_leader()
  if leader_watch then
    return
  end
  local uv = vim.uv or vim.loop
  local timer = uv.new_timer()
  local seen = false
  local deadline = uv.now() + 5000
  leader_watch = timer
  timer:start(30, 30, vim.schedule_wrap(function()
    -- Each tick queues one callback; while the editor is busy several queue
    -- up, and the ones after the close must not touch the timer again.
    if timer:is_closing() then
      return
    end
    local ok, wk = pcall(require, "which-key.state")
    local open = ok and wk.state ~= nil
    if open then
      seen = true
    end
    if (seen and not open) or (not seen and uv.now() > deadline) then
      timer:stop()
      timer:close()
      leader_watch = nil
      if seen and last_key == esc then
        require("config.insert").start()
      end
    end
  end))
end

map(modes, "<Esc>", function()
  local bt = vim.bo.buftype
  -- A prompt buffer is a modal UI (telescope and friends) wherever its
  -- window sits; a nofile float is one too. Close it, then land in Insert.
  if bt == "prompt" or (bt == "nofile" and vim.api.nvim_win_get_config(0).relative ~= "") then
    -- "close!" because a prompt buffer holds its query as an unsaved change.
    pcall(vim.cmd, "close!")
    -- Insert belongs to the window that is current after the close.
    vim.schedule(require("config.insert").start)
    return
  end
  require("config.insert").start()
end, { desc = "Insert mode" })

map(modes, "<F6>", function()
  to_normal()
  -- Type the leader from a timer, not from inside the map: keys fed during
  -- mapping resolution never reach which-key's trigger, and nvim_input
  -- goes through the real input path, so which-key sees a typed Space.
  -- Which-key owns F6 and Esc from there (see which-key.lua).
  watch_leader()
  vim.defer_fn(function()
    vim.api.nvim_input(" ")
  end, 10)
end, { desc = "Leader mode" })
require("config.cockpit")
