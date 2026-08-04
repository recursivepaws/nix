local buf_map = require("utils").buf_map
return {
	"danymat/neogen",
	config = function()
		vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
			-- pattern = { "*.js", "*.ts" },
			callback = function(args)
				local map = buf_map(tonumber(args.data))
				map("n", "<leader>ld", function()
					require("neogen").generate()
				end, { desc = "Generate Docs" })
			end,
		})
		require("neogen").setup({ enable = true })
	end,
	version = "*",
}
