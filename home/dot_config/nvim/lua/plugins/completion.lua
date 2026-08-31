-- lua/plugins/completion.lua
-- Why this file is shaped the way it is:
--   docs-site → Internals → Neovim

return {
  "saghen/blink.cmp",
  event = "InsertEnter",
  version = "1.*", -- tagged release so the prebuilt rust fuzzy lib is fetched
  dependencies = { "rafamadriz/friendly-snippets" },
  opts = {
    keymap = {
      preset = "super-tab",
      ["<CR>"] = { "accept", "fallback" },
      ["<Esc>"] = { "cancel", "fallback" },
    },
    appearance = { nerd_font_variant = "mono" },
    completion = {
      documentation = { auto_show = true, auto_show_delay_ms = 200 },
    },
    sources = {
      default = { "lsp", "snippets", "path", "buffer" },
    },
    signature = { enabled = true },
    fuzzy = { implementation = "prefer_rust_with_warning" },
  },
  opts_extend = { "sources.default" },
}
