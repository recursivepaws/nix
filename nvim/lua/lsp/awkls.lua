
vim.lsp.config("awkls", {
	cmd = { "awk-language-server", "start" },
	filetypes = { "awk" },
	settings = {},
	workspace_required = false,
})

vim.lsp.enable("awkls")
