-- General keymaps. Plugin-specific maps live in their plugin specs (keys = ...).
local map = vim.keymap.set

map("n", "<C-h>", "<C-w>h", { desc = "Go to left window" })
map("n", "<C-j>", "<C-w>j", { desc = "Go to lower window" })
map("n", "<C-k>", "<C-w>k", { desc = "Go to upper window" })
map("n", "<C-l>", "<C-w>l", { desc = "Go to right window" })

map("n", "<C-Up>", "<cmd>resize +2<CR>", { desc = "Increase height" })
map("n", "<C-Down>", "<cmd>resize -2<CR>", { desc = "Decrease height" })
map("n", "<C-Left>", "<cmd>vertical resize -2<CR>", { desc = "Decrease width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<CR>", { desc = "Increase width" })

map("n", "<leader>|", "<cmd>vsplit<CR>", { desc = "Split right" })
map("n", "<leader>-", "<cmd>split<CR>", { desc = "Split below" })

map("n", "<S-h>", "<cmd>bprevious<CR>", { desc = "Previous buffer" })
map("n", "<S-l>", "<cmd>bnext<CR>", { desc = "Next buffer" })
map("n", "<leader>bd", "<cmd>bdelete<CR>", { desc = "Delete buffer" })

map("n", "<A-j>", "<cmd>m .+1<CR>==", { desc = "Move line down" })
map("n", "<A-k>", "<cmd>m .-2<CR>==", { desc = "Move line up" })
map("v", "<A-j>", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("v", "<A-k>", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- Keep cursor centered on jumps / search (these maps carry no desc).
--
-- NO DESC ON PURPOSE, and the manual agrees: which-key should not list a key
-- whose behavior is the vim default plus a re-centre, so help/nvim.nuon
-- records these four — and the visual </> pair below — as desc: null. Adding
-- a desc to one of them contradicts the manual.
--
-- Do NOT "simplify" the zz away as redundant under scrolloff = 999
-- (01-options): scrolloff is a minimum distance from the window edge and
-- never scrolls PAST THE END of the buffer, while zz does — so the appended
-- zz is exactly what keeps the last half-screen centered. The zv in nzzzv is
-- the other half: it opens the fold a search match lands in.
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")
map("n", "n", "nzzzv")
map("n", "N", "Nzzzv")

map("v", "<", "<gv")
map("v", ">", ">gv")

map("n", "<leader>w", "<cmd>write<CR>", { desc = "Save" })
map("n", "<leader>q", "<cmd>quit<CR>", { desc = "Quit" })

map("x", "<leader>p", [["_dP]], { desc = "Paste (keep register)" })

-- R9: <C-q> IS LEFT UNBOUND ON PURPOSE. No node in this epic may map it.
--
-- 14-shift-select binds Ctrl+V in VISUAL mode to a register-safe paste,
-- which shadows vim's entry into blockwise-visual from a selection (live bug
-- L-9, ported as decided 2026-08-21). <C-q> is vim's built-in synonym for
-- blockwise-visual and therefore the escape hatch that makes that shadow
-- acceptable: bind it to anything and the hatch closes. Stated here as a
-- comment because an unbound key is invisible to search — nothing else in
-- the tree would stop a later agent from taking it.
