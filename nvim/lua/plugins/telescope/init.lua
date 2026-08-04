-- Improved file search

local icons = require("utils.icons")
-- Added cmdline via telescope
return {
	"nvim-telescope/telescope.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-lua/popup.nvim",
		{
			"nvim-telescope/telescope-fzf-native.nvim",
			build = "make",
		},
		"nvim-telescope/telescope-ui-select.nvim",
		"olimorris/persisted.nvim",
	},
	init = function()
		local actions = require("telescope.actions")
		require("telescope").setup({
			defaults = {
				layout_config = {},
				i = {
					["<c-d>"] = actions.delete_buffer,
				},
				n = {
					["<c-d>"] = actions.delete_buffer,
				},
			},
			pickers = {
				-- lsp_references = {
				--   theme = "dropdown",
				-- },
			},
			extensions = {
				["ui-select"] = {
					require("telescope.themes").get_dropdown({ winblend = 10 }),
				},
			},

			prompt_prefix = "🔍 ",
			selection_caret = icons.folder.arrow_closed,
			file_ignore_patterns = {
				".git/",
				"node_modules/",
				"__snapshots__/",
				"*.ipynb",
			},
			dynamic_preview_title = true,
		})

		require("telescope").load_extension("ui-select")
		require("telescope").load_extension("fzf")
		require("telescope").load_extension("persisted")

		-- normal mappings
		local map = require("utils").map
		local telescope = require("utils.lsp").telescope
		local t = require("plugins.telescope.utils")
		local project_files, project_grep = t.project_files, t.project_grep

		map("n", "<leader>fp", project_files, { desc = "Find project file" })
		map("n", "<leader>fg", project_grep, { desc = "Grep whole project" })

		map("n", "<leader>ft", telescope("todo-comments theme=ivy"), { desc = "Find todos" })
		map("n", "<leader>ff", telescope("find_files theme=ivy"), { desc = "Find file" })
		map("n", "<leader>fc", telescope("commands theme=ivy"), { desc = "Find commands" })
		map("n", "<leader>fk", telescope("keys theme=ivy"), { desc = "Find keymappings" })
		map("n", "<leader>fs", telescope("live_grep theme=ivy"), { desc = "Grep string" })
		map("n", "<leader>fh", telescope("help_tags theme=ivy"), { desc = "Find Help" })
		-- map("n", "<leader>ft", telescope("treesitter"), { desc = "Grep treesitter" })
		-- map("n", "<leader>fm", telescope("treesitter symbols=function"), { desc = "Grep methods" })
		map("n", "<leader>fb", telescope("buffers theme=ivy"), { desc = "Find buffer" })
		map("n", "<leader>fw", telescope("grep_string theme=ivy"), { desc = "Grep current word" })
	end,
	lazy = false,
}
