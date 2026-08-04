local mason_bin = require("utils.lsp").mason_bin

vim.lsp.config("sqls", {
	cmd = { mason_bin .. "sqls" },
	filetypes = {
		"sql",
	},
	root_markers = {
		".git",
	},
	workspace_required = false,
})

-- vim.lsp.enable("sqls")
