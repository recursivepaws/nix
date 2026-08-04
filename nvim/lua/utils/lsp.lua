local M = {}

local augroup_name = "Meow.Lsp"
M.augroup = vim.api.nvim_create_augroup(augroup_name, { clear = true })

M.format_on_save_enabled = true

--- @param operation string
M.telescope = function(operation)
	return function()
		vim.cmd("Telescope " .. operation)
	end
end

M.toggle_format_on_save = function()
	M.format_on_save_enabled = not M.format_on_save_enabled
	vim.notify(string.format("Format on save: %s", M.format_on_save_enabled))
end

M.mason_bin = vim.fn.expand("$HOME/.local/share/nvim/mason/bin/")

--- Resolve a project-local executable from the workspace root's `node_modules/.bin`.
--- The git root is used as the anchor since pnpm installs shared tooling there.
--- @param bin string
--- @return string|nil absolute path to the local binary, if one exists
local function node_modules_bin(bin)
	local root = require("utils").git_root()
	if not root then
		return nil
	end
	local candidate = root .. "/node_modules/.bin/" .. bin
	if vim.fn.executable(candidate) == 1 then
		return candidate
	end
end

--- Build an LSP `cmd` list, preferring the project-local binary over the Mason binary.
--- @param args string[] e.g. `{ "biome", "lsp-proxy" }`
--- @return string[]
M.pnpm_or_mason = function(args)
	args[1] = node_modules_bin(args[1]) or (M.mason_bin .. args[1])
	return args
end

--- Build an LSP `cmd` list, preferring a native binary over the Mason binary
---@param name
M.native_or_mason = function(name)
	if vim.fn.executable(name) == 1 then
		return { name }
	else
		return { M.mason_bin .. name }
	end
end

--- @param root_files string[] List of root-marker files to append to.
--- @param new_names string[] Potential root-marker filenames (e.g. `{ 'package.json', 'package.json5' }`) to inspect for the given `field`.
--- @param field string Field to search for in the given `new_names` files.
--- @param fname string Full path of the current buffer name to start searching upwards from.
function M.root_markers_with_field(root_files, new_names, field, fname)
	local path = vim.fn.fnamemodify(fname, ":h")
	local found = vim.fs.find(new_names, { path = path, upward = true })

	for _, f in ipairs(found or {}) do
		-- Match the given `field`.
		for line in io.lines(f) do
			if line:find(field) then
				root_files[#root_files + 1] = vim.fs.basename(f)
				break
			end
		end
	end

	return root_files
end

function M.insert_package_json(root_files, field, fname)
	return M.root_markers_with_field(root_files, { "package.json", "package.json5" }, field, fname)
end

return M
