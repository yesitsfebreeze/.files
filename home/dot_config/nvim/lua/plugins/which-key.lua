-- lua/plugins/which-key.lua
-- Why this file is shaped the way it is:
--   manual → internals/neovim

return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    spec = {
      { "<leader>f", group = "find" },
      { "<leader>b", group = "buffer" },
      { "<leader>c", group = "code" },
      { "<leader>r", group = "rename/refactor" },
      { "<leader>t", group = "table" },
      { "<leader>s", group = "session" },
    },
  },
}
