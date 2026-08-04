local lead_map = require("utils").lead_map

-- Initialize the global diagnostic level
-- vim.g.diagnostic_level = vim.g.diagnostic_level or "error"

-- Mapping of level names to severity constants
-- local severity_map = {
-- 	error = vim.diagnostic.severity.ERROR,
-- 	warn = vim.diagnostic.severity.WARN,
-- 	info = vim.diagnostic.severity.INFO,
-- 	hint = vim.diagnostic.severity.HINT,
-- }
--
-- local cycle_order = { "error", "warn", "info", "hint" }

-- Function to cycle diagnostic level
--[[ function CycleDiagnosticLevel()
	local current = vim.g.diagnostic_level
	local current_index = 1

	-- Find current position in cycle
	for i, level in ipairs(cycle_order) do
		if level == current then
			current_index = i
			break
		end
	end

	-- Get next level (with wraparound)
	local next_index = (current_index % #cycle_order) + 1
	vim.g.diagnostic_level = cycle_order[next_index]

	vim.notify("Diagnostic level: " .. vim.g.diagnostic_level)
end ]]

-- Helper to get current severity
-- function GetCurrentSeverity()
-- 	return severity_map[vim.g.diagnostic_level]
-- end
--
-- -- Navigation functions that respect current level
-- function GotoNextDiagnostic()
-- 	vim.diagnostic.jump({ count = 1, float = true, severity = GetCurrentSeverity() })
-- end
--
-- function GotoPrevDiagnostic()
-- 	vim.diagnostic.jump({ severity = GetCurrentSeverity() })
-- end
--
-- -- Show diagnostics for current level in location list
-- function ShowDiagnosticsInLocList()
-- 	vim.diagnostic.setloclist({ severity = GetCurrentSeverity() })
-- end
--
-- -- Show diagnostics for current level in quickfix
-- function ShowDiagnosticsInQfList()
-- 	vim.diagnostic.setqflist({ severity = GetCurrentSeverity() })
-- end
--
-- map("n", "<leader>xl", function()
-- 	vim.diagnostic.setloclist({ severity = GetCurrentSeverity() })
-- end, { desc = "Loclist" })
--
-- map("n", "<leader>xq", function()
-- 	vim.diagnostic.setloclist({ severity = GetCurrentSeverity() })
-- end, { desc = "Quickfix" })
--
--

lead_map("x[", function()
	vim.diagnostic.jump({ count = -1, float = true })
end, { desc = "Prev diagnostic" })

lead_map("x]", function()
	vim.diagnostic.jump({ count = 1, float = true })
end, { desc = "Next diagnostic" })
lead_map("xs", function()
	vim.diagnostic.open_float()
end, { desc = "Show full diagnostic" })

return {
	"folke/trouble.nvim",
	cmd = "Trouble",
	dependencies = {
		"nvim-tree/nvim-web-devicons",
		"pogyomo/submode.nvim",
	},
	lazy = false,
	config = function()
		local trouble = require("trouble")
		trouble.setup({
			default = {},
		})
		local submode = require("submode")
		lead_map("xx", function()
			submode.enter("Trouble")
		end, { desc = "Diagnostics" })

		submode.create("Trouble", {
			mode = "n",
			leave = { "<Esc>", "q", "<C-c>" },
			hook = {
				on_enter = function()
					vim.notify("Trouble mode: entered")
					if not trouble.is_open("diagnostics") then
						trouble.open({ mode = "diagnostics", focus = false })
					end
				end,
				on_leave = function()
					vim.notify("Trouble mode: exited")
					if trouble.is_open("diagnostics") then
						trouble.close()
					end
				end,
			},

			default = function(register)
				register("[", function()
					trouble.prev("diagnostics", { skip_groups = true, jump = true })
				end, { desc = "Find prev" })
				register("]", function()
					trouble.next("diagnostics", { skip_groups = true, jump = true })
				end, { desc = "Find next" })
			end,
		})
	end,
}

--
-- {
--   "<leader>xx",
--   "<cmd>Trouble diagnostics toggle<cr>",
--   desc = "Diagnostics (Trouble)",
-- },
-- {
--   "<leader>xx",
--   "<cmd>Trouble diagnostics toggle<cr>",
--   desc = "Diagnostics (Trouble)",
-- },
-- {
--   "<leader>xX",
--   "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
--   desc = "Buffer Diagnostics (Trouble)",
-- },
-- {
--   "<leader>xs",
--   "<cmd>Trouble symbols toggle focus=false<cr>",
--   desc = "Symbols (Trouble)",
-- },
-- {
--   "<leader>xl",
--   "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
--   desc = "LSP Definitions / references / ... (Trouble)",
-- },
-- {
--   "<leader>xL",
--   "<cmd>Trouble loclist toggle<cr>",
--   desc = "Location List (Trouble)",
-- },
-- {
--   "<leader>xQ",
--   "<cmd>Trouble qflist toggle<cr>",
--   desc = "Quickfix List (Trouble)",
-- },
