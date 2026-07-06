local opt = vim.opt

-- Leader must be set before lazy/plugins load.
vim.g.mapleader = " "
vim.g.maplocalleader = " "

opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.signcolumn = "yes"
opt.termguicolors = true
opt.scrolloff = 999       -- keep the cursor line vertically centered
opt.sidescrolloff = 8
opt.wrap = false
opt.showmode = false
opt.splitright = true
opt.splitbelow = true
opt.cmdheight = 1
opt.pumheight = 10

opt.expandtab = true
opt.shiftwidth = 4
opt.tabstop = 4
opt.softtabstop = 4
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
-- Mirror VS Code's renderWhitespace=boundary: dots on runs of 2+ spaces
-- (single spaces stay clean), tab as right arrow, enter sign at eol.
opt.list = true
opt.listchars = { eol = "↵", tab = "→ ", multispace = "·", trail = "·", nbsp = "␣" }

opt.laststatus = 3
