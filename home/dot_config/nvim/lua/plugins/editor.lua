-- Smaller editor quality-of-life plugins.
return {
    -- Git signs in the gutter.
    {
        "lewis6991/gitsigns.nvim",
        event = { "BufReadPre", "BufNewFile" },
        opts = {
            signs = {
                add = { text = "▎" },
                change = { text = "▎" },
                delete = { text = "" },
                topdelete = { text = "" },
                changedelete = { text = "▎" },
            },
        },
    },

    -- Keybinding hints.
    {
        "folke/which-key.nvim",
        event = "VeryLazy",
        opts = {
            spec = {
                { "<leader>f", group = "find" },
                { "<leader>b", group = "buffer" },
                { "<leader>c", group = "code" },
                { "<leader>r", group = "rename/refactor" },
            },
        },
    },

    -- Auto-close brackets/quotes.
    {
        "windwp/nvim-autopairs",
        event = "InsertEnter",
        config = true,
    },

    -- Commenting (gcc / gc).
    {
        "numToStr/Comment.nvim",
        event = { "BufReadPost", "BufNewFile" },
        config = true,
    },

    -- Formatting on save.
    {
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
            },
            format_on_save = { timeout_ms = 500, lsp_format = "fallback" },
        },
    },
}
