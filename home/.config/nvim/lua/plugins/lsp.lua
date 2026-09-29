-- lua/plugins/lsp.lua
-- Why this file is shaped the way it is:
--   manual → internals/neovim

return {
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      { "mason-org/mason.nvim", opts = { registry_cache = { refresh = false } } },
      "mason-org/mason-lspconfig.nvim",
      "saghen/blink.cmp",
    },
    config = function()
      vim.diagnostic.config({
        virtual_text = { prefix = "●" },
        severity_sort = true,
        float = { border = "rounded", source = true },
      })

      vim.lsp.config("*", {
        capabilities = require("blink.cmp").get_lsp_capabilities(),
      })

      -- Its own target directory, deliberately: with the default, the editor's
      -- cargo check takes the same lock every terminal build in the tree is
      -- waiting on, and one open buffer stalls every other session's build.
      vim.lsp.config("rust_analyzer", {
        settings = { ["rust-analyzer"] = { cargo = { targetDir = true } } },
      })

      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            diagnostics = { globals = { "vim" } },
            workspace = { checkThirdParty = false },
            telemetry = { enable = false },
          },
        },
      })

      require("mason-lspconfig").setup({
        ensure_installed = { "lua_ls", "bashls", "pyright", "rust_analyzer", "tailwindcss" },
      })
    end,
  },
}
