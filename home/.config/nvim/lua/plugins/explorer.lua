-- lua/plugins/explorer.lua
-- Why this file is shaped the way it is:
--   manual → internals/neovim

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
