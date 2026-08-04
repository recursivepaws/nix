vim.api.nvim_create_autocmd("User", {
	pattern = "MasonToolsStartingInstall",
	callback = function()
		vim.schedule(function()
			vim.notify("[mason] Installing Mason tools...", vim.log.levels.INFO)
		end)
	end,
})

return {
	"WhoIsSethDaniel/mason-tool-installer.nvim",
	requires = {
		"mason-org/mason.nvim",
	},
	config = function()
		require("mason-tool-installer").setup({
			run_on_start = true,
			ensure_installed = {
				--- Mental illnesses
				-- Prettier formatting
				"prettier",
				-- Vale for .md
				"vale",
				-- Lua
				"lua-language-server",
				-- ESLint
				-- "eslint-lsp",
				-- "eslint_d",
				"biome",
				"vtsls",
				"tsgo",
				"zls",

				"nil",
				-- Yaml
				"circleci-yaml-language-server",
				"gh-actions-language-server",
				"yaml-language-server",
				-- GQL
				"graphql-language-service-cli",
				-- JSON
				"json-lsp",
				-- HTML
				"html-lsp",
				-- SQLlike languages
				"sqls",
				-- Debugging
				"codelldb",
				-- Typescript
				-- "typescript-language-server",

				-- Python
				"basedpyright",
				"ruff",

				-- WGPU
				"wgsl-analyzer",
				-- Bash
				"bash-language-server",
				"awk-language-server",
				"shfmt",
				-- Rust toml
				"tombi",
				-- "rust-analyzer",

				-- Typst
				"tinymist",
				"typstyle",

				-- Docker
				"dockerfile-language-server",
			},
		})
	end,
}
