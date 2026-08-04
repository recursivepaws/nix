return {
	"mrcjkb/rustaceanvim",
	version = "^6",
	ft = { "rust" },
	lazy = false,
	init = function()
		vim.api.nvim_create_autocmd("BufWritePost", {
			pattern = "*.rs",
			callback = function()
				local cwd = vim.fn.getcwd()
				if vim.fn.filereadable(cwd .. "/Dioxus.toml") == 1 then
					local command = "dx fmt"
					vim.cmd("silent ! " .. command)
					-- vim.notify("dx fmt")
				end
			end,
		})
	end,
}
