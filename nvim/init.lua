if vim.fn.has("nvim-0.11") == 0 then
	error("Need Neovim v0.11+ in order to Meovv!")
end

-- No remote plugins in use; skip provider probing
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_node_provider = 0

vim.filetype.add({
	extension = {
		mdx = "markdown",
		wgsl = "wgsl",
		zshrc = "zsh",
		bashrc = "sh",
	},
})

vim.filetype.add({
	pattern = {
		["%.env%.[%w_.-]+"] = "sh",
	},
})

-- Deno-specific markup
vim.g.markdown_fenced_languages = {
	"ts=typescript",
}

local ok, err = pcall(require, "core")
if not ok then
	error(("Error loading core...\n\n%s"):format(err))
end
