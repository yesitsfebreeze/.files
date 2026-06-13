-- Core editor options.
local opt = vim.opt

-- Leader must be set before lazy/plugins load.
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- UI
opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.signcolumn = "yes"
opt.termguicolors = true
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.wrap = false
opt.showmode = false
opt.splitright = true
opt.splitbelow = true
opt.cmdheight = 1
opt.pumheight = 10

-- Indentation
opt.expandtab = true
opt.shiftwidth = 4
opt.tabstop = 4
opt.softtabstop = 4
opt.smartindent = true
opt.breakindent = true

-- Search
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = false
opt.incsearch = true

-- Files / undo
opt.swapfile = false
opt.backup = false
opt.undofile = true
opt.updatetime = 250
opt.timeoutlen = 400

-- Editing
opt.clipboard = "unnamedplus"
opt.mouse = "a"
opt.completeopt = "menu,menuone,noselect"
opt.virtualedit = "block"
opt.fillchars = { eob = " " }
opt.list = true
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- Use a Nerd-Font-aware split UI
opt.laststatus = 3
