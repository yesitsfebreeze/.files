-- init.lua
-- Why this file is shaped the way it is:
--   docs-site → Internals → Neovim

require("config.options")

vim.filetype.add({
  extension = {
    jd = "markdown",
  },
})

require("config.keymaps")

require("config.shift-select")

require("config.autocmds")

require("config.lazy")
