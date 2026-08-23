-- Directories as editable buffers: rename, create and delete files with
-- ordinary editing commands instead of a bespoke tree UI. Replaces netrw,
-- which lua/config/lazy.lua disables via disabled_plugins.
--
-- WHY `lazy = false` — do not "optimise" this back to a keys-only spec.
-- The live config had no `lazy = false`, and that absence is live bug L-7.
-- lua/config/lazy.lua sets `defaults = { lazy = false }`, but a spec that
-- carries `keys` overrides that default: measured, the live shape reports
-- plugins["oil.nvim"].lazy == true at startup. Three facts make eager
-- loading non-negotiable (all measured 2026-08-23, nvim 0.12.4):
--
--   1. Oil installs its `default_file_explorer` hijack inside setup()
--      (oil.nvim/lua/oil/config.lua:4, the option defaults to true), so
--      while the plugin is unloaded it hijacks nothing.
--   2. With netrw disabled and oil lazy, `:e some/dir` opens an ordinary
--      empty buffer named for the directory — filetype empty, one blank
--      line, oil still unloaded. Neither explorer answers.
--   3. That is worse than stock Neovim: with "netrwPlugin" removed from
--      disabled_plugins the same `:e some/dir` gives filetype = netrw and
--      a real listing (netrw v184). So the dead end is this config's
--      doing, not Neovim's, and this config has to undo it.
--
-- The cost is bounded and small: lazy reports oil's load at 3.0-3.6 ms at
-- startup (`_.loaded.time`, three runs). Same trade 11-colorscheme R1
-- already makes for tinted-nvim — a thing that must be in place before the
-- user's first action cannot be lazy on that action.
--
-- `<leader>e` stays in `keys` and is a BINDING, not a loader. lazy's
-- Handler.setup() runs before Loader.startup(), so it registers a loader
-- stub for the key while oil is unloaded; loading oil eagerly then calls
-- Handler.disable -> keys:_del -> keys:_set, which deletes the stub and
-- sets the real mapping. Read back at startup: rhs = <cmd>Oil<CR>,
-- expr = 0. The lazy shape reads rhs = nil, expr = 1 — same desc, so a
-- desc-only check cannot tell the two apart.
return {
  "stevearc/oil.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  lazy = false,
  opts = {
    view_options = {
      show_hidden = true,
    },
  },
  keys = {
    { "<leader>e", "<cmd>Oil<CR>", desc = "Open file explorer" },
  },
}
