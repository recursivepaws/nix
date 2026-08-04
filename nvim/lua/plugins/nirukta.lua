-- Nirukta (.sloka / .sutra) support: tree-sitter grammar, LSP, and colors.
-- Everything but the colors lives in the nirukta repo itself; this spec
-- puts the grammar on the runtimepath and loads the repo's nvim glue.

local NIRUKTA = vim.fn.expand("~/Software/nirukta")
local GRAMMAR = NIRUKTA .. "/tree-sitter-nirukta"
local GLUE = NIRUKTA .. "/contrib/nvim/nirukta.lua"

-- Only enable on machines where the nirukta grammar + nvim glue are checked
-- out. Elsewhere lazy.nvim would choke on the missing `dir` and the config
-- would error on the dofile below.
local available = vim.fn.isdirectory(GRAMMAR) == 1 and vim.fn.filereadable(GLUE) == 1

return {
  dir = GRAMMAR,
  name = "tree-sitter-nirukta",
  enabled = available,
  lazy = false,
  build = "tree-sitter generate"
    .. " && cc -shared -fPIC -O2 -I src src/parser.c -o parser/nirukta.so",
  config = function()
    dofile(GLUE)

    -- same carbonfox colors the old syntax/nirukta.vim setup used, scoped
    -- to the nirukta grammar via the @capture.nirukta group suffix
    local function colors()
      local palette = require("nightfox.palette").load("carbonfox")
      local hl = {
        ["@markup.heading.nirukta"] = { fg = palette.yellow.base, bold = true },
        ["@keyword.directive.nirukta"] = { fg = palette.magenta.base },
        ["@string.special.nirukta"] = { fg = palette.cyan.base },
        ["@attribute.nirukta"] = { fg = palette.black.bright, italic = true },
        ["@operator.nirukta"] = { fg = palette.pink.base, bold = true },
        ["@punctuation.bracket.nirukta"] = { fg = palette.magenta.base },
        ["@string.nirukta"] = { fg = palette.green.base },
        ["@punctuation.delimiter.nirukta"] = { fg = palette.magenta.dim },
        ["@comment.nirukta"] = { fg = palette.comment, italic = true },
        -- merged and inflected forms render as plain words, like the old setup
        ["@function.nirukta"] = { link = "@none" },
        ["@function.method.nirukta"] = { link = "@none" },
        -- conjugated verb forms (dhatu ~> form)
        ["@function.macro.nirukta"] = { fg = palette.orange.base },
        -- swara accent marks sit inside word tokens, out of the grammar's
        -- reach; the ftplugin highlights them with a window match
        ["slokaSwara"] = { fg = palette.red.bright, bold = true },
      }
      for group, spec in pairs(hl) do
        vim.api.nvim_set_hl(0, group, spec)
      end
    end

    colors()
    vim.api.nvim_create_autocmd("ColorScheme", { callback = colors })
  end,
}
