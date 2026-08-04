local map = require("utils").map
map("v", "<leader>cc", "<cmd>Imprint<cr>", { desc = "Screenshot" })
map("n", "<leader>cc", "<cmd>Imprint<cr>", { desc = "Screenshot" })

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
		local imprint = require("imprint")
		local dir = vim.fn.expand("~/Pictures/Code")
		vim.fn.mkdir(dir, "p")

		imprint.setup({
			output_dir = dir,
			copy_to_clipboard = true,
			required_title_by_default = false,
		})
	end,
}
