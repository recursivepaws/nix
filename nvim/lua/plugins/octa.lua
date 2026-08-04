return {
	"pwntester/octo.nvim",
	requires = {
		"nvim-lua/plenary.nvim",
		"nvim-telescope/telescope.nvim",
		"nvim-tree/nvim-web-devicons",
	},
	lazy = true,
	cmd = { "Octo" },
	config = function()
		require("octo").setup()
		vim.keymap.set("i", "@", "@<C-x><C-o>", { silent = true, buffer = true })
		vim.keymap.set("i", "#", "#<C-x><C-o>", { silent = true, buffer = true })
	end,
}
