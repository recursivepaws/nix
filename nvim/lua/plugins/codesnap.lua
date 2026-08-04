return {
	"mistricky/codesnap.nvim",
	dir = require("nix-paths")["codesnap.nvim"],
	cmd = { "CodeSnap", "CodeSnapSave", "CodeSnapASCII", "CodeSnapHighlight" },
	keys = {
		{ "<leader>cc", "<Esc><cmd>CodeSnap<cr>", mode = "x", desc = "Snapshot into clipboard" },
		{
			"<leader>cs",
			function()
				local dir = vim.fn.expand("~/Pictures/Codesnap")
				vim.fn.mkdir(dir, "p")
				vim.cmd("CodeSnapSave " .. dir .. os.date("/%Y-%m-%d_%H-%M-%S") .. ".png")
			end,
			mode = "x",
			desc = "Save snapshot to ~/Pictures/Codesnap",
		},
	},
	opts = {
		snapshot_config = {
			window = {
				margin = { x = 40, y = 28 },
			},
			watermark = {
				content = "",
			},
		},
	},
}
