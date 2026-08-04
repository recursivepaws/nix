local mason_bin = require("utils.lsp").mason_bin

vim.lsp.config("tinymist", {
	cmd = { mason_bin .. "tinymist" },
	filetypes = { "typst" },
	settings = {},
	workspace_required = false,
})

vim.lsp.enable("tinymist")
