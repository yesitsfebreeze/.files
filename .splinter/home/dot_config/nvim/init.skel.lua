-- §source home/dot_config/nvim/init.lua
-- Load order: options -> keymaps -> autocmds -> plugin manager (lazy.nvim).
require("config.options")
require("config.keymaps")
require("config.autocmds")
require("config.lazy")

vim.filetype.add({
    extension = {
        jd = "markdown",
    },
})
