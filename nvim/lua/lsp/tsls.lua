
vim.lsp.config("tsls", {
	cmd = { "typescript-language-server", "--stdio" },
	filetypes = {
		"typescript",
		"typescriptreact",
		"typescript.tsx",
		"typescript.tsx",
	},
	root_markers = {
		-- "tsconfig.json",
		".git",
	},
})

vim.lsp.enable("tsls")
