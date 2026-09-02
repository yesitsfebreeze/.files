-- lua/config/options.lua
-- Why this file is shaped the way it is:
--   manual → internals/neovim

local opt = vim.opt

vim.g.mapleader = " "
vim.g.maplocalleader = " "

opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.signcolumn = "yes"
opt.scrolloff = 999
opt.sidescrolloff = 8
opt.wrap = false
opt.showmode = false
opt.splitright = true
opt.splitbelow = true
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

opt.swapfile = false
opt.undofile = true
opt.updatetime = 250
opt.timeoutlen = 400

opt.clipboard = "unnamedplus"
opt.virtualedit = "block"
opt.fillchars = { eob = " " }
opt.list = true
opt.listchars = { eol = "↵", tab = "→ ", multispace = "·", trail = "·", nbsp = "␣" }

opt.laststatus = 3

vim.lsp.log.set_level(vim.log.levels.OFF)
