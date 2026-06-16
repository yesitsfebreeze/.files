-- General keymaps. Plugin-specific maps live in their plugin specs (keys = ...).
local map = vim.keymap.set

map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear highlight" })

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

-- Keep cursor centered on jumps / search (these maps carry no desc).
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")
map("n", "n", "nzzzv")
map("n", "N", "Nzzzv")

map("v", "<", "<gv")
map("v", ">", ">gv")

map("n", "<leader>w", "<cmd>write<CR>", { desc = "Save" })
map("n", "<leader>q", "<cmd>quit<CR>", { desc = "Quit" })

map("x", "<leader>p", [["_dP]], { desc = "Paste (keep register)" })

-- Editor-style "shift to select". The system clipboard is shared
-- (clipboard=unnamedplus), so copy/paste crosses between nvim and the terminal.
--
-- Entering visual mode via Shift+<arrow> (or starting a selection from insert)
-- sets a flag. While that flag is set, a plain motion (h/j/k/l or an unshifted
-- arrow) collapses the selection and returns to normal mode, just like a
-- conventional editor. Holding Shift keeps extending the selection. A selection
-- started the vim way (plain `v`) is unaffected and extends on motion as usual.
local shift_select = false

local function feed(keys)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), "n", false)
end

-- Reset the flag whenever we leave visual mode, so a later `v` selection keeps
-- normal extend-on-motion behaviour.
vim.api.nvim_create_autocmd("ModeChanged", {
  pattern = "*:*",
  callback = function()
    if vim.v.event.old_mode:find("^[vV\22]") then
      shift_select = false
    end
  end,
})

-- Start a selection from normal mode.
local function select_start(motion)
  return function()
    shift_select = true
    feed("v" .. motion)
  end
end

-- Extend a selection (Shift held) from visual mode.
local function select_extend(motion)
  return function()
    shift_select = true
    feed(motion)
  end
end

-- Start a selection from insert mode.
local function select_start_insert(keys)
  return function()
    shift_select = true
    feed("<Esc>" .. keys)
  end
end

-- Plain motion in visual mode: collapse + leave when we got here via Shift,
-- otherwise behave like a normal visual-mode motion (counts preserved).
local function visual_motion(motion)
  return function()
    local count = vim.v.count > 0 and tostring(vim.v.count) or ""
    if shift_select then
      shift_select = false
      feed("<Esc>" .. count .. motion)
    else
      feed(count .. motion)
    end
  end
end

map("n", "<S-Up>", select_start("<Up>"), { desc = "Select up" })
map("n", "<S-Down>", select_start("<Down>"), { desc = "Select down" })
map("n", "<S-Left>", select_start("<Left>"), { desc = "Select left" })
map("n", "<S-Right>", select_start("<Right>"), { desc = "Select right" })

map("v", "<S-Up>", select_extend("<Up>"), { desc = "Extend selection up" })
map("v", "<S-Down>", select_extend("<Down>"), { desc = "Extend selection down" })
map("v", "<S-Left>", select_extend("<Left>"), { desc = "Extend selection left" })
map("v", "<S-Right>", select_extend("<Right>"), { desc = "Extend selection right" })

for _, m in ipairs({ "h", "j", "k", "l", "<Up>", "<Down>", "<Left>", "<Right>" }) do
  map("v", m, visual_motion(m), { desc = "Move (collapse selection)" })
end

map("i", "<S-Up>", select_start_insert("v<Up>"), { desc = "Select up" })
map("i", "<S-Down>", select_start_insert("v<Down>"), { desc = "Select down" })
map("i", "<S-Left>", select_start_insert("v<Left>"), { desc = "Select left" })
map("i", "<S-Right>", select_start_insert("lv<Right>"), { desc = "Select right" })

-- Ctrl+C copies the selection to the clipboard and leaves visual mode;
-- Ctrl+V pastes over the selection without clobbering the clipboard.
map("v", "<C-c>", "y", { desc = "Copy to clipboard" })
map("v", "<C-v>", [["_dP]], { desc = "Paste over selection" })
