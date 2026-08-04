local mason_bin = require("utils.lsp").mason_bin

vim.lsp.config("wgsl", {
	cmd = { mason_bin .. "wgsl-analyzer" },
	filetypes = { "wgsl", "vert", "frag" },
	init_options = {
		provideFormatter = true,
	},
	settings = {},
	workspace_required = false,
})

vim.lsp.enable("wgsl")
