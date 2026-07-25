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
                { "<leader>t", group = "table" },
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
                -- prettier aligns markdown table pipes and normalizes lists;
                -- prose stays unwrapped (proseWrap defaults to "preserve").
                markdown = { "prettier" },
                ["markdown.mdx"] = { "prettier" },
            },
            format_on_save = { timeout_ms = 500, lsp_format = "fallback" },
        },
    },

    -- Live table alignment while typing: pipes realign on every `|` in insert mode.
    {
        "dhruvasagar/vim-table-mode",
        ft = { "markdown", "markdown.mdx" },
        cmd = { "TableModeToggle", "TableModeEnable", "TableModeRealign", "Tableize" },
        init = function()
            -- GitHub-flavored corners: `|` instead of vim-table-mode's default `+`.
            vim.g.table_mode_corner = "|"
            vim.g.table_mode_map_prefix = "<leader>t"
        end,
        config = function()
            local function enable()
                vim.cmd("silent! TableModeEnable")
            end
            vim.api.nvim_create_autocmd("FileType", {
                pattern = { "markdown", "markdown.mdx" },
                callback = enable,
            })
            -- The FileType event that lazy-loaded us already fired for this buffer.
            enable()
        end,
    },
}
