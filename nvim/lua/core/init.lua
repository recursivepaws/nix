local modules = {
	"core.editor",
	"core.pluginsInit",
	"core.commands",
	"lsp",
	"core.mappings",
}

vim.opt.runtimepath:prepend(require("nix-paths")["lazy.nvim"])

-- set up cosmicnvim
for _, mod in ipairs(modules) do
	local ok, err = pcall(require, mod)
	if not ok then
		error(("Error loading %s...\n\n%s"):format(mod, err))
	end
end
