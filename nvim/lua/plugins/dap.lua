local map = require("utils").map
local icons = require("utils.icons")

return {
	{
		"rcarriga/nvim-dap-ui",
		dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
		init = function()
			map("n", "<leader>dt", vim.cmd.DapTerminate, { desc = "Terminate" })
			map("n", "<leader>dn", vim.cmd.DapNew, { desc = "New" })
			map("n", "<leader>dc", vim.cmd.DapContinue, { desc = "Continue" })
			map("n", "<leader>db", vim.cmd.DapToggleBreakpoint, { desc = "Toggle Breakpoint" })
			map("n", "<leader>de", vim.cmd.DapEval, { desc = "Evaluate" })
			map("n", "<leader>di", vim.cmd.DapEval, { desc = "Step Into" })
			map("n", "<leader>do", vim.cmd.DapEval, { desc = "Step Out" })
			map("n", "<leader>du", vim.cmd.DapEval, { desc = "Step Over" })
			map("n", "<leader>dd", function()
				require("dapui").toggle()
			end, { desc = "Toggle UI" })
		end,
		config = function()
			require("dapui").setup()
		end,
	},
	{
		"mfussenegger/nvim-dap",
		config = function()
			local dap = require("dap")
			local dapui = require("dapui")

			vim.cmd("hi DapBreakpointColor guifg=#fa4848")
			vim.fn.sign_define(
				"DapBreakpoint",
				{ text = icons.menus.debug, texthl = "DapBreakpointColor", linehl = "", numhl = "" }
			)

			dap.listeners.after.event_initialized["dapui_config"] = dapui.open
			dap.listeners.before.event_terminated["dapui_config"] = dapui.close
			dap.listeners.before.event_exited["dapui_config"] = dapui.close

			dap.adapters.codelldb = {
				type = "server",
				host = "127.0.0.1",
				port = 13000,
				executable = {
					command = "codelldb",
					args = { "--port", "13000" },
				},
			}

			local codelldb = {
				name = "Launch lldb",
				type = "codelldb", -- matches the adapter
				request = "launch", -- could also attach to a currently running process
				program = function()
					return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/target/debug/", "file")
				end,
				cwd = "${workspaceFolder}",
				stopOnEntry = false,
				args = {},
				runInTerminal = false,
			}

			dap.configurations.rust = {
				codelldb,
			}
		end,
	},
}
