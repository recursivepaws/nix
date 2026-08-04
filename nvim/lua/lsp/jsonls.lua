local mason_bin = require("utils.lsp").mason_bin

vim.lsp.config("jsonls", {
	cmd = { mason_bin .. "vscode-json-language-server", "--stdio" },
	filetypes = { "json", "jsonc" },
	init_options = {
		provideFormatter = true,
	},
	settings = {
		json = {
			format = {
				enable = true,
			},
			validate = { enable = true },
		},
	},
})

vim.lsp.enable("jsonls")
