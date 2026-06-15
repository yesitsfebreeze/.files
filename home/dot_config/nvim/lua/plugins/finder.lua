-- finder.nvim — composable, chainable fuzzy finder (your own plugin). Replaces
-- telescope: pipe Files -> Grep -> Commits, etc. It themes itself from the
-- active colorscheme's highlight groups, so it follows tinty automatically.
-- Depends on space.nvim for its floating UI.
return {
    "yesitsfebreeze/finder.nvim",
    dependencies = { "yesitsfebreeze/space.nvim" },
    cmd = "Finder",
    keys = {
        { "<leader>ff", "<cmd>Finder<CR>", desc = "Finder" },
        { "<leader><space>", "<cmd>Finder<CR>", desc = "Finder" },
    },
    config = function()
        require("finder").setup({})
    end,
}
