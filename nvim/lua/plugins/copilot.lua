local node_runtime = vim.trim(vim.fn.system("source ~/.nvm/nvm.sh && nvm exec --silent 22 which node"):gsub("\n", ""))
return {
	-- "zbirenbaum/copilot.lua",
	-- dependencies = {
	--   -- "copilotlsp-nvim/copilot-lsp",
	-- },
	-- config = function()
	--   require("copilot").setup({
	--     copilot_node_command = node_runtime,
	--   })
	-- end,
}
