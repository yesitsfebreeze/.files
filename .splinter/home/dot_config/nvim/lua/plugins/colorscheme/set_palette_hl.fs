-- §head home/dot_config/nvim/lua/plugins/colorscheme.lua:64-75 set_palette_hl
-- §sig local function set_palette_hl()
local ok, tn = pcall(require, "tinted-nvim")
            if not ok then return end
            local p = tn.get_palette()
            if not p then return end
            vim.api.nvim_set_hl(0, "CursorNormal", { bg = p.base0D }) -- blue
            vim.api.nvim_set_hl(0, "CursorInsert", { bg = p.base0B }) -- green
            vim.api.nvim_set_hl(0, "CursorVisual", { bg = p.base0E }) -- magenta
            vim.api.nvim_set_hl(0, "CursorReplace", { bg = p.base08 }) -- red
            vim.api.nvim_set_hl(0, "Whitespace", { fg = p.base02 })
            vim.api.nvim_set_hl(0, "NonText", { fg = p.base02 })
-- §foot home/dot_config/nvim/lua/plugins/colorscheme.lua set_palette_hl