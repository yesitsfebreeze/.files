-- §source home/dot_config/nvim/lua/plugins/statusline.lua
-- Statusline. lualine's "auto" theme collapses any base16-* colorscheme to its
-- bundled "base16" theme, which requires the separate nvim-base16 plugin and
-- errors when it is absent. tinted-nvim is not that plugin, so we never let
-- lualine fall back to "auto": we build the theme directly from tinted-nvim's
-- active palette and rebuild it on every ColorScheme event (keeping the
-- statusline in lockstep with tinty). Before the palette is ready, we fall back
-- to lualine's own builtin "gruvbox_dark" theme (a real theme file, no
-- nvim-base16 dependency), so the base16 lualine theme is never requested.
local fallback_theme = "gruvbox_dark"

return {
    {
        "nvim-lualine/lualine.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        event = "VeryLazy",
        opts = {
            options = {
                globalstatus = true,
                component_separators = "",
                section_separators = { left = "", right = "" },
            },
            sections = {
                lualine_a = { "mode" },
                lualine_b = { "branch", "diff", "diagnostics" },
                lualine_c = { { "filename", path = 1 } },
                lualine_x = { "encoding", "fileformat", "filetype" },
                lualine_y = { "progress" },
                lualine_z = { "location" },
            },
        },
        config = function(_, opts)
            local function lualine_theme()
                
-- §.splinter/home/dot_config/nvim/lua/plugins/statusline/lualine_theme.fs

            end
            opts.options.theme = lualine_theme()
            require("lualine").setup(opts)
            vim.api.nvim_create_autocmd("ColorScheme", {
                group = vim.api.nvim_create_augroup("lualine_tinty", { clear = true }),
                callback = function()
                    opts.options.theme = lualine_theme()
                    require("lualine").setup(opts)
                end,
            })
        end,
    },
}
