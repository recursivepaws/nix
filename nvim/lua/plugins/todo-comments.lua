local icons = require("utils.icons")

-- TODO:
-- FIXME:
-- BUG:
-- HACK:
-- WARN:
-- XXX:
-- PERF:
-- REFACTOR:
-- DEPRECATED:
-- NOTE:
-- DOCS:

local palette = require("nightfox.palette").load("carbonfox")

return {
	"folke/todo-comments.nvim",
	dependencies = { "nvim-lua/plenary.nvim", "EdenEast/nightfox.nvim" },
	opts = {
		merge_keywords = false, -- use only the keywords below, not the plugin defaults
		colors = {
			error = { palette.red.base }, -- FIXME, BUG, SECURITY
			warning = { palette.pink.base }, -- HACK, WARN, XXX
			info = { palette.cyan.base }, -- TODO, REVIEW
			hint = { palette.green.base }, -- NOTE, DOCS
			default = { palette.blue.base }, -- PERF
			refactor = { palette.magenta.base }, -- REFACTOR
			deprecated = { palette.fg3 }, -- DEPRECATED
		},
		keywords = {
			FIXME = { icon = icons.menus.debug, color = "error", alt = { "BUG" } },
			SECURITY = { icon = icons.warn, color = "error" },
			HACK = { icon = icons.flame, color = "warning" },
			WARN = { icon = icons.warn, color = "warning", alt = { "XXX" } },
			TODO = { icon = icons.check, color = "info" },
			REVIEW = { icon = icons.comment, color = "info" },
			NOTE = { icon = icons.comment, color = "hint" },
			DOCS = { icon = icons.file, color = "hint" },
			PERF = { icon = icons.clock, color = "default" },
			REFACTOR = { icon = icons.hint, color = "refactor" },
			DEPRECATED = { icon = icons.file, color = "deprecated" },
		},
	},
}
