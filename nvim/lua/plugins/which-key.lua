local mi = require("utils.icons").menus

-- local colors = {}
-- for _, name in ipairs({ "azure", "blue", "cyan", "green", "grey", "orange", "purple", "red", "yellow" }) do
--   colors[name] = name
-- end

return {
	"folke/which-key.nvim",
	config = function()
		local wk = require("which-key")
		-- azure, blue, cyan, green, grey, orange, purple, red, yellow
		local get_icon = function(bind, group, color)
			return { "<leader>" .. bind, group = group, icon = { icon = mi[group], color = color } }
		end

		wk.setup({
			win = {
				padding = { 3, 2, 3, 2 },
			},
			layout = {
				height = { min = 10, max = 25 },
				width = { min = 20, max = 50 },
				spacing = 8,
				align = "center",
			},
		})

		wk.add({
			{
				"<leader>?",
				function()
					require("which-key").show({ global = true })
				end,
				desc = "Which-Key",
				icon = mi.question,
			},
			get_icon("x", "diagnostics", "red"),
			get_icon("g", "goto", "orange"),
			get_icon("d", "debug", "yellow"),
			get_icon("f", "find", "green"),
			get_icon("k", "file", "grey"),
			get_icon("l", "lsp", "cyan"),
			get_icon("j", "tab", "grey"),
			get_icon("v", "github", "purple"),
			get_icon("p", "lazy", "grey"),
			get_icon("w", "session", "grey"),
			get_icon("t", "testing", "grey"),
		})
	end,
	event = "VeryLazy",
}
