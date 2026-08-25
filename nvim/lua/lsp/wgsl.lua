
vim.lsp.config("wgsl", {
	cmd = { "wgsl-analyzer" },
	filetypes = { "wgsl", "glsl" },
	init_options = {
		provideFormatter = true,
	},
	settings = {},
	workspace_required = false,
})

vim.lsp.enable("wgsl")
