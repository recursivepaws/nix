
vim.lsp.config("ruff", {
	cmd = { "ruff", "server" },
	filetypes = {
		"python",
	},

	settings = {},
})

vim.lsp.enable("ruff")
