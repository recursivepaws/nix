
vim.lsp.config("luals", {
	cmd = { "lua-language-server" },
	filetypes = { "lua" },
	root_markers = { ".luarc.json", ".luarc.jsonc" },
	settings = {
		Lua = {
			runtime = {
				version = "LuaJIT",
			},
			hint = {
				enable = true,
				paramName = "Literal",
				setType = true,
			},
			diagnostics = {
				-- Get the language server to recognize the `vim` global
				globals = {
					"vim",
					"require",
					"ide",
				},
			},
			workspace = {
				checkThirdParty = false,
				library = {
					vim.env.VIMRUNTIME,
					vim.fn.stdpath("data") .. "/lazy",
				},
			},
			-- Do not send telemetry data containing a randomized but unique identifier
			telemetry = {
				enable = false,
			},
		},
	},
})

vim.lsp.enable("luals")
