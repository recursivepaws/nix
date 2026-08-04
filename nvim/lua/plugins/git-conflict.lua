local lead_map = require("utils").lead_map
local icons = require("utils.icons")

return {
	"akinsho/git-conflict.nvim",
	tag = "*",
	dependencies = { "pogyomo/submode.nvim" },
	config = function()
		local gc = require("git-conflict")
		gc.setup({
			default_mappings = false,
			default_commands = true,
			disable_diagnostics = false,
			list_opener = "copen",
			highlights = {
				incoming = "DiffAdd",
				current = "DiffText",
			},
			debug = false,
		})

		local submode = require("submode")
		lead_map("vc", function()
			submode.enter("GitConflict")
		end, { desc = "Git Conflict" })

		submode.create("GitConflict", {
			mode = "n",
			leave = { "<Esc>", "q", "<C-c>" },
			hook = {
				on_enter = function()
					vim.notify("Git-Conflict mode: entered")
					local bufnr = vim.api.nvim_get_current_buf()
					if gc.conflict_count(bufnr) == 0 then
						vim.notify("No Git Conflicts to resolve.")
						submode.leave()
					end
				end,
				on_leave = function()
					vim.notify("Git-Conflict mode: exited")
				end,
			},

			default = function(register)
				register("o", function()
					gc.choose("ours")
				end, { desc = "Choose ours" })
				register("t", function()
					gc.choose("theirs")
				end, { desc = "Choose theirs" })
				register("b", function()
					gc.choose("both")
				end, { desc = "Choose both" })
				register("x", function()
					gc.choose("none")
				end, { desc = "Choose none" })
				register("[", function()
					gc.find_prev("base")
				end, { desc = "Find prev" })
				register("]", function()
					gc.find_next("base")
				end, { desc = "Find next" })
			end,
		})

		vim.api.nvim_create_autocmd("User", {
			pattern = "GitConflictDetected",
			callback = function()
				vim.notify(icons.warn .. " Git conflict detected")
			end,
		})
	end,
}
