
vim.lsp.config("sqls", {
	cmd = { "sqls" },
	filetypes = {
		"sql",
	},
	root_markers = {
		".git",
	},
	workspace_required = false,
})

-- vim.lsp.enable("sqls")
