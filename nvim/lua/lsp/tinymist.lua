
vim.lsp.config("tinymist", {
	cmd = { "tinymist" },
	filetypes = { "typst" },
	settings = {},
	workspace_required = false,
})

vim.lsp.enable("tinymist")
