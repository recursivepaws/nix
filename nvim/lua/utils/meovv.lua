local M = {}

function M.get_install_dir()
	local config_dir = os.getenv("MEOVVVIM_INSTALL_DIR")
	if not config_dir then
		return vim.fn.stdpath("config")
	end
	return config_dir
end

return M
