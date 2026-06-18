-- Colorscheme: tinted-nvim, driven by tinty. The shell `theme` switcher runs
-- `tinty apply`, which writes the active base16 scheme name to
-- ~/.local/share/tinted-theming/tinty/current_scheme. The file selector below
-- watches that file and re-themes nvim live. default_scheme is the gruvbox
-- fallback before any tinty pick.
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
            selector = {
                enabled = true,
                mode = "file",
                path = "~/.local/share/tinted-theming/tinty/current_scheme",
                watch = true,
            },
        })

        -- Mode-aware cursor: shape per mode, colors pulled from the active base16
        -- palette so the cursor signals the mode and follows the theme. Re-derived
        -- on every colorscheme change, including live tinty switches.
        local function set_cursor_hl()
            local ok, tn = pcall(require, "tinted-nvim")
            if not ok then return end
            local p = tn.get_palette()
            if not p then return end
            vim.api.nvim_set_hl(0, "CursorNormal", { bg = p.base0D }) -- blue
            vim.api.nvim_set_hl(0, "CursorInsert", { bg = p.base0B }) -- green
            vim.api.nvim_set_hl(0, "CursorVisual", { bg = p.base0E }) -- magenta
            vim.api.nvim_set_hl(0, "CursorReplace", { bg = p.base08 }) -- red
        end
        set_cursor_hl()
        vim.api.nvim_create_autocmd("ColorScheme", {
            group = vim.api.nvim_create_augroup("mode_cursor_hl", { clear = true }),
            callback = set_cursor_hl,
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
