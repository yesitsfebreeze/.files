-- Colorscheme: tinted-nvim, static Gruvbox Dark Hard. The palette-derived
-- highlights below are re-derived on every colorscheme change.
return {
    "tinted-theming/tinted-nvim",
    priority = 1000,
    lazy = false,
    config = function()
        require("tinted-nvim").setup({
            default_scheme = "base16-gruvbox-dark-hard",
            apply_scheme_on_startup = true,
            ui = { transparent = true },
            highlights = {
                integrations = {
                    blink = true,
                    lualine = true,
                },
            },
        })

        -- Palette-derived highlights, re-derived on every colorscheme change.
        -- Mode-aware cursor: shape per mode, colors pulled from the active base16
        -- palette. Whitespace/NonText use base02 to keep listchars as dim as VS
        -- Code's editorWhitespace.
        local function set_palette_hl()
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
        end
        set_palette_hl()
        vim.api.nvim_create_autocmd("ColorScheme", {
            group = vim.api.nvim_create_augroup("palette_hl", { clear = true }),
            callback = set_palette_hl,
        })

        vim.opt.guicursor = table.concat({
            "a:blinkwait700-blinkon400-blinkoff250",
            "n-c-sm:block-CursorNormal",
            "i-ci-ve:ver25-CursorInsert",
            "v:block-CursorVisual",
            "r-cr-o:hor20-CursorReplace",
        }, ",")
    end,
}
