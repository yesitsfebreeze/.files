-- TODO:
-- telescope, lsp, treesitter
-- line number -> git color
-- copilot??


-- this is semi akward
-- lua doesnt know about vim types, so making shortcuts for commonly used ones
-- reduces the clutter and the warnings.
local g = vim.g
local o = vim.opt
local ol = vim.opt_local
local km = vim.keymap.set
local ac = vim.api.nvim_create_autocmd
local cmd = vim.cmd
local sch = vim.schedule
local api = vim.api
local fn = vim.fn
local usrcmd = vim.api.nvim_create_user_command
local notify = vim.notify
local loop = vim.loop
local bo = vim.bo

-- bootstrap mini.nvim package manager
local path_package = fn.stdpath('data') .. '/site/'
local mini_path = path_package .. 'pack/deps/start/mini.nvim'
if not loop.fs_stat(mini_path) then
	cmd('echo "Installing `mini.nvim`" | redraw')
	local clone_cmd = {
		'git', 'clone', '--filter=blob:none',
		'https://github.com/nvim-mini/mini.nvim', mini_path
	}
	fn.system(clone_cmd)
	cmd('packadd mini.nvim | helptags ALL')
	cmd('echo "Installed `mini.nvim`" | redraw')
end

require('mini.deps').setup({ path = { package = path_package } })
local add = MiniDeps.add

g.mapleader = ' '
g.maplocalleader = ' '
o.winborder = 'rounded'
o.number = true
o.wrap = false
o.mouse = 'a'
o.clipboard = 'unnamedplus'
o.ignorecase = true
o.smartcase = true
o.signcolumn = 'yes'
o.splitright = true
o.splitbelow = true
o.updatetime = 200
o.timeoutlen = 400
o.termguicolors = true
o.cursorline = false
o.undodir = os.getenv('HOME') .. '/.vim/undodir'
o.swapfile = false
o.ignorecase = true

-- indent
o.expandtab = false
o.tabstop = 2
o.shiftwidth = 2
o.softtabstop = 0
o.smartindent = true

o.list = true
o.listchars = {
	multispace = '•',
	tab = '→ ',
	eol = '¬',
	trail = '•',
	extends = '<',
	precedes = '>'
}


local plugins = {
	'vague-theme/vague.nvim',
	'mhinz/vim-startify',
	'MunifTanjim/nui.nvim',
	'rcarriga/nvim-notify',
	'folke/noice.nvim',
	'stevearc/oil.nvim',
	'nvim-tree/nvim-web-devicons',
	'nvim-lualine/lualine.nvim',
	'nullromo/go-up.nvim'
}

for _, plugin in ipairs(plugins) do
	add({ source = 'https://github.com/' .. plugin })
end

-- Load theme colors exported by WezTerm
local theme_ok, theme = pcall(require, 'theme_colors')
if not theme_ok then
	theme = {
		bg = '#131719',
		fg = '#C0CCDB',
		black = '#101010',
		red = '#f5a191',
		green = '#90b99f',
		yellow = '#e6b99d',
		blue = '#aca1cf',
		magenta = '#e29eca',
		cyan = '#ea83a5',
		white = '#a0a0a0',
		bright_black = '#7e7e7e',
		bright_red = '#ff8080',
		bright_green = '#99ffe4',
		bright_yellow = '#ffc799',
		bright_blue = '#b9aeda',
		bright_magenta = '#ecaad6',
		bright_cyan = '#f591b2',
		bright_white = '#ffffff',
	}
end

-- Set terminal colors from theme
if theme.ansi then
	for i, color in ipairs(theme.ansi) do
		g['terminal_color_' .. (i - 1)] = color
	end
end
if theme.brights then
	for i, color in ipairs(theme.brights) do
		g['terminal_color_' .. (i + 7)] = color
	end
end

require('vague').setup({
	transparent = true,
	bold = true,
	italic = false,
	colors = {
		bg          = theme.bg,
		inactiveBg  = theme.bg,
		fg          = theme.fg,
		line        = theme.bright_black,
		floatBorder = theme.bright_black,
		visual      = theme.cyan,
		search      = theme.yellow,
		comment     = theme.bright_black,
		string      = theme.green,
		number      = theme.cyan,
		constant    = theme.yellow,
		builtin     = theme.yellow,
		keyword     = theme.red,
		operator    = theme.bright_black,
		type        = theme.blue,
		func        = theme.cyan,
		parameter   = theme.fg,
		property    = theme.green,
		error       = theme.red,
		warning     = theme.yellow,
		hint        = theme.magenta,
		plus        = theme.green,
		delta       = theme.yellow,
	},
})
cmd('colorscheme vague')


-- cursor
api.nvim_set_hl(0, 'CUR_INSERT', { fg = '#000000', bg = '#ffc888' })
api.nvim_set_hl(0, 'CUR_NORMAL', { fg = '#000000', bg = '#43b5b3' })

local blink = '-blinkwait10-blinkon100-blinkoff100'
o.guicursor = table.concat({
	'i-v-ci-ve:block-CUR_INSERT' .. blink, -- insert-like modes
	'n-c-sm:block-CUR_NORMAL' .. blink,    -- normal / visual / command
	'r-cr-o:block-CUR_NORMAL' .. blink,    -- replace / operator-pending etc
}, ',')

