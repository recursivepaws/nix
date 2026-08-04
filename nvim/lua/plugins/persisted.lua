local map = require("utils").map
local telescope = require("utils.lsp").telescope
local git_root = require("utils").git_root

-- Set session options
vim.o.sessionoptions = "buffers,curdir,folds,globals,tabpages,winpos,winsize"
-- Workspace
map("n", "<leader>wo", telescope("persisted"), { desc = "Load session" })
map("n", "<leader>ws", ":SessionSave<cr>", { desc = "Save session" })
map("n", "<leader>wb", telescope("git_branches"), { desc = "Switch branch" })
map("n", "<leader>wa", ":wall<cr>", { desc = "Write all buffers" })
map("n", "<leader>wq", ":wqall<cr>", { desc = "Write quit all buffers" })

return {
	"olimorris/persisted.nvim",
	event = "BufReadPre",
	-- opts = ,
	config = function(_, opts)
		local p = require("persisted")
		p.branch = function()
			local branch = vim.fn.systemlist("git branch --show-current")[1]
			return vim.v.shell_error == 0 and branch or nil
		end
		p.setup({
			ignored_dirs = {
				{ "~", exact = true },
				{ "/", exact = true },
				-- { "~/Documents/hightouch", exact = true },
				{ "~/Documents", exact = true },
			},
			use_git_branch = true,
		})

		vim.api.nvim_create_autocmd("User", {
			pattern = "PersistedTelescopeLoadPre",
			callback = function()
				local persisted = require("persisted")

				if vim.g.dont_save_session == true then
					vim.g.dont_save_session = false
					-- vim.notify("Not saving session during transition state")
					return
				elseif not vim.g.persisted_loaded_session then
					-- vim.notify("No existing session needs saving")
					return
				else
					-- vim.notify("Saving current state as " .. vim.g.persisted_loaded_session)
					-- Save the currently loaded session passing in the path to the current session
					persisted.save({ session = vim.g.persisted_loaded_session })

					-- Delete all of the open buffers
					vim.api.nvim_input("<ESC>:%bd!<CR>")
				end
			end,
		})

		vim.api.nvim_create_autocmd("User", {
			pattern = "PersistedLoadPost",
			callback = function()
				local session_dir = vim.fn.getcwd()
				local temp_file = os.getenv("HOME") .. "/.local/state/nvim/cwd"
				local file = io.open(temp_file, "w")
				if file then
					file:write(session_dir)
					file:close()
					-- vim.notify("Saved cwd")
				end

				local persisted = require("persisted")

				-- Get the branch from the loaded session filename, not current git branch
				local session_branch = nil
				local current_session = persisted.current()

				if current_session then
					-- Extract branch from session filename (format: project@@branch.vim)
					local filename = vim.fn.fnamemodify(vim.g.persisted_loaded_session, ":t:r") -- get filename without extension
					local parts = vim.split(filename, "@@")
					if #parts >= 2 then
						session_branch = parts[2]:gsub("%%", "/")
					end
				end

				if session_branch then
					-- Check if we're already on the correct branch
					local current_branch = vim.fn.systemlist("git branch --show-current")[1]

					if current_branch == session_branch then
						-- vim.notify("Already on branch: " .. session_branch)
						-- Reload every buffer from disk on deference
						vim.defer_fn(function()
							vim.cmd("windo if @% != '' | edit! | endif")
						end, 100)
						return
					end

					-- vim.notify("Switching from " .. current_branch .. " to " .. session_branch)
					local result = vim.fn.system("git checkout --quiet " .. vim.fn.shellescape(session_branch))

					if vim.v.shell_error ~= 0 then
						vim.notify(
							"Failed to checkout branch: " .. session_branch .. "\n" .. result,
							vim.log.levels.ERROR
						)
					else
						-- vim.notify("Successfully switched to branch: " .. session_branch)

						-- When reloading this session, we don't want to save the blank buffers
						-- and overwrite the session we're trying to load
						vim.g.dont_save_session = true
						vim.cmd("SessionLoad")
					end
				else
					-- vim.notify("No branch found in session filename")
				end
			end,
		})
	end,
}
