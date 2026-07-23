-- §source home/dot_config/nvim/lua/plugins/completion.lua
-- Completion: blink.cmp — one batteries-included engine (LSP, snippets, path,
-- buffer, signature help, fuzzy matching) replacing the nvim-cmp + LuaSnip +
-- cmp-* stack. Faster per-keystroke and far fewer plugins.
return {
    "saghen/blink.cmp",
    event = "InsertEnter",
    version = "1.*", -- tagged release so the prebuilt rust fuzzy lib is fetched
    dependencies = { "rafamadriz/friendly-snippets" },
    opts = {
        -- super-tab: <Tab> selects/accepts and jumps snippets, <S-Tab> reverses,
        -- <C-n>/<C-p> cycle, <C-Space> toggles, <C-e> hides. Closest to the old
        -- nvim-cmp Tab-driven flow.
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
