
vim.lsp.config("html", {
	cmd = { "vscode-html-language-server", "--stdio" },
	filetypes = {
		"htmlangular",
		"html",
		"templ",
	},
})

vim.lsp.enable("html")
