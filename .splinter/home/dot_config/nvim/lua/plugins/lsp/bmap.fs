-- §head home/dot_config/nvim/lua/plugins/lsp.lua:27-29 bmap
-- §sig local function bmap(keys, fn, desc)
vim.keymap.set("n", keys, fn, { buffer = event.buf, desc = "LSP: " .. desc })
-- §foot home/dot_config/nvim/lua/plugins/lsp.lua bmap