-- §source home/dot_config/nvim/lua/plugins/explorer.lua
return {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-tree/nvim-web-devicons",
        "MunifTanjim/nui.nvim",
    },
    cmd = "Neotree",
    keys = {
        { "<leader>e", "<cmd>Neotree toggle<CR>", desc = "Toggle file explorer" },
        { "<leader>o", "<cmd>Neotree focus<CR>", desc = "Focus file explorer" },
    },
    opts = {
        close_if_last_window = true,
        filesystem = {
            follow_current_file = { enabled = true },
            use_libuv_file_watcher = true,
            filtered_items = {
                hide_dotfiles = false,
                hide_gitignored = true,
            },
        },
        window = {
            width = 32,
            mappings = {
                ["<space>"] = "none",
            },
        },
    },
}
