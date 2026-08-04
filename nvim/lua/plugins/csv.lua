local buf_map = require("utils").buf_map
return {
	"hat0uma/csvview.nvim",
	---@module "csvview"
	---@type CsvView.Options
	opts = {
		parser = { comments = { "#", "//" } },
		keymaps = {
			-- Text objects for selecting fields
			textobject_field_inner = { "if", mode = { "o", "x" } },
			textobject_field_outer = { "af", mode = { "o", "x" } },
			-- Excel-like navigation:
			-- Use <Tab> and <S-Tab> to move horizontally between fields.
			-- Use <Enter> and <S-Enter> to move vertically between rows and place the cursor at the end of the field.
			-- Note: In terminals, you may need to enable CSI-u mode to use <S-Tab> and <S-Enter>.
			jump_next_field_end = { "<Tab>", mode = { "n", "v" } },
			jump_prev_field_end = { "<S-Tab>", mode = { "n", "v" } },
			jump_next_row = { "<Enter>", mode = { "n", "v" } },
			jump_prev_row = { "<S-Enter>", mode = { "n", "v" } },
		},
	},
	-- lazy = false,
	cmd = { "CsvViewEnable", "CsvViewDisable", "CsvViewToggle" },
	init = function()
		local csv_opts = {
			view = {
				display_mode = "border",
				header_lnum = 1,
			},
		}
		vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
			pattern = { "*.csv" },
			callback = function(args)
				local bufnr = tonumber(args.data)
				local map = buf_map(bufnr)

				-- Set up toggle
				map("n", "<leader>lt", function()
					require("csvview").toggle(bufnr, csv_opts)
				end, { desc = "Toggle View" })

				-- Auto enable
				require("csvview").enable(bufnr, csv_opts)
			end,
		})
	end,
}
