local pnpm_or_path = require("utils.lsp").pnpm_or_path

vim.lsp.config("tsgo", {
	cmd = pnpm_or_path({ "tsgo", "--lsp", "-stdio" }),
	filetypes = {
		"javascript",
		"javascriptreact",
		"typescript",
		"typescriptreact",
	},
	root_markers = { "tsconfig.json" },
})

vim.lsp.enable("tsgo")
