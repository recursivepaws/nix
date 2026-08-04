local mason_bin = require("utils.lsp").mason_bin

vim.lsp.config("basedpyright", {
	cmd = { mason_bin .. "basedpyright-langserver", "--stdio" },
	filetypes = {
		"python",
	},
	settings = {
		basedpyright = {
			analysis = {
				useLibraryCodeForTypes = true,
				typeCheckingMode = "basic",
				diagnosticMode = "workspace",
				autoSearchPaths = true,
				completeFunctionParens = true,
			},
		},
	},
})

vim.lsp.enable("basedpyright")
