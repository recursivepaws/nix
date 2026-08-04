local mason_bin = require("utils.lsp").mason_bin

vim.lsp.config("awkls", {
	cmd = { mason_bin .. "awk-language-server", "start" },
	filetypes = { "awker" },
	settings = {},
	workspace_required = false,
})

vim.lsp.enable("awkls")
