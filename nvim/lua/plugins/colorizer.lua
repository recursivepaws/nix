-- Turns color codes like "#FF0000" into actual colors
return {
	"norcalli/nvim-colorizer.lua",
	cmd = { "ColorizerToggle" },
	lazy = false,
	config = function()
		require("colorizer").setup()
	end,
}
