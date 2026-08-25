
vim.lsp.config("dockerls", {
	cmd = { "docker-langserver", "--stdio" },
	filetypes = { "dockerfile" },
	settings = {},
	workspace_required = false,
})

vim.lsp.enable("dockerls")
