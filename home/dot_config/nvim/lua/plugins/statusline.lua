-- Statusline. lualine's "auto" theme collapses any base16-* colorscheme to its
-- bundled "base16" theme, which requires the separate nvim-base16 plugin and
-- warns when it is absent. tinted-nvim is not that plugin, so instead we build
-- the lualine theme directly from tinted-nvim's active palette and rebuild it on
-- every ColorScheme event, keeping the statusline in lockstep with tinty.
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
                local ok, tn = pcall(require, "tinted-nvim")
                if not ok then return "auto" end
                local p = tn.get_palette()
                if not p then return "auto" end
                local function s(fg, bg) return { fg = fg, bg = bg } end
                local b = s(p.base05, p.base02)
                local c = s(p.base04, p.base01)
                return {
                    normal = { a = s(p.base00, p.base0D), b = b, c = c },
                    insert = { a = s(p.base00, p.base0B), b = b, c = c },
                    visual = { a = s(p.base00, p.base0E), b = b, c = c },
                    replace = { a = s(p.base00, p.base08), b = b, c = c },
                    command = { a = s(p.base00, p.base0A), b = b, c = c },
                    inactive = {
                        a = s(p.base03, p.base01),
                        b = s(p.base03, p.base01),
                        c = s(p.base03, p.base01),
                    },
                }
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
