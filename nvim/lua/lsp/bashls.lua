local mason_bin = require("utils.lsp").mason_bin

vim.lsp.config("bashls", {
	cmd = { mason_bin .. "bash-language-server", "start" },
	filetypes = { "sh", "zsh" },
	settings = {},
	workspace_required = false,
})

vim.lsp.enable("bashls")
