local mason_bin = require("utils.lsp").mason_bin

vim.lsp.config("gqlls", {
	cmd = { mason_bin .. "graphql-language-service-cli", "start" },
	filetypes = { "graphql" },
	settings = {},
	workspace_required = false,
})

vim.lsp.enable("gqlls")
