local map = require("utils").map
map("v", "<leader>cc", "<cmd>Imprint -o<cr>", { desc = "Screenshot" })
map("n", "<leader>cc", "<cmd>Imprint -o<cr>", { desc = "Screenshot" })

return {
	"glyccogen/imprint.nvim",
	dir = require("nix-paths")["imprint.nvim"],
	pin = true,
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

		-- Imprint --open goes through vim.ui.open, route its output
		-- to the noctalia screen-toolkit annotate overlay instead of xdg-open
		local open = vim.ui.open
		vim.ui.open = function(path, opt)
			if type(path) == "string" and vim.startswith(path, dir .. "/") then
				return vim.system({ "noctalia-shell", "ipc", "call", "plugin:screen-toolkit", "annotateFile", path }), nil
			end
			return open(path, opt)
		end
	end,
}
