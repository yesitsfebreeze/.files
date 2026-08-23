local opt = vim.opt

-- Leader must be set before lazy/plugins load.
vim.g.mapleader = " "
vim.g.maplocalleader = " "

opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.signcolumn = "yes"
opt.termguicolors = true
-- scrolloff is a minimum distance from the window edge, not a centering
-- command: 999 keeps the cursor line centered everywhere except the first
-- and last half-screen of the buffer, where there is nothing left to
-- scroll and the cursor walks to the edge (correction M-1).
opt.scrolloff = 999
opt.sidescrolloff = 8
opt.wrap = false
opt.showmode = false
opt.splitright = true
opt.splitbelow = true
opt.cmdheight = 1
opt.pumheight = 10

opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.softtabstop = 2
opt.smartindent = true
opt.breakindent = true

opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = false
opt.incsearch = true

opt.swapfile = false
opt.backup = false
opt.undofile = true
opt.updatetime = 250
opt.timeoutlen = 400

opt.clipboard = "unnamedplus"
opt.mouse = "a"
opt.completeopt = "menu,menuone,noselect"
opt.virtualedit = "block"
opt.fillchars = { eob = " " }
-- Mirror VS Code's renderWhitespace=boundary: multispace (not space) puts
-- dots only on runs of 2+ spaces (single spaces stay clean), tab as right
-- arrow, enter sign at eol.
opt.list = true
opt.listchars = { eol = "↵", tab = "→ ", multispace = "·", trail = "·", nbsp = "␣" }

opt.laststatus = 3

-- Servers like rust-analyzer can spam stderr in a tight loop; nvim mirrors
-- every line into ~/.local/state/nvim/lsp.log with no rotation (once grew to 17GB).
vim.lsp.log.set_level(vim.log.levels.OFF)
