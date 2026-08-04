local M = {}

--- noremap? boolean
--- nowait? boolean
--- silent? boolean
--- script? boolean
--- expr? boolean
--- unique? boolean
--- callback? function
--- desc? string
--- replace_keycodes? boolean

---@param mode string|string[] Mode "short-name" (see |nvim_set_keymap()|), or a list thereof.
---@param lhs string           Left-hand side |{lhs}| of the mapping.
---@param rhs string|function  Right-hand side |{rhs}| of the mapping, can be a Lua function.
---@param opts? vim.keymap.set.Opts
function M.map(mode, lhs, rhs, opts)
	local defaults = {
		silent = true,
		noremap = true,
	}
	vim.keymap.set(mode, lhs, rhs, M.merge(defaults, opts or {}))
end

function M.lead_map(lhs, rhs, opts_or_desc)
	local opts = nil
	if type(opts_or_desc) == "string" then
		opts = { desc = opts_or_desc }
	else
		opts = opts_or_desc
	end
	M.map("n", "<leader>" .. lhs, rhs, opts)
end

function M.buf_map(bufnr, opts)
	return function(mode, lhs, rhs, map_opts)
		M.map(
			mode,
			lhs,
			rhs,
			M.merge({
				buffer = bufnr,
			}, opts or {}, map_opts or {})
		)
	end
end

--- Return the git root for the current directory, or nil when not in a repo.
--- Uses vim.fs.root rather than shelling out to git so it is cheap on hot paths.
function M.git_root()
	return vim.fs.root(vim.fn.getcwd(), ".git")
end

function M.merge_list(tbl1, tbl2)
	for _, v in ipairs(tbl2) do
		table.insert(tbl1, v)
	end
	return tbl1
end

function M.merge(...)
	return vim.tbl_deep_extend("force", ...)
end

function M.split(str, sep)
	local res = {}
	for w in str:gmatch("([^" .. sep .. "]*)") do
		if w ~= "" then
			table.insert(res, w)
		end
	end
	return res
end

function M.get_short_file_path(path)
	local dirs = {}
	for dir in string.gmatch(path, "([^/]+)") do
		table.insert(dirs, dir)
	end

	local n = #dirs
	if n > 3 then
		return "../" .. dirs[n - 2] .. "/" .. dirs[n - 1] .. "/" .. dirs[n]
	end

	return path
end

function M.get_short_cwd()
	local parts = vim.split(vim.fn.getcwd(), "/")
	return parts[#parts]
end

function M.diff_source()
	local gitsigns = vim.b.gitsigns_status_dict
	if gitsigns then
		return {
			added = gitsigns.added,
			modified = gitsigns.changed,
			removed = gitsigns.removed,
		}
	end
end

function M.show_macro_recording()
	local recording_register = vim.fn.reg_recording()
	if recording_register == "" then
		return ""
	else
		return "Recording @" .. recording_register
	end
end

function M.is_linux()
	return vim.loop.os_uname().sysname == "Linux"
end

return M
