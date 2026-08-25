
vim.lsp.config("nil", {
	cmd = { "nil", "--stdio" },
	filetypes = { "nix" },
	workspace_required = false,
})

vim.lsp.enable("nil")
