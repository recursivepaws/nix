-- local claude = {
--   adapter = "anthropic",
--   -- model = "claude-sonnet-4-20250514",
-- }

return {
	"olimorris/codecompanion.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-treesitter/nvim-treesitter",
	},
	-- ANTHROPIC_API_KEY must be in env
	opts = {
		interactions = {
			-- chat = claude,
			-- inline = claude,
			-- cmd = claude,
			-- background = claude,
		},
		opts = {
			-- or "TRACE"
			log_level = "DEBUG",
		},
	},
}
