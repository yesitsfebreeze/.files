-- lua/plugins/conform.lua
-- Why this file is shaped the way it is:
--   manual → internals/neovim

return {
  "stevearc/conform.nvim",
  event = "BufWritePre",
  cmd = "ConformInfo",
  keys = {
    {
      "<leader>cf",
      function()
        require("conform").format({ async = true, lsp_format = "fallback" })
      end,
      desc = "Format buffer",
    },
  },
  opts = {
    formatters_by_ft = {
      lua = { "stylua" },
      rust = { "rustfmt" },
      python = { "black" },
      markdown = { "prettier" },
    },
    format_on_save = { timeout_ms = 500, lsp_format = "fallback" },
  },
}
