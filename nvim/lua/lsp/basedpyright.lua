
vim.lsp.config("basedpyright", {
	cmd = { "basedpyright-langserver", "--stdio" },
	filetypes = {
		"python",
	},
	settings = {
		basedpyright = {
			analysis = {
				useLibraryCodeForTypes = true,
				typeCheckingMode = "basic",
				diagnosticMode = "workspace",
				autoSearchPaths = true,
				completeFunctionParens = true,
			},
		},
	},
})

vim.lsp.enable("basedpyright")
