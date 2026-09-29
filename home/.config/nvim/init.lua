-- init.lua
-- Why this file is shaped the way it is:
--   manual → internals/neovim

require("config.options")

vim.filetype.add({
  extension = {
    jd = "markdown",
  },
})

-- A second listen socket on a stable path. v:servername is a random per-run
-- directory, so nothing outside this process can address it; an agent given
-- the pid can build this one. `nvim --server <sock> --remote-expr` then drives
-- this instance and reads its LSP without starting a second rust-analyzer.
local run = vim.fn.fnamemodify(vim.fn.stdpath("run"), ":h")
vim.g.agent_socket = ("%s/agent-%d.sock"):format(run, vim.fn.getpid())
pcall(vim.fn.serverstart, vim.g.agent_socket)

require("config.keymaps")

require("config.shift-select")

require("config.autocmds")

require("config.lazy")
