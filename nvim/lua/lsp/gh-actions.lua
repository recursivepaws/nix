local mason_bin = require("utils.lsp").mason_bin

vim.lsp.config("gh-actions", {
	cmd = { mason_bin .. "gh-actions-language-server", "--stdio" },
	filetypes = { "yaml" },
	-- `root_dir` ensures that the LSP does not attach to all yaml files
	root_dir = function(bufnr, on_dir)
		local parent = vim.fs.dirname(vim.api.nvim_buf_get_name(bufnr))
		if vim.endswith(parent, "/.github/workflows") then
			on_dir(parent)
		end
	end,
	-- Needs to be present
	-- See https://github.com/neovim/nvim-lspconfig/pull/3713#issuecomment-2857394868
	-- Once in v2.1.0 can remove
	init_options = {},
	capabilities = {
		workspace = {
			didChangeWorkspaceFolders = {
				dynamicRegistration = true,
			},
		},
	},
})

vim.lsp.enable("gh-actions")
