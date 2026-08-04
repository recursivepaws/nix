vim.g.rustaceanvim = {
	tools = {
		hover_actions = { auto_focus = true },
	},
	server = {
		settings = {
			["rust-analyzer"] = {
				-- cargo = {
				--   features = "all",
				-- },
			},
		},
	},
}

-- { "rust-analyzer.server.path": "~/.local/bin/rust-analyzer-linux" }

-- Custom tooling to update the Rust Analyzer target spontaneously
-- function UpdateRustAnalyzerTarget(newTarget)
-- 	require("lspconfig").rust_analyzer.setup({
-- 		settings = {
-- 			["rust-analyzer"] = {
-- 				cargo = {
-- 					--features = "all",
-- 					target = newTarget,
-- 				},
-- 			},
-- 		},
-- 	})
--
-- 	-- Restart rust-analyzer
-- 	vim.lsp.stop_client(vim.lsp.get_active_clients({ name = "rust-analyzer" }))
-- 	vim.cmd([[edit]])
-- end
--
-- vim.cmd([[command! -nargs=1 SetTarget lua UpdateRustAnalyzerTarget(<f-args>)]])
--
-- -- Picker for choosing between targets
-- function RustTargetPicker()
-- 	local targets = {
-- 		"wasm32-unknown-unknown",
-- 		"x86_64-unknown-linux-gnu",
-- 	}
--
-- 	require("telescope.pickers")
-- 		.new({}, {
-- 			prompt_title = "Rust Analyzer Target",
-- 			finder = require("telescope.finders").new_table({
-- 				results = targets,
-- 			}),
-- 			sorter = require("telescope.config").values.generic_sorter({}),
-- 			attach_mappings = function(prompt_bufnr, map)
-- 				local actions = require("telescope.actions")
-- 				actions.select_default:replace(function()
-- 					local selection = require("telescope.actions.state").get_selected_entry()
-- 					actions.close(prompt_bufnr)
-- 					UpdateRustAnalyzerTarget(selection.value)
-- 				end)
--
-- 				return true
-- 			end,
-- 		})
-- 		:find()
-- end
--
-- vim.cmd([[command! PickTarget call v:lua.RustTargetPicker()]])
