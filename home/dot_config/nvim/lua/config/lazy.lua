-- Bootstrap lazy.nvim (clones it on first run) and load plugin specs.
--
-- Lockfile policy: lazy-lock.json lives beside init.lua and is committed.
-- lazy rewrites the deployed copy on sync/update; carry that change back to
-- the repo in the same commit as the spec change that caused it. Every
-- plugin node (E.5+) commits its lockfile delta with its spec.
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local repo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", repo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
    }, true, {})
    -- The guard is load-bearing, not dead code: a bare getchar() blocks
    -- forever in --headless, even with stdin at /dev/null (measured
    -- 2026-08-22, nvim 0.12.4) — an offline scripted launch would hang
    -- instead of failing. Interactive launch still waits for the keypress;
    -- headless gets the error on stderr and exit 1.
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
  install = { colorscheme = { "base16-gruvbox-dark-hard" } },
  checker = { enabled = true, notify = false },
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
