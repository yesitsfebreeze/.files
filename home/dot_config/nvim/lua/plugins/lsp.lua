-- CONSTRAINT: the LSP log kill-switch is NOT here. lua/config/options.lua
-- turns the LSP log level OFF (01-options R11) and this file must never
-- raise it: Neovim mirrors every LSP stderr line into
-- ~/.local/state/nvim/lsp.log with NO rotation, and a chatty rust-analyzer
-- once grew it to 17 GB. rust_analyzer is in ensure_installed below, so this
-- is exactly the file where turning logging up to debug a server is
-- tempting. Raise it in a scratch probe (tests/nvim-lsp.sh does), never here.
--
-- LSP: mason (server installer, mason-org v2) + Neovim 0.11 native LSP.
-- nvim-lspconfig ships the per-server lsp/*.lua defaults; mason-lspconfig
-- auto-installs and auto-enables them via vim.lsp.enable(). Per-server tweaks
-- and capabilities go through the native vim.lsp.config() API.
return {
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      { "mason-org/mason.nvim", opts = {} },
      "mason-org/mason-lspconfig.nvim",
      "saghen/blink.cmp",
    },
    config = function()
      vim.diagnostic.config({
        virtual_text = { prefix = "●" },
        severity_sort = true,
        float = { border = "rounded", source = true },
      })

      -- Neovim 0.11 ships default LSP maps (grn rename, gra code action,
      -- grr references, gri implementation, gO symbols, K hover) and
      -- diagnostic maps (]d, [d). Add only the extra aliases we want.
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

      -- Capabilities from the completion engine, applied to every server.
      vim.lsp.config("*", {
        capabilities = require("blink.cmp").get_lsp_capabilities(),
      })

      -- Per-server settings (merged over nvim-lspconfig's bundled config).
      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            diagnostics = { globals = { "vim" } },
            workspace = { checkThirdParty = false },
            telemetry = { enable = false },
          },
        },
      })

      -- Install + auto-enable. bashls/pyright/rust_analyzer use defaults.
      -- This call stays LAST in the body: setup() enables the installed
      -- servers synchronously, so a vim.lsp.config call placed after it
      -- would not be merged into the config the first attach reads.
      require("mason-lspconfig").setup({
        ensure_installed = { "lua_ls", "bashls", "pyright", "rust_analyzer", "tailwindcss" },
      })
    end,
  },
}
