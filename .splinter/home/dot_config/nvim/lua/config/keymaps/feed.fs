-- §head home/dot_config/nvim/lua/config/keymaps.lua:52-54 feed
-- §sig local function feed(keys)
vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), "n", false)
-- §foot home/dot_config/nvim/lua/config/keymaps.lua feed