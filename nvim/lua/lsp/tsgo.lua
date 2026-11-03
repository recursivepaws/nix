local pnpm_or_path = require("utils.lsp").pnpm_or_path

local cmd = pnpm_or_path({ "tsgo", "--lsp", "-stdio" })
-- nix typescript 7 is the Go port but ships its binary as tsc, not tsgo
if cmd[1] == "tsgo" then
	cmd[1] = "tsc"
end

vim.lsp.config("tsgo", {
	cmd = cmd,
	filetypes = {
		"javascript",
		"javascriptreact",
		"typescript",
		"typescriptreact",
	},
	root_markers = { "tsconfig.json" },
})

vim.lsp.enable("tsgo")
