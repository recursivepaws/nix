local mason_bin = require("utils.lsp").mason_bin

vim.lsp.config("nil", {
	cmd = { mason_bin .. "nil", "--stdio" },
	filetypes = { "nix" },
	workspace_required = false,
})

vim.lsp.enable("nil")
