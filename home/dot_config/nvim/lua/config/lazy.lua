-- lua/config/lazy.lua
-- Why this file is shaped the way it is:
--   manual → internals/neovim

local checking = vim.env.HELP_CHECK == "1"

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  if checking then
    io.stderr:write("HELP_CHECK: lazy.nvim is not installed at " .. lazypath .. "\n")
    os.exit(1)
  end
  local repo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", repo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
    }, true, {})
    if #vim.api.nvim_list_uis() > 0 then vim.fn.getchar() end
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = {
    { import = "plugins" },
  },
  defaults = { lazy = false, version = false },
  rocks = { hererocks = false },
  install = { colorscheme = { "base16-gruvbox-dark-hard" }, missing = not checking },
  checker = { enabled = not checking, notify = false },
  change_detection = { notify = false },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
        "netrwPlugin",
      },
    },
  },
})
