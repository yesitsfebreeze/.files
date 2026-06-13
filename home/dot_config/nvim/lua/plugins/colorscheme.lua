-- Catppuccin Mocha — the editor half of the unified theme.
return {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    lazy = false,
    opts = {
        flavour = "mocha",
        transparent_background = false,
        term_colors = true,
        integrations = {
            cmp = true,
            gitsigns = true,
            treesitter = true,
            telescope = true,
            which_key = true,
            mason = true,
            native_lsp = { enabled = true },
            neotree = true,
        },
    },
    config = function(_, opts)
        require("catppuccin").setup(opts)
        vim.cmd.colorscheme("catppuccin")
    end,
}
