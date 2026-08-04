return {
	"mrjones2014/smart-splits.nvim",

	-- event = "VeryLazy",
	-- For `kitty` specifically this should be false
	lazy = false,
	dependencies = { "pogyomo/submode.nvim" },
	config = function()
		local ss = require("smart-splits")
		ss.setup({
			default_amount = 3,
			-- Kitty doesn't support `wrap`
			at_edge = "stop",
		})

		-- resize submode: enter with <C-w>r, then h/j/k/l to resize, Esc to exit
		local submode = require("submode")

		submode.create("WinResize", {
			mode = "n",
			enter = "<C-w>r",
			leave = { "<Esc>", "q", "<C-c>" },
			hook = {
				on_enter = function()
					vim.notify("Resize mode: h/j/k/l to resize, Esc to exit")
				end,
				on_leave = function()
					vim.notify("Resize mode: exited")
				end,
			},
			default = function(register)
				register("h", ss.resize_left, { desc = "Resize left" })
				register("j", ss.resize_down, { desc = "Resize down" })
				register("k", ss.resize_up, { desc = "Resize up" })
				register("l", ss.resize_right, { desc = "Resize right" })
			end,
		})
	end,
}
