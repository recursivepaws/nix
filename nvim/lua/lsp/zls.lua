
vim.lsp.config("zls", {
	cmd = { "zls" },
	filetypes = { "zig" },
	workspace_required = false,
})

vim.lsp.enable("zls")
