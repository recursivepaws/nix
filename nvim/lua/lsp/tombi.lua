
vim.lsp.config("tombi", {
	cmd = { "tombi", "lsp" },
	filetypes = { "toml" },
	settings = {},
	workspace_required = false,
})

vim.lsp.enable("tombi")
