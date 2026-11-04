-- lua/plugins/which-key.lua
-- Why this file is shaped the way it is:
--   manual → internals/neovim

return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    -- The leader is the editor's exit gesture, so it opens without the
    -- default 200ms pause that which-key gives non-plugin prefixes.
    delay = 0,
    spec = {
      { "<leader>f", group = "find" },
      { "<leader>b", group = "buffer" },
      { "<leader>c", group = "code" },
      { "<leader>r", group = "rename/refactor" },
      { "<leader>t", group = "table" },
      { "<leader>s", group = "session" },
      -- Inside the leader, the exit gestures are leader mappings. They live
      -- in the spec, not an after-the-fact add(): which-key reads this tree
      -- to decide what a key means, and an unknown key is fed back with the
      -- whole prefix, which re-opens the popup and never reaches the
      -- editor's own maps.
      {
        "<leader><F24>",
        function()
          require("which-key.state").stop()
        end,
        desc = "Close the leader, stay in Normal",
        hidden = true,
      },
      {
        "<leader><Esc>",
        function()
          require("which-key.state").stop()
          vim.cmd("startinsert")
        end,
        desc = "Close the leader and return to Insert",
        hidden = true,
      },
    },
  },
}
