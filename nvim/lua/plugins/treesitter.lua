return {
	"nvim-treesitter/nvim-treesitter",
	dependencies = {
		"windwp/nvim-ts-autotag",
	},
	lazy = false,
	branch = "main",
	event = "BufEnter",
	build = ":TSUpdate",
	config = function()
		require("nvim-treesitter").install({
			-- real
			"bash",
			"json",
			"lua",
			"swift",
			-- "luadoc",
			"markdown",
			"markdown_inline",
			"toml",
			"yaml",
			"kdl",
			"sql",
			"wgsl",
			"glsl",
			"xml",
			"ssh_config",
			"rust",
			"regex",
			"python",
			"perl",

			-- Without vim, cmdline and docs might break
			"vim",

			-- Required for getting most of the `todo-comments` working
			"comment",

			-- "latex",
			"graphql",

			"gitattributes",
			"gitcommit",
			"gitignore",
			"git_config",
			"git_rebase",

			"dockerfile",
			"rust",
			"csv",

			"nix",

			-- maybe in the future
			-- "make"

			-- fake
			"astro",
			"css",
			"scss",
			"go",
			"html",
			"javascript",
			"jsdoc",
			"php",
			"styled",
			"tsx",
			"typescript",
			"typst",
		})
		-- require("nvim-treesitter.configs").setup({
		-- 	modules = {},
		-- 	sync_install = true,
		-- 	ignore_install = {},
		-- 	auto_install = true,
		-- 	highlight = {
		-- 		enable = true,
		-- 		use_languagetree = true,
		-- 	},
		-- 	indent = {
		-- 		enable = true,
		-- 	},
		-- 	autotag = {
		-- 		enable = true,
		-- 	},
		-- 	refactor = {
		-- 		highlight_definitions = { enable = true },
		-- 		highlight_current_scope = { enable = false },
		-- 	},
		-- })
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
