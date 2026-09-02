-- lua/config/shift-select.lua
-- Why this file is shaped the way it is:
--   manual → internals/neovim

local map = vim.keymap.set

local shift_select = false

local function feed(keys)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), "n", false)
end

vim.api.nvim_create_autocmd("ModeChanged", {
  group = vim.api.nvim_create_augroup("shift_select", { clear = true }),
  pattern = "*:*",
  callback = function()
    if vim.v.event.old_mode:find("^[vV\22]") then
      shift_select = false
    end
  end,
})

local function select_start(motion)
  return function()
    shift_select = true
    feed("v" .. motion)
  end
end

local function select_extend(motion)
  return function()
    shift_select = true
    feed(motion)
  end
end

local function select_start_insert(keys)
  return function()
    shift_select = true
    feed("<Esc>" .. keys)
  end
end

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

map("v", "h", visual_motion("h"), { desc = "Move (collapse selection)" })
map("v", "j", visual_motion("j"), { desc = "Move (collapse selection)" })
map("v", "k", visual_motion("k"), { desc = "Move (collapse selection)" })
map("v", "l", visual_motion("l"), { desc = "Move (collapse selection)" })
map("v", "<Up>", visual_motion("<Up>"), { desc = "Move (collapse selection)" })
map("v", "<Down>", visual_motion("<Down>"), { desc = "Move (collapse selection)" })
map("v", "<Left>", visual_motion("<Left>"), { desc = "Move (collapse selection)" })
map("v", "<Right>", visual_motion("<Right>"), { desc = "Move (collapse selection)" })

map("i", "<S-Up>", select_start_insert("v<Up>"), { desc = "Select up" })
map("i", "<S-Down>", select_start_insert("v<Down>"), { desc = "Select down" })
map("i", "<S-Left>", select_start_insert("v<Left>"), { desc = "Select left" })
map("i", "<S-Right>", select_start_insert("lv<Right>"), { desc = "Select right" })

map("v", "<C-c>", "y", { desc = "Copy to clipboard" })
map("v", "<C-v>", [["_dP]], { desc = "Paste over selection" })
