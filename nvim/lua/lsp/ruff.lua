local mason_bin = require("utils.lsp").mason_bin

vim.lsp.config("ruff", {
	cmd = { mason_bin .. "ruff", "server" },
	filetypes = {
		"python",
	},

	settings = {},
})

vim.lsp.enable("ruff")
