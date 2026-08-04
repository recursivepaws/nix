return {
	"lukas-reineke/indent-blankline.nvim",
	main = "ibl",
	opts = {},
	config = function()
		require("ibl")
		-- Hide indent guides
		vim.api.nvim_create_autocmd({ "VimEnter" }, {
			command = "IBLDisable",
		})
		-- Show when a buffer is entered
		vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
			command = "IBLEnable",
		})
	end,
}
