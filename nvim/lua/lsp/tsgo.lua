local pnpm_or_mason = require("utils.lsp").pnpm_or_mason

vim.lsp.config("tsgo", {
	cmd = pnpm_or_mason({ "tsgo", "--lsp", "-stdio" }),
	filetypes = {
		"javascript",
		"javascriptreact",
		"typescript",
		"typescriptreact",
	},
	root_markers = { "tsconfig.json" },
})

vim.lsp.enable("tsgo")
