-- lua/config/shift-select.lua
-- Why this file is shaped the way it is:
--   manual → internals/neovim

vim.o.keymodel = "startsel,stopsel"

vim.keymap.set("v", "<C-c>", "y", { desc = "Copy to clipboard" })
vim.keymap.set("v", "<C-v>", [["_dP]], { desc = "Paste over selection" })
