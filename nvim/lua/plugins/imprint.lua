return {
	"glyccogen/imprint.nvim",
	dir = require("nix-paths")["imprint.nvim"],
	cmd = "Imprint",
	dependencies = {
		"nvim-tree/nvim-web-devicons",
	},
	config = function()
		-- tohtml became an opt pack in nvim 0.12, imprint expects it loaded
		vim.cmd.packadd("nvim.tohtml")
		vim.env.PLAYWRIGHT_BROWSERS_PATH = require("nix-paths")["playwright-browsers"]
		vim.env.PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS = "true"
		require("imprint").setup({})
	end,
}
