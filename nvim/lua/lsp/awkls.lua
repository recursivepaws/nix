
vim.lsp.config("awkls", {
	cmd = { "awk-language-server", "start" },
	filetypes = { "awker" },
	settings = {},
	workspace_required = false,
})

vim.lsp.enable("awkls")
