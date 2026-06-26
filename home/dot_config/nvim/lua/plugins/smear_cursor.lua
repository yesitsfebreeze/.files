-- Neovide-style trailing smear cursor in the terminal.
return {
    {
        "sphamba/smear-cursor.nvim",
        event = "VeryLazy",
        opts = {
            -- Use built-in Unicode block/diagonal glyphs for a sharper smear.
            legacy_computing_symbols_support = true,
        },
    },
}
