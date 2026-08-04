local pnpm_or_mason = require("utils.lsp").pnpm_or_mason

vim.lsp.config("biome", {
	cmd = pnpm_or_mason({ "biome", "lsp-proxy" }),
	filetypes = {
		"javascript",
		"javascriptreact",
		"typescript",
		"typescriptreact",
		"json",
	},
	-- Root at VCS root so Biome's `"extends": "//"` in nested configs
	-- (e.g. packages/app/biome.jsonc) resolves to the repo root config.
	-- Biome handles per-file config resolution internally.
	root_markers = { ".git" },
	single_file_support = true,
})

vim.lsp.enable("biome")
