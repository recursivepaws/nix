require("lazy").setup("plugins", {
	-- ~/.config/nvim is a read-only nix store link.
	-- Writing the lock into the repo working tree keeps changes in git.
	lockfile = "/etc/nixos/nvim/lazy-lock.json",
	rocks = { enabled = false },
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
