-- Bootstrap lazy.nvim (clones it on first run) and load plugin specs.
--
-- Lockfile policy: lazy-lock.json lives beside init.lua and is committed.
-- lazy rewrites the deployed copy on sync/update; carry that change back to
-- the repo in the same commit as the spec change that caused it. Every
-- plugin node (E.5+) commits its lockfile delta with its spec.
-- HELP_CHECK=1 — the drift check's read-only spawn (06-help/04-drift-check).
-- `help --check` starts THIS config headless to read `nvim_get_keymap`, and a
-- startup that installs is a startup that changes its own answer: measured
-- 2026-08-29, a plugin in lazy-lock.json with no local store was git-cloned
-- from the network in the middle of a check run, and lazy's clone chatter
-- landed on stdout where the check reads its JSON. The check must observe the
-- configuration, never provision it. Under this variable lazy installs
-- nothing and polls nothing; a missing lazy.nvim is a FAILED check, not a
-- clone (see the bootstrap guard below). Nothing else reads it today and an
-- ordinary launch is unchanged.
--
-- TWO MORE INSTALLERS EXIST AND ARE DELIBERATELY NOT GUARDED HERE, because
-- the global-map spawn cannot reach them: lua/plugins/lsp.lua's
-- `mason-lspconfig` (`ensure_installed`, five servers) sits behind
-- `event = BufReadPre/BufNewFile`, and lua/plugins/treesitter.lua's
-- `install()` behind `BufReadPost/BufNewFile`. Measured: a headless start
-- that opens no buffer runs neither. A check that OPENS a buffer does —
-- 06-help/04-drift-check/04-nvim-buffer-maps is that check, and extending
-- this same variable to those two call sites is its job, not this one's.
local checking = vim.env.HELP_CHECK == "1"

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  if checking then
    -- Loud on stderr and rc 1, so `help --check` raises with a real reason
    -- instead of reporting Neovim's own 123 default maps as our drift.
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
  -- `install.missing` defaults to true — it is the clone-on-start that the
  -- check must not trigger; `checker` polls GitHub for updates. Both are off
  -- under HELP_CHECK and unchanged otherwise.
  -- KEY ORDER IS LOAD-BEARING HERE, and only for a reader outside this file:
  -- tests/nvim-colorscheme.sh:216 extracts the scheme with the literal regex
  -- `install = \{ colorscheme = \{ "` , so `missing` goes AFTER `colorscheme`
  -- or that gate stops finding the string and goes red on a file it only
  -- reads. Measured 2026-08-29 by running that grep against both orders:
  -- with `missing` first it matches nothing, with it last it still returns
  -- the scheme.
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
