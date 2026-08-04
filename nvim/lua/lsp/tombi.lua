local mason_bin = require("utils.lsp").mason_bin

vim.lsp.config("tombi", {
	cmd = { mason_bin .. "tombi", "lsp" },
	filetypes = { "toml" },
	settings = {},
	workspace_required = false,
})

vim.lsp.enable("tombi")
