local map = require("utils").map
map("n", "<BS>", "<CMD>Oil<CR>", { desc = "Open File Explorer" })

return {
	"stevearc/oil.nvim",
	opts = {},
	dependencies = { "nvim-tree/nvim-web-devicons" },
	lazy = false,
}
