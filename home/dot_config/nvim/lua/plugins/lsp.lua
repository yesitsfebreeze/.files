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
      -- CONSTRAINT: mason must NEVER refresh its registry on its own.
      -- `registry_cache.refresh` is mason's own setting (lua/mason/settings.lua,
      -- @since 2.3.0; the pinned mason is v2.3.1 / 2a6940a, so the key is
      -- live). With it false, mason-registry's refresh() returns
      -- callback(true, {}) without touching mason-registry.installer and NO
      -- curl is spawned at all — measured 2026-08-24: zero network attempts on
      -- a launch that loads this file, against four on the default (curl and
      -- wget against both endpoints).
      --
      -- THE REASON IS A DISCARDED WRITE, not politeness.
      -- mason-lspconfig.setup() calls mason-registry.refresh() on every launch.
      -- When the fetch's on_spawn handler (mason-core/fetch.lua:134, wrapped in
      -- a.scope) shuts down the stdin pipe of a curl that has ALREADY EXITED,
      -- uv.shutdown fails with ENOTCONN and a.scope re-raises it with
      -- error(err, 0) from inside a libuv callback — which propagates out of
      -- WHATEVER BLOCKING CALL IS PUMPING THE LOOP at that instant. A
      -- BufWritePre consumer that pumps the loop (conform's format_lines_sync
      -- is one) therefore loses its write: the buffer is not written and the
      -- file stays byte-identical, which is data loss on a laptop that woke up
      -- on a train. Not fetching a catalogue at launch removes the promise, so
      -- there is nothing left to reject into anyone's save.
      -- See 00-delivery/corrections/offline-launch-eats-first-save.
      --
      -- TWO OTHER CANDIDATES WERE TRIED FIRST AND BOTH FAILED, which is why
      -- this is a setting and not a pcall: seeding <data>/mason/registries
      -- still aborted 5/5, 4/4 and 6/6, and draining the pending work under
      -- pcall before the write aborted 1/6 and then 3/6. A pcall at one call
      -- site fixes one victim at a time and was excluded on the same grounds —
      -- any BufWritePre consumer that pumps the loop inherits this.
      --
      -- WHAT IT COSTS, measured 2026-08-24 and real. A machine with an empty
      -- <data>/mason never bootstraps its catalogue on its own: online with the
      -- default, registries/github/mason-org/mason-registry/registry.json
      -- appears (536 KB); with this, nothing under <data>/mason is created, and
      -- ensure_installed below cannot resolve a server it cannot look up. And
      -- the catalogue then goes stale until it is refreshed by hand. Both are
      -- recoverable with ONE command; a discarded save is not.
      --
      -- :MasonUpdate IS THE DELIBERATE REFRESH, and mason's networking is not
      -- broken. Measured offline on a cold root, :MasonUpdate raised the
      -- network-attempt count from 0 to 2; measured online on a cold root it
      -- installed the registry and has_package("pyright") came back true
      -- afterwards. tests/nvim-lsp.sh --headless asserts that pair, because a
      -- zero-attempt check on its own passes just as well on a mason that is
      -- entirely broken.
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
