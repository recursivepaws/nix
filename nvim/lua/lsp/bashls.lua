
vim.lsp.config("bashls", {
	cmd = { "bash-language-server", "start" },
	filetypes = { "sh", "zsh" },
	settings = {},
	workspace_required = false,
})

vim.lsp.enable("bashls")
