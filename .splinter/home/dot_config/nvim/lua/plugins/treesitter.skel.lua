-- §source home/dot_config/nvim/lua/plugins/treesitter.lua
return {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
        require("nvim-treesitter").setup({})
        require("nvim-treesitter").install({
            "odin",
            "bash",
            "c",
            "lua",
            "luadoc",
            "markdown",
            "markdown_inline",
            "nu",
            "python",
            "query",
            "rust",
            "toml",
            "vim",
            "vimdoc",
            "yaml",
            "json",
        })
        local function attach(buf)
            
-- §.splinter/home/dot_config/nvim/lua/plugins/treesitter/attach.fs

        end
        vim.api.nvim_create_autocmd("FileType", {
            callback = function(ev)
                attach(ev.buf)
            end,
        })
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            if vim.api.nvim_buf_is_loaded(buf) then
                attach(buf)
            end
        end
    end,
}
