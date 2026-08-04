local cmd = vim.cmd
local opt = vim.opt
local opt_local = vim.opt_local
local g = vim.g
local indent = 2

cmd([[
	filetype plugin indent on
]])

local augroup_name = "MeovvNvimEditor"
local group = vim.api.nvim_create_augroup(augroup_name, { clear = true })
vim.api.nvim_create_autocmd("BufWritePre", {
	command = [[%s/\s\+$//e]],
	group = group,
})

-- Make sure we load the right spacing for web files
vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
	pattern = { "*.js", "*.jsx", "*.tsx", "*.ts" },
	callback = function()
		opt_local.expandtab = true
		opt_local.shiftwidth = 2
		opt_local.tabstop = 2
	end,
})

vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
	pattern = { "*.lua" },
	callback = function()
		opt_local.expandtab = false
	end,
})

g.mapleader = " "

-- misc
opt.backspace = { "eol", "start", "indent" }
opt.clipboard = "unnamedplus"
opt.encoding = "utf-8"
opt.matchpairs = { "(:)", "{:}", "[:]", "<:>" }
opt.syntax = "enable"

-- indention
opt.autoindent = true
opt.expandtab = true
opt.shiftwidth = indent
opt.smartindent = true
opt.softtabstop = indent
opt.tabstop = indent

-- search
opt.hlsearch = true
opt.ignorecase = true
opt.smartcase = true
opt.wildignore = opt.wildignore + { "*/node_modules/*", "*/.git/*", "*/vendor/*" }
opt.wildmenu = true

-- ui
opt.cursorline = true
opt.laststatus = 2
--[[ opt.lazyredraw = true ]]
opt.list = true
opt.listchars = {
	tab = "❘-",
	trail = "·",
	lead = "·",
	extends = "»",
	precedes = "«",
	nbsp = "×",
}
opt.mouse = "a"
opt.number = true
opt.rnu = true
opt.scrolloff = 5
opt.showmode = false
opt.sidescrolloff = 3 -- Lines to scroll horizontally
opt.signcolumn = "yes"
opt.splitbelow = true -- Open new split below
opt.splitright = true -- Open new split to the right
opt.wrap = false

-- backups
opt.backup = false
opt.swapfile = false
opt.writebackup = false

-- autocomplete
opt.completeopt = { "menu", "menuone", "noselect" }
opt.shortmess = opt.shortmess + { c = true }

-- perfomance
opt.redrawtime = 1500
opt.timeoutlen = 200
opt.ttimeoutlen = 10
opt.updatetime = 1000

-- theme
opt.termguicolors = true