require('notify').setup({ background_colour = '#000000' })
require('noice').setup()
require('oil').setup({
	view_options = {
		show_hidden = true,
	},
})


local gup = require("go-up")
gup.setup({
	respectScrolloff = true,
	goUpLimit = nil,
})
ac({ "CursorMoved", "CursorMovedI" }, { callback = function() gup.centerScreen() end })
ac("BufWinEnter", { callback = function() gup.centerScreen() end })

ac('FileType', {
	pattern = 'oil',
	callback = function()
		cmd('stopinsert')
	end,
})

-- this is prolly a hot take, but i like to be in insery mode by default
-- and only switch to normal mode when i explicitly want to
-- this is the code for it, hate me or dont, idc

-- used to switch to normal mode,
-- i remapped that in my keyboard
g.normal_key = '<F24>'
o.virtualedit = 'onemore'
o.selectmode = 'key'
o.keymodel:append({ 'startsel', 'stopsel' })

g.invert_mode = false



local function on_buffer_enter()
	gup.centerScreen()
	if can_insert() then
		start_insert()
	end
end

local function on_buffer_exit()
	-- Reset invert_mode so entering a new buffer can auto-insert
	g.invert_mode = false
end

ac('BufEnter', { callback = on_buffer_enter })
ac('BufLeave', { callback = on_buffer_exit })


local function can_insert(buf)
	buf = buf or api.nvim_get_current_buf()
	if bo[buf].buftype ~= '' then return false end
	if not bo[buf].modifiable then return false end
	if bo[buf].readonly then return false end
	return true
end

local function start_insert()
	if g.invert_mode then return end
	if not can_insert() then return end

	-- Save cursor position before starting insert
	local pos = api.nvim_win_get_cursor(0)
	cmd('startinsert')
	-- Restore cursor position to prevent forward jump
	sch(function()
		api.nvim_win_set_cursor(0, pos)
	end)
	ol.relativenumber = false
end

local function to_normal()
	g.invert_mode = true
	-- Save position and compensate for stopinsert's leftward movement
	local pos = api.nvim_win_get_cursor(0)
	cmd('stopinsert')
	-- Schedule to run after mode change completes
	sch(function()
		-- Move one column right to compensate
		api.nvim_win_set_cursor(0, {pos[1], pos[2] })
	end)
	ol.relativenumber = true
end

ac('VimEnter',	 { callback = start_insert })
ac('InsertLeave',	{ callback = function() sch(start_insert) end })
ac('InsertEnter',	{ callback = function()
	g.invert_mode = false
	ol.relativenumber = false
end })

for _, k in ipairs({ '<Esc>', '<C-[>', '<C-c>' }) do
	km('i', k, '<NOP>', { noremap = true })
end

km({ 'i', 'v' }, g.normal_key, to_normal, { noremap = true, silent = true })

km('i', '<C-Space>', to_normal, { noremap = true, silent = true })
km('n', '<Esc>', function()
	local pos = api.nvim_win_get_cursor(0)
	cmd('startinsert')
	sch(function()
		api.nvim_win_set_cursor(0, pos)
	end)
end, { noremap = true })

-- tap normal key twice to enter command mode
km('n', g.normal_key, function()
 api.nvim_feedkeys(':', 'n', false)
end, { noremap = true, silent = true })
km('c', g.normal_key, '<Ignore>', { noremap = true })


km('n', 'rlc', function()
	cmd('update')
	cmd('source ' .. fn.stdpath('config') .. '/init.lua')
	notify('Config reloaded')
end, { noremap = true, silent = true })

-- km('n', '<leader>q', ':q!<CR>')

km({ 'n', 'v' }, '<C-c>', '+y', { silent = true })
km({ 'n', 'v' }, '<C-v>', '+p', { silent = true })
km('i', '<C-v>', '<C-r>+', { silent = true })

km('i', '<S-Del>', '<Esc>ddi', { silent = true })
km('i', '<S-Tab>', '<C-d>', { silent = true })

km({ 'n', 'i', 'v' }, '<C-z>', '<cmd>undo<CR>', { silent = true })
km({ 'n', 'i', 'v' }, '<C-S-z>', '<cmd>redo<CR>', { silent = true })


-- user commands
usrcmd('Q', 'q!', {})

-- Theme switcher command
usrcmd('ThemeSwitch', function()
	-- Send Ctrl+Shift+T to WezTerm via terminal escape sequence
	-- This triggers the theme picker in WezTerm
	local esc = vim.api.nvim_replace_termcodes('<C-\\><C-N>', true, false, true)
	vim.api.nvim_feedkeys(esc, 'n', false)
	
	-- Send the Ctrl+Shift+T key sequence to terminal
	vim.fn.chansend(vim.b.terminal_job_id or vim.v.stderr, '\x1b[84;6u')
end, {})

km('n', '<C-S-t>', function()
	-- This requires terminal to pass through Ctrl+Shift+T
	-- Most terminals map this already to WezTerm's keybinding
end, { noremap = true, silent = true })
