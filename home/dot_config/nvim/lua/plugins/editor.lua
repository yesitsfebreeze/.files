-- Smaller editor quality-of-life plugins.
-- Note: line/block commenting (gc, gcc, gc{motion}) is built into Neovim 0.10+,
-- so no Comment.nvim plugin is needed.
return {
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

    {
        "windwp/nvim-autopairs",
        event = "InsertEnter",
        config = true,
    },

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
