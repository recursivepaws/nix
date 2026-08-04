local u = require("utils.meovv")
require("lazy").setup("plugins", {
	lockfile = u.get_install_dir() .. "/lazy-lock.json",
	ui = {
		--border = user_config.border,
		size = { width = 0.7, height = 0.7 },
	},
	performance = {
		rtp = {
			disabled_plugins = {
				"netrw",
				"netrwPlugin",
				"netrwSettings",
				"netrwFileHandlers",
				"gzip",
				"zip",
				"zipPlugin",
				"tar",
				"tarPlugin",
				"getscript",
				"getscriptPlugin",
				"vimball",
				"vimballPlugin",
				"2html_plugin",
				"logipat",
				"rrhelper",
				"spellfile_plugin",
				"matchit",
			},
		},
	},
})
