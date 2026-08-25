return {
	"nvim-treesitter/nvim-treesitter",
	dir = require("nix-paths")["nvim-treesitter"],
	pin = true,
	dependencies = {
		"windwp/nvim-ts-autotag",
	},
	lazy = false,
	config = function()
		-- Parsers are nix-built onto the runtimepath; the list lives in neovim.nix
		-- Register octo as a markdown file
		vim.treesitter.language.register("markdown", "octo")

		-- TODO: Figure out if we need to turn this on for anything
		-- vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"

		-- TODO: Figure out what we actually need here
		--,
		--,
		vim.api.nvim_create_autocmd("FileType", {
			pattern = {
				"bash",
				"c",
				"css",
				"gitcommit",
				"gitignore",
				"vimdoc",
				"wgsl",
				"help",
				"html",
				"json",
				"lua",
				"python",
				"rust",
				"nix",
				"markdown",
				"sh",
				"toml",
				"typescript",
				"typescriptreact",
				"javascript",
				"javascriptreact",
				"yaml",
				"typst",
			},
			callback = function()
				vim.treesitter.start()
			end,
		})
	end,
}
