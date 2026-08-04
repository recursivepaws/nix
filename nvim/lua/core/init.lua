local modules = {
	"core.editor",
	"core.pluginsInit",
	"core.commands",
	"lsp",
	"core.mappings",
}

-- set up lazy.nvim to install plugins
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"--single-branch",
		"https://github.com/folke/lazy.nvim.git",
		lazypath,
	})
end
vim.opt.runtimepath:prepend(lazypath)

-- set up cosmicnvim
for _, mod in ipairs(modules) do
	local ok, err = pcall(require, mod)
	if not ok then
		error(("Error loading %s...\n\n%s"):format(mod, err))
	end
end
