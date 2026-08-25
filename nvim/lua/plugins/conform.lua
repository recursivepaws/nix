local pnpm_or_path = require("utils.lsp").pnpm_or_path
return {
	"stevearc/conform.nvim",
	config = function()
		prettier_cmd = pnpm_or_path({ "prettier", "--stdin-filepath", "$FILENAME" })
		require("conform").setup({
			formatters = {
				prettier = {
					command = prettier_cmd[1],
					args = vim.list_slice(prettier_cmd, 2),
				},
				cwd = require("conform.util").root_file({
					".prettierrc",
					".prettierrc.json",
					".prettierrc.js",
					"prettier.config.js",
					"package.json",
				}),
			},
			formatters_by_ft = {
				-- rust = { "rustfmt" },
				javascript = { "prettier" },
				javascriptreact = { "prettier" },
				typescript = { "prettier" },
				typescriptreact = { "prettier" },
				css = { "prettier" },
				json = { "prettier" },
				html = { "prettier" },
				jsonc = { "prettier" },
				yaml = { "prettier" },
				lua = { "stylua" },
				nix = { "nixfmt" },
				sql = {},
				sh = { "shfmt" },
				zsh = { "shfmt" },
				typst = { "typstyle" },
			},
			format_on_save = {
				timeout_ms = 2000,
				lsp_fallback = false,
			},
		})
	end,
}
