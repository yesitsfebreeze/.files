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

      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("lsp_attach", { clear = true }),
        callback = function(event)
          local function bmap(keys, fn, desc)
            vim.keymap.set("n", keys, fn, { buffer = event.buf, desc = "LSP: " .. desc })
          end
          bmap("gd", vim.lsp.buf.definition, "Goto definition")
          bmap("gI", vim.lsp.buf.implementation, "Goto implementation")
          bmap("<leader>rn", vim.lsp.buf.rename, "Rename")
          bmap("<leader>ca", vim.lsp.buf.code_action, "Code action")
        end,
      })

      vim.lsp.config("*", {
        capabilities = require("blink.cmp").get_lsp_capabilities(),
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
