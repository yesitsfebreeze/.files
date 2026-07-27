return {
    "stevearc/oil.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
        view_options = {
            show_hidden = true,
        },
    },
    keys = {
        { "<leader>e", "<cmd>Oil<CR>", desc = "Open file explorer" },
    },
}
