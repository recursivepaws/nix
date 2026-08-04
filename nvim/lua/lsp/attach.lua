local buf_map = require("utils").buf_map
local augroup = require("utils.lsp").augroup

vim.api.nvim_create_autocmd("LspAttach", {
	group = augroup,

	callback = function(args)
		local map = buf_map(args.buf)
		local client = assert(vim.lsp.get_client_by_id(args.data.client_id))

		-- for _, client in ipairs(vim.lsp.get_clients())
		--- @param method vim.lsp.protocol.Method.ClientToServer
		local supports = function(method)
			return client:supports_method(method)
		end

		-- L prefix (perform LSP action)
		map("n", "<leader>lwa", vim.lsp.buf.add_workspace_folder, { desc = "Add workspace folder" })
		map("n", "<leader>lwr", vim.lsp.buf.remove_workspace_folder, { desc = "Remove workspace folder" })
		map("n", "<leader>lwl", function()
			vim.notify(vim.inspect(vim.lsp.buf.list_workspace_folders()))
		end, { desc = "Show workspace folders" })

		if supports("textDocument/codeAction") then
			map("n", "<leader>la", vim.lsp.buf.code_action, { desc = "Code Actions" })
		end

		-- Disable formatting for biome and vtsls
		-- vim.notify(
		--   "lsp attached: "
		--   .. client.name
		--   .. "; formatting: "
		--   .. string.format("%s", client.server_capabilities.documentFormattingProvider)
		-- )

		-- vim.api.nvim_create_autocmd("CursorHold", {
		--   buffer = args.buf,
		--   callback = function()
		--     vim.lsp.buf.hover({ focusable = false, silent = true })
		--   end,
		-- })
		--
		vim.lsp.handlers["textDocument/hover"] =
			vim.lsp.with(vim.lsp.handlers.hover, { focusable = false, border = "rounded", silent = true })

		vim.keymap.set("n", "K", function()
			vim.lsp.buf.hover()
		end, { desc = "Show hover" })

		local format = function()
			local filetype = vim.bo[args.buf].filetype
			if client.name == "eslint" then
				if vim.fn.exists(":LspEslintFixAll") > 0 then
					vim.cmd("LspEslintFixAll")
				end
			else
				if client.name == "rust-analyzer" then
					vim.lsp.buf.format({ bufnr = args.buf, id = client.id, timeout_ms = 2000 })
				elseif
					(
						(filetype == "typescript" or filetype == "javascript")
						and (client.name == "biome" or client.name == "vtsls")
					) or (filetype == "lua" and client.name == "luals")
				then
				-- Do nothing
				-- I want `prettier` and `stylua` to handle this via `conform`
				else
					if not supports("textDocument/willSaveWaitUntil") and supports("textDocument/formatting") then
						vim.lsp.buf.format({ bufnr = args.buf, id = client.id, timeout_ms = 1000 })
					end
				end
			end
		end

		if client.server_capabilities.documentFormattingProvider then
			map("n", "<leader>lf", format, { desc = "Format" })
		end
		-- TODO: range formatting
		-- if supports("textDocument/rangeFormatting") then
		--   map("v", "<leader>lf", vim.lsp.buf.format, { desc = "Range Format" })
		-- end
		if supports("textDocument/rename") then
			map("n", "<leader>lr", vim.lsp.buf.rename, { desc = "Rename" })
		end

		if supports("textDocument/inlayHint") then
			map("n", "<leader>lh", function()
				vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
			end, { desc = "Toggle inlay hints" })
		end

		local builtin = require("telescope.builtin")
		--[[ local theme = { layout_strategy = "horizontal", layout_config = { width = 0.8 } }
    local telescope = function(cmd)
      return function()
        builtin[cmd](theme)
      end
    end ]]
		local telescope = require("utils.lsp").telescope
		if supports("textDocument/implementation") then
			map("n", "<leader>gi", telescope("lsp_implementations theme=ivy"), { desc = "Go to implementation" })
		end

		if supports("textDocument/definition") then
			map("n", "<leader>gd", telescope("lsp_definitions theme=ivy"), { desc = "Go to declaration" })
		end
		if supports("textDocument/typeDefinition") then
			map("n", "<leader>gt", telescope("lsp_type_definitions theme=ivy"), { desc = "Go to type" })
		end
		if supports("textDocument/references") then
			map("n", "<leader>gr", telescope("lsp_references theme=ivy"), { desc = "Go to references" })
		end

		-- F prefix (find)
		-- if supports("textDocument/diagnostic") or supports("workspace/diagnostic") then
		if vim.diagnostic.is_enabled() then
			map("n", "<leader>fd", telescope("diagnostics"), { desc = "Workspace diagnostics" })
		end
		-- end

		vim.api.nvim_create_autocmd("BufWritePre", {
			group = augroup,
			buffer = args.buf,
			callback = format,
		})

		-- Rustaceanvim has some custom options that we need to overwrite
		if client.name == "rust-analyzer" then
			map("n", "K", function()
				vim.cmd.RustLsp({ "hover", "actions" })
			end, { desc = "Hover" })
			map("n", "<leader>la", function()
				vim.cmd.RustLsp("codeAction")
			end, { desc = "Code Actions" })
			map("n", "<leader>lf", format, { desc = "Format" })
			map("v", "<leader>lf", function()
				vim.lsp.buf.format({ bufnr = args.buf, id = client.id, timeout_ms = 2000 })
			end, { desc = "Format" })
		end
	end,
})
