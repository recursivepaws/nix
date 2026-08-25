
vim.lsp.config("gqlls", {
	cmd = { "graphql-language-service-cli", "start" },
	filetypes = { "graphql" },
	settings = {},
	workspace_required = false,
})

vim.lsp.enable("gqlls")
