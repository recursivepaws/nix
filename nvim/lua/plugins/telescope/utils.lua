local icons = require("utils.icons")
local git_root = require("utils").git_root
local M = {}

M.project_files = function()
	local opts = {} -- define here if you want to define something
	local ok = pcall(require("telescope.builtin").git_files, opts)
	if not ok then
		require("telescope.builtin").find_files({})
	end
end

M.project_grep = function()
	local builtin = require("telescope.builtin")
	local root = git_root()
	if root then
		builtin.live_grep({
			prompt_title = icons.menus.github .. " Grep Git Project " .. icons.menus.github,
			cwd = root,
		})
	else
		vim.notify("Not in a git direcotry")
	end
end

return M
