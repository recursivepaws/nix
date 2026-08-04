local mason_bin = require("utils.lsp").mason_bin

vim.lsp.config("zls", {
	cmd = { mason_bin .. "zls" },
	filetypes = { "zig" },
	workspace_required = false,
})

vim.lsp.enable("zls")
