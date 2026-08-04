-- vim.lsp.set_log_level("TRACE")

-- Real programming languages
require("lsp.luals")
-- TODO: https://github.com/EmmyLuaLs/emmylua-analyzer-rust
-- apparently much faster
-- require("lsp.emmylua_ls")
require("lsp.basedpyright")
require("lsp.ruff")
require("lsp.sqls")
require("lsp.wgsl")
require("lsp.bashls")
require("lsp.awkls")
require("lsp.dockerls")
require("lsp.tombi")
require("lsp.nil")
require("lsp.tinymist")
require("lsp.zls")

-- XXX: Terminal mental disorders
-- require("lsp.eslint")
-- require("lsp.tsls")

-- INFO: Treatable mental disorders
require("lsp.html")

require("lsp.tsgo")
-- require("lsp.vtsls")
require("lsp.biome")

-- require("lsp.jsonls")

-- Worthy of rehabilitation
require("lsp.yaml")
require("lsp.gh-actions")

-- Normal things
require("lsp.diagnostics")
require("lsp.mappings")

-- vim.lsp.config("rust-analyzer", {})

-- Auto attach mappings
require("lsp.attach")
