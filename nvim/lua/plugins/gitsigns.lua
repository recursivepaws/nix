local u = require("utils")
local lead_map = require("utils").lead_map

return {
	"lewis6991/gitsigns.nvim",
	dependencies = { "nvim-lua/plenary.nvim" },
	event = "VeryLazy",
	cmd = "Gs",
	opts = {
		preview_config = {
			-- Options passed to nvim_open_win
			border = "rounded",
			style = "minimal",
			relative = "cursor",
			row = 0,
			col = 1,
		},
		on_attach = function(bufnr)
			local gs = require("gitsigns")
			local map = u.buf_map(bufnr)

			-- Nav
			--- @type Gitsigns.NavOpts
			local navops = {
				wrap = true,
				foldopen = false,
				greedy = true,
				navigation_message = true,
				preview = true,
				count = 1,
				target = "all",
			}

			lead_map("v]", function()
				gs.nav_hunk("next", navops)
			end, { desc = "Next hunk" })
			lead_map("v[", function()
				gs.nav_hunk("prev", navops)
			end, { desc = "Prev hunk" })

			-- Actions
			lead_map("vs", gs.stage_hunk, { desc = "Stage hunk" })
			lead_map("vr", gs.reset_hunk, { desc = "Reset hunk" })
			lead_map("vS", gs.stage_buffer, { desc = "Stage buffer" })
			lead_map("vR", gs.reset_buffer, { desc = "Reset buffer" })
			lead_map("vp", gs.preview_hunk, { desc = "Preview hunk" })
			lead_map("vp", gs.preview_hunk, { desc = "Preview hunk" })
			lead_map("vb", gs.toggle_current_line_blame, { desc = "Current blame line" })
			lead_map("vB", function()
				gs.blame_line({ full = true })
			end, {
				desc = "Blame line",
			})
			lead_map("vd", gs.diffthis, { desc = "Diff buffer" })
			lead_map("vD", function()
				gs.diffthis({}, "~")
			end, { desc = "Diff project" })
			-- lead_map("td", gs.toggle_deleted, { desc = "Toggle delete" })

			--[[ -- Text object ]]
			map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", { desc = "Select hunk" })
		end,
	},
}
