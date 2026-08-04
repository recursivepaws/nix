local mason_bin = require("utils.lsp").mason_bin

vim.lsp.config("dockerls", {
	cmd = { mason_bin .. "docker-langserver", "--stdio" },
	filetypes = { "dockerfile" },
	settings = {},
	workspace_required = false,
})

vim.lsp.enable("dockerls")
