-- Neovim entry point — from-scratch modular config.
-- Load order: options -> keymaps -> autocmds -> plugin manager (lazy.nvim).
require("config.options")
require("config.keymaps")
require("config.autocmds")
require("config.lazy")
