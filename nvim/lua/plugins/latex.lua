return {
	{
		"jbyuki/nabla.nvim",
		keys = {
			--[[ {
				"<leader>nN",
				function()
					require("nabla").popup()
				end,
				desc = "Notation",
			}, ]]
		},
		config = function()
			require("nabla").enable_virt()
		end,
	},
	{
		"vim-pandoc/vim-pandoc",
		event = "VeryLazy",
		enabled = false,
		dependencies = { "vim-pandoc/vim-pandoc-syntax" },
	},
	{
		"frabjous/knap",
		init = function()
			-- vim.g.knap_settings =
		end,
		keys = {
			{
				"<F5>",
				function()
					require("knap").process_once()
				end,
				desc = "Preview",
			},
			{
				"<F6>",
				function()
					require("knap").close_viewer()
				end,
				desc = "Close Preview",
			},
			{
				"<F7>",
				function()
					require("knap").toggle_autopreviewing()
				end,
				desc = "Toggle Preview",
			},
			{
				"<F8>",
				function()
					require("knap").forward_jump()
				end,
				desc = "Forward Jump",
			},
			--[[ {
				"<leader>np",
				function()
					require("knap").launch_notepad()
				end,
				desc = "Temporary Notepad",
			}, ]]
		},
		t = { "markdown", "tex" },
	},
	{
		"lervag/vimtex",
		ft = { "tex" },
		opts = { patterns = { "*.tex" } },
		config = function(_, opts)
			vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
				pattern = opts.patterns,
				callback = function()
					vim.cmd([[VimtexCompile]])
				end,
			})

			vim.g.vimtex_compiler_latexmk = {
				build_dir = ".out",
				options = {
					"-shell-escape",
					"-verbose",
					"-file-line-error",
					"-interaction=nonstopmode",
					"-synctex=1",
				},
			}
			vim.g.vimtex_view_method = "sioyek"
			vim.g.vimtex_fold_enabled = true
			vim.g.vimtex_syntax_conceal = {
				accents = 1,
				ligatures = 1,
				cites = 1,
				fancy = 1,
				spacing = 1,
				greek = 1,
				math_bounds = 1,
				math_delimiters = 1,
				math_fracs = 1,
				math_super_sub = 1,
				sections = 0,
				styles = 1,
			}
		end,
	},
}
