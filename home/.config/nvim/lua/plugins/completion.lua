-- lua/plugins/completion.lua
-- Why this file is shaped the way it is:
--   manual → internals/neovim

return {
  "saghen/blink.cmp",
  event = "InsertEnter",
  version = "1.*", -- tagged release so the prebuilt rust fuzzy lib is fetched
  dependencies = { "rafamadriz/friendly-snippets" },
  opts = {
    -- Esc is the editor's mode gesture in pickers and prompts, and
    -- blink's buffer-local Esc would swallow it before the editor map.
    enabled = function()
      return vim.bo.buftype ~= "prompt" and vim.bo.buftype ~= "nofile"
    end,
    keymap = {
      preset = "super-tab",
      ["<CR>"] = { "accept", "fallback" },
      ["<Esc>"] = { "cancel" },
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
