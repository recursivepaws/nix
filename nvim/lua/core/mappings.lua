local map = require("utils").map
local lead_map = require("utils").lead_map
local is_linux = require("utils").is_linux

-- buffer navigation
lead_map("kp", ":bprev<cr>", "Prev buffer")

lead_map("kn", ":bnext<cr>", "Next buffer")
lead_map("kd", ":bdelete<cr>", "Delete buffer")
lead_map("kc", ":new<cr>", "New buffer")
lead_map("ko", "<cmd>%bd|e#<cr>", "Close all buffers but the current one") -- https://stackoverflow.com/a/42071865/516188

-- tab navigation
lead_map("j[", ":tabprevious<cr>", "Prev tab")
lead_map("j]", ":tabnext<cr>", "Next tab")
lead_map("jn", ":tabnew<cr>", "New tab")
lead_map("jc", ":tabclose<cr>", "Close tab")

-- plugin management
local lazy = require("lazy")
lead_map("pc", lazy.check, "Check plugins")
lead_map("pu", lazy.update, "Update plugins")
lead_map("ps", lazy.show, "Show plugins")
lead_map("ph", lazy.help, "Help")
lead_map("pp", lazy.profile, "Profile")
lead_map("pl", lazy.logs, "Logs")
lead_map("px", lazy.clear, "Clear uninstalled plugins")
lead_map("pr", lazy.restore, "Restore plugins from lockfile")

-- window resizing handled by smart-splits.nvim (<C-w>r to enter resize mode)

map("n", "q:", ":q")

-- Disable arrow keys in normal mode
-- but leave them intact on Mac
if is_linux() then
	map("n", "<up>", "<nop>")
	map("n", "<down>", "<nop>")
	map("n", "<left>", "<nop>")
	map("n", "<right>", "<nop>")
end
