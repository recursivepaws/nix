local lsp_utils = require("utils.lsp")
local function debug_print(message)
	vim.notify("[NEOTEST-DEBUG] " .. message, vim.log.levels.INFO)
end

--[[ return {
	"nvim-neotest/neotest",
	dependencies = {
		"nvim-neotest/neotest-jest",
		"nvim-neotest/nvim-nio",
		"nvim-lua/plenary.nvim",
		"antoinemadec/FixCursorHold.nvim",
		"nvim-treesitter/nvim-treesitter",
	},
	config = function()
		require("neotest").setup({
			adapters = {
				require("neotest-jest")({
					jestCommand = "pnpm test --",
					jest_test_discovery = false,
					discovery = {
						enabled = true,
					},
					env = { CI = true },
					jestConfigFile = function(file)
						if string.find(file, "/packages/") then
							return string.match(file, "(.-/[^/]+/)src") .. "jest.config.ts"
						end

						return vim.fn.getcwd() .. "/jest.config.ts"
					end,
					cwd = function(file)
						if string.find(file, "/packages/") then
							return string.match(file, "(.-/[^/]+/)src")
						end
						return vim.fn.getcwd()
					end,
				}),
			},
		})
	end,
	keys = {
		{
			"<leader>tn",
			":lua require('neotest').run.run()<CR>",
			desc = "Run nearest test",
			noremap = true,
			silent = true,
		},
		{
			"<leader>tf",
			":lua require('neotest').run.run(vim.fn.expand('%'))<CR>",
			desc = "Run file tests",
		},
		{
			"<leader>ts",
			":lua require('neotest').summary.toggle()<CR>",
			desc = "Toggle test summary",
		},
		{
			"<leader>tw",
			":lua require('neotest').run.run({ jestCommand = 'jest --watch ' })<CR>",
			desc = "Jest test watch",
		},
	},
} ]]

return {}
