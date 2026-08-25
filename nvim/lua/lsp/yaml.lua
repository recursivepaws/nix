
vim.lsp.config("yaml", {
	cmd = { "yaml-language-server", "--stdio" },
	filetypes = { "yaml" },
	settings = {
		-- https://github.com/redhat-developer/vscode-redhat-telemetry#how-to-disable-telemetry-reporting
		redhat = { telemetry = { enabled = false } },
	},
	workspace_required = false,
})

vim.lsp.enable("yaml")
