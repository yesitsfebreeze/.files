-- lua/plugins/session.lua
-- Why this file is shaped the way it is:
--   docs-site → Internals → Neovim

return {
  "folke/persistence.nvim",
  lazy = false,
  opts = {},
  keys = {
    { "<leader>ss", function() require("persistence").load() end, desc = "Restore session for this directory" },
    { "<leader>sl", function() require("persistence").load({ last = true }) end, desc = "Restore last session" },
    { "<leader>sd", function() require("persistence").stop() end, desc = "Stop session save on exit" },
  },
}
