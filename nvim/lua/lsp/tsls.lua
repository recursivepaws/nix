local mason_bin = require("utils.lsp").mason_bin

vim.lsp.config("tsls", {
	cmd = { mason_bin .. "typescript-language-server", "--stdio" },
	filetypes = {
		"typescript",
		"typescriptreact",
		"typescript.tsx",
		"typescript.tsx",
	},
	root_markers = {
		-- "tsconfig.json",
		".git",
	},
})

vim.lsp.enable("tsls")
