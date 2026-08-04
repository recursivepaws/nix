local icons = require("utils.icons")

-- NOTE:
-- TODO:
-- WARN:
-- PERF:
-- INFO:
-- FIXME:
-- FIXIT:
-- ISSUE:
-- BUG:
-- DOCS:
-- WARNING:
-- XXX:
-- OPTIMIZE:
-- NOTE:
-- REFACTOR:
-- HACK:

-- local dracula = require("").setup()
local palette = require("nightfox.palette").load("carbonfox")

return {
	"folke/todo-comments.nvim",
	dependencies = { "nvim-lua/plenary.nvim", "EdenEast/nightfox.nvim" },
	opts = {
		colors = {
			error = { palette.red.base },
			warning = { palette.orange.base },
			info = { palette.cyan.base },
			hint = { palette.green.base },
			default = { palette.blue.base },
			refactor = { palette.pink.base },
		},
		keywords = {
			FIX = {
				icon = icons.menus.debug, -- icon used for the sign, and in search results
				color = "error", -- can be a hex color, or a named color (see below)
				alt = { "FIXME", "BUG", "FIXIT", "ISSUE", "fix", "fixme", "bug" }, -- a set of other keywords that all map to this FIX keywords
			},
			TODO = { icon = icons.check, color = "info" },
			DOCS = { icon = icons.file, color = "hint" },
			HACK = { icon = icons.flame, color = "warning" },
			WARN = { icon = icons.warn, color = "warning", alt = { "WARNING", "XXX" } },
			PERF = { icon = icons.clock, alt = { "OPTIM", "PERFORMANCE", "OPTIMIZE" } },
			NOTE = { icon = icons.comment, color = "hint" },
			INFO = { icon = icons.info, color = "hint" },
			REFACTOR = { icon = icons.hint, color = "refactor" },
		},
	},
}
