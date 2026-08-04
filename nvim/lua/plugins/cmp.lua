return {
	{
		"folke/lazydev.nvim",
		ft = "lua", -- only load on lua files
		opts = {
			library = {
				-- See the configuration section for more details
				-- Load luvit types when the `vim.uv` word is found
				{ path = "${3rd}/luv/library", words = { "vim%.uv" } },
				-- DAP ui
				"nvim-dap-ui",
			},
			integrations = {

				-- lspconfig
			},
		},
	},
	{
		"saghen/blink.cmp",
		version = "*",
		dependencies = {
			"rafamadriz/friendly-snippets",
			"saghen/blink.compat",
			{
				"onsails/lspkind.nvim",
				opts = {
					symbol_map = { spell = "󰓆", cmdline = "", markdown = "" },
				},
			},
			{ "allaman/emoji.nvim", opts = { enable_cmp_integration = true }, lazy = true, event = "InsertEnter" },
		},
		config = function()
			require("blink.cmp").setup({
				keymap = {
					preset = "none",

					-- This is the default preset
					["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
					["<C-e>"] = { "hide" },
					["<C-y>"] = { "select_and_accept" },

					["<Up>"] = { "select_prev", "fallback" },
					["<Down>"] = { "select_next", "fallback" },
					["<C-p>"] = { "select_prev", "fallback_to_mappings" },
					["<C-n>"] = { "select_next", "fallback_to_mappings" },

					["<C-b>"] = { "scroll_documentation_up", "fallback" },
					["<C-f>"] = { "scroll_documentation_down", "fallback" },

					["<Tab>"] = { "snippet_forward", "fallback" },
					["<S-Tab>"] = { "snippet_backward", "fallback" },

					["<C-k>"] = { "show_signature", "hide_signature", "fallback" },
				},
				appearance = {
					use_nvim_cmp_as_default = false,
					nerd_font_variant = "normal",
				},
				completion = {
					menu = {
						border = "single",
						draw = {
							columns = {
								{ "kind_icon" },
								{ "label", "label_description", gap = 1 },
							},
							components = {
								kind_icon = {
									ellipsis = false,
									--[[ highight = function(ctx)
                  local hl = "BlinkCmpKind" .. ctx.kind
                      or require("blink.cmp.completion.windows.render.tailwind").get_hl(ctx)
                  if vim.tbl_contains({ "Path" }, ctx.source_name) then
                    local dev_icon, dev_hl = require("nvim-web-devicons").get_icon(ctx.label)
                    if dev_icon then
                      hl = dev_hl
                    end
                  end
                  return hl
                end, ]]
									text = function(ctx)
										local icon = ctx.kind_icon
										if vim.tbl_contains({ "Path" }, ctx.source_name) then
											local dev_icon, _ = require("nvim-web-devicons").get_icon(ctx.label)
											if dev_icon then
												icon = dev_icon
											end
										else
											icon = require("lspkind").symbol_map[ctx.kind] or ""
										end

										return icon .. ctx.icon_gap
									end,
								},
							},
						},
					},
					documentation = {
						auto_show = true,
						window = { border = "single" },
					},
					accept = { auto_brackets = { enabled = true } },
					-- list = {
					--   selection = { auto_insert = true },
					-- },
				},
				signature = {
					enabled = true,
					window = { border = "single" },
				},
				fuzzy = {
					implementation = "rust",
					sorts = {
						-- -- Always prioritize exact matches, case-sensitive.
						"exact",

						-- Sort by Fuzzy matching score.
						"score",

						-- Kind of thing
						"kind",

						-- This is :
						-- -- Sort by `label` field from LSP server, i.e. name in completion menu.
						-- -- Needed to sort results from LSP server by `label`,
						-- -- even though protocol specifies default value of `sortText` is `label`.
						-- "label",
						function(a, b)
							-- Force labels to the bottom of the list by substituting
							-- underscored prefixes with ascii values lower on the list
							if a.source_id == "lsp" then
								local x = a.label
								local y = b.label
								if x:len() > 1 then
									x = "~" .. x:sub(2)
								end
								if y:len() > 1 then
									y = "~" .. y:sub(2)
								end
								return x < y
							end
						end,
					},
				},
				sources = {
					default = {
						"lazydev",
						"snippets",
						"lsp",
						"buffer",
						"path",
						"emoji",
					},
					per_filetype = {
						markdown = { "markview" },
					},
					providers = {
						lsp = {
							name = "LSP",
							module = "blink.cmp.sources.lsp",
							score_offset = 100, -- Base score for LSP items
							transform_items = function(_, items)
								local before_cursor = vim.api.nvim_get_current_line():sub(1, vim.fn.col("."))
								-- Check if we're typing after a dot (method/property access)
								local is_after_dot = before_cursor:match("%w+%.%s*%w*$") ~= nil
								-- Import completion item kinds for comparison
								local CompletionItemKind = require("blink.cmp.types").CompletionItemKind

								for _, item in ipairs(items) do
									local kind = item.kind

									if is_after_dot then
										-- After dot: prioritize methods and functions
										if kind == CompletionItemKind.Method then
											item.score_offset = 300 -- Highest priority for methods
										elseif kind == CompletionItemKind.Function then
											item.score_offset = 250 -- High priority for functions
										elseif kind == CompletionItemKind.Property then
											item.score_offset = 200 -- Good priority for properties
										elseif kind == CompletionItemKind.Field then
											item.score_offset = 150 -- Medium priority for fields
										else
											item.score_offset = 50 -- Lower priority for other types
										end
									else
										-- From scratch: prioritize variables
										if kind == CompletionItemKind.Variable then
											item.score_offset = 300 -- Highest priority for variables
										elseif kind == CompletionItemKind.Field then
											item.score_offset = 250 -- High priority for fields
										elseif kind == CompletionItemKind.Property then
											item.score_offset = 200 -- Good priority for properties
										elseif kind == CompletionItemKind.Function then
											item.score_offset = 150 -- Medium priority for functions
										elseif kind == CompletionItemKind.Method then
											item.score_offset = 100 -- Lower priority for methods
										else
											item.score_offset = 100 -- Base score for other types
										end
									end
								end

								return items
							end,
						},
						snippets = {
							score_offset = 100,
						},
						lazydev = {
							name = "LazyDev",
							module = "lazydev.integrations.blink",
							score_offset = 90,
						},
						emoji = {
							name = "emoji",
							module = "blink.compat.source",
							-- overwrite kind of suggestion
							transform_items = function(_, items)
								-- vs being triggered by typing keywords from scratch
								local before_cursor = vim.api.nvim_get_current_line():sub(1, vim.fn.col("."))

								-- Check if we're typing after a dot (method/property access)
								local is_after_colon = before_cursor:match("%s+%:%w*$") ~= nil

								local kind = require("blink.cmp.types").CompletionItemKind.Text
								for i = 1, #items do
									items[i].kind = kind
									if is_after_colon then
										items[i].score_offset = 1000
									end
								end
								return items
							end,
							score_offset = 50,
						},
					},
				},
				cmdline = {
					enabled = true,
					sources = function()
						local type = vim.fn.getcmdtype()

						if type == "/" or type == "?" then
							return { "buffer" }
						end
						if type == ":" or type == "@" then
							return { "cmdline", "path", "buffer" }
						end
						return {}
					end,
					completion = {
						menu = { auto_show = true },
					},
				},
			})
		end,
		opts_extend = { "sources.default" },
		lazy = false,
	},
}
